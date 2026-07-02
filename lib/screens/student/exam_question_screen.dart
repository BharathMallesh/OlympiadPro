import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/repo.dart';
import '../../widgets/common.dart';
import '../../widgets/math_text.dart';

/// Live exam screen, fully backed by the API: starts/resumes the submission,
/// renders backend questions (answer key never present), autosaves every
/// answer, and submits for instant MCQ auto-grading.
class ExamQuestionScreen extends StatefulWidget {
  const ExamQuestionScreen({super.key, required this.examId});
  final String examId;
  @override
  State<ExamQuestionScreen> createState() => _ExamQuestionScreenState();
}

class _ExamQuestionScreenState extends State<ExamQuestionScreen> {
  Map<String, dynamic>? _exam;
  List<dynamic> _questions = [];
  final Map<String, dynamic> _answers = {}; // question_id -> answer json
  final Set<int> _marked = {};
  int _index = 0;
  bool _loading = true;
  String? _error;
  bool _submitting = false;

  Timer? _ticker;
  Duration _remaining = Duration.zero;

  final _textCtrl = TextEditingController();

  Map<String, dynamic>? get _q => _questions.isEmpty
      ? null
      : _questions[_index] as Map<String, dynamic>;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    try {
      final data = await Repo.startExam(widget.examId);
      final exam = data['exam'] as Map<String, dynamic>;
      final saved = data['saved_answers'] as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _exam = exam;
        _questions = data['questions'] as List<dynamic>;
        for (final s in saved) {
          _answers[(s as Map<String, dynamic>)['question_id'] as String] =
              s['answer'];
        }
        _remaining = Duration(minutes: (exam['duration_min'] as num).toInt());
        _loading = false;
      });
      _syncTextField();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_remaining.inSeconds <= 0) {
          _ticker?.cancel();
          _submit(auto: true);
          return;
        }
        setState(() => _remaining -= const Duration(seconds: 1));
      });
      if (saved.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Resumed — your saved answers were restored.')));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String get _clock {
    final h = _remaining.inHours.toString().padLeft(2, '0');
    final m = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<void> _saveAnswer(String questionId, dynamic answer) async {
    setState(() => _answers[questionId] = answer);
    try {
      await Repo.saveAnswers(widget.examId, [
        {'question_id': questionId, 'answer': answer},
      ]);
    } catch (_) {
      // Network blip — answer stays locally and re-saves on next change.
    }
  }

  void _syncTextField() {
    final q = _q;
    if (q == null) return;
    final ans = _answers[q['question_id']];
    // Option-based types use selection cards, not the text field.
    final hasOptions = (q['options'] as List? ?? []).isNotEmpty ||
        const {'multiple_choice', 'assertion_reason', 'match_columns'}
            .contains(q['qtype']);
    if (!hasOptions) {
      _textCtrl.text = (ans?['value'] ?? ans?['text'] ?? '').toString();
    }
  }

  void _jumpTo(int i) {
    setState(() => _index = i);
    _syncTextField();
  }

  void _next() {
    if (_index >= _questions.length - 1) {
      _submit();
      return;
    }
    _jumpTo(_index + 1);
  }

  Future<void> _submit({bool auto = false}) async {
    if (_submitting) return;
    if (!auto) {
      final answered = _answers.length;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surfaceHigh,
          title: const Text('Submit Exam?'),
          content: Text('Answered: $answered / ${_questions.length}\n'
              'Marked for review: ${_marked.length}\n'
              'Unanswered: ${_questions.length - answered}\n\n'
              'Once submitted, answers cannot be changed.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Keep Working')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Submit',
                    style: TextStyle(color: AppColors.secondary))),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() => _submitting = true);
    try {
      final result = await Repo.submitExam(widget.examId);
      _ticker?.cancel();
      if (!mounted) return;
      final needsReview = result['needs_manual_review'] as bool? ?? false;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surfaceHigh,
          title: Row(children: [
            const Icon(Icons.check_circle, color: AppColors.success),
            const SizedBox(width: 10),
            const Text('Submitted!'),
          ]),
          content: Text(needsReview
              ? 'Objective questions scored ${result['auto_score']} marks '
                  'instantly. The rest is with your teacher for grading — '
                  'check back for your final score.'
              : 'Final score: ${result['auto_score']} marks. '
                  'All questions were auto-graded.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('View My Exams')),
          ],
        ),
      );
      if (mounted) context.go('/student/exams');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showPalette() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceHigh,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Question Palette', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 6),
            Wrap(spacing: 14, children: [
              _legend('Answered', AppColors.success),
              _legend('Marked', AppColors.secondary),
              _legend('Unseen', AppColors.surfaceHighest),
            ]),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 6,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                for (var i = 0; i < _questions.length; i++)
                  Builder(builder: (context) {
                    final qid = (_questions[i]
                        as Map<String, dynamic>)['question_id'] as String;
                    final answered = _answers.containsKey(qid);
                    return InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _jumpTo(i);
                      },
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _marked.contains(i)
                              ? AppColors.secondaryStrong.withValues(alpha: 0.3)
                              : answered
                                  ? AppColors.success.withValues(alpha: 0.25)
                                  : AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(
                              color: i == _index
                                  ? AppColors.primary
                                  : _marked.contains(i)
                                      ? AppColors.secondary
                                      : answered
                                          ? AppColors.success
                                          : AppColors.outline,
                              width: i == _index ? 2 : 1),
                        ),
                        child: Text('${i + 1}',
                            style: AppTheme.mono(13, FontWeight.w600,
                                color: AppColors.onSurface)),
                      ),
                    );
                  }),
              ],
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  Widget _legend(String label, Color color) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 10, height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: AppTheme.mono(9, FontWeight.w500)),
      ]);

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          backgroundColor: AppColors.scaffold,
          body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.scaffold,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 40),
            const SizedBox(height: 12),
            Text(_error!, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 14),
            AppButton('Back', onPressed: () => context.go('/student/exams')),
          ]),
        ),
      );
    }

    final q = _q!;
    final qid = q['question_id'] as String;
    final qtype = q['qtype'] as String? ?? 'short_answer';
    final options = (q['options'] as List? ?? []);
    // Option-based types (MCQ, assertion-reason, match-the-columns) all render
    // as selectable cards; numeric/integer get a number field; the rest a text box.
    final isMcq = options.isNotEmpty ||
        const {'multiple_choice', 'assertion_reason', 'match_columns'}
            .contains(qtype);
    final isNumeric = qtype == 'numeric' || qtype == 'integer';
    final imageUrls = (q['image_urls'] as List? ?? []).cast<String>();
    final selectedIdx = isMcq
        ? ((_answers[qid]?['selected'] as List?)?.cast<num>() ?? const [])
        : const <num>[];
    final isMarked = _marked.contains(_index);

    return PopRedirect(
      fallbackRoute: '/student/exams',
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          leading: const Icon(Icons.menu_book_outlined, color: AppColors.primary),
          titleSpacing: 0,
          title: Text(_exam?['title'] as String? ?? 'Exam',
              style: Theme.of(context).textTheme.titleLarge,
              overflow: TextOverflow.ellipsis),
          actions: [
            IconButton(
              tooltip: 'Question palette',
              onPressed: _showPalette,
              icon: const Icon(Icons.grid_view, size: 20),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: _remaining.inMinutes < 5
                    ? AppColors.error.withValues(alpha: 0.2)
                    : AppColors.tealStrong.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(_clock,
                  style: AppTheme.mono(13, FontWeight.w700,
                      color: _remaining.inMinutes < 5
                          ? AppColors.error
                          : AppColors.teal)),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryStrong.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text('Q${_index + 1}/${_questions.length}',
                          style: AppTheme.mono(12, FontWeight.w700,
                              color: AppColors.primary)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                          switch (qtype) {
                            'multiple_choice' => 'MULTIPLE CHOICE',
                            'assertion_reason' => 'ASSERTION & REASON',
                            'match_columns' => 'MATCH THE COLUMNS',
                            'numeric' || 'integer' => 'NUMERIC ANSWER',
                            'long_answer' => 'LONG ANSWER',
                            'case_study' => 'CASE STUDY',
                            _ => 'SHORT ANSWER',
                          },
                          style: AppTheme.mono(11, FontWeight.w600,
                              color: AppColors.onSurface, ls: 1)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text('+${q['marks']} Marks',
                      style: AppTheme.mono(10, FontWeight.w500,
                          color: AppColors.success)),
                  const SizedBox(height: 16),
                  MixedMathText(q['prompt'] as String? ?? '',
                      fontSize: 16, color: AppColors.onSurface),
                  for (final url in imageUrls) ...[
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Image.network(url,
                          width: double.infinity,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const SizedBox()),
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (isMcq)
                    for (var i = 0; i < options.length; i++)
                      _OptionCard(
                        letter: String.fromCharCode(65 + i),
                        latex: (options[i] as Map)['text'] as String? ?? '',
                        selected: selectedIdx.contains(i),
                        onTap: () => _saveAnswer(qid, {
                          'selected': [i]
                        }),
                      )
                  else
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FieldLabel(isNumeric
                              ? 'Your Numeric Answer'
                              : 'Your Answer'),
                          AppInput(
                            controller: _textCtrl,
                            maxLines: isNumeric ? 1 : 4,
                            hint: isNumeric
                                ? 'e.g. 42 or 3.14'
                                : 'Type your answer…',
                            onChanged: (v) => _saveAnswer(
                                qid,
                                isNumeric ? {'value': v} : {'text': v}),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            border: Border(top: BorderSide(color: AppColors.outline)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(children: [
                _ToolAction(
                  icon: isMarked ? Icons.bookmark : Icons.bookmark_outline,
                  label: 'MARK REVIEW',
                  color: isMarked ? AppColors.secondary : AppColors.muted,
                  onTap: () => setState(() =>
                      isMarked ? _marked.remove(_index) : _marked.add(_index)),
                ),
                const SizedBox(width: 16),
                if (_index > 0)
                  _ToolAction(
                    icon: Icons.chevron_left,
                    label: 'PREV',
                    color: AppColors.muted,
                    onTap: () => _jumpTo(_index - 1),
                  ),
                const Spacer(),
                AppButton(
                    _submitting
                        ? 'Submitting…'
                        : _index >= _questions.length - 1
                            ? 'Submit Exam'
                            : 'Save & Next',
                    kind: AppBtnKind.primary,
                    onPressed: _next),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.letter, required this.latex,
    required this.selected, required this.onTap,
  });
  final String letter, latex;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primaryStrong.withValues(alpha: 0.12)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
                color: selected ? AppColors.primary : AppColors.outline,
                width: selected ? 1.5 : 1),
          ),
          child: Row(children: [
            Container(
              width: 30, height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.scaffold,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                    color: selected ? AppColors.primary : AppColors.outlineStrong),
              ),
              child: Text(letter,
                  style: AppTheme.mono(13, FontWeight.w700,
                      color: selected ? AppColors.primary : AppColors.muted)),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: MixedMathText(latex,
                    fontSize: 16, color: AppColors.onSurface)),
            if (selected)
              const Icon(Icons.check_circle, size: 20, color: AppColors.primary),
          ]),
        ),
      ),
    );
  }
}

class _ToolAction extends StatelessWidget {
  const _ToolAction({
    required this.icon, required this.label,
    required this.color, required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 3),
            Text(label, style: AppTheme.mono(8, FontWeight.w600, color: color)),
          ]),
        ),
      );
}
