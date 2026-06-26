import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/repo.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/common.dart';
import '../../widgets/math_text.dart';
import 'puc_paper_screen.dart' show kSubjects;

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

  // Generation state: which class is picked, and which of its chapters are
  // selected. A class can hold several subject PDFs; chapters are shown flat.
  String? _selClass; // class group key: a class_id, or '__none__' (unassigned)
  final Set<String> _selChapters = {};
  int _mcq = 5, _short = 0, _long = 0;
  bool _busy = false;

  // Curriculum → Subject cascade filters: narrow which syllabi (and therefore
  // which topics/chapters) are shown before picking topics to generate from.
  String? _selCurriculum;
  String? _selSubject;
  // Blueprint extracted from an uploaded previous paper (analyzePaper) plus
  // whether to also mimic its wording/difficulty in the new questions.
  Map<String, dynamic>? _paperFormat;
  bool _mimicStyle = true;

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
    final yearCtrl = TextEditingController();
    String? classId;
    String? selSubject;
    final boards = <String>{};
    const boardOptions = ['JEE', 'NEET', 'CET', 'CBSE', 'State Board'];
    final result = await showDialog<(String, String?, List<String>, String?)>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('New syllabus'),
          content: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Which subject is this syllabus for?'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selSubject,
                isExpanded: true,
                decoration: const InputDecoration(
                    labelText: 'Subject', isDense: true),
                items: kSubjects
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setLocal(() => selSubject = v),
              ),
              const SizedBox(height: 12),
              const Text('Academic year (optional — labels this edition)'),
              const SizedBox(height: 8),
              AppInput(
                  controller: yearCtrl,
                  hint: 'e.g. 2025-26',
                  icon: Icons.event_outlined),
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
              const SizedBox(height: 16),
              const Text('Which exam board(s)? (optional — scopes student '
                  'practice to those boards)'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: boardOptions.map((b) {
                  final sel = boards.contains(b);
                  return InkWell(
                    onTap: () => setLocal(
                        () => sel ? boards.remove(b) : boards.add(b)),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.teal : AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                            color:
                                sel ? AppColors.teal : AppColors.outlineStrong),
                      ),
                      child: Text(b,
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
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () {
                  final s = selSubject?.trim() ?? '';
                  if (s.isEmpty) {
                    _toast('Pick a subject', error: true);
                    return;
                  }
                  Navigator.pop(ctx,
                      (s, classId, boards.toList(), yearCtrl.text.trim()));
                },
                child: const Text('Choose PDF')),
          ],
        ),
      ),
    );
    if (result == null) return;
    final subject = result.$1;
    final classId2 = result.$2;
    final boards2 = result.$3;
    final year2 = result.$4;

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
            classId: classId2, boards: boards2, academicYear: year2);
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

  Future<void> _generateForClass() async {
    if (_busy) return;
    if (_selChapters.isEmpty) {
      _toast('Select at least one chapter', error: true);
      return;
    }
    if (_mcq + _short + _long == 0) {
      _toast('Choose how many questions to generate', error: true);
      return;
    }

    // The backend generates per syllabus (PDF), but a class can hold several
    // subject PDFs. Group the selected chapters by the syllabus they belong to,
    // preserving a stable order, then call generate once per syllabus.
    final group = _groupFor(_selClass);
    final order = <String>[]; // syllabus ids, in display order
    final bySyllabus = <String, List<String>>{};
    for (final syl in group?.syllabi ?? const []) {
      final sid = syl['id'] as String;
      for (final c in (syl['chapters'] as List? ?? const [])) {
        final cid = (c as Map)['id'] as String;
        if (_selChapters.contains(cid)) {
          bySyllabus.putIfAbsent(sid, () {
            order.add(sid);
            return [];
          }).add(cid);
        }
      }
    }
    if (bySyllabus.isEmpty) {
      _toast('Select at least one chapter', error: true);
      return;
    }

    // Spread each requested total evenly across the selected chapters, then sum
    // per syllabus — so counts split sensibly when chapters span subject PDFs.
    final counts = order.map((sid) => bySyllabus[sid]!.length).toList();
    final mcqEach = _splitByChapter(_mcq, counts);
    final shortEach = _splitByChapter(_short, counts);
    final longEach = _splitByChapter(_long, counts);

    // When a previous paper was analyzed and "mimic style" is on, mirror its
    // wording/difficulty in the new questions.
    String? styleRef;
    if (_paperFormat != null && _mimicStyle) {
      final parts = [_paperFormat!['difficulty'], _paperFormat!['style_notes']]
          .where((x) => x != null && x.toString().trim().isNotEmpty)
          .map((x) => x.toString());
      if (parts.isNotEmpty) styleRef = parts.join(' — ');
    }

    setState(() => _busy = true);
    _toast('Generating questions — this can take a moment…');
    var total = 0;
    try {
      for (var i = 0; i < order.length; i++) {
        if (mcqEach[i] + shortEach[i] + longEach[i] == 0) continue;
        final r = await Repo.generateFromSyllabus(
          order[i],
          chapterIds: bySyllabus[order[i]]!,
          mcq: mcqEach[i],
          short: shortEach[i],
          long: longEach[i],
          styleReference: styleRef,
        );
        total += (r['generated'] as num?)?.toInt() ?? 0;
      }
      await _load();
      setState(() {
        _selChapters.clear();
        _tab = 1; // jump to review
      });
      _toast('$total questions generated — review & approve them now');
    } catch (e) {
      _toast('Generation failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Pick a previous question paper PDF and extract its FORMAT — pre-fills the
  /// MCQ/short/long counts and (when "mimic style" stays on) makes the new
  /// questions follow its wording and difficulty.
  Future<void> _analyzePaper() async {
    if (_busy) return;
    final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['pdf'], withData: true);
    final file = picked?.files.firstOrNull;
    if (file == null || file.bytes == null) return;
    setState(() => _busy = true);
    _toast('Reading the paper\'s format…');
    try {
      final fmt = await Repo.analyzePaper(file.bytes!, file.name);
      setState(() {
        _paperFormat = fmt;
        _mimicStyle = true;
        _mcq = ((fmt['mcq'] as num?)?.toInt() ?? _mcq).clamp(0, 30);
        _short = ((fmt['short'] as num?)?.toInt() ?? _short).clamp(0, 15);
        _long = ((fmt['long'] as num?)?.toInt() ?? _long).clamp(0, 10);
      });
      _toast('Format detected — counts set. Pick topics, then Generate.');
    } catch (e) {
      _toast('$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Distribute `total` questions evenly across every selected chapter (one
  /// share each, remainder to the earliest), then fold the shares into
  /// per-syllabus subtotals. `counts[i]` = selected chapters in syllabus i.
  List<int> _splitByChapter(int total, List<int> counts) {
    final k = counts.fold<int>(0, (a, b) => a + b);
    if (k == 0) return List<int>.filled(counts.length, 0);
    final base = total ~/ k;
    var rem = total % k;
    final out = List<int>.filled(counts.length, 0);
    for (var i = 0; i < counts.length; i++) {
      for (var j = 0; j < counts[i]; j++) {
        out[i] += base + (rem > 0 ? 1 : 0);
        if (rem > 0) rem--;
      }
    }
    return out;
  }

  /// Group uploaded syllabi by class, so the validator picks a class first and
  /// then sees all of that class's chapters flat — regardless of how many
  /// subject PDFs were uploaded under it. Syllabi with no class (the global
  /// self-study pool) fall under "All students".
  /// Distinct curricula across uploaded syllabi (for the cascade dropdown).
  List<String> _curriculaList() {
    final set = <String>{};
    for (final s in _syllabi) {
      final c = ((s as Map)['curriculum'] as String?)?.trim() ?? '';
      if (c.isNotEmpty) set.add(c);
    }
    final l = set.toList()..sort();
    return l;
  }

  /// Distinct subjects, narrowed to the chosen curriculum if one is picked.
  List<String> _subjectsList() {
    final set = <String>{};
    for (final s in _syllabi) {
      final syl = s as Map;
      if (syl['archived'] == true) continue;
      final c = (syl['curriculum'] as String?)?.trim() ?? '';
      if (_selCurriculum != null && _selCurriculum!.isNotEmpty && c != _selCurriculum) {
        continue;
      }
      final subj = (syl['subject'] as String?)?.trim() ?? '';
      if (subj.isNotEmpty) set.add(subj);
    }
    final l = set.toList()..sort();
    return l;
  }

  bool _passesCascade(Map syl) {
    final c = (syl['curriculum'] as String?)?.trim() ?? '';
    final subj = (syl['subject'] as String?)?.trim() ?? '';
    if (_selCurriculum != null && _selCurriculum!.isNotEmpty && c != _selCurriculum) {
      return false;
    }
    if (_selSubject != null && _selSubject!.isNotEmpty && subj != _selSubject) {
      return false;
    }
    return true;
  }

  List<_ClassGroup> _classGroups() {
    final map = <String, _ClassGroup>{};
    for (final s in _syllabi) {
      final syl = s as Map<String, dynamic>;
      // Archived (superseded) syllabus editions don't appear in the generate
      // picker — so questions are only ever generated from the current year's.
      if (syl['archived'] == true) continue;
      // Honour the Curriculum → Subject cascade filters.
      if (!_passesCascade(syl)) continue;
      final cid = syl['class_id'] as String?;
      final key = cid ?? '__none__';
      final name = (syl['class_name'] as String?)?.trim();
      map
          .putIfAbsent(
              key,
              () => _ClassGroup(
                  key: key,
                  name: (name == null || name.isEmpty) ? 'All students' : name))
          .syllabi
          .add(syl);
    }
    return map.values.toList()
      ..sort((a, b) {
        if (a.key == '__none__') return 1;
        if (b.key == '__none__') return -1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
  }

  _ClassGroup? _groupFor(String? key) {
    for (final g in _classGroups()) {
      if (g.key == key) return g;
    }
    return null;
  }

  /// Attach a figure (gallery/file) to a generated question the AI flagged as
  /// needing one, so it doesn't reach the bank blank.
  Future<void> _attachFigure(Map<String, dynamic> q) async {
    final id = q['id'] as String;
    final picked = await FilePicker.platform.pickFiles(
        type: FileType.image, withData: true);
    final file = picked?.files.firstOrNull;
    if (file == null || file.bytes == null) return;
    setState(() => _busy = true);
    try {
      final updated = await Repo.uploadGeneratedImage(id, file.bytes!, file.name);
      final i = _pending.indexWhere((x) => x['id'] == id);
      if (i >= 0) {
        setState(() => _pending[i] = {
              ..._pending[i] as Map<String, dynamic>,
              'image_urls': updated['image_urls'],
              'needs_figure': updated['needs_figure'],
            });
      }
      _toast('Figure attached');
    } catch (e) {
      _toast('$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _approve(Map<String, dynamic> q) async {
    final id = q['id'] as String;
    final hasOptions = ((q['options'] as List?) ?? const []).isNotEmpty;
    setState(() => _busy = true);
    try {
      if (hasOptions && _correctSel.containsKey(id)) {
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
    final groups = _classGroups();
    // Default to the first class with material; recover if the previously
    // selected class was deleted or its syllabi removed.
    if (groups.isNotEmpty && !groups.any((g) => g.key == _selClass)) {
      _selClass = groups.first.key;
    }
    final group = _groupFor(_selClass);

    return [
      AppCard(
        color: AppColors.surfaceContainer,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('Upload a syllabus', icon: Icons.upload_file),
            const SizedBox(height: 8),
            Text(
                'Add a subject syllabus PDF for a class. We extract its chapters '
                'so you can generate questions from any chapter.',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 14),
            AppButton(_busy ? 'Working…' : 'Add syllabus PDF',
                icon: Icons.add,
                onPressed: _busy ? null : _startUpload),
          ],
        ),
      ),
      const SizedBox(height: 20),
      if (_syllabi.isEmpty)
        AppCard(
          child: Text('No syllabi yet — upload one above to get started.',
              style: Theme.of(context).textTheme.bodyMedium),
        )
      else ...[
        ..._cascadeAndFormat(),
        const SizedBox(height: 18),
        Text('CHOOSE A CLASS',
            style: AppTheme.mono(11, FontWeight.w600,
                color: AppColors.muted, ls: 1.2)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: groups.map((g) {
            final sel = g.key == _selClass;
            return InkWell(
              onTap: () => setState(() {
                _selClass = g.key;
                _selChapters.clear();
              }),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: sel ? AppColors.primary : AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                      color:
                          sel ? AppColors.primary : AppColors.outlineStrong),
                ),
                child: Text('${g.name}  ·  ${g.chapterCount} ch',
                    style: TextStyle(
                        color:
                            sel ? AppColors.onPrimary : AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        if (group != null) ..._classChapters(group),
      ],
    ];
  }

  /// The Curriculum → Subject cascade filters plus the "match a previous
  /// paper's format" control. Sits above the class/topic picker.
  List<Widget> _cascadeAndFormat() {
    final curricula = _curriculaList();
    final subjects = _subjectsList();
    // Keep dropdown values valid: clear a subject that the chosen curriculum
    // no longer offers (Flutter throws if value isn't among items).
    if (_selSubject != null && !subjects.contains(_selSubject)) {
      _selSubject = null;
    }
    final fmt = _paperFormat;
    return [
      AppCard(
        color: AppColors.surfaceContainer,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('Curriculum → Subject → Topics',
                icon: Icons.account_tree_outlined),
            const SizedBox(height: 6),
            Text(
                'Pick a curriculum and subject to narrow the topics below, then '
                'select topics to generate from.',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: (_selCurriculum?.isNotEmpty ?? false) ? _selCurriculum : null,
                  isExpanded: true,
                  decoration: const InputDecoration(
                      labelText: 'Curriculum', isDense: true),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Any')),
                    ...curricula.map((c) =>
                        DropdownMenuItem(value: c, child: Text(c))),
                  ],
                  onChanged: (v) => setState(() {
                    _selCurriculum = v;
                    _selChapters.clear();
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: (_selSubject?.isNotEmpty ?? false) ? _selSubject : null,
                  isExpanded: true,
                  decoration: const InputDecoration(
                      labelText: 'Subject', isDense: true),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    ...subjects.map((s) =>
                        DropdownMenuItem(value: s, child: Text(s))),
                  ],
                  onChanged: (v) => setState(() {
                    _selSubject = v;
                    _selChapters.clear();
                  }),
                ),
              ),
            ]),
            const Divider(height: 24),
            Row(children: [
              const Icon(Icons.description_outlined,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Match a previous paper (optional)',
                    style: AppTheme.mono(12, FontWeight.w700,
                        color: AppColors.onSurface)),
              ),
            ]),
            const SizedBox(height: 4),
            Text(
                'Upload a past paper — we read its format and pre-fill the '
                'counts. Keep "mimic style" on to copy its wording & difficulty.',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 10),
            AppButton(_busy ? 'Working…' : 'Upload previous paper',
                kind: AppBtnKind.ghost,
                icon: Icons.upload_file,
                onPressed: _busy ? null : _analyzePaper),
            if (fmt != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.scaffold,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Detected: ${(fmt['mcq'] as num?)?.toInt() ?? 0} MCQ · '
                        '${(fmt['short'] as num?)?.toInt() ?? 0} short · '
                        '${(fmt['long'] as num?)?.toInt() ?? 0} long'
                        '${fmt['total_marks'] != null ? ' · ${(fmt['total_marks'] as num).toInt()} marks' : ''}',
                        style: AppTheme.mono(12, FontWeight.w700,
                            color: AppColors.onSurface)),
                    if ((fmt['difficulty'] as String?)?.trim().isNotEmpty ?? false) ...[
                      const SizedBox(height: 6),
                      Text('Difficulty: ${fmt['difficulty']}',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                    if ((fmt['style_notes'] as String?)?.trim().isNotEmpty ?? false) ...[
                      const SizedBox(height: 4),
                      Text('Style: ${fmt['style_notes']}',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                    const SizedBox(height: 6),
                    Row(children: [
                      Checkbox(
                        value: _mimicStyle,
                        activeColor: AppColors.primary,
                        onChanged: (v) =>
                            setState(() => _mimicStyle = v ?? true),
                      ),
                      const Expanded(
                          child: Text('Mimic style & difficulty when generating')),
                    ]),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ];
  }

  /// All of the selected class's chapters, flat and grouped by subject, with
  /// the question-count steppers and the generate button.
  List<Widget> _classChapters(_ClassGroup group) {
    final rows = <Widget>[];
    String? lastSubject;
    var anyChapters = false;
    for (final syl in group.syllabi) {
      final subject = syl['subject']?.toString() ?? 'Subject';
      final year = (syl['academic_year'] as String?)?.trim() ?? '';
      // Edition label keeps two years of the same subject distinguishable.
      final header = year.isEmpty ? subject : '$subject · $year';
      final chapters = (syl['chapters'] as List?) ?? const [];
      for (final c in chapters) {
        anyChapters = true;
        final ch = c as Map<String, dynamic>;
        final cid = ch['id'] as String;
        final on = _selChapters.contains(cid);
        // Subheader whenever the edition changes — keeps the flat list scannable
        // when a class spans several subject PDFs / years.
        if (header != lastSubject) {
          lastSubject = header;
          rows.add(Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 2),
            child: Text(header.toUpperCase(),
                style: AppTheme.mono(11, FontWeight.w700,
                    color: AppColors.primary, ls: 0.8)),
          ));
        }
        rows.add(CheckboxListTile(
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
        ));
      }
    }

    return [
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('SELECT CHAPTERS',
                  style: AppTheme.mono(11, FontWeight.w600,
                      color: AppColors.muted, ls: 1.2)),
              const Spacer(),
              Text('${_selChapters.length} selected',
                  style: AppTheme.mono(11, FontWeight.w500,
                      color: AppColors.muted)),
            ]),
            if (!anyChapters)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text('No chapters extracted yet for this class.',
                    style: Theme.of(context).textTheme.bodyMedium),
              )
            else
              ...rows,
            const Divider(height: 24),
            Text('HOW MANY (across selected chapters)',
                style: AppTheme.mono(11, FontWeight.w600,
                    color: AppColors.muted, ls: 1.2)),
            const SizedBox(height: 8),
            _counter('MCQ', _mcq, 30, (v) => setState(() => _mcq = v)),
            _counter(
                'Short answer', _short, 15, (v) => setState(() => _short = v)),
            _counter('Long answer', _long, 10, (v) => setState(() => _long = v)),
            const SizedBox(height: 14),
            AppButton(_busy ? 'Generating…' : 'Generate questions',
                icon: Icons.auto_awesome,
                expand: true,
                onPressed: _busy ? null : _generateForClass),
          ],
        ),
      ),
    ];
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
    final isBank = q['_source'] == 'bank';
    final options = (q['options'] as List?) ?? const [];
    // Any option-bearing type (MCQ, assertion-reason, match-columns) gets the
    // selectable option list + correct-key picker.
    final isMcq = options.isNotEmpty;
    final answerText = (q['answer_text'] as String?)?.trim() ?? '';
    final marking = (q['marking_scheme'] as List?) ?? const [];
    final solution = (q['solution'] as String?)?.trim() ?? '';
    final imageUrls = ((q['image_urls'] as List?) ?? const []).cast<String>();
    final needsFigure = q['needs_figure'] == true && imageUrls.isEmpty;
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
              if (q['difficulty'] != null) ...[
                DifficultyChip((q['difficulty'] as num).toInt()),
                const SizedBox(width: 8),
              ],
              if (needsFigure) ...[
                StatusChip('Needs figure',
                    color: AppColors.secondary,
                    icon: Icons.image_not_supported_outlined),
                const SizedBox(width: 8),
              ],
              if (isBank) ...[
                StatusChip('Needs key',
                    color: AppColors.secondary, icon: Icons.vpn_key_outlined),
                const SizedBox(width: 8),
              ],
              if (q['verified'] == true) ...[
                StatusChip('AI-checked',
                    color: AppColors.success, icon: Icons.verified_outlined),
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
            MixedMathText(
              q['prompt']?.toString() ?? '',
              fontSize: 15,
              color: AppColors.onSurface,
              style: const TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.35),
            ),
            if (((q['verify_notes'] as String?) ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.auto_awesome,
                    size: 13, color: AppColors.success),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(q['verify_notes'].toString(),
                      style: AppTheme.mono(10.5, FontWeight.w500,
                          color: AppColors.success)),
                ),
              ]),
            ],
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
                          child: MixedMathText(text,
                              fontSize: 15,
                              color: AppColors.onSurface,
                              style: Theme.of(context).textTheme.bodyMedium)),
                    ]),
                  ),
                );
              }),
              Text('Tap the correct option before approving.',
                  style: AppTheme.mono(10.5, FontWeight.w500,
                      color: AppColors.muted)),
            ],
            // Numeric answer (integer/numeric types) so the validator can verify it.
            if (!isMcq && answerText.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Answer:  ',
                    style: AppTheme.mono(12, FontWeight.w700,
                        color: AppColors.success)),
                Expanded(
                  child: MixedMathText(answerText,
                      fontSize: 14, color: AppColors.onSurface),
                ),
              ]),
            ],
            // Step-wise marking scheme for long / case-study answers.
            if (marking.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('MARKING SCHEME',
                  style: AppTheme.mono(10, FontWeight.w700,
                      color: AppColors.muted, ls: 1)),
              const SizedBox(height: 4),
              for (final m in marking)
                if (m is Map)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('+${m['marks'] ?? 0}  ',
                              style: AppTheme.mono(11, FontWeight.w700,
                                  color: AppColors.success)),
                          Expanded(
                            child: MixedMathText(
                                (m['step'] ?? '').toString(),
                                fontSize: 13,
                                color: AppColors.onSurface),
                          ),
                        ]),
                  ),
            ],
            // Worked solution for non-option types (short/long/case-study/integer).
            if (!isMcq && solution.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('MODEL ANSWER',
                  style: AppTheme.mono(10, FontWeight.w700,
                      color: AppColors.muted, ls: 1)),
              const SizedBox(height: 4),
              MixedMathText(solution,
                  fontSize: 13, color: AppColors.onSurface),
            ],
            // Attached figures, if any.
            if (imageUrls.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final url in imageUrls)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: Image.network(url,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox(
                              height: 80, width: 80,
                              child: Icon(Icons.broken_image_outlined,
                                  color: AppColors.muted))),
                    ),
                ],
              ),
            ],
            // Figure attach (this question references a diagram the AI couldn't draw).
            if (q['needs_figure'] == true || imageUrls.isNotEmpty) ...[
              const SizedBox(height: 8),
              if (needsFigure)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                      'This question references a figure — attach it before approving.',
                      style: AppTheme.mono(10.5, FontWeight.w500,
                          color: AppColors.secondary)),
                ),
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _attachFigure(q),
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 16),
                label: Text(imageUrls.isEmpty ? 'Attach figure' : 'Add another figure'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.outlineStrong)),
              ),
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
      case 'integer':
      case 'numeric':
        return 'Numeric';
      case 'assertion_reason':
        return 'Assertion–Reason';
      case 'match_columns':
        return 'Match';
      case 'case_study':
        return 'Case Study';
      default:
        return 'MCQ';
    }
  }
}

/// One class's worth of uploaded material: the syllabi (subject PDFs) tagged to
/// it, used to show the class's chapters flat on the Generate tab.
class _ClassGroup {
  _ClassGroup({required this.key, required this.name});
  final String key; // class_id, or '__none__' for the unassigned/global pool
  final String name;
  final List<Map<String, dynamic>> syllabi = [];
  int get chapterCount => syllabi.fold<int>(
      0, (a, s) => a + ((s['chapters'] as List?)?.length ?? 0));
}
