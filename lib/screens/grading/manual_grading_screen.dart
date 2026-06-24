import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../data/repo.dart';
import '../../widgets/common.dart';
import '../../widgets/math_text.dart';

/// Manual grading backed by the real API: loads the submission's answers
/// alongside the exam questions, lets the teacher award marks per question,
/// and submits the grades (the backend rolls them up into the final score).
class ManualGradingScreen extends StatefulWidget {
  const ManualGradingScreen({super.key, this.submissionId = ''});
  final String submissionId;
  @override
  State<ManualGradingScreen> createState() => _ManualGradingScreenState();
}

class _ManualGradingScreenState extends State<ManualGradingScreen> {
  Map<String, dynamic>? _submission;
  List<dynamic> _answers = [];
  List<dynamic> _questions = [];
  final Map<String, double> _awarded = {}; // question_id -> marks
  bool _loading = true;
  bool _saving = false;
  String? _error;

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
      final detail = await Repo.submission(widget.submissionId);
      final submission = detail['submission'] as Map<String, dynamic>;
      final questions =
          await Repo.examQuestions(submission['exam_id'] as String);
      if (!mounted) return;
      setState(() {
        _submission = submission;
        _answers = detail['answers'] as List<dynamic>;
        _questions = questions;
        for (final a in _answers) {
          final m = a as Map<String, dynamic>;
          if (m['awarded_marks'] != null) {
            _awarded[m['question_id'] as String] =
                (m['awarded_marks'] as num).toDouble();
          }
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Map<String, dynamic>? _questionFor(String id) {
    for (final q in _questions) {
      if (q['id'] == id) return q as Map<String, dynamic>;
    }
    return null;
  }

  String _renderAnswer(Map<String, dynamic> answer, Map<String, dynamic>? q) {
    final selected = answer['selected'];
    if (selected is List && q != null) {
      final options = (q['options'] as List? ?? []);
      final picked = [
        for (final i in selected)
          if (i is num && i.toInt() < options.length)
            options[i.toInt()]['text'] as String? ?? '?'
      ];
      return picked.isEmpty ? 'No option selected' : picked.join(', ');
    }
    if (answer['value'] != null) return '${answer['value']}';
    if (answer['text'] != null) return '${answer['text']}';
    return answer.toString();
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final items = [
        for (final e in _awarded.entries)
          {'question_id': e.key, 'awarded_marks': e.value.round()}
      ];
      final updated = await Repo.grade(widget.submissionId, items);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Graded · final score ${updated['score']}/${updated['max_score']}')));
        popOrGo(context, '/grading/submissions');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopRedirect(
      fallbackRoute: '/grading/submissions',
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          leading: IconButton(
              tooltip: 'Back',
              icon: const Icon(Icons.arrow_back),
              onPressed: () => popOrGo(context, '/grading/submissions')),
          titleSpacing: 0,
          title: Text('Manual Grading',
              style: Theme.of(context).textTheme.titleLarge),
          actions: [
            if (_submission != null)
              StatusChip(
                  (_submission!['status'] as String).replaceAll('_', ' '),
                  color: AppColors.secondary),
            const SizedBox(width: 16),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_error!,
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 12),
                    AppButton('Retry', onPressed: _load),
                  ]))
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 860),
                      child: ListView(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        children: [
                          if (_answers.isEmpty)
                            AppCard(
                              child: Column(children: [
                                const Icon(Icons.inbox_outlined,
                                    color: AppColors.muted, size: 36),
                                const SizedBox(height: 10),
                                Text(
                                    'This student has not answered any questions yet.',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                              ]),
                            ),
                          for (var i = 0; i < _answers.length; i++)
                            _AnswerCard(
                              index: i,
                              answer: _answers[i] as Map<String, dynamic>,
                              question: _questionFor((_answers[i]
                                  as Map<String, dynamic>)['question_id']
                                  as String),
                              awarded: _awarded[(_answers[i]
                                  as Map<String, dynamic>)['question_id']],
                              renderAnswer: _renderAnswer,
                              onAward: (qid, v) =>
                                  setState(() => _awarded[qid] = v),
                            ),
                          const SizedBox(height: 10),
                          if (_answers.isNotEmpty)
                            AppButton(
                                _saving
                                    ? 'Submitting…'
                                    : 'Submit Grades & Finalize',
                                kind: AppBtnKind.secondary,
                                expand: true,
                                trailingIcon: Icons.check_circle_outline,
                                onPressed: _submit),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({
    required this.index,
    required this.answer,
    required this.question,
    required this.awarded,
    required this.renderAnswer,
    required this.onAward,
  });
  final int index;
  final Map<String, dynamic> answer;
  final Map<String, dynamic>? question;
  final double? awarded;
  final String Function(Map<String, dynamic>, Map<String, dynamic>?)
      renderAnswer;
  final void Function(String, double) onAward;

  @override
  Widget build(BuildContext context) {
    final qid = answer['question_id'] as String;
    final maxMarks = ((question?['marks'] as num?) ?? 4).toDouble();
    final autoGraded = answer['auto_graded'] as bool? ?? false;
    final value = (awarded ?? 0).clamp(0, maxMarks).toDouble();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('Q${index + 1}',
                  style: AppTheme.mono(13, FontWeight.w700,
                      color: AppColors.primary)),
              const SizedBox(width: 10),
              StatusChip(question?['qtype'] as String? ?? 'question',
                  color: AppColors.onSurfaceVariant),
              const Spacer(),
              if (autoGraded)
                StatusChip('Auto-graded', color: AppColors.success,
                    icon: Icons.bolt),
            ]),
            const SizedBox(height: 10),
            MixedMathText(question?['prompt'] as String? ?? 'Question unavailable',
                fontSize: 15),
            const SizedBox(height: 12),
            const FieldLabel("Student's Answer"),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.outline),
              ),
              child: Text(
                  renderAnswer(
                      (answer['answer'] as Map).cast<String, dynamic>(),
                      question),
                  style: Theme.of(context).textTheme.bodyLarge),
            ),
            _MarkingGuide(answer: answer),
            const SizedBox(height: 14),
            Row(children: [
              const FieldLabel('Marks Awarded'),
              const Spacer(),
              Text('${value.toStringAsFixed(0)} / ${maxMarks.toStringAsFixed(0)}',
                  style: AppTheme.mono(15, FontWeight.w700,
                      color: AppColors.secondary)),
            ]),
            Slider(
              value: value,
              min: 0,
              max: maxMarks,
              divisions: maxMarks.toInt(),
              activeColor: AppColors.secondary,
              onChanged: autoGraded ? null : (v) => onAward(qid, v),
            ),
          ],
        ),
      ),
    );
  }
}

