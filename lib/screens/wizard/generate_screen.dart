import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/repo.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/common.dart';

/// Validator / teacher workspace: upload a syllabus, generate questions from
/// its chapters with Gemini, then review and approve them into the bank. This
/// is the mobile-native equivalent of the super-admin web portal's syllabus →
/// generate → approve flow, so validators (who only have phones) can build the
/// self-study question bank without a computer.
class GenerateScreen extends StatefulWidget {
  const GenerateScreen({super.key});
  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen> {
  int _tab = 0; // 0 = Generate, 1 = Review
  bool _loading = true;
  String? _error;

  List<dynamic> _syllabi = [];
  List<dynamic> _pending = []; // generated questions awaiting approval
  List<dynamic> _bankNeedsKey = []; // bank MCQs missing an answer key
  List<dynamic> _classes = []; // institution's classes, for tagging on upload

  // Inline generation state for the currently-expanded syllabus.
  String? _expandedId;
  final Set<String> _selChapters = {};
  int _mcq = 5, _short = 0, _long = 0;
  bool _busy = false;

  // Per-question chosen correct option index in the review tab.
  final Map<String, int> _correctSel = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        Repo.syllabi(),
        Repo.generatedQuestions(status: 'pending'),
        Repo.bankNeedsKey(),
        Repo.classes(),
      ]);
      if (!mounted) return;
      final pending = results[1];
      for (final q in pending) {
        (q as Map)['_source'] = 'generated';
      }
      final bank = results[2];
      for (final q in bank) {
        (q as Map)['_source'] = 'bank';
      }
      setState(() {
        _syllabi = results[0];
        _pending = pending;
        _bankNeedsKey = bank;
        _classes = results[3];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.error : AppColors.success,
    ));
  }

  /// Ask for the subject, then pick a PDF and upload it as a syllabus.
  Future<void> _startUpload() async {
    if (_busy) return;
    final ctrl = TextEditingController();
    String? classId;
    final result = await showDialog<(String, String?)>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('New syllabus'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Which subject is this syllabus for?'),
              const SizedBox(height: 12),
              AppInput(
                  controller: ctrl, hint: 'e.g. Physics', icon: Icons.book_outlined),
              const SizedBox(height: 16),
              Text(_classes.isEmpty
                  ? 'No classes yet — create one first so you can tag this.'
                  : 'Which class? (only that class\'s students will see it)'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _classes.map((c) {
                  final cls = c as Map<String, dynamic>;
                  final id = cls['id'] as String;
                  final sel = classId == id;
                  return InkWell(
                    onTap: () => setLocal(() => classId = id),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primary : AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                            color: sel
                                ? AppColors.primary
                                : AppColors.outlineStrong),
                      ),
                      child: Text(cls['name']?.toString() ?? 'Class',
                          style: TextStyle(
                              color: sel
                                  ? AppColors.onPrimary
                                  : AppColors.onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () {
                  final s = ctrl.text.trim();
                  if (s.isEmpty) return;
                  Navigator.pop(ctx, (s, classId));
                },
                child: const Text('Choose PDF')),
          ],
        ),
      ),
    );
    if (result == null) return;
    final subject = result.$1;
    final classId2 = result.$2;

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
      allowMultiple: true,
    );
    final files =
        picked?.files.where((f) => f.bytes != null).toList() ?? [];
    if (files.isEmpty) return;

    setState(() => _busy = true);
    var done = 0;
    try {
      // Each selected PDF is uploaded as its own syllabus under this subject;
      // chapter extraction runs per file, so this can take a moment each.
      for (final file in files) {
        _toast(
            'Uploading "${file.name}" (${done + 1}/${files.length}) — extracting chapters…');
        await Repo.uploadSyllabus(file.bytes!, file.name, subject,
            classId: classId2);
        done++;
      }
      await _load();
      _toast(files.length == 1
          ? 'Syllabus added — pick chapters to generate questions'
          : '$done syllabus PDFs added — pick chapters to generate');
    } catch (e) {
      await _load();
      _toast('Uploaded $done of ${files.length}; failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _generate(Map<String, dynamic> syl) async {
    if (_busy) return;
    if (_selChapters.isEmpty) {
      _toast('Select at least one chapter', error: true);
      return;
    }
    if (_mcq + _short + _long == 0) {
      _toast('Choose how many questions to generate', error: true);
      return;
    }
    setState(() => _busy = true);
    _toast('Generating questions — this can take a moment…');
    try {
      final r = await Repo.generateFromSyllabus(
        syl['id'] as String,
        chapterIds: _selChapters.toList(),
        mcq: _mcq,
        short: _short,
        long: _long,
      );
      final n = r['generated'] ?? 0;
      await _load();
      setState(() {
        _expandedId = null;
        _selChapters.clear();
        _tab = 1; // jump to review
      });
      _toast('$n questions generated — review & approve them now');
    } catch (e) {
      _toast('Generation failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _approve(Map<String, dynamic> q) async {
    final id = q['id'] as String;
    final isMcq = q['qtype'] == 'multiple_choice';
    setState(() => _busy = true);
    try {
      if (isMcq && _correctSel.containsKey(id)) {
        await Repo.editGenerated(id, correct: _correctSel[id]);
      }
      await Repo.approveGenerated(id);
      setState(() => _pending.removeWhere((x) => x['id'] == id));
      _toast('Approved — added to the bank');
    } catch (e) {
      _toast('$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveKey(Map<String, dynamic> q) async {
    final id = q['id'] as String;
    final sel = _correctSel[id] ?? -1;
    if (sel < 0) {
      _toast('Tap the correct option first', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await Repo.setAnswerKey(id, sel);
      setState(() => _bankNeedsKey.removeWhere((x) => x['id'] == id));
      _toast('Answer key saved — now practice-ready');
    } catch (e) {
      _toast('$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject(Map<String, dynamic> q) async {
    final id = q['id'] as String;
    setState(() => _busy = true);
    try {
      await Repo.rejectGenerated(id);
      setState(() => _pending.removeWhere((x) => x['id'] == id));
      _toast('Discarded');
    } catch (e) {
      _toast('$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Generate Questions',
      currentRoute: '/generate',
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  _tabBar(),
                  const SizedBox(height: 16),
                  if (_error != null)
                    AppCard(
                      color: AppColors.error.withValues(alpha: 0.08),
                      child: Text(_error!,
                          style: const TextStyle(color: AppColors.error)),
                    )
                  else if (_tab == 0)
                    ..._generateTab()
                  else
                    ..._reviewTab(),
                ],
              ),
            ),
    );
  }

  Widget _tabBar() {
    Widget pill(String label, int idx, {int? badge}) {
      final sel = _tab == idx;
      return Expanded(
        child: InkWell(
          onTap: () => setState(() => _tab = idx),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: sel ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                  color: sel ? AppColors.primary : AppColors.outline),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: AppTheme.mono(13, FontWeight.w600,
                        color: sel ? AppColors.onPrimary : AppColors.onSurface,
                        ls: 0.5)),
                if (badge != null && badge > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.onPrimary : AppColors.secondaryStrong,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text('$badge',
                        style: AppTheme.mono(11, FontWeight.w700,
                            color: sel ? AppColors.primary : const Color(0xFF3A1500))),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Row(children: [
      pill('GENERATE', 0),
      const SizedBox(width: 10),
      pill('REVIEW', 1, badge: _pending.length + _bankNeedsKey.length),
    ]);
  }

  // ---- Generate tab ----

  List<Widget> _generateTab() {
    return [
      AppCard(
        color: AppColors.surfaceContainer,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('Upload a syllabus', icon: Icons.upload_file),
            const SizedBox(height: 8),
            Text(
                'Add a subject syllabus PDF. We extract its chapters so you can '
                'generate questions from any chapter.',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 14),
            AppButton(_busy ? 'Working…' : 'Add syllabus PDF',
                icon: Icons.add,
                onPressed: _busy ? null : _startUpload),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Text('YOUR SYLLABI',
          style: AppTheme.mono(11, FontWeight.w600,
              color: AppColors.muted, ls: 1.2)),
      const SizedBox(height: 10),
      if (_syllabi.isEmpty)
        AppCard(
          child: Text('No syllabi yet — upload one above to get started.',
              style: Theme.of(context).textTheme.bodyMedium),
        )
      else
        ..._syllabi.map((s) => _syllabusCard(s as Map<String, dynamic>)),
    ];
  }

  Widget _syllabusCard(Map<String, dynamic> syl) {
    final id = syl['id'] as String;
    final chapters = (syl['chapters'] as List?) ?? const [];
    final expanded = _expandedId == id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() {
                if (expanded) {
                  _expandedId = null;
                  _selChapters.clear();
                } else {
                  _expandedId = id;
                  _selChapters.clear();
                  _mcq = 5;
                  _short = 0;
                  _long = 0;
                }
              }),
              child: Row(children: [
                const Icon(Icons.menu_book_outlined,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(syl['subject']?.toString() ?? 'Subject',
                          style: Theme.of(context).textTheme.titleMedium),
                      Text('${chapters.length} chapters',
                          style: AppTheme.mono(11, FontWeight.w500,
                              color: AppColors.muted)),
                    ],
                  ),
                ),
                Icon(expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.muted),
              ]),
            ),
            if (expanded) ...[
              const Divider(height: 24),
              Text('SELECT CHAPTERS',
                  style: AppTheme.mono(11, FontWeight.w600,
                      color: AppColors.muted, ls: 1.2)),
              const SizedBox(height: 6),
              ...chapters.map((c) {
                final ch = c as Map<String, dynamic>;
                final cid = ch['id'] as String;
                final on = _selChapters.contains(cid);
                return CheckboxListTile(
                  value: on,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppColors.primary,
                  title: Text('${ch['number']}. ${ch['title']}',
                      style: Theme.of(context).textTheme.bodyMedium),
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      _selChapters.add(cid);
                    } else {
                      _selChapters.remove(cid);
                    }
                  }),
                );
              }),
              const SizedBox(height: 8),
              Text('HOW MANY (across selected chapters)',
                  style: AppTheme.mono(11, FontWeight.w600,
                      color: AppColors.muted, ls: 1.2)),
              const SizedBox(height: 8),
              _counter('MCQ', _mcq, 30, (v) => setState(() => _mcq = v)),
              _counter('Short answer', _short, 15, (v) => setState(() => _short = v)),
              _counter('Long answer', _long, 10, (v) => setState(() => _long = v)),
              const SizedBox(height: 14),
              AppButton(_busy ? 'Generating…' : 'Generate questions',
                  icon: Icons.auto_awesome,
                  expand: true,
                  onPressed: _busy ? null : () => _generate(syl)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _counter(String label, int value, int max, ValueChanged<int> onChange) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(
            child: Text(label,
                style: Theme.of(context).textTheme.bodyMedium)),
        _stepBtn(Icons.remove, value > 0 ? () => onChange(value - 1) : null),
        SizedBox(
          width: 36,
          child: Text('$value',
              textAlign: TextAlign.center,
              style: AppTheme.mono(15, FontWeight.w700)),
        ),
        _stepBtn(Icons.add, value < max ? () => onChange(value + 1) : null),
      ]),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback? onTap) => Material(
        color: onTap == null ? AppColors.surface : AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon,
                size: 18,
                color: onTap == null ? AppColors.muted : AppColors.primary),
          ),
        ),
      );

  // ---- Review tab ----

  List<Widget> _reviewTab() {
    final items = [..._pending, ..._bankNeedsKey];
    if (items.isEmpty) {
      return [
        AppCard(
          child: Column(children: [
            const Icon(Icons.check_circle_outline,
                color: AppColors.success, size: 40),
            const SizedBox(height: 10),
            Text('Nothing to review',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
                'Generated questions and bank questions that still need an '
                'answer key will appear here.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
          ]),
        ),
      ];
    }
    return [
      Text('${items.length} to review'
          '${_bankNeedsKey.isNotEmpty ? " · ${_bankNeedsKey.length} need an answer key" : ""}',
          style: AppTheme.mono(11, FontWeight.w600,
              color: AppColors.muted, ls: 1.2)),
      const SizedBox(height: 10),
      ...items.map((q) => _reviewCard(q as Map<String, dynamic>)),
    ];
  }

  Widget _reviewCard(Map<String, dynamic> q) {
    final id = q['id'] as String;
    final isMcq = q['qtype'] == 'multiple_choice';
    final isBank = q['_source'] == 'bank';
    final options = (q['options'] as List?) ?? const [];
    // Default selected correct option = whichever the AI flagged, if any.
    final flagged = options.indexWhere(
        (o) => o is Map && o['correct'] == true);
    final sel = _correctSel[id] ?? (flagged >= 0 ? flagged : -1);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              StatusChip(_typeLabel(q['qtype']?.toString()),
                  color: AppColors.primary),
              const SizedBox(width: 8),
              if (isBank) ...[
                StatusChip('Needs key',
                    color: AppColors.secondary, icon: Icons.vpn_key_outlined),
                const SizedBox(width: 8),
              ],
              if (q['topic'] != null)
                Expanded(
                  child: Text(q['topic'].toString(),
                      style: AppTheme.mono(11, FontWeight.w500,
                          color: AppColors.muted),
                      overflow: TextOverflow.ellipsis),
                ),
            ]),
            const SizedBox(height: 10),
            Text(q['prompt']?.toString() ?? '',
                style: const TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.35)),
            if (isMcq) ...[
              const SizedBox(height: 10),
              ...List.generate(options.length, (i) {
                final o = options[i];
                final text = o is Map
                    ? (o['text'] ?? o['label'] ?? o.toString()).toString()
                    : o.toString();
                final on = sel == i;
                return InkWell(
                  onTap: () => setState(() => _correctSel[id] = i),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: on
                          ? AppColors.success.withValues(alpha: 0.10)
                          : AppColors.scaffold,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                          color: on ? AppColors.success : AppColors.outline),
                    ),
                    child: Row(children: [
                      Icon(
                          on
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 18,
                          color: on ? AppColors.success : AppColors.muted),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(text,
                              style: Theme.of(context).textTheme.bodyMedium)),
                    ]),
                  ),
                );
              }),
              Text('Tap the correct option before approving.',
                  style: AppTheme.mono(10.5, FontWeight.w500,
                      color: AppColors.muted)),
            ],
            const SizedBox(height: 12),
            if (isBank)
              AppButton('Save answer key',
                  icon: Icons.vpn_key,
                  expand: true,
                  onPressed: _busy ? null : () => _saveKey(q))
            else
              Row(children: [
                Expanded(
                  child: AppButton('Approve',
                      icon: Icons.check,
                      expand: true,
                      onPressed: _busy ? null : () => _approve(q)),
                ),
                const SizedBox(width: 10),
                AppButton('Reject',
                    kind: AppBtnKind.ghost,
                    onPressed: _busy ? null : () => _reject(q)),
              ]),
          ],
        ),
      ),
    );
  }

  String _typeLabel(String? t) {
    switch (t) {
      case 'short_answer':
        return 'Short';
      case 'long_answer':
        return 'Long';
      default:
        return 'MCQ';
    }
  }
}
