import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../app/theme.dart';
import '../../data/exam_scope.dart';
import '../../data/repo.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/common.dart';
import '../../widgets/math_text.dart';
// Canonical subjects (kept on top); shared with the upload picker.
const kSubjects = ['Maths', 'Physics', 'Chemistry', 'Biology'];

/// Canonical subjects first, then any extra (legacy/DB) ones, de-duplicated.
List<String> subjectOptions(Iterable<String> extra) {
  final seen = <String>{};
  final out = <String>[];
  for (final s in [...kSubjects, ...extra]) {
    final t = s.trim();
    final k = t.toLowerCase();
    if (t.isEmpty || seen.contains(k)) continue;
    seen.add(k);
    out.add(t);
  }
  return out;
}

/// One blueprint section (Section A/B/C): how many questions of a bucket.
class _Section {
  _Section(this.name, this.bucket, this.marks, this.count);
  String name;
  String bucket; // mcq | short | long
  int marks;
  int count;
}

/// PUC Paper builder for validators: pick class → curriculum → subject →
/// topics, generate a fresh paper FROM THE TEXTBOOK, view/edit it, print/
/// download it, then submit the questions into the bank for students.
class PucPaperScreen extends StatefulWidget {
  const PucPaperScreen({super.key});
  @override
  State<PucPaperScreen> createState() => _PucPaperScreenState();
}

class _PucPaperScreenState extends State<PucPaperScreen> {
  bool _loading = true;
  String? _error;
  bool _busy = false;

  List<dynamic> _classes = [];
  List<dynamic> _topics = []; // all topics for the chosen class+curriculum
  String? _selClass;
  String? _selCurriculum;
  String? _selSubject;
  final Set<String> _selChapters = {}; // chapter_id values
  String? _board;
  final _titleCtrl = TextEditingController(text: '');

  final List<_Section> _blueprint = [
    _Section('Section A', 'mcq', 1, 5),
    _Section('Section B', 'short', 2, 3),
    _Section('Section C', 'long', 5, 2),
  ];

