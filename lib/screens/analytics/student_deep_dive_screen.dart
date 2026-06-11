import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../data/mock.dart';
import '../../models/models.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';

class StudentDeepDiveScreen extends StatelessWidget {
  const StudentDeepDiveScreen({super.key, this.studentId = ''});
  final String studentId;

  static const _fallback = Student('Aravind Sharma', 'JEE-2024-0004',
      tag: 'Advanced Calculus Sec B',
      score: 91,
      status: 'ELITE TIER',
      color: AppColors.teal,
      trend: [0.45, 0.5, 0.48, 0.55, 0.62, 0.7, 0.82, 0.9]);

  Student get student {
    for (final s in Mock.students) {
      if (s.id == studentId) return s;
    }
    return _fallback;
  }

  String get rank {
    final i = Mock.students.indexWhere((s) => s.id == studentId);
    return i >= 0 ? '#0${i + 1}' : '#04';
  }

  @override
  Widget build(BuildContext context) {
    final student = this.student;
    return AppShell(
      brand: 'MathKraft',
      currentRoute: '/analytics/class',
      titleWidget: Row(children: [
        Text('Classes',
            style: AppTheme.mono(11, FontWeight.w500, color: AppColors.muted)),
        const Icon(Icons.chevron_right, size: 14, color: AppColors.muted),
        Text('Advanced Calculus Sec B',
            style: AppTheme.mono(11, FontWeight.w500, color: AppColors.muted)),
        const Icon(Icons.chevron_right, size: 14, color: AppColors.muted),
        Flexible(
          child: Text(student.name,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.mono(11, FontWeight.w500, color: AppColors.primary)),
        ),
      ]),
      title: 'Student Profile',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header
            LayoutBuilder(builder: (context, c) {
              final wide = c.maxWidth >= 640;
              return Flex(
                direction: wide ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: wide ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    InitialsAvatar(student.name,
                        size: 68, color: student.color ?? AppColors.teal),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(student.name,
                            style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 6),
                        Row(children: [
                          StatusChip(
                              student.status.isEmpty ? 'Elite Tier' : student.status,
                              color: AppColors.secondary),
                          const SizedBox(width: 10),
                          const Icon(Icons.location_on_outlined,
                              size: 14, color: AppColors.muted),
                          const SizedBox(width: 4),
                          Text('New Delhi, India',
                              style: Theme.of(context).textTheme.bodySmall),
                        ]),
                      ],
                    ),
                  ]),
                  if (wide) const Spacer(),
                  SizedBox(height: wide ? 0 : 16),
                  Wrap(spacing: 12, runSpacing: 12, children: [
                    _PillStat('Overall Rank', rank, AppColors.primary),
                    const _PillStat('Attendance', '98%', AppColors.teal),
                    _PillStat('Avg Score', '${student.score ?? 91}',
                        AppColors.success),
                  ]),
                ],
              );
            }),
            const SizedBox(height: 24),

            // Subject mastery (radar) + score trend (area)
            LayoutBuilder(builder: (context, c) {
              final wide = c.maxWidth >= 820;
              return Flex(
                direction: wide ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: wide ? 2 : 0,
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Subject Mastery',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 12),
                          const Center(
                            child: RadarChart(
                              [0.88, 0.95, 0.82, 0.7, 0.78],
                              ['PHYSICS', 'MATHS', 'CHEM', 'BIO', 'LOGIC'],
                              size: 220,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: const [
                              _Mastery('PHYS', '88%', AppColors.primary),
                              _Mastery('MATH', '95%', AppColors.success),
                              _Mastery('CHEM', '82%', AppColors.teal),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: wide ? 16 : 0, height: wide ? 0 : 16),
                  Expanded(
                    flex: wide ? 3 : 0,
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                                child: Text('Score Trend',
                                    style: Theme.of(context).textTheme.titleLarge)),
                            StatusChip('Mock Exams', color: AppColors.primary),
                            const SizedBox(width: 8),
                            StatusChip('Quizzes', color: AppColors.onSurfaceVariant),
                          ]),
                          const SizedBox(height: 20),
                          AreaChart(
                            student.trend,
                            color: student.color ?? AppColors.primary,
                            height: 200,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              for (final m in const ['#12', '#13', '#14', '#15', '#16'])
                                Text('MOCK $m',
                                    style: AppTheme.mono(8, FontWeight.w500)),
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

            // Struggling topics + recent exams
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
                                child: Text('Struggling Topics',
                                    style: Theme.of(context).textTheme.titleLarge)),
                            StatusChip('Needs Attention', color: AppColors.error),
                          ]),
                          const SizedBox(height: 16),
                          _StruggleRow('Rotational Dynamics',
                              'Avg. Time: 4m 12s / Question', '42%'),
                          _StruggleRow('Inorganic Qualitative Analysis',
                              'Avg. Time: 1m 45s / Question', '38%'),
                          _StruggleRow('Definite Integration',
                              'Avg. Time: 3m 02s / Question', '51%'),
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
                          Text('Recent Exams',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 16),
                          _ExamRow('Mock IIT-JEE Full #16', 'Mar 14, 2024',
                              '284/300', AppColors.success, 'PASSED'),
                          _ExamRow('Weekly Quiz: Optics', 'Mar 10, 2024',
                              '18/20', AppColors.success, 'PASSED'),
                          _ExamRow('Mock IIT-JEE Full #15', 'Mar 03, 2024',
                              '241/300', AppColors.secondary, 'REVIEW'),
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
}

class _PillStat extends StatelessWidget {
  const _PillStat(this.label, this.value, this.color);
  final String label, value;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(children: [
          Text(label.toUpperCase(), style: AppTheme.mono(9, FontWeight.w500, ls: 0.8)),
          const SizedBox(height: 4),
          Text(value, style: AppTheme.mono(20, FontWeight.w700, color: color)),
        ]),
      );
}

class _Mastery extends StatelessWidget {
  const _Mastery(this.label, this.value, this.color);
  final String label, value;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value, style: AppTheme.mono(16, FontWeight.w700, color: color)),
        Text(label, style: AppTheme.mono(9, FontWeight.w500)),
      ]);
}

class _StruggleRow extends StatelessWidget {
  const _StruggleRow(this.title, this.sub, this.accuracy);
  final String title, sub, accuracy;
  @override
  Widget build(BuildContext context) {
    final pct = double.parse(accuracy.replaceAll('%', '')) / 100;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  Text(sub, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Text('$accuracy Accuracy',
                style: AppTheme.mono(12, FontWeight.w600, color: AppColors.error)),
          ]),
          const SizedBox(height: 8),
          ProgressLine(pct, color: AppColors.error, height: 6),
        ],
      ),
    );
  }
}

class _ExamRow extends StatelessWidget {
  const _ExamRow(this.title, this.date, this.score, this.color, this.status);
  final String title, date, score, status;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(date, style: AppTheme.mono(9, FontWeight.w500)),
              ],
            ),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(score, style: AppTheme.mono(14, FontWeight.w700, color: AppColors.onSurface)),
            StatusChip(status, color: color),
          ]),
        ]),
      );
}
