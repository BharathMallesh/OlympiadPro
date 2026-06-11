import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';
import 'student_shell.dart';

class StudentExamAnalysisScreen extends StatelessWidget {
  const StudentExamAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StudentShell(
      title: 'Exam Analysis',
      currentTab: 2,
      leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => popOrGo(context, '/student/hub')),
      actions: [
        IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert, size: 20)),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score hero
            AppCard(
              color: AppColors.surfaceContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: DonutChart(
                      const [(0.84, AppColors.primary), (0.16, AppColors.surfaceHigh)],
                      size: 150,
                      center: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text('84%',
                            style: AppTheme.mono(24, FontWeight.w700,
                                color: AppColors.onSurface)),
                        Text('ACCURACY', style: AppTheme.mono(9, FontWeight.w500)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FieldLabel('Total Score'),
                  Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('182',
                            style: AppTheme.mono(32, FontWeight.w700,
                                color: AppColors.onSurface, ls: -1)),
                        Text('/300',
                            style: AppTheme.mono(18, FontWeight.w600,
                                color: AppColors.muted)),
                      ]),
                  const SizedBox(height: 8),
                  const ProgressLine(182 / 300, height: 6),
                  const SizedBox(height: 18),
                  FieldLabel('Percentile'),
                  Text('98.2',
                      style: AppTheme.mono(20, FontWeight.w700,
                          color: AppColors.teal)),
                  Text('Top 2% of candidates globally',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const StudentSection('Subject Breakdown', icon: Icons.segment),
            for (final (subject, chip, chipColor, score, acc, icon) in const [
              ('Physics', 'Improvement Needed', AppColors.error, 52, 0.64, Icons.bolt),
              ('Chemistry', 'Steady', AppColors.teal, 68, 0.82, Icons.science_outlined),
              ('Mathematics', 'Strength', AppColors.success, 62, 0.91, Icons.functions),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  accentTop: chipColor,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: chipColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Icon(icon, size: 16, color: chipColor),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(subject,
                                style: Theme.of(context).textTheme.titleMedium)),
                        StatusChip(chip, color: chipColor),
                      ]),
                      const SizedBox(height: 14),
                      Row(children: [
                        const Expanded(child: FieldLabel('Score')),
                        Text('$score/100',
                            style: AppTheme.mono(13, FontWeight.w700,
                                color: AppColors.onSurface)),
                      ]),
                      Row(children: [
                        const Expanded(child: FieldLabel('Accuracy')),
                        Text('${(acc * 100).round()}%',
                            style:
                                AppTheme.mono(13, FontWeight.w700, color: chipColor)),
                      ]),
                      const SizedBox(height: 6),
                      ProgressLine(acc, color: chipColor, height: 6),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),

            const StudentSection('AI Strategic Diagnostic',
                icon: Icons.psychology_outlined),
            _InsightCard(
              icon: Icons.auto_awesome,
              color: AppColors.success,
              label: 'TOP STRENGTH',
              title: 'Calculus & Integration',
              body:
                  'You solved 14/15 questions in this category with an average time of 42s.',
              footerLabel: 'MAINTENANCE IMPACT',
              footerValue: '+8 Marks',
            ),
            _InsightCard(
              icon: Icons.warning_amber,
              color: AppColors.error,
              label: 'CRITICAL GAP',
              chip: 'PRIORITY: HIGH',
              title: 'Rotational Dynamics',
              body:
                  'Found significant struggle in multi-concept torque problems. Practice recommended.',
              mastery: 0.32,
              footerLabel: 'PREDICTED IMPACT',
              footerValue: '+12 Marks',
            ),
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.schedule, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text('TIME EFFICIENCY',
                        style: AppTheme.mono(11, FontWeight.w600,
                            color: AppColors.onSurface, ls: 1)),
                  ]),
                  const SizedBox(height: 10),
                  Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('1.2m',
                            style: AppTheme.mono(26, FontWeight.w700,
                                color: AppColors.onSurface)),
                        const SizedBox(width: 8),
                        Text('/ avg per q',
                            style: AppTheme.mono(11, FontWeight.w500)),
                      ]),
                  Text('12% faster than average successful candidates.',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              accentTop: AppColors.success,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.event_note_outlined,
                        size: 16, color: AppColors.success),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('DAILY STUDY PLAN',
                          style: AppTheme.mono(11, FontWeight.w600,
                              color: AppColors.success, ls: 1)),
                    ),
                    const Icon(Icons.add_task, size: 16, color: AppColors.muted),
                  ]),
                  const SizedBox(height: 12),
                  for (final item in const [
                    'Moment of Inertia Derivations',
                    'Rolling without Slipping',
                    'Angular Momentum Conservation',
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        const Icon(Icons.circle, size: 6, color: AppColors.success),
                        const SizedBox(width: 10),
                        Text(item, style: Theme.of(context).textTheme.bodyMedium),
                      ]),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              color: AppColors.surfaceContainer,
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recommended Pathway',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text(
                          'Focus on 15 advanced Kinetics problems to boost Physics '
                          'percentile by ~5%.',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AppButton('Start Path',
                    onPressed: () => context.push('/student/practice-generator')),
              ]),
            ),
            const SizedBox(height: 20),
            AppButton('Review All Solutions',
                expand: true,
                icon: Icons.rule,
                onPressed: () => context.push('/student/solution')),
            const SizedBox(height: 10),
            AppButton('Practice Weak Topics',
                kind: AppBtnKind.ghost,
                expand: true,
                icon: Icons.track_changes,
                onPressed: () => context.push('/student/practice-generator')),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.icon, required this.color, required this.label,
    required this.title, required this.body,
    this.chip, this.mastery, this.footerLabel, this.footerValue,
  });
  final IconData icon;
  final Color color;
  final String label, title, body;
  final String? chip;
  final double? mastery;
  final String? footerLabel, footerValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        borderColor: color.withValues(alpha: 0.35),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(label,
                          style: AppTheme.mono(10, FontWeight.w600,
                              color: color, ls: 1)),
                    ),
                    if (chip != null)
                      StatusChip(chip!, color: color, filled: true),
                  ]),
                  const SizedBox(height: 4),
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  if (mastery != null) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: ProgressLine(mastery!, color: color, height: 5)),
                      const SizedBox(width: 10),
                      Text('Mastery: ${(mastery! * 100).round()}%',
                          style: AppTheme.mono(10, FontWeight.w600, color: color)),
                    ]),
                  ],
                  const SizedBox(height: 6),
                  Text(body, style: Theme.of(context).textTheme.bodyMedium),
                  if (footerLabel != null) ...[
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                        child: Text(footerLabel!,
                            style: AppTheme.mono(9, FontWeight.w600,
                                color: AppColors.muted, ls: 0.8)),
                      ),
                      Text(footerValue!,
                          style: AppTheme.mono(13, FontWeight.w700,
                              color: AppColors.success)),
                    ]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
