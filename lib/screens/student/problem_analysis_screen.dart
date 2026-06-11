import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/math_text.dart';

class ProblemAnalysisScreen extends StatelessWidget {
  const ProblemAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopRedirect(
      fallbackRoute: '/student/exam-analysis',
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => popOrGo(context, '/student/exam-analysis')),
          titleSpacing: 0,
          title: Text('Problem 14 Analysis',
              style: Theme.of(context).textTheme.titleLarge),
          actions: [
            StatusChip('Incorrect', color: AppColors.error, filled: true,
                icon: Icons.cancel_outlined),
            const SizedBox(width: 10),
            Center(
              child: Text('24:59',
                  style: AppTheme.mono(13, FontWeight.w700,
                      color: AppColors.onSurface)),
            ),
            const SizedBox(width: 14),
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
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    StatusChip('Integral Calculus', color: AppColors.primary),
                    StatusChip('Hard (790 Elo)', color: AppColors.secondary),
                    StatusChip('Marks: +4 / -1', color: AppColors.onSurfaceVariant),
                  ]),
                  const SizedBox(height: 16),

                  // Problem statement
                  AppCard(
                    accentTop: AppColors.primary,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PROBLEM STATEMENT',
                            style: AppTheme.mono(11, FontWeight.w600,
                                color: AppColors.primary, ls: 1)),
                        const SizedBox(height: 12),
                        Text('Let f(x) be a continuous function such that',
                            style: Theme.of(context).textTheme.bodyLarge),
                        const SizedBox(height: 10),
                        const _LatexBlock(
                            r'\int_{0}^{1} f(x)\,dx = 4, \quad \int_{0}^{2} f(x)\,dx = 7'),
                        const SizedBox(height: 12),
                        Text('Determine the value of the integral:',
                            style: Theme.of(context).textTheme.bodyLarge),
                        const SizedBox(height: 10),
                        const _LatexBlock(
                            r'\int_{1}^{2} \left[ 3f(x) + 2x \right] dx'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Figure
                  Container(
                    width: double.infinity,
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: Stack(children: [
                      const Center(
                          child: Icon(Icons.show_chart,
                              color: AppColors.primaryStrong, size: 40)),
                      Positioned(
                        left: 12, bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          color: AppColors.surfaceHigh,
                          child: Text('Fig 1.4 Area Visualizer',
                              style: AppTheme.mono(9, FontWeight.w600)),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // Response audit
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('RESPONSE AUDIT',
                            style: AppTheme.mono(11, FontWeight.w600,
                                color: AppColors.onSurface, ls: 1)),
                        const SizedBox(height: 12),
                        _AuditRow(
                            label: 'YOUR ANSWER',
                            value: '15',
                            color: AppColors.error,
                            icon: Icons.error_outline),
                        const SizedBox(height: 10),
                        _AuditRow(
                            label: 'CORRECT SOLUTION',
                            value: '12',
                            color: AppColors.success,
                            icon: Icons.check_circle_outline),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // AI diagnostic report
                  AppCard(
                    color: AppColors.surfaceContainer,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.psychology_outlined,
                              size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('AI DIAGNOSTIC REPORT',
                                style: AppTheme.mono(11, FontWeight.w600,
                                    color: AppColors.onSurface, ls: 1)),
                          ),
                        ]),
                        const SizedBox(height: 12),
                        StatusChip('Calculation Slip',
                            color: AppColors.secondary,
                            icon: Icons.warning_amber),
                        const SizedBox(height: 14),
                        Row(children: [
                          Expanded(
                            child: Text('CONCEPT MASTERY: DEFINITE INTEGRALS',
                                style: AppTheme.mono(9, FontWeight.w600, ls: 0.5)),
                          ),
                          Text('65%',
                              style: AppTheme.mono(12, FontWeight.w700,
                                  color: AppColors.secondary)),
                        ]),
                        const SizedBox(height: 6),
                        const ProgressLine(0.65,
                            color: AppColors.secondaryStrong, height: 5),
                        const SizedBox(height: 14),
                        Text(
                            'You correctly identified the property of integral '
                            'splitting. However, a sign error occurred during the '
                            'arithmetic integration of 2x. You likely evaluated '
                            '(x² 2) from 1 to 2 as (4+1) instead of (4−1).',
                            style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border(
                                left: BorderSide(
                                    color: AppColors.secondaryStrong, width: 3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('REMEDY',
                                  style: AppTheme.mono(10, FontWeight.w700,
                                      color: AppColors.secondary, ls: 1)),
                              const SizedBox(height: 6),
                              Text(
                                  'Review the Power Rule for Integration and '
                                  'practice evaluating definite boundaries to '
                                  'avoid sign-flip errors.',
                                  style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(children: [
                          Expanded(
                            child: AppButton('Practice Similar',
                                kind: AppBtnKind.ghost,
                                expand: true,
                                icon: Icons.fitness_center,
                                onPressed: () =>
                                    context.push('/student/practice-generator')),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: AppButton('Concept Video',
                                kind: AppBtnKind.ghost,
                                expand: true,
                                icon: Icons.play_circle_outline,
                                onPressed: () {}),
                          ),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text('Step-by-Step Resolution',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 14),
                  for (final (n, title, body, latex) in const [
                    ('1', 'Split the Integral',
                        'Utilize the linearity property of integrals to decompose the expression:',
                        r'\int_{1}^{2}[3f(x)+2x]dx = 3\int_{1}^{2} f(x)dx + \int_{1}^{2} 2x\,dx'),
                    ('2', 'Apply Additive Interval Property',
                        'Find ∫₁² f(x)dx using the given total range:',
                        r'\int_{0}^{2} f - \int_{0}^{1} f = 7 - 4 = 3 \implies 3(3) = 9'),
                    ('3', 'Evaluate Final Sum',
                        'Integrate the second term and combine results:',
                        r'\int_{1}^{2} 2x\,dx = [x^2]_1^2 = 4-1 = 3,\;\; 9 + 3 = 12'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(
                                width: 24, height: 24,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryStrong
                                      .withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(n,
                                    style: AppTheme.mono(12, FontWeight.w700,
                                        color: AppColors.primary)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(title,
                                    style:
                                        Theme.of(context).textTheme.titleMedium),
                              ),
                            ]),
                            const SizedBox(height: 10),
                            Text(body,
                                style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 10),
                            _LatexBlock(latex),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),

                  // Scratchpad
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                            child: Text('Your Scratchpad',
                                style: Theme.of(context).textTheme.titleMedium),
                          ),
                          TextButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.open_in_full, size: 14),
                            label: const Text('Expand'),
                          ),
                        ]),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          height: 110,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: AppColors.outline),
                          ),
                          child: const Center(
                            child: Icon(Icons.gesture,
                                color: AppColors.muted, size: 32),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text('Practice This Topic',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: _TopicCard(
                          title: 'Limits & Continuity',
                          level: 'Medium',
                          levelColor: AppColors.secondary,
                          onTap: () =>
                              context.push('/student/practice-generator')),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TopicCard(
                          title: 'Basic Differentiation',
                          level: 'Hard',
                          levelColor: AppColors.error,
                          onTap: () =>
                              context.push('/student/practice-generator')),
                    ),
                  ]),
                  const SizedBox(height: 24),
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final icon in const [
                    Icons.edit_outlined,
                    Icons.straighten,
                    Icons.undo,
                    Icons.redo,
                  ])
                    IconButton(
                        onPressed: () {},
                        icon: Icon(icon, size: 20, color: AppColors.muted)),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                        color: AppColors.secondaryStrong, shape: BoxShape.circle),
                    child: const Icon(Icons.auto_awesome,
                        size: 18, color: Colors.black),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LatexBlock extends StatelessWidget {
  const _LatexBlock(this.latex);
  final String latex;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.outline),
        ),
        child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: MathText(latex, fontSize: 15)),
      );
}

class _AuditRow extends StatelessWidget {
  const _AuditRow({
    required this.label, required this.value,
    required this.color, required this.icon,
  });
  final String label, value;
  final Color color;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTheme.mono(9, FontWeight.w600, color: color, ls: 1)),
                const SizedBox(height: 4),
                Text(value,
                    style: AppTheme.mono(22, FontWeight.w700,
                        color: AppColors.onSurface)),
              ],
            ),
          ),
          Icon(icon, size: 24, color: color),
        ]),
      );
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.title, required this.level,
    required this.levelColor, required this.onTap,
  });
  final String title, level;
  final Color levelColor;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(title,
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis),
                ),
                const Icon(Icons.arrow_forward, size: 16, color: AppColors.muted),
              ]),
              const SizedBox(height: 8),
              StatusChip(level, color: levelColor),
            ],
          ),
        ),
      );
}
