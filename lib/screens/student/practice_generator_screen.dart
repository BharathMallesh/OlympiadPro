import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/exam_scope.dart';
import '../../data/repo.dart';
import '../../widgets/common.dart';
import 'student_shell.dart';

/// Builds a practice set from the question bank. The student can either pick a
/// number of questions per *subject*, or drill into specific *topics*
/// (chapters) — e.g. to revise exactly what was taught that day, or to focus a
/// quick exam on a topic they're weak in.
class PracticeGeneratorScreen extends StatefulWidget {
  const PracticeGeneratorScreen(
      {super.key,
      this.initialSubject,
      this.initialCurricula,
      this.initialBoards,
      this.pyq = false});

  /// Subject chosen on the hub; if it has questions it's pre-selected here.
  final String? initialSubject;

  /// Curriculum + exam-board focus chosen on the hub. When provided these scope
  /// this practice set; null falls back to the student's saved profile.
  final List<String>? initialCurricula;
  final List<String>? initialBoards;

  /// When true, this builds a PREVIOUS-YEARS test: the pool is scoped to the
  /// 'PYQ' curriculum (real past-paper questions) instead of the exam syllabus.
  final bool pyq;

  @override
  State<PracticeGeneratorScreen> createState() => _PracticeGeneratorScreenState();
}

class _PracticeGeneratorScreenState extends State<PracticeGeneratorScreen> {
  bool _loading = true;
  bool _loadingSubjects = false;
  bool _generating = false;
  String? _error;


  /// 'subject' or 'topic'.
  String _mode = 'subject';

  List<Map<String, dynamic>> _subjects = const [];
  final Map<String, int> _counts = {}; // subject -> count

  bool _topicsLoaded = false;
  List<Map<String, dynamic>> _topics = const [];
  final Map<String, int> _topicCounts = {}; // "subjecttopic" -> count
  String _filter = '';
  /// In the Chapter/Topic drill-down, focus on ONE subject at a time so the
  /// student picks a subject first and only sees that subject's chapters/topics
  /// (subject → chapter → topic), instead of one long mixed list.
  String? _focusSubject;

  List<String> get _subjectNames => [
        for (final s in _subjects) (s['subject'] as String? ?? '')
      ].where((e) => e.isNotEmpty).toList();

  // Curriculum + exam-board scope for this set — chosen on the hub (or the
  // student's profile as fallback). Shown read-only here; the picker lives on
  // the hub now so subject selection is the focus of this screen.
  final Set<String> _curricula = {};
  final Set<String> _boards = {};

  /// The state the student prepares for, from the exam they chose at
  /// onboarding. Null = a pan-India-only (JEE/NEET) student. Scopes the exam
  /// chips so a Kerala student isn't offered Karnataka's KCET or Maharashtra's
  /// MHT-CET.
  String? _studentState;

  static const _subjectIcons = {
    'Math': Icons.functions,
    'Maths': Icons.functions,
    'Mathematics': Icons.functions,
    'Physics': Icons.bolt,
    'Chemistry': Icons.science_outlined,
    'Biology': Icons.biotech_outlined,
  };

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
      // Exam is required, so subjects are NOT loaded until one is chosen. If the
      // hub/profile already implies an exam, pre-select it.
      final boards = widget.initialBoards ?? await Repo.studentBoards();
      if (!mounted) return;
      final exam = ExamScope.examOf(boards);
      setState(() {
        _loading = false;
        _studentState = exam != null ? ExamScope.stateFor(exam) : null;
      });
      if (exam != null) _selectExam(exam);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /// Pick an exam: sets the board + its implied curriculum (NEET/JEE→NCERT,
  /// CET→State Board), clears any prior selection, and (re)loads the subject
  /// list scoped to that syllabus. Tapping the selected exam clears it.
  void _selectExam(String board) {
    setState(() {
      final wasSelected = _boards.contains(board);
      _boards.clear();
      _curricula.clear();
      _counts.clear();
      _topicCounts.clear();
      _openChapters.clear();
      _topics = const [];
      _topicsLoaded = false;
      _subjects = const [];
      _mode = 'subject';
      _focusSubject = null;
      if (!wasSelected) {
        _boards.add(board);
        _curricula.add(widget.pyq ? 'PYQ' : ExamScope.curriculumFor(board));
      }
    });
    if (_boards.isNotEmpty) _reloadForScope();
  }

