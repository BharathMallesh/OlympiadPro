import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/math_text.dart';

class SolutionViewScreen extends StatelessWidget {
  const SolutionViewScreen({super.key});

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
          title: Text('Question 14 Solution',
              style: Theme.of(context).textTheme.titleLarge),
          actions: [
            StatusChip('Incorrect', color: AppColors.error, filled: true),
            IconButton(
                onPressed: () {}, icon: const Icon(Icons.more_vert, size: 20)),
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
                    StatusChip('Calculus', color: AppColors.secondary,
                        icon: Icons.functions),
                    const Spacer(),
                    Text('No. 12s spent', style: AppTheme.mono(9, FontWeight.w500)),
                  ]),
                  const SizedBox(height: 14),
                  Text('Evaluate the following definite integral using '
                      'trigonometric identities:',
                      style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 12),
                  _LatexBlock(
                    r'I = \int_{0}^{\pi/2} \sin(2x)\cos(2x)\,dx',
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: const Center(
                        child: Icon(Icons.scatter_plot_outlined,
                            color: AppColors.primaryStrong, size: 36)),
                  ),
                  const SizedBox(height: 24),

                  Row(children: [
                    const Icon(Icons.auto_fix_high,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text('Detailed Solution',
                        style: Theme.of(context).textTheme.headlineSmall),
                  ]),
                  const SizedBox(height: 16),
                  _SolutionStep(
                    step: 'STEP 1: SIMPLIFY TRIGONOMETRIC PRODUCT',
                    body: 'We start by utilizing the double-angle identity '
                        'sin(2x) = 2 sin(x)cos(x). This implies:',
                    latex: r'\sin(2x)\cos(2x) = \tfrac{1}{2}\sin(4x)',
                    color: AppColors.primary,
                  ),
                  _SolutionStep(
                    step: 'STEP 2: USE POWER REDUCTION IDENTITY',
                    body: "Applying the identity sin(2θ) = 2 sin θ cos θ to our "
                        'expression where θ = 2x:',
                    latex: r'I = \tfrac{1}{2}\int_{0}^{\pi/2} \sin(4x)\,dx',
                    color: AppColors.teal,
                  ),
                  _SolutionStep(
                    step: 'STEP 3: INTEGRATE',
                    body: 'Integrating and evaluating between the bounds:',
                    latex:
                        r'I = \tfrac{1}{2}\left[-\tfrac{\cos(4x)}{4}\right]_0^{\pi/2} = 0',
                    color: AppColors.success,
                  ),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.4)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.lightbulb_outline,
                          size: 16, color: AppColors.secondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                            'Tip: Always look for symmetry or double-angle '
                            'simplifications before integrating products of '
                            'trigonometric powers.',
                            style: Theme.of(context).textTheme.bodySmall),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 24),

                  FieldLabel('Your Submission'),
                  _SubmissionRow(
                      latex: r'I = \pi/8', correct: false),
                  const SizedBox(height: 8),
                  _SubmissionRow(latex: r'I = 0', correct: true),
                  const SizedBox(height: 24),

                  // Expert walkthrough
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 150,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(AppRadius.lg)),
                          ),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.25),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.play_arrow,
                                  color: AppColors.primary, size: 28),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Expert Walkthrough',
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              Text('By Prof. Adrian Sterling, MIT',
                                  style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Global performance
                  AppCard(
                    color: AppColors.surfaceContainer,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FieldLabel('Global Performance'),
                        const SizedBox(height: 4),
                        Row(children: [
                          const Expanded(
                              child: Text('Correct Rate',
                                  style: TextStyle(
                                      color: AppColors.onSurfaceVariant))),
                          Text('22%',
                              style: AppTheme.mono(16, FontWeight.w700,
                                  color: AppColors.success)),
                        ]),
                        const SizedBox(height: 8),
                        const ProgressLine(0.22,
                            color: AppColors.success, height: 6),
                        const SizedBox(height: 14),
                        Row(children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('AVG TIME',
                                    style: AppTheme.mono(8, FontWeight.w600)),
                                Text('1m 47s',
                                    style: AppTheme.mono(13, FontWeight.w700,
                                        color: AppColors.onSurface)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('PEER RANK',
                                    style: AppTheme.mono(8, FontWeight.w600)),
                                Text('P (48%)',
                                    style: AppTheme.mono(13, FontWeight.w700,
                                        color: AppColors.onSurface)),
                              ],
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(children: [
                TextButton.icon(
                  onPressed: () => popOrGo(context, '/student/exam-analysis'),
                  icon: const Icon(Icons.chevron_left, size: 18),
                  label: Text('Back',
                      style: AppTheme.mono(11, FontWeight.w500,
                          color: AppColors.onSurfaceVariant)),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Issue reported. Thank you!'))),
                  icon: const Icon(Icons.flag_outlined,
                      size: 16, color: AppColors.muted),
                  label: Text('Report an Issue',
                      style: AppTheme.mono(10, FontWeight.w500,
                          color: AppColors.muted)),
                ),
                const SizedBox(width: 8),
                AppButton('Next Solution',
                    trailingIcon: Icons.chevron_right,
                    onPressed: () => context.push('/student/problem-analysis')),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _LatexBlock extends StatelessWidget {
  const _LatexBlock(this.latex, {this.color});
  final String latex;
  final Color? color;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.outline),
        ),
        child: Text(latex,
            style: AppTheme.mono(13.5, FontWeight.w500,
                color: color ?? const Color(0xFFF5F5F5), ls: 0)),
      );
}

class _SolutionStep extends StatelessWidget {
  const _SolutionStep({
    required this.step, required this.body,
    required this.latex, required this.color,
  });
  final String step, body, latex;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(step, style: AppTheme.mono(10, FontWeight.w700, color: color, ls: 0.8)),
            const SizedBox(height: 8),
            Text(body, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 10),
            _LatexBlock(latex),
          ],
        ),
      );
}

class _SubmissionRow extends StatelessWidget {
  const _SubmissionRow({required this.latex, required this.correct});
  final String latex;
  final bool correct;
  @override
  Widget build(BuildContext context) {
    final color = correct ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: MathText(latex, fontSize: 15, color: color)),
        ),
        Icon(correct ? Icons.check_circle : Icons.error_outline,
            size: 18, color: color),
      ]),
    );
  }
}
