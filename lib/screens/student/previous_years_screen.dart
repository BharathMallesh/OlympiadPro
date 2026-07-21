import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../data/exam_scope.dart';
import '../../data/repo.dart';
import '../../widgets/common.dart';
import '../../widgets/math_text.dart';

/// Browse/reference the last few years' actual exam questions (JEE/NEET),
/// picked by exam → year → subject → chapter, with each question's correct
/// answer and full solution. Reference only (not auto-graded practice).
class PreviousYearsScreen extends StatefulWidget {
  const PreviousYearsScreen({super.key});

  @override
  State<PreviousYearsScreen> createState() => _PreviousYearsScreenState();
}

class _PreviousYearsScreenState extends State<PreviousYearsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _index = [];

  String? _exam;
  int? _year;
  String? _subject;
  String? _chapter;

  /// The state the student is preparing for, derived from the exam they chose
  /// at onboarding (KCET->Karnataka, KEAM->Kerala, …). Null = a pan-India-only
  /// student (JEE/NEET). Used to hide other states' exams from the picker.
  String? _studentState;

  bool _loadingQs = false;
  List<dynamic> _questions = const [];

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
      final rows = await Repo.pyqIndex();
      // The exam(s) the student targets → their state, so the picker shows only
      // that state's exam plus the pan-India ones. Best-effort: a failure here
      // just leaves the state null (pan-India only).
      String? state;
      try {
        final exam = ExamScope.examOf(await Repo.studentBoards());
        if (exam != null) state = ExamScope.stateFor(exam);
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _index = rows.cast<Map<String, dynamic>>();
        _studentState = state;
        _loading = false;
        _exam = _exams.isNotEmpty ? _exams.first : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<String> get _exams => (_index
      .map((e) => e['board'] as String)
      .toSet()
      // Show pan-India exams (stateFor == null: JEE/NEET) plus only the
      // student's own state exam — a Kerala student shouldn't be offered KCET or
      // MHT-CET. A pan-India-only student (no state) sees just JEE/NEET.
      .where((b) =>
          ExamScope.stateFor(b) == null || ExamScope.stateFor(b) == _studentState)
      .toList())
    ..sort();

  List<int> get _years => _exam == null
      ? []
      : (_index
          .where((e) => e['board'] == _exam)
          .map((e) => (e['year'] as num).toInt())
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a)));

  List<String> get _subjects => (_exam == null || _year == null)
      ? []
      : (_index
          .where((e) => e['board'] == _exam && e['year'] == _year)
          .map((e) => e['subject'] as String)
          .toSet()
          .toList()
        ..sort());

  List<Map<String, dynamic>> get _chapters =>
      (_exam == null || _year == null || _subject == null)
          ? []
          : _index
              .where((e) =>
                  e['board'] == _exam &&
                  e['year'] == _year &&
                  e['subject'] == _subject)
              .toList();

  Future<void> _loadQuestions() async {
    if (_exam == null || _year == null || _subject == null || _chapter == null) {
      return;
    }
    setState(() {
      _loadingQs = true;
      _questions = const [];
    });
    try {
      final qs = await Repo.pyqQuestions(_exam!, _year!, _subject!, _chapter!);
      if (!mounted) return;
      setState(() {
        _questions = qs;
        _loadingQs = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingQs = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Previous Years', style: Theme.of(context).textTheme.titleLarge),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error!, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 12),
                  AppButton('Retry', onPressed: _load),
                ]))
              : _index.isEmpty
                  ? Center(
                      child: Text('No previous-year questions available yet.',
                          style: Theme.of(context).textTheme.bodyMedium))
                  : Column(children: [
                      _pickers(context),
                      const Divider(height: 1),
                      Expanded(child: _questionsArea(context)),
                    ]),
    );
  }

  Widget _pickers(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(children: [
        Row(children: [
          Expanded(
              child: _drop<String>('Exam', _exam, _exams, (v) {
            setState(() {
              _exam = v;
              _year = null;
              _subject = null;
              _chapter = null;
              _questions = const [];
            });
          })),
          const SizedBox(width: 8),
          Expanded(
              child: _drop<int>('Year', _year, _years, (v) {
            setState(() {
              _year = v;
              _subject = null;
              _chapter = null;
              _questions = const [];
            });
          }, label: (y) => '$y')),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
              child: _drop<String>('Subject', _subject, _subjects, (v) {
            setState(() {
              _subject = v;
              _chapter = null;
              _questions = const [];
            });
          })),
          const SizedBox(width: 8),
          Expanded(
              child: _drop<String>(
                  'Chapter',
                  _chapter,
                  _chapters.map((c) => c['chapter'] as String).toList(), (v) {
            setState(() => _chapter = v);
            _loadQuestions();
          })),
        ]),
      ]),
    );
  }

  Widget _drop<T>(String hint, T? value, List<T> items, void Function(T?) onCh,
      {String Function(T)? label}) {
    return DropdownButtonFormField<T>(
      initialValue: items.contains(value) ? value : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: hint,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
      items: items
          .map((e) => DropdownMenuItem(
              value: e,
              child: Text(label != null ? label(e) : '$e',
                  overflow: TextOverflow.ellipsis)))
          .toList(),
      onChanged: items.isEmpty ? null : onCh,
    );
  }

  Widget _questionsArea(BuildContext context) {
    if (_loadingQs) return const Center(child: CircularProgressIndicator());
    if (_chapter == null) {
      return Center(
          child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text('Pick an exam, year, subject and chapter to see the '
            'actual questions from that paper.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium),
      ));
    }
    if (_questions.isEmpty) {
      return Center(
          child: Text('No questions found for that selection.',
              style: Theme.of(context).textTheme.bodyMedium));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _questions.length,
      itemBuilder: (ctx, i) => _qCard(ctx, _questions[i] as Map, i),
    );
  }

  Widget _qCard(BuildContext context, Map q, int i) {
    final ans = (q['answer']?.toString() ?? '').trim();
    final sol = (q['solution']?.toString() ?? '').trim();
    final session = (q['session']?.toString() ?? '').trim();
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('Q${q['position'] ?? i + 1}',
                style: AppTheme.mono(12, FontWeight.w700, color: AppColors.primary)),
            const Spacer(),
            Text('$_exam $_year${session.isNotEmpty ? ' · $session' : ''}',
                style: AppTheme.mono(9, FontWeight.w500)),
          ]),
          const SizedBox(height: 8),
          MixedMathText(q['prompt']?.toString() ?? '', fontSize: 15),
          if (ans.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Answer: $ans',
                style: AppTheme.mono(12, FontWeight.w700, color: AppColors.success)),
          ],
          if (sol.isNotEmpty)
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                title: Text('Solution',
                    style: AppTheme.mono(11, FontWeight.w700,
                        color: AppColors.primary)),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: MixedMathText(sol, fontSize: 13),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
