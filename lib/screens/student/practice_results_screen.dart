import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/math_text.dart';

/// Shows the server-graded outcome of a practice set: overall score,
/// per-subject accuracy, and a question-by-question review with the
/// correct answers revealed.
class PracticeResultsScreen extends StatelessWidget {
  const PracticeResultsScreen({super.key, required this.payload});

  /// {result: grade response, questions: generated questions,
  ///  selected: {question_id: [indices]}}
  final Map<String, dynamic> payload;

  Map<String, dynamic> get _result =>
      payload['result'] as Map<String, dynamic>? ?? const {};
  List<Map<String, dynamic>> get _questions =>
      ((payload['questions'] as List<dynamic>?) ?? const [])
          .cast<Map<String, dynamic>>();
  Map<String, dynamic> get _selected =>
      payload['selected'] as Map<String, dynamic>? ?? const {};

  @override
  Widget build(BuildContext context) {
    final score = (_result['score'] as num?)?.toInt() ?? 0;
    final total = (_result['total'] as num?)?.toInt() ?? 0;
    final pct = total == 0 ? 0 : (score / total * 100).round();
    final subjects = ((_result['subjects'] as List<dynamic>?) ?? const [])
        .cast<Map<String, dynamic>>();
    final results = {
      for (final r in ((_result['results'] as List<dynamic>?) ?? const [])
          .cast<Map<String, dynamic>>())
        r['question_id'] as String: r
    };

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/student/hub')),
        title: Text('Practice Results',
            style: Theme.of(context).textTheme.titleLarge),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              AppCard(
                accentTop: pct >= 60 ? AppColors.success : AppColors.error,
                child: Column(children: [
                  Text('YOUR SCORE',
                      style: AppTheme.mono(10, FontWeight.w600, ls: 1.5)),
                  const SizedBox(height: 10),
                  Text('$score / $total',
                      style: Theme.of(context)
                          .textTheme
                          .displaySmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  StatusChip('$pct% correct',
                      color:
                          pct >= 60 ? AppColors.success : AppColors.error),
                ]),
              ),
              const SizedBox(height: 16),
              if (subjects.isNotEmpty) ...[
                const SectionTitle('Subject Breakdown',
                    icon: Icons.donut_small_outlined),
                const SizedBox(height: 10),
                AppCard(
                  child: Column(children: [
                    for (final s in subjects)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(
                                  child: Text(s['subject'] as String? ?? '',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge)),
                              Text(
                                  '${s['correct']}/${s['total']}',
                                  style: AppTheme.mono(13, FontWeight.w700,
                                      color: AppColors.teal)),
                            ]),
                            const SizedBox(height: 6),
                            ProgressLine(
                                (s['total'] as num? ?? 0) == 0
                                    ? 0
                                    : ((s['correct'] as num? ?? 0) /
                                            (s['total'] as num))
                                        .toDouble(),
                                color: AppColors.teal,
                                height: 6),
                          ],
                        ),
                      ),
                  ]),
                ),
                const SizedBox(height: 16),
              ],
              const SectionTitle('Review', icon: Icons.fact_check_outlined),
              const SizedBox(height: 10),
              for (final (i, q) in _questions.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _reviewCard(context, i, q,
                      results[q['question_id'] as String]),
                ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: AppButton('Practice Again', kind: AppBtnKind.ghost,
                      onPressed: () =>
                          context.go('/student/practice-generator')),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton('Back to Hub',
                      onPressed: () => context.go('/student/hub')),
                ),
              ]),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reviewCard(BuildContext context, int index, Map<String, dynamic> q,
      Map<String, dynamic>? r) {
    final qid = q['question_id'] as String;
    final correct = r?['correct'] as bool? ?? false;
    final correctIdx = ((r?['correct_selected'] as List<dynamic>?) ?? const [])
        .map((e) => (e as num).toInt())
        .toSet();
    final pickedIdx = ((_selected[qid] as List<dynamic>?) ?? const [])
        .map((e) => (e as num).toInt())
        .toSet();
    final options = ((q['options'] as List<dynamic>?) ?? const [])
        .cast<Map<String, dynamic>>();
    String letters(Set<int> s) => s.isEmpty
        ? '—'
        : (s.toList()..sort())
            .map((i) => String.fromCharCode(65 + i))
            .join(', ');
    final firstCorrect =
        correctIdx.isEmpty ? null : (correctIdx.toList()..sort()).first;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(correct ? Icons.check_circle : Icons.cancel,
                size: 18,
                color: correct ? AppColors.success : AppColors.error),
            const SizedBox(width: 8),
            Expanded(
                child: Text('Q${index + 1} · ${q['subject'] ?? ''}',
                    style: AppTheme.mono(10, FontWeight.w600, ls: 0.5))),
          ]),
          const SizedBox(height: 8),
          MixedMathText(q['prompt'] as String? ?? '', fontSize: 15),
          const SizedBox(height: 8),
          Text('Your answer: ${letters(pickedIdx)}   ·   Correct: ${letters(correctIdx)}',
              style: AppTheme.mono(11, FontWeight.w500,
                  color: correct ? AppColors.success : AppColors.error)),
          // Render the correct option through MixedMathText so LaTeX answers
          // (matrices, fractions, …) don't leak raw markup into the summary.
          if (firstCorrect != null && options.length > firstCorrect)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: MixedMathText(options[firstCorrect]['text'] as String? ?? '',
                  fontSize: 12,
                  color: correct ? AppColors.success : AppColors.error)),
        ],
      ),
    );
  }
}