/// The marking guide for one answer: the expected numeric answer, the step-wise
/// marking scheme (board-valuation style), and the model answer — so the grader
/// can allot marks fairly. Collapsed by default to keep the card compact.
class _MarkingGuide extends StatelessWidget {
  const _MarkingGuide({required this.answer});
  final Map<String, dynamic> answer;

  @override
  Widget build(BuildContext context) {
    final expected = (answer['answer_text'] as String?)?.trim() ?? '';
    final scheme = (answer['marking_scheme'] as List?) ?? const [];
    final solution = (answer['solution'] as String?)?.trim() ?? '';
    if (expected.isEmpty && scheme.isEmpty && solution.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 8),
          dense: true,
          leading: const Icon(Icons.checklist_rtl,
              size: 18, color: AppColors.primary),
          title: Text('Marking guide',
              style: AppTheme.mono(12, FontWeight.w600,
                  color: AppColors.primary, ls: 0.5)),
          children: [
            if (expected.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Expected:  ',
                      style: AppTheme.mono(12, FontWeight.w700,
                          color: AppColors.success)),
                  Expanded(child: MixedMathText(expected, fontSize: 14)),
                ]),
              ),
            if (scheme.isNotEmpty) ...[
              Text('STEP MARKS',
                  style: AppTheme.mono(10, FontWeight.w700,
                      color: AppColors.muted, ls: 1)),
              const SizedBox(height: 4),
              for (final m in scheme)
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
                              child: MixedMathText((m['step'] ?? '').toString(),
                                  fontSize: 13)),
                        ]),
                  ),
              const SizedBox(height: 8),
            ],
            if (solution.isNotEmpty) ...[
              Text('MODEL ANSWER',
                  style: AppTheme.mono(10, FontWeight.w700,
                      color: AppColors.muted, ls: 1)),
              const SizedBox(height: 4),
              MixedMathText(solution, fontSize: 13),
            ],
          ],
        ),
      ),
    );
  }
}
