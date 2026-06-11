import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../data/mock.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';

class ExamAnalyticsScreen extends StatelessWidget {
  const ExamAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    return AppShell(
      brand: 'OlympiadPro',
      currentRoute: '/analytics/exam',
      // On phones the two action buttons would push the title out of the
      // AppBar, so the title moves into the body and the actions collapse
      // into an overflow menu.
      titleWidget: wide
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Advanced Calculus Mastery',
                    style: Theme.of(context).textTheme.titleLarge),
                Text('Analytics Report · Fall Semester 2024',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            )
          : null,
      title: 'Exam Analytics',
      actions: wide
          ? [
              AppButton('Export PDF', kind: AppBtnKind.ghost,
                  icon: Icons.download_outlined, onPressed: () {}),
              const SizedBox(width: 10),
              AppButton('Share Report', kind: AppBtnKind.secondary,
                  icon: Icons.share_outlined, onPressed: () {}),
              const SizedBox(width: 12),
            ]
          : [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.onSurfaceVariant),
                color: AppColors.surfaceHigh,
                onSelected: (_) {},
                itemBuilder: (context) => const [
                  PopupMenuItem(
                      value: 'export',
                      child: Row(children: [
                        Icon(Icons.download_outlined, size: 18),
                        SizedBox(width: 10),
                        Text('Export PDF'),
                      ])),
                  PopupMenuItem(
                      value: 'share',
                      child: Row(children: [
                        Icon(Icons.share_outlined, size: 18),
                        SizedBox(width: 10),
                        Text('Share Report'),
                      ])),
                ],
              ),
              const SizedBox(width: 4),
            ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!wide) ...[
              Text('Advanced Calculus Mastery',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text('Analytics Report · Fall Semester 2024',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 20),
            ],
            // KPI row
            LayoutBuilder(builder: (context, c) {
              final cross = c.maxWidth >= 720 ? 3 : 1;
              return GridView.count(
                crossAxisCount: cross,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: cross == 1 ? 2.8 : 2.6,
                children: const [
                  _KpiCard(label: 'Avg Score', value: '68%', delta: '↑ 4.2%',
                      icon: Icons.bar_chart, color: AppColors.primary),
                  _KpiCard(label: 'Top Score', value: '98%', sub: 'Class record setter',
                      icon: Icons.emoji_events_outlined, color: AppColors.secondary),
                  _KpiCard(label: 'Completion', value: '92%', sub: '424/460 students',
                      icon: Icons.check_circle_outline, color: AppColors.success),
                ],
              );
            }),
            const SizedBox(height: 20),

            // Topic performance + time distribution
            LayoutBuilder(builder: (context, c) {
              final wide = c.maxWidth >= 820;
              return Flex(
                direction: wide ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: wide ? 3 : 0,
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                                child: Text('Topic-wise Performance',
                                    style: Theme.of(context).textTheme.titleLarge)),
                            _legend('Class Avg', AppColors.primary),
                            const SizedBox(width: 12),
                            _legend('Target', AppColors.muted),
                          ]),
                          const SizedBox(height: 20),
                          for (final t in Mock.topics) _TopicBar(topic: t),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: wide ? 16 : 0, height: wide ? 0 : 16),
                  Expanded(
                    flex: wide ? 2 : 0,
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Time Distribution',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 16),
                          Center(
                            child: DonutChart(
                              const [
                                (0.65, AppColors.primary),
                                (0.25, AppColors.teal),
                                (0.10, AppColors.success),
                              ],
                              size: 160,
                              center: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('1h 14m',
                                      style: AppTheme.mono(18, FontWeight.w700,
                                          color: AppColors.onSurface)),
                                  Text('AVG DURATION',
                                      style: AppTheme.mono(8, FontWeight.w500)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _legendStat('65%', 'SOLVED', AppColors.primary),
                              _legendStat('25%', 'REVIEW', AppColors.teal),
                              _legendStat('10%', 'IDLE', AppColors.success),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 24),

            // Critical gaps
            Row(children: [
              const Icon(Icons.warning_amber, color: AppColors.secondary, size: 18),
              const SizedBox(width: 8),
              Text('Critical Gaps Identified',
                  style: Theme.of(context).textTheme.titleLarge),
            ]),
            const SizedBox(height: 12),
            LayoutBuilder(builder: (context, c) {
              final cross = c.maxWidth >= 720 ? 2 : 1;
              return GridView.count(
                crossAxisCount: cross,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: cross == 1 ? 3.2 : 3.4,
                children: const [
                  _GapCard('Integration by Parts', 'Common error: Polynomial term choice',
                      '45%', AppColors.error, Icons.functions),
                  _GapCard('Taylor Series Convergence', 'Struggle with: Interval of convergence',
                      '38%', AppColors.error, Icons.timeline),
                  _GapCard('Limits at Infinity', "L'Hopital's Rule misapplication",
                      '52%', AppColors.secondary, Icons.trending_up),
                  _GapCard('Substitution Rule (u-sub)', 'Complex trigonometric substitution',
                      '55%', AppColors.secondary, Icons.calculate_outlined),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _legend(String label, Color color) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 10, height: 10,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: AppTheme.mono(10, FontWeight.w500)),
      ]);

  Widget _legendStat(String value, String label, Color color) => Column(children: [
        Text(value, style: AppTheme.mono(16, FontWeight.w700, color: color)),
        Text(label, style: AppTheme.mono(8, FontWeight.w500)),
      ]);
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label, required this.value, required this.icon, required this.color,
    this.delta, this.sub,
  });
  final String label, value;
  final IconData icon;
  final Color color;
  final String? delta, sub;
  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.surfaceContainer,
      accentTop: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: FieldLabel(label)),
            Icon(icon, size: 16, color: color),
          ]),
          const SizedBox(height: 6),
          Row(crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic, children: [
            Text(value, style: AppTheme.mono(30, FontWeight.w700,
                color: AppColors.onSurface, ls: -1)),
            const SizedBox(width: 8),
            if (delta != null)
              Text(delta!, style: AppTheme.mono(12, FontWeight.w600, color: AppColors.success)),
          ]),
          if (sub != null)
            Text(sub!, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _TopicBar extends StatelessWidget {
  const _TopicBar({required this.topic});
  final dynamic topic;
  @override
  Widget build(BuildContext context) {
    final score = topic.score as double;
    final target = topic.target as double;
    final color = score >= 0.75
        ? AppColors.success
        : score >= 0.5
            ? AppColors.secondary
            : AppColors.error;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(topic.name as String,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 14))),
            Text('${(score * 100).round()}% / ${(target * 100).round()}%',
                style: AppTheme.mono(12, FontWeight.w600, color: AppColors.onSurfaceVariant)),
          ]),
          const SizedBox(height: 8),
          Stack(children: [
            ProgressLine(target, color: AppColors.surfaceHighest, height: 8),
            ProgressLine(score, color: color, height: 8),
          ]),
        ],
      ),
    );
  }
}

class _GapCard extends StatelessWidget {
  const _GapCard(this.title, this.sub, this.rate, this.color, this.icon);
  final String title, sub, rate;
  final Color color;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      borderColor: color.withValues(alpha: 0.4),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis),
              Text(sub, style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(rate, style: AppTheme.mono(16, FontWeight.w700, color: color)),
          Text('SUCCESS', style: AppTheme.mono(8, FontWeight.w500)),
        ]),
      ]),
    );
  }
}
