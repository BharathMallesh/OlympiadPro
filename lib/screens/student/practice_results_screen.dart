import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';
import 'student_shell.dart';

class PracticeResultsScreen extends StatelessWidget {
  const PracticeResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StudentShell(
      title: 'OlympiadPro',
      currentTab: 2,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PRACTICE COMPLETED',
                style: AppTheme.mono(11, FontWeight.w600,
                    color: AppColors.teal, ls: 1.2)),
            const SizedBox(height: 6),
            Text('Practice Results',
                style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: AppButton('Review All Questions',
                    icon: Icons.visibility_outlined,
                    expand: true,
                    onPressed: () => context.push('/student/solution')),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton('Back to Hub',
                    kind: AppBtnKind.ghost,
                    icon: Icons.home_outlined,
                    expand: true,
                    onPressed: () => context.go('/student/hub')),
              ),
            ]),
            const SizedBox(height: 20),

            // Score ring
            AppCard(
              color: AppColors.surfaceContainer,
              child: Column(children: [
                FieldLabel('Total Score'),
                const SizedBox(height: 6),
                DonutChart(
                  const [(0.85, AppColors.primary), (0.15, AppColors.surfaceHigh)],
                  size: 140,
                  center: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('85',
                        style: AppTheme.mono(30, FontWeight.w700,
                            color: AppColors.onSurface)),
                    Text('/ 100', style: AppTheme.mono(11, FontWeight.w500)),
                  ]),
                ),
                const SizedBox(height: 12),
                Text('Top 5% Performance',
                    style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 15)),
              ]),
            ),
            const SizedBox(height: 12),
            _MetricRow(
              icon: Icons.timer_outlined,
              label: 'TIME TAKEN',
              value: '42:15',
              sub: '12 minutes faster than average for this module.',
            ),
            _MetricRow(
              icon: Icons.track_changes,
              label: 'ACCURACY',
              value: '88%',
              sub: 'High precision maintained in multi-choice sections.',
            ),
            const SizedBox(height: 16),

            const StudentSection('AI Performance Diagnostic',
                icon: Icons.bolt_outlined),
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DiagItem(
                    tag: 'FIX',
                    tagColor: AppColors.error,
                    spans: const [
                      ('Review ', null),
                      ('Vector Cross Products', AppColors.teal),
                      (': Your accuracy was low in this area during the second half of the exam.', null),
                    ],
                    chips: const [('HARD', AppColors.error), ('8m 12s', AppColors.muted)],
                  ),
                  _DiagItem(
                    tag: 'TIP',
                    tagColor: AppColors.secondary,
                    spans: const [
                      ('Speed up ', null),
                      ('Organic Synthesis', AppColors.success),
                      (': You spent 4.5 minutes on a single reaction question. Practice timed drills.', null),
                    ],
                  ),
                  _DiagItem(
                    tag: 'TREND',
                    tagColor: AppColors.primary,
                    spans: const [
                      ('TOPIC TREND: Your speed in ', null),
                      ('Thermodynamics', AppColors.teal),
                      (' has increased by 15% over the last 3 sessions.', null),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AppButton('Generate Personalized Roadmap',
                      expand: true,
                      icon: Icons.route_outlined,
                      onPressed: () => context.push('/student/exam-analysis')),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text('Topic Performance',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 14),
            for (final (topic, score, total, chips, color) in const [
              ('Calculus', 22, 25, ['INTEGRATION', 'LIMITS'], AppColors.primary),
              ('Thermodynamics', 18, 25, ['ENTROPY', 'IDEAL GASES'], AppColors.teal),
              ('Organic Chemistry', 20, 25, ['ALKANES', 'ISOMERISM'], AppColors.success),
              ('Classical Mechanics', 15, 25, ['ROTATION', 'VECTORS'], AppColors.error),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child: Text(topic,
                                style: Theme.of(context).textTheme.titleMedium)),
                        Text.rich(TextSpan(children: [
                          TextSpan(
                              text: '$score',
                              style: AppTheme.mono(13, FontWeight.w700,
                                  color: AppColors.onSurface)),
                          TextSpan(
                              text: ' / $total',
                              style: AppTheme.mono(11, FontWeight.w500,
                                  color: color == AppColors.error
                                      ? AppColors.error
                                      : AppColors.muted)),
                        ])),
                      ]),
                      const SizedBox(height: 10),
                      ProgressLine(score / total, color: color, height: 7),
                      const SizedBox(height: 12),
                      Wrap(spacing: 8, children: [
                        for (final c in chips)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(color: AppColors.outline),
                            ),
                            child: Text(c,
                                style: AppTheme.mono(8.5, FontWeight.w600, ls: 0.5)),
                          ),
                      ]),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),

            // Percentile histogram
            AppCard(
              color: AppColors.surfaceContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('How you compare',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                      'Your performance is in the 95th percentile. You are '
                      'currently outpacing 14,200 other students in the JEE '
                      'Advanced track.',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 110,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        for (final (h, you) in const [
                          (0.35, false), (0.55, false), (0.75, false),
                          (0.6, false), (1.0, true), (0.45, false), (0.3, false),
                        ])
                          Container(
                            width: 26,
                            height: 110 * h,
                            decoration: BoxDecoration(
                              color: you
                                  ? AppColors.primary
                                  : AppColors.surfaceHighest,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.icon, required this.label,
    required this.value, required this.sub,
  });
  final IconData icon;
  final String label, value, sub;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AppCard(
          accentTop: AppColors.teal,
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.tealStrong.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, size: 20, color: AppColors.teal),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTheme.mono(9, FontWeight.w600, ls: 1)),
                  Text(value,
                      style: AppTheme.mono(22, FontWeight.w700,
                          color: AppColors.onSurface)),
                  Text(sub, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ]),
        ),
      );
}

class _DiagItem extends StatelessWidget {
  const _DiagItem({
    required this.tag, required this.tagColor,
    required this.spans, this.chips = const [],
  });
  final String tag;
  final Color tagColor;
  final List<(String, Color?)> spans;
  final List<(String, Color)> chips;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: tagColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(tag,
                  style: AppTheme.mono(9, FontWeight.w700, color: tagColor)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(TextSpan(children: [
                    for (final (text, color) in spans)
                      TextSpan(
                          text: text,
                          style: TextStyle(
                              color: color ?? AppColors.onSurfaceVariant,
                              fontWeight:
                                  color != null ? FontWeight.w600 : null)),
                  ])),
                  if (chips.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(spacing: 8, children: [
                      for (final (c, col) in chips)
                        StatusChip(c, color: col),
                    ]),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
}