  Future<void> _reloadForScope() async {
    setState(() => _loadingSubjects = true);
    try {
      final rows = await Repo.practiceSubjects(
          boards: _boards.toList(), curricula: _curricula.toList());
      if (!mounted) return;
      // Restrict to the exam's real subjects: NEET has no Maths, JEE no Biology.
      // A state CET (subjectsFor == null) keeps every subject the pool offers.
      final exam = ExamScope.examOf(_boards.toList());
      final allowed = exam != null ? ExamScope.subjectsFor(exam) : null;
      var subjects = rows.cast<Map<String, dynamic>>();
      if (allowed != null) {
        subjects =
            subjects.where((r) => allowed.contains(r['subject'])).toList();
      }
      setState(() {
        _subjects = subjects;
        _loadingSubjects = false;
        _preselectInitial();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingSubjects = false;
      });
    }
  }

  /// Pre-select the subject the student chose on the hub (if it has questions),
  /// so the builder opens already focused on their choice instead of blank.
  /// Call inside setState. Matches case-insensitively and treats
  /// Math/Maths/Mathematics as the same subject.
  void _preselectInitial() {
    final want = widget.initialSubject;
    if (want == null || want.trim().isEmpty || _counts.isNotEmpty) return;
    String norm(String s) {
      s = s.trim().toLowerCase();
      return s.startsWith('math') ? 'math' : s;
    }
    for (final s in _subjects) {
      final subj = s['subject'] as String? ?? '';
      final avail = (s['available'] as num?)?.toInt() ?? 0;
      if (avail > 0 && norm(subj) == norm(want)) {
        _counts[subj] = avail < 10 ? avail : 10; // sensible default count
        break;
      }
    }
  }