  Map<String, dynamic>? _paper; // the generated paper (editable)

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final classes = await Repo.classes();
      if (!mounted) return;
      setState(() {
        _classes = classes;
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

  Future<void> _loadTopics() async {
    setState(() {
      _topics = [];
      _selSubject = null;
      _selChapters.clear();
    });
    try {
      final t = await Repo.syllabusTopics(
          classId: _selClass, curriculum: _selCurriculum);
      if (!mounted) return;
      setState(() => _topics = t);
    } catch (e) {
      _toast('$e', error: true);
    }
  }

  List<String> _subjects() {
    final extra = <String>[];
    for (final t in _topics) {
      final s = ((t as Map)['subject'] as String?)?.trim() ?? '';
      if (s.isNotEmpty) extra.add(s);
    }
    return subjectOptions(extra);
  }

  /// Topics for the chosen subject, de-duplicated by title.
  List<Map<String, dynamic>> _visibleTopics() {
    final seen = <String>{};
    final out = <Map<String, dynamic>>[];
    for (final t in _topics) {
      final m = t as Map<String, dynamic>;
      if (_selSubject != null &&
          _selSubject!.isNotEmpty &&
          (m['subject'] as String?) != _selSubject) {
        continue;
      }
      final key = (m['title'] as String? ?? '').trim().toLowerCase();
      if (key.isEmpty || seen.contains(key)) continue;
      seen.add(key);
      out.add(m);
    }
    return out;
  }

  Future<void> _generate() async {
    if (_selChapters.isEmpty) {
      _toast('Pick at least one topic', error: true);
      return;
    }
    final total = _blueprint.fold<int>(0, (a, s) => a + s.count);
    if (total == 0) {
      _toast('Ask for at least one question', error: true);
      return;
    }
    // Map selected chapter_ids back to their syllabus_id.
    final chapters = <Map<String, String>>[];
    for (final t in _topics) {
      final m = t as Map<String, dynamic>;
      if (_selChapters.contains(m['chapter_id'])) {
        chapters.add({
          'syllabus_id': m['syllabus_id'] as String,
          'chapter_id': m['chapter_id'] as String,
        });
      }
    }
    setState(() => _busy = true);
    _toast('Generating $total questions from the textbook — ~1–2 min…');
    try {
      final paper = await Repo.generatePaper({
        'title': _titleCtrl.text.trim(),
        'subject': _selSubject ?? '',
        'curriculum': _selCurriculum ?? '',
        if (_board != null) 'board': _board,
        'chapters': chapters,
        'sections': _blueprint
            .map((s) => {
                  'name': s.name,
                  'bucket': s.bucket,
                  'marks': s.marks,
                  'count': s.count
                })
            .toList(),
      });
      if (!mounted) return;
      setState(() => _paper = paper);
    } catch (e) {
      _toast('Generation failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// All questions across sections, flattened (for submit + PDF).
  List<Map<String, dynamic>> _allQuestions() {
    final out = <Map<String, dynamic>>[];
    for (final s in (_paper?['sections'] as List? ?? const [])) {
      for (final q in ((s as Map)['questions'] as List? ?? const [])) {
        out.add(q as Map<String, dynamic>);
      }
    }
    return out;
  }

  Future<void> _submit() async {
    final qs = _allQuestions();
    if (qs.isEmpty) return;
    setState(() => _busy = true);
    try {
      final boards = (_paper!['boards'] as List?) ?? const [];
      final r = await Repo.submitPaper({
        'subject': _paper!['subject'],
        'curriculum': _paper!['curriculum'],
        if (boards.isNotEmpty) 'board': boards.first,
        if (_selClass != null) 'class_id': _selClass,
        'questions': qs
            .map((q) => {
                  'prompt': q['prompt'],
                  'qtype': q['qtype'],
                  'options': q['options'],
                  'answer_text': q['answer_text'],
                  'solution': q['solution'],
                  'marking_scheme': q['marking_scheme'],
                  'marks': q['marks'],
                  'difficulty': q['difficulty'],
                  'topic': q['topic'],
                  'has_graph': q['has_graph'],
                })
            .toList(),
      });
      final n = (r['inserted'] as num?)?.toInt() ?? 0;
      _toast('Submitted $n question(s) to the bank — students can take them now');
    } catch (e) {
      _toast('Submit failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'PUC Paper',
      currentRoute: '/puc-paper',
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  if (_error != null)
                    AppCard(
                      color: AppColors.error.withValues(alpha: 0.08),
                      child: Text(_error!,
                          style: const TextStyle(color: AppColors.error)),
                    )
                  else if (_paper == null)
                    ..._setupTab()
                  else
                    ..._paperTab(),
                ],
              ),
            ),
    );
  }

  // ---- Setup ----
  List<Widget> _setupTab() {
    final subjects = _subjects();
    if (_selSubject != null && !subjects.contains(_selSubject)) _selSubject = null;
    final topics = _visibleTopics();
    return [
      AppCard(
        color: AppColors.surfaceContainer,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('Generate a PUC paper',
                icon: Icons.description_outlined),
            const SizedBox(height: 6),
            Text(
                'Every question is written fresh from the uploaded textbook for '
                'the class & topics you pick.',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 14),
            AppInput(
                controller: _titleCtrl,
                hint: 'Paper title (e.g. 2nd PUC Maths Mock)',
                icon: Icons.title),
            const SizedBox(height: 12),
            _dropdown<String>(
              label: 'Class (1st PUC / 2nd PUC)',
              value: _selClass,
              items: [
                const DropdownMenuItem(value: null, child: Text('Select class')),
                ..._classes.map((c) => DropdownMenuItem(
                    value: (c as Map)['id'] as String,
                    child: Text(c['name']?.toString() ?? 'Class'))),
              ],
              onChanged: (v) {
                setState(() => _selClass = v);
                _loadTopics();
              },
            ),
            const SizedBox(height: 12),
            _dropdown<String>(
              label: 'Exam (sets the syllabus)',
              value: _board,
              items: [
                const DropdownMenuItem(value: null, child: Text('Any')),
                ...ExamScope.exams.map(
                    (e) => DropdownMenuItem(value: e, child: Text(e))),
              ],
              onChanged: (v) {
                setState(() {
                  _board = v;
                  _selCurriculum = v == null ? null : ExamScope.curriculumFor(v);
                });
                _loadTopics();
              },
            ),
            if (_board != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                    '$_board · ${ExamScope.curriculumFor(_board!)} syllabus',
                    style: AppTheme.mono(11, FontWeight.w700,
                        color: AppColors.teal)),
              ),
            const SizedBox(height: 12),
            _dropdown<String>(
              label: 'Subject',
              value: _selSubject,
              items: [
                const DropdownMenuItem(value: null, child: Text('All subjects')),
                ...subjects.map(
                    (s) => DropdownMenuItem(value: s, child: Text(s))),
              ],
              onChanged: (v) => setState(() {
                _selSubject = v;
                _selChapters.clear();
              }),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('TOPICS',
                style: AppTheme.mono(11, FontWeight.w600,
                    color: AppColors.muted, ls: 1.2)),
            const SizedBox(height: 8),
            if (topics.isEmpty)
              Text(
                  _selClass == null
                      ? 'Pick a class to load its syllabus topics.'
                      : 'No topics — upload the syllabus PDF for this class first.',
                  style: Theme.of(context).textTheme.bodyMedium)
            else
              ...topics.map((t) {
                final cid = t['chapter_id'] as String;
                final on = _selChapters.contains(cid);
                return CheckboxListTile(
                  value: on,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppColors.primary,
                  title: Text('${t['number']}. ${t['title']}',
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
          ],
        ),
      ),
      const SizedBox(height: 16),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BLUEPRINT',
                style: AppTheme.mono(11, FontWeight.w600,
                    color: AppColors.muted, ls: 1.2)),
            const SizedBox(height: 6),
            for (final s in _blueprint)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Expanded(
                      child: Text('${s.name} · ${s.marks}m each',
                          style: Theme.of(context).textTheme.bodyMedium)),
                  _stepBtn(Icons.remove,
                      s.count > 0 ? () => setState(() => s.count--) : null),
                  SizedBox(
                      width: 32,
                      child: Text('${s.count}',
                          textAlign: TextAlign.center,
                          style: AppTheme.mono(15, FontWeight.w700))),
                  _stepBtn(Icons.add, () => setState(() => s.count++)),
                ]),
              ),
            const SizedBox(height: 16),
            AppButton(_busy ? 'Generating from textbook…' : 'Generate paper',
                icon: Icons.auto_awesome,
                expand: true,
                onPressed: _busy ? null : _generate),
          ],
        ),
      ),
    ];
  }

  // ---- Paper view / edit ----
  List<Widget> _paperTab() {
    final p = _paper!;
    final shortfalls = (p['shortfalls'] as List?) ?? const [];
    return [
      Row(children: [
        Expanded(
          child: Text(p['title']?.toString() ?? 'Mock Test',
              style: Theme.of(context).textTheme.titleLarge),
        ),
        TextButton.icon(
          onPressed: _busy ? null : () => setState(() => _paper = null),
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('Back'),
        ),
      ]),
      Text(
          '${p['subject'] ?? ''}  ·  ${p['total_questions']} questions  ·  ${p['total_marks']} marks',
          style: AppTheme.mono(12, FontWeight.w500, color: AppColors.muted)),
      const SizedBox(height: 12),
      if (shortfalls.isNotEmpty)
        AppCard(
          color: AppColors.secondary.withValues(alpha: 0.10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Not fully filled',
                  style: AppTheme.mono(11, FontWeight.w700,
                      color: AppColors.secondary)),
              const SizedBox(height: 4),
              ...shortfalls.map((s) => Text('• $s',
                  style: Theme.of(context).textTheme.bodySmall)),
            ],
          ),
        ),
      const SizedBox(height: 8),
      ...((p['sections'] as List?) ?? const []).map((s) => _sectionCard(s)),
      const SizedBox(height: 8),
      _answerKeyCard(p),
      const SizedBox(height: 16),
      // Full-width stacked buttons — side-by-side overflowed the icon+label.
      AppButton(_busy ? 'Working…' : 'Download / Print PDF',
          icon: Icons.print_outlined,
          kind: AppBtnKind.ghost,
          expand: true,
          onPressed: _busy ? null : _exportPdf),
      const SizedBox(height: 10),
      AppButton(_busy ? 'Working…' : 'Submit to Question Bank',
          icon: Icons.cloud_upload_outlined,
          expand: true,
          onPressed: _busy ? null : _confirmSubmit),
      const SizedBox(height: 30),
    ];
  }

  Widget _sectionCard(dynamic section) {
    final s = section as Map<String, dynamic>;
    final qs = (s['questions'] as List?) ?? const [];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${s['name']}  ·  ${s['marks_each']} mark(s) each',
                style: AppTheme.mono(12, FontWeight.w700,
                    color: AppColors.primary)),
            if ((s['instructions'] as String?)?.isNotEmpty ?? false)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(s['instructions'].toString(),
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            const SizedBox(height: 6),
            ...qs.map((q) => _questionRow(q as Map<String, dynamic>)),
          ],
        ),
      ),
    );
  }

  Widget _questionRow(Map<String, dynamic> q) {
    final opts = (q['options'] as List?) ?? const [];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${q['position']}. ',
                style: AppTheme.mono(13, FontWeight.w700)),
            Expanded(
                child: MixedMathText(q['prompt']?.toString() ?? '',
                    fontSize: 14, color: AppColors.onSurface)),
            InkWell(
              onTap: _busy ? null : () => _editQuestion(q),
              child: const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(Icons.edit_outlined,
                    size: 16, color: AppColors.primary),
              ),
            ),
          ]),
          if (opts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(opts.length, (i) {
                  final o = opts[i] as Map;
                  // MixedMathText so $…$ inside options typesets, not raw LaTeX.
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: MixedMathText(
                        '(${String.fromCharCode(65 + i)}) ${o['text'] ?? ''}',
                        fontSize: 13, color: AppColors.onSurface),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _answerKeyCard(Map<String, dynamic> p) {
    final key = (p['answer_key'] as List?) ?? const [];
    return AppCard(
      color: AppColors.surfaceContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ANSWER KEY & EXPLANATIONS',
              style: AppTheme.mono(11, FontWeight.w700,
                  color: AppColors.muted, ls: 1)),
          const SizedBox(height: 8),
          ...key.map((a) {
            final m = a as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // MixedMathText so the answer's $…$ typesets (e.g. "B. $f$ …").
                  MixedMathText('${m['position']}. ${m['answer']}',
                      fontSize: 13.5,
                      color: AppColors.onSurface,
                      style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface)),
                  Padding(
                    padding: const EdgeInsets.only(left: 14, top: 2),
                    child: MixedMathText(m['explanation']?.toString() ?? '',
                        fontSize: 12.5, color: AppColors.muted),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ---- Edit a question in place ----
  Future<void> _editQuestion(Map<String, dynamic> q) async {
    final promptCtrl = TextEditingController(text: q['prompt']?.toString() ?? '');
    final solCtrl = TextEditingController(text: q['solution']?.toString() ?? '');
    final ansCtrl =
        TextEditingController(text: q['answer_text']?.toString() ?? '');
    final opts = ((q['options'] as List?) ?? const [])
        .map((o) => Map<String, dynamic>.from(o as Map))
        .toList();
    final optCtrls =
        opts.map((o) => TextEditingController(text: o['text']?.toString() ?? '')).toList();
    int correct = opts.indexWhere((o) => o['correct'] == true);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Edit question'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Question'),
                const SizedBox(height: 6),
                TextField(controller: promptCtrl, maxLines: null),
                if (opts.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text('Options — tap the dot to mark correct'),
                  const SizedBox(height: 6),
                  for (var i = 0; i < opts.length; i++)
                    Row(children: [
                      IconButton(
                        icon: Icon(
                            correct == i
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: correct == i
                                ? AppColors.success
                                : AppColors.muted),
                        onPressed: () => setLocal(() => correct = i),
                      ),
                      Expanded(child: TextField(controller: optCtrls[i])),
                    ]),
                ],
                if (opts.isEmpty) ...[
                  const SizedBox(height: 14),
                  const Text('Answer'),
                  const SizedBox(height: 6),
                  TextField(controller: ansCtrl),
                ],
                const SizedBox(height: 14),
                const Text('Explanation / model answer'),
                const SizedBox(height: 6),
                TextField(controller: solCtrl, maxLines: null),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save')),
          ],
        ),
      ),
    );
    if (saved != true) return;
    setState(() {
      q['prompt'] = promptCtrl.text.trim();
      q['solution'] = solCtrl.text.trim();
      if (opts.isNotEmpty) {
        for (var i = 0; i < opts.length; i++) {
          opts[i]['text'] = optCtrls[i].text.trim();
          opts[i]['correct'] = i == correct;
        }
        q['options'] = opts;
      } else {
        q['answer_text'] = ansCtrl.text.trim();
      }
      // Keep the answer key in sync with the edit.
      final key = (_paper!['answer_key'] as List?) ?? const [];
      for (final a in key) {
        if ((a as Map)['position'] == q['position']) {
          if (opts.isNotEmpty && correct >= 0) {
            a['answer'] =
                '${String.fromCharCode(65 + correct)}. ${opts[correct]['text']}';
          } else if (opts.isEmpty) {
            a['answer'] = ansCtrl.text.trim();
          }
          a['explanation'] = solCtrl.text.trim();
        }
      }
    });
    _toast('Question updated');
  }

  Future<void> _confirmSubmit() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Submit to question bank?'),
        content: Text(
            'All ${_allQuestions().length} questions will be added to the bank '
            'and become available to students for practice and tests.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Submit')),
        ],
      ),
    );
    if (ok == true) _submit();
  }

  // ---- PDF export (print / share / save) ----
  // Math is rendered to images with flutter_math_fork (the SAME engine as the
  // on-screen view) and placed inline in the PDF, so `$…$` typesets properly
  // instead of showing raw LaTeX.
  static final _texRe = RegExp(r'\$\$(.+?)\$\$|\$(.+?)\$', dotAll: true);

  /// Rasterise one LaTeX string to a PNG (offscreen). Returns (bytes, w/h).
  Future<(Uint8List, double)?> _rasterize(String tex) async {
    if (tex.trim().isEmpty) return null;
    final overlay = Overlay.of(context);
    final key = GlobalKey();
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -10000,
        top: 0,
        child: RepaintBoundary(
          key: key,
          child: Material(
            color: const Color(0xFFFFFFFF),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Math.tex(
                tex,
                textStyle: const TextStyle(fontSize: 24, color: Color(0xFF000000)),
                onErrorFallback: (_) => Text(tex,
                    style: const TextStyle(fontSize: 20, color: Color(0xFF000000))),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    try {
      await Future.delayed(const Duration(milliseconds: 90));
      final ro = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final img = await ro.toImage(pixelRatio: 3.0);
      final w = img.width.toDouble(), h = img.height.toDouble();
      final bd = await img.toByteData(format: ui.ImageByteFormat.png);
      if (bd == null || h == 0) return null;
      return (bd.buffer.asUint8List(), w / h);
    } catch (_) {
      return null;
    } finally {
      entry.remove();
    }
  }

  /// Split a "text with $math$" string into PDF inline spans, substituting the
  /// pre-rendered math images.
  List<pw.InlineSpan> _spans(String s, Map<String, Uint8List> imgs,
      Map<String, double> aspect,
      {double size = 11}) {
    final out = <pw.InlineSpan>[];
    var cur = 0;
    for (final m in _texRe.allMatches(s)) {
      if (m.start > cur) {
        out.add(pw.TextSpan(text: s.substring(cur, m.start)));
      }
      final t = (m.group(1) ?? m.group(2) ?? '').trim();
      final bytes = imgs[t];
      if (bytes != null) {
        final hh = size * 1.3;
        out.add(pw.WidgetSpan(
            child: pw.Image(pw.MemoryImage(bytes),
                height: hh, width: hh * (aspect[t] ?? 2.0))));
      } else {
        out.add(pw.TextSpan(text: t)); // fallback: raw
      }
      cur = m.end;
    }
    if (cur < s.length) out.add(pw.TextSpan(text: s.substring(cur)));
    return out;
  }

  Future<void> _exportPdf() async {
    final p = _paper!;
    setState(() => _busy = true);
    try {
      // 1. Collect every unique LaTeX expression in the paper.
      final tex = <String>{};
      void scan(Object? s) {
        if (s == null) return;
        for (final m in _texRe.allMatches(s.toString())) {
          tex.add((m.group(1) ?? m.group(2) ?? '').trim());
        }
      }

      for (final sec in (p['sections'] as List? ?? const [])) {
        for (final q in ((sec as Map)['questions'] as List? ?? const [])) {
          scan((q as Map)['prompt']);
          for (final o in (q['options'] as List? ?? const [])) {
            scan((o as Map)['text']);
          }
        }
      }
      for (final a in (p['answer_key'] as List? ?? const [])) {
        scan((a as Map)['answer']);
        scan(a['explanation']);
      }

      // 2. Rasterise each once.
      final imgs = <String, Uint8List>{};
      final aspect = <String, double>{};
      for (final t in tex) {
        final r = await _rasterize(t);
        if (r != null) {
          imgs[t] = r.$1;
          aspect[t] = r.$2;
        }
      }

      // 3. Build the PDF with inline math images.
      pw.Widget line(String s, {double size = 11, bool bold = false}) =>
          pw.RichText(
              text: pw.TextSpan(
                  style: pw.TextStyle(
                      fontSize: size,
                      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal),
                  children: _spans(s, imgs, aspect, size: size)));

      final blocks = <pw.Widget>[
        pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                  child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                    pw.Text(p['title']?.toString() ?? 'Mock Test',
                        style: pw.TextStyle(
                            fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                        '${p['subject'] ?? ''}'
                        '${p['curriculum'] != null ? ' · ${p['curriculum']}' : ''}'
                        ' · ${p['total_questions']} questions',
                        style: const pw.TextStyle(
                            fontSize: 10, color: PdfColors.grey700)),
                  ])),
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                pw.Text('MAX MARKS',
                    style: const pw.TextStyle(
                        fontSize: 9, color: PdfColors.grey700)),
                pw.Text('${p['total_marks']}',
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold)),
              ]),
            ]),
        pw.Divider(),
      ];

      for (final s in (p['sections'] as List? ?? const [])) {
        final sec = s as Map<String, dynamic>;
        blocks.add(pw.SizedBox(height: 8));
        blocks.add(pw.Text('${sec['name']}  (${sec['marks_each']} mark(s) each)',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)));
        if ((sec['instructions'] as String?)?.isNotEmpty ?? false) {
          blocks.add(pw.Text(sec['instructions'].toString(),
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)));
        }
        for (final q in (sec['questions'] as List? ?? const [])) {
          final qm = q as Map<String, dynamic>;
          blocks.add(pw.SizedBox(height: 6));
          blocks.add(line('${qm['position']}. ${qm['prompt'] ?? ''}  [${qm['marks']}]'));
          final opts = (qm['options'] as List?) ?? const [];
          for (var i = 0; i < opts.length; i++) {
            final o = opts[i] as Map;
            blocks.add(pw.Padding(
                padding: const pw.EdgeInsets.only(left: 16, top: 2),
                child: line(
                    '(${String.fromCharCode(65 + i)}) ${o['text'] ?? ''}',
                    size: 10)));
          }
        }
      }

      final keyBlocks = <pw.Widget>[
        pw.Text('Answer Key & Explanations',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.Divider(),
      ];
      for (final a in (p['answer_key'] as List? ?? const [])) {
        final am = a as Map<String, dynamic>;
        keyBlocks.add(pw.SizedBox(height: 5));
        keyBlocks.add(line('${am['position']}. ${am['answer'] ?? ''}',
            size: 11, bold: true));
        keyBlocks.add(pw.Padding(
            padding: const pw.EdgeInsets.only(left: 14, top: 1),
            child: line('${am['explanation'] ?? ''}', size: 9.5)));
      }

      final doc = pw.Document();
      doc.addPage(pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          build: (_) => [...blocks, pw.NewPage(), ...keyBlocks]));
      final bytes = await doc.save();
      await Printing.layoutPdf(
          onLayout: (_) async => bytes,
          name: '${p['title'] ?? 'mock-test'}.pdf');
    } catch (e) {
      _toast('PDF failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---- small UI helpers ----
  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, isDense: true),
      items: items,
      onChanged: onChanged,
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
}
