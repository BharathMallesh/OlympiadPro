import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/mock.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/common.dart';

class ClassHeatmapScreen extends StatelessWidget {
  const ClassHeatmapScreen({super.key});

  static Color _heat(int v) {
    if (v >= 80) return AppColors.success;
    if (v >= 55) return AppColors.secondary;
    return AppColors.errorStrong;
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      brand: 'OlympiadPro',
      currentRoute: '/analytics/class',
      title: 'Class Analytics',
      actions: [
        AppButton('Manage Roster', kind: AppBtnKind.ghost,
            icon: Icons.group_add_outlined,
            onPressed: () => context.push('/roster')),
        const SizedBox(width: 10),
        TopAction(Icons.notifications_outlined,
            onTap: () => context.push('/notifications')),
        const SizedBox(width: 12),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  StatBlock(label: 'Average Score', value: '78.4', delta: '+5.2%',
                      valueColor: AppColors.onSurface),
                  StatBlock(label: 'Class Percentile', value: '92nd',
                      delta: 'Top 10 Schools', deltaColor: AppColors.muted,
                      valueColor: AppColors.primary),
                  StatBlock(label: 'Attendance Rate', value: '96.8%', delta: '-1.2%',
                      deltaColor: AppColors.error, valueColor: AppColors.teal),
                ],
              );
            }),
            const SizedBox(height: 20),

            LayoutBuilder(builder: (context, c) {
              final wide = c.maxWidth >= 880;
              return Flex(
                direction: wide ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Heatmap table
                  Expanded(
                    flex: wide ? 3 : 0,
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                                child: Text('Topic Performance Heatmap',
                                    style: Theme.of(context).textTheme.titleLarge)),
                            _legend('Low', AppColors.errorStrong),
                            const SizedBox(width: 8),
                            _legend('High', AppColors.success),
                          ]),
                          const SizedBox(height: 18),
                          // header
                          Row(children: const [
                            Expanded(flex: 3, child: _HCell('Topic Name')),
                            Expanded(flex: 2, child: _HCell('Top 20%')),
                            Expanded(flex: 2, child: _HCell('Mid 60%')),
                            Expanded(flex: 2, child: _HCell('Bottom 20%')),
                            Expanded(flex: 2, child: _HCell('Overall')),
                          ]),
                          const SizedBox(height: 8),
                          for (final (topic, cells, overall) in Mock.heatmap)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Row(children: [
                                Expanded(flex: 3,
                                    child: Text(topic,
                                        style: Theme.of(context).textTheme.bodyLarge
                                            ?.copyWith(fontSize: 14))),
                                for (final v in cells)
                                  Expanded(flex: 2, child: _HeatCell(v, _heat(v))),
                                Expanded(flex: 2,
                                    child: Text('$overall%',
                                        textAlign: TextAlign.center,
                                        style: AppTheme.mono(13, FontWeight.w700,
                                            color: AppColors.onSurface))),
                              ]),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: wide ? 16 : 0, height: wide ? 0 : 16),
                  // Subject mastery
                  Expanded(
                    flex: wide ? 2 : 0,
                    child: AppCard(
                      color: AppColors.surfaceContainer,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Subject Mastery',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 18),
                          for (final (subj, pct, color) in const [
                            ('Physics', 0.74, AppColors.primary),
                            ('Chemistry', 0.82, AppColors.teal),
                            ('Mathematics', 0.91, AppColors.success),
                          ])
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Expanded(child: Text(subj,
                                        style: Theme.of(context).textTheme.bodyLarge
                                            ?.copyWith(fontSize: 14))),
                                    Text('${(pct * 100).round()}%',
                                        style: AppTheme.mono(13, FontWeight.w700, color: color)),
                                  ]),
                                  const SizedBox(height: 8),
                                  ProgressLine(pct, color: color, height: 8),
                                ],
                              ),
                            ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Text(
                                'Academic Insight: Class is performing exceptionally '
                                'well in Calculus but struggling with conceptual '
                                'application in Electromagnetism. Focused problem '
                                'sets recommended.',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(fontStyle: FontStyle.italic)),
                          ),
                        ],
                      ),
                    ),
                  ),
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
}

class _HCell extends StatelessWidget {
  const _HCell(this.text);
  final String text;
  @override
  Widget build(BuildContext context) =>
      Text(text, textAlign: text == 'Topic Name' ? TextAlign.left : TextAlign.center,
          style: AppTheme.mono(9.5, FontWeight.w600, ls: 0.5));
}

class _HeatCell extends StatelessWidget {
  const _HeatCell(this.value, this.color);
  final int value;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        height: 34,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Text('$value',
            style: AppTheme.mono(13, FontWeight.w700, color: Colors.black87, ls: 0)),
      );
}