  Future<void> _loadTopics() async {
    if (_topicsLoaded) return;
    try {
      final rows = await Repo.practiceTopics(
          boards: _boards.toList(), curricula: _curricula.toList());
      if (!mounted) return;
      setState(() {
        _topics = rows.cast<Map<String, dynamic>>();
        _topicsLoaded = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  String _key(String subject, String topic) => '$subject$topic';

  int get _total => _mode == 'subject'
      ? _counts.values.fold(0, (a, b) => a + b)
      : _topicCounts.values.fold(0, (a, b) => a + b);

  void _bump(Map<String, int> store, String key, int available, int delta) {
    setState(() {
      final next = ((store[key] ?? 0) + delta).clamp(0, available);
      if (next == 0) {
        store.remove(key);
      } else {
        store[key] = next;
      }
    });
  }

  /// 3-part key (subject/chapter/topic) for finer topic selections; uses the
  /// same U+0001 separator as [_key] so both split identically in [_generate].
  String _tkey(String subject, String chapter, String topic) =>
      '$subject$chapter$topic';

  final Set<String> _openChapters = {}; // chapters expanded in the drill

  String _chapterOf(Map<String, dynamic> t) {
    final c = (t['chapter'] as String?)?.trim();
    return (c != null && c.isNotEmpty) ? c : (t['topic'] as String? ?? 'General');
  }

  String? _subTopic(Map<String, dynamic> t) {
    final tp = (t['topic'] as String?)?.trim();
    return (tp == null || tp.isEmpty || tp == 'General') ? null : tp;
  }

  /// The finer topic rows tagged under a chapter (empty if none tagged yet).
  List<Map<String, dynamic>> _topicsOf(String subject, String chapter) => [
        for (final t in _topics)
          if ((t['subject'] as String? ?? 'General') == subject &&
              _chapterOf(t) == chapter &&
              _subTopic(t) != null)
            t
      ];

  Future<void> _generate() async {
    setState(() => _generating = true);
    try {
      final items = _mode == 'subject'
          ? [
              for (final e in _counts.entries)
                {'subject': e.key, 'count': e.value}
            ]
          : [
              // Each key is subjectchapter (whole chapter) or
              // subjectchaptertopic (a finer topic within it).
              for (final e in _topicCounts.entries)
                if (e.value > 0)
                  (() {
                    final p = e.key.split('');
                    return p.length >= 3
                        ? {
                            'subject': p[0],
                            'chapter': p[1],
                            'topic': p[2],
                            'count': e.value,
                          }
                        : {'subject': p[0], 'chapter': p[1], 'count': e.value};
                  })()
            ];
      final res = await Repo.practiceGenerate(items,
          curricula: _curricula.toList(), boards: _boards.toList());
      if (!mounted) return;
      context.push('/student/practice-session',
          extra: (res['questions'] as List<dynamic>));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  /// Chapters aggregated from the subject→chapter→topic rows the API returns.
  /// Each entry: {subject, chapter, available (summed over its topics)}.
  List<Map<String, dynamic>> get _allChapters {
    final agg = <String, Map<String, int>>{}; // subject -> chapter -> available
    for (final t in _topics) {
      final subject = t['subject'] as String? ?? 'General';
      final chapterRaw = (t['chapter'] as String?)?.trim();
      final chapter = (chapterRaw != null && chapterRaw.isNotEmpty)
          ? chapterRaw
          : (t['topic'] as String? ?? 'General');
      final av = (t['available'] as num?)?.toInt() ?? 0;
      (agg[subject] ??= {}).update(chapter, (v) => v + av, ifAbsent: () => av);
    }
    final out = <Map<String, dynamic>>[];
    for (final se in agg.entries) {
      for (final ce in se.value.entries) {
        out.add({'subject': se.key, 'chapter': ce.key, 'available': ce.value});
      }
    }
    return out;
  }

  /// Chapters grouped by subject, filtered by the search box.
  Map<String, List<Map<String, dynamic>>> get _grouped {
    final q = _filter.trim().toLowerCase();
    final out = <String, List<Map<String, dynamic>>>{};
    for (final c in _allChapters) {
      final subject = c['subject'] as String;
      final chapter = c['chapter'] as String;
      if (q.isNotEmpty &&
          !chapter.toLowerCase().contains(q) &&
          !subject.toLowerCase().contains(q)) {
        continue;
      }
      (out[subject] ??= []).add(c);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return StudentShell(
      title: 'Vidyora',
      currentTab: 1,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error!, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 12),
                  AppButton('Retry', onPressed: _load),
                ]))
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                widget.pyq
                                    ? 'Student Hub  /  Previous Years Test'
                                    : 'Student Hub  /  AI Practice',
                                style:
                                    AppTheme.mono(10, FontWeight.w500, ls: 0.5)),
                            const SizedBox(height: 8),
                            Text(
                                widget.pyq
                                    ? 'Build a Previous-Years Test'
                                    : 'Build Your Practice Set',
                                style:
                                    Theme.of(context).textTheme.headlineMedium),
                            const SizedBox(height: 6),
                            Text(
                                _boards.isEmpty
                                    ? 'Choose your exam first — then pick subjects, '
                                        'chapters or topics to practise.'
                                    : _mode == 'subject'
                                        ? 'Pick how many questions you want from '
                                            'each subject.'
                                        : _mode == 'chapter'
                                            ? 'Drill into a chapter to revise what '
                                                "you were taught."
                                            : 'Pick specific topics to focus on '
                                                'exactly what you need.',
                                style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 16),
                            ..._examChips(context),
                            ..._afterExamBody(context),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: AppButton(
                          _total == 0
                              ? 'Select questions to begin'
                              : _generating
                                  ? 'Generating…'
                                  : 'Generate & Start · $_total questions',
                          expand: true,
                          trailingIcon: Icons.play_arrow,
                          onPressed: _total == 0 || _generating
                              ? null
                              : _generate),
                    ),
                  ],
                ),
    );
  }

  /// Exam scope (#9): NEET / JEE / CET. Selecting one just FILTERS the pool to
  /// that exam's questions — it does NOT start a session. The set is only built
  /// when the main "Generate" button is tapped, using the chosen subjects/
  /// chapters/topics scoped to this board.
  List<Widget> _examChips(BuildContext context) {
    // Pan-India exams (JEE/NEET) plus only the student's own state exam — a
    // Kerala student practising shouldn't be offered KCET or MHT-CET.
    final exams = ExamScope.exams
        .where((e) =>
            ExamScope.stateFor(e) == null || ExamScope.stateFor(e) == _studentState)
        .toList();
    return [
      Text('SELECT YOUR EXAM',
          style: AppTheme.mono(10, FontWeight.w700, ls: 1)),
      const SizedBox(height: 8),
      Row(children: [
        for (var i = 0; i < exams.length; i++) ...[
          Expanded(child: _examChip(exams[i])),
          if (i < exams.length - 1) const SizedBox(width: 8),
        ],
      ]),
      const SizedBox(height: 16),
    ];
  }

  Widget _examChip(String board) {
    final sel = _boards.contains(board);
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: _loadingSubjects ? null : () => _selectExam(board),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: sel ? AppColors.primary.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: sel ? AppColors.primary : AppColors.outline),
        ),
        child: Text(ExamScope.label(board),
            style: AppTheme.mono(11, FontWeight.w700,
                color: sel ? AppColors.primary : AppColors.muted)),
      ),
    );
  }

  Widget _modeToggle(BuildContext context) {
    Widget tab(String value, String label, IconData icon) {
      final active = _mode == value;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          onTap: () {
            setState(() {
              _mode = value;
              // Default the drill-down to the first subject so the student
              // starts narrowed to one subject, then picks chapter/topic.
              if ((value == 'chapter' || value == 'topic') &&
                  _focusSubject == null) {
                _focusSubject =
                    _subjectNames.isNotEmpty ? _subjectNames.first : null;
              }
            });
            if (value == 'chapter' || value == 'topic') _loadTopics();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: active
                  ? AppColors.primary.withValues(alpha: 0.18)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                  color: active ? AppColors.primary : AppColors.outline),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon,
                  size: 16,
                  color: active ? AppColors.primary : AppColors.muted),
              const SizedBox(width: 8),
              Text(label,
                  style: AppTheme.mono(11, FontWeight.w600,
                      color: active ? AppColors.primary : AppColors.muted)),
            ]),
          ),
        ),
      );
    }

    return Row(children: [
      tab('subject', 'SUBJECT', Icons.category_outlined),
      const SizedBox(width: 8),
      tab('chapter', 'CHAPTER', Icons.account_tree_outlined),
      // Topic-level drill-down is offered for AI practice only; the
      // previous-years test builder stops at subject/chapter.
      if (!widget.pyq) ...[
        const SizedBox(width: 8),
        tab('topic', 'TOPIC', Icons.label_outline),
      ],
    ]);
  }

  /// Subject selector shown above the Chapter/Topic lists: pick a subject first,
  /// then only that subject's chapters/topics are listed below.
  Widget _subjectFilter(BuildContext context) {
    final subs = _subjectNames;
    if (subs.length < 2) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SELECT SUBJECT',
            style: AppTheme.mono(10, FontWeight.w700, ls: 1)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final s in subs) ...[
              _subjectFilterChip(s),
              const SizedBox(width: 8),
            ],
          ]),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _subjectFilterChip(String subject) {
    final sel = _focusSubject == subject;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: () => setState(() => _focusSubject = subject),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: sel ? AppColors.teal.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: sel ? AppColors.teal : AppColors.outline),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(_subjectIcons[subject] ?? Icons.menu_book_outlined,
              size: 14, color: sel ? AppColors.teal : AppColors.muted),
          const SizedBox(width: 6),
          Text(subject,
              style: AppTheme.mono(11, FontWeight.w700,
                  color: sel ? AppColors.teal : AppColors.muted)),
        ]),
      ),
    );
  }

  // ---- Post-exam content (gated on an exam being selected) ----

  /// Everything below the exam chips. Nothing shows until an exam is chosen so
  /// the student never sees an NCERT list while thinking they're on CET, etc.
  List<Widget> _afterExamBody(BuildContext context) {
    if (_boards.isEmpty) return _pickExamPrompt(context);
    if (_loadingSubjects) {
      return const [
        Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        )
      ];
    }
    if (_subjects.isEmpty) return _noExamQuestions(context);
    return [
      _syllabusBanner(context),
      const SizedBox(height: 12),
      _modeToggle(context),
      const SizedBox(height: 16),
      if (_mode == 'subject')
        ..._subjectBody(context)
      else if (_mode == 'chapter')
        ..._topicBody(context)
      else
        ..._byTopicBody(context),
    ];
  }

  List<Widget> _pickExamPrompt(BuildContext context) => [
        const SizedBox(height: 28),
        Center(
          child: Column(children: [
            const Icon(Icons.checklist_rtl, size: 34, color: AppColors.muted),
            const SizedBox(height: 10),
            Text('Choose an exam above to begin',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                  'NEET & JEE follow the NCERT syllabus; CET follows the State '
                  'Board syllabus — so the questions differ.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
          ]),
        ),
      ];

  List<Widget> _noExamQuestions(BuildContext context) {
    final exam = _boards.isNotEmpty ? _boards.first : '';
    final cur = _curricula.isNotEmpty ? _curricula.first : '';
    return [
      _syllabusBanner(context),
      const SizedBox(height: 28),
      Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text('No $exam ($cur) questions in the bank yet.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
        ),
      ),
    ];
  }

  Widget _syllabusBanner(BuildContext context) {
    final exam = _boards.isNotEmpty ? _boards.first : '';
    final cur = _curricula.isNotEmpty ? _curricula.first : '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(children: [
        const Icon(Icons.menu_book_outlined, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
              widget.pyq ? '$exam  ·  previous-year papers' : '$exam  ·  $cur syllabus',
              style: AppTheme.mono(12, FontWeight.w700, color: AppColors.onSurface),
              overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  }

  // ---- Subject mode ----

  List<Widget> _subjectBody(BuildContext context) {
    if (_subjects.isEmpty) {
      return [_emptyBank(context)];
    }
    return [
      for (final s in _subjects)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _subjectRow(context, s),
        ),
    ];
  }

  Widget _subjectRow(BuildContext context, Map<String, dynamic> s) {
    final subject = s['subject'] as String? ?? '';
    final available = (s['available'] as num?)?.toInt() ?? 0;
    final count = _counts[subject] ?? 0;
    final active = count > 0;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: (active ? AppColors.primary : AppColors.muted)
                .withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(_subjectIcons[subject] ?? Icons.menu_book_outlined,
              size: 18, color: active ? AppColors.primary : AppColors.muted),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subject, style: Theme.of(context).textTheme.titleMedium),
              Text('$available available',
                  style: AppTheme.mono(9, FontWeight.w500)),
            ],
          ),
        ),
        _stepper(count, available, (d) => _bump(_counts, subject, available, d)),
      ]),
    );
  }

  // ---- Topic mode (flat topic picker) ----

  List<Widget> _byTopicBody(BuildContext context) {
    if (!_topicsLoaded) {
      return const [
        Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        )
      ];
    }
    // Flatten to individual sub-topics across all chapters.
    final flat = <Map<String, dynamic>>[];
    for (final t in _topics) {
      final sub = _subTopic(t);
      if (sub == null) continue;
      flat.add({
        'subject': t['subject'] as String? ?? 'General',
        'chapter': _chapterOf(t),
        'topic': sub,
        'available': (t['available'] as num?)?.toInt() ?? 0,
      });
    }
    if (flat.isEmpty) return [_emptyBank(context)];
    final q = _filter.trim().toLowerCase();
    final shown = flat
        .where((t) =>
            // Focused subject first, then the text search.
            (_focusSubject == null || t['subject'] == _focusSubject) &&
            (q.isEmpty ||
                (t['topic'] as String).toLowerCase().contains(q) ||
                (t['chapter'] as String).toLowerCase().contains(q) ||
                (t['subject'] as String).toLowerCase().contains(q)))
        .toList();
    return [
      _subjectFilter(context),
      TextField(
        onChanged: (v) => setState(() => _filter = v),
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search topics…',
          prefixIcon: const Icon(Icons.search, size: 18),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm)),
        ),
      ),
      const SizedBox(height: 16),
      if (shown.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(
              child: Text('No topics match "$_filter".',
                  style: Theme.of(context).textTheme.bodyMedium)),
        )
      else
        for (final t in shown)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _topicFlatRow(context, t),
          ),
    ];
  }

  Widget _topicFlatRow(BuildContext context, Map<String, dynamic> t) {
    final subject = t['subject'] as String;
    final chapter = t['chapter'] as String;
    final topic = t['topic'] as String;
    final available = t['available'] as int;
    final key = _tkey(subject, chapter, topic);
    final count = _topicCounts[key] ?? 0;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(topic,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 14, color: count > 0 ? AppColors.onSurface : null)),
            const SizedBox(height: 2),
            Text('$subject · $chapter · $available available',
                style: AppTheme.mono(9, FontWeight.w500)),
          ]),
        ),
        const SizedBox(width: 8),
        _stepper(count, available, (d) => _bump(_topicCounts, key, available, d)),
      ]),
    );
  }

  // ---- Chapter mode ----

  List<Widget> _topicBody(BuildContext context) {
    if (!_topicsLoaded) {
      return const [
        Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        )
      ];
    }
    if (_topics.isEmpty) {
      return [_emptyBank(context)];
    }
    // Only the focused subject's chapters (subject → chapter drill-down).
    final grouped = {
      for (final e in _grouped.entries)
        if (_focusSubject == null || e.key == _focusSubject) e.key: e.value
    };
    return [
      _subjectFilter(context),
      TextField(
        onChanged: (v) => setState(() => _filter = v),
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search chapters…',
          prefixIcon: const Icon(Icons.search, size: 18),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm)),
        ),
      ),
      const SizedBox(height: 16),
      if (grouped.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(
              child: Text('No topics match "$_filter".',
                  style: Theme.of(context).textTheme.bodyMedium)),
        )
      else
        for (final entry in grouped.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Row(children: [
              Icon(_subjectIcons[entry.key] ?? Icons.menu_book_outlined,
                  size: 15, color: AppColors.teal),
              const SizedBox(width: 8),
              Text(entry.key.toUpperCase(),
                  style: AppTheme.mono(11, FontWeight.w700,
                      color: AppColors.teal, ls: 1)),
              const SizedBox(width: 8),
              Text('${entry.value.length} chapters',
                  style: AppTheme.mono(9, FontWeight.w500)),
            ]),
          ),
          for (final t in entry.value)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _topicRow(context, t),
            ),
          const SizedBox(height: 8),
        ],
    ];
  }

  Widget _topicRow(BuildContext context, Map<String, dynamic> t) {
    final subject = t['subject'] as String? ?? 'General';
    final chapter = t['chapter'] as String? ?? 'General';
    final available = (t['available'] as num?)?.toInt() ?? 0;
    final topics = _topicsOf(subject, chapter);

    // No finer topics tagged yet → plain chapter row (whole-chapter selection).
    if (topics.isEmpty) {
      final key = _key(subject, chapter);
      final count = _topicCounts[key] ?? 0;
      return AppCard(
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        child: Row(children: [
          Expanded(child: _chapterLabel(context, chapter, '$available available', count > 0)),
          const SizedBox(width: 8),
          _stepper(count, available, (d) => _bump(_topicCounts, key, available, d)),
        ]),
      );
    }

    // Has topics → tap to expand and pick a specific topic within the chapter.
    final ckey = _key(subject, chapter);
    final open = _openChapters.contains(ckey);
    final chosen = topics.fold<int>(
        0,
        (a, tp) =>
            a + (_topicCounts[_tkey(subject, chapter, tp['topic'] as String)] ?? 0));
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(children: [
        InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => setState(() =>
              open ? _openChapters.remove(ckey) : _openChapters.add(ckey)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
            child: Row(children: [
              Icon(open ? Icons.expand_less : Icons.expand_more,
                  size: 20, color: AppColors.muted),
              const SizedBox(width: 6),
              Expanded(
                  child: _chapterLabel(context, chapter,
                      '${topics.length} topics · $available available', chosen > 0)),
              if (chosen > 0) StatusChip('$chosen', color: AppColors.teal),
            ]),
          ),
        ),
        if (open)
          for (final tp in topics)
            Padding(
              padding: const EdgeInsets.fromLTRB(34, 0, 10, 10),
              child: _subTopicRow(context, subject, chapter, tp),
            ),
      ]),
    );
  }

  Widget _chapterLabel(BuildContext context, String title, String sub, bool active) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 14, color: active ? AppColors.onSurface : null)),
        const SizedBox(height: 2),
        Text(sub, style: AppTheme.mono(9, FontWeight.w500)),
      ]);

  Widget _subTopicRow(
      BuildContext context, String subject, String chapter, Map<String, dynamic> t) {
    final topic = t['topic'] as String? ?? 'General';
    final available = (t['available'] as num?)?.toInt() ?? 0;
    final key = _tkey(subject, chapter, topic);
    final count = _topicCounts[key] ?? 0;
    return Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(topic,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: count > 0 ? AppColors.onSurface : null)),
          Text('$available available', style: AppTheme.mono(9, FontWeight.w500)),
        ]),
      ),
      const SizedBox(width: 8),
      _stepper(count, available, (d) => _bump(_topicCounts, key, available, d)),
    ]);
  }

  // ---- Shared bits ----

  Widget _stepper(int count, int available, void Function(int) onDelta) {
    final active = count > 0;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      _stepBtn(Icons.remove, count > 0, () => onDelta(-1)),
      SizedBox(
        width: 40,
        child: Text('$count',
            textAlign: TextAlign.center,
            style: AppTheme.mono(16, FontWeight.w700,
                color: active ? AppColors.teal : AppColors.muted)),
      ),
      _stepBtn(Icons.add, count < available, () => onDelta(1)),
    ]);
  }

  Widget _emptyBank(BuildContext context) => AppCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(
              child: Text(
                  'No practice questions available yet. Ask your teacher to '
                  'add questions to the bank.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium)),
        ),
      );

  Widget _stepBtn(IconData icon, bool enabled, VoidCallback onTap) => InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
                color: enabled ? AppColors.outlineStrong : AppColors.outline),
          ),
          child: Icon(icon,
              size: 16,
              color: enabled ? AppColors.onSurface : AppColors.muted),
        ),
      );
}
