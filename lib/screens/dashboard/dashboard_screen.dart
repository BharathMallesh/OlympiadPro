import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/mock.dart';
import '../../models/models.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      brand: 'MathKraft',
      currentRoute: '/dashboard',
      title: 'Class Dashboard: 12th Grade A',
      actions: [
        TopAction(Icons.search, tooltip: 'Search'),
        TopAction(Icons.notifications_outlined,
            tooltip: 'Alerts',
            onTap: () => context.push('/notifications')),
        const SizedBox(width: 8),
        const InitialsAvatar('Aris Thorne', size: 34),
        const SizedBox(width: 8),
      ],
      body: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth >= 760;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top stats
              Flex(
                direction: wide ? Axis.horizontal : Axis.vertical,
                children: [
                  Expanded(
                    flex: wide ? 1 : 0,
                    child: _MetricCard(
                      label: 'Class Average',
                      value: '74%',
                      delta: '↑ up 2%',
                      progress: 0.74,
                      progressColor: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: wide ? 16 : 0, height: wide ? 0 : 16),
                  Expanded(
                    flex: wide ? 1 : 0,
                    child: _MetricCard(
                      label: 'Submissions',
                      value: '42/48',
                      delta: '87.5% completion',
                      progress: 0.875,
                      progressColor: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Active exams
              Row(children: [
                Text('Active Exams',
                    style: Theme.of(context).textTheme.headlineSmall),
                const Spacer(),
                TextButton(
                    onPressed: () => context.go('/grading/submissions'),
                    child: const Text('View All')),
              ]),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final exam in Mock.exams)
                    SizedBox(
                      width: wide ? (c.maxWidth - 48 - 32) / 3 : c.maxWidth - 48,
                      child: _ExamCard(exam: exam),
                    ),
                ],
              ),
              const SizedBox(height: 32),

              // Student performance
              Row(children: [
                Text('Student Performance',
                    style: Theme.of(context).textTheme.headlineSmall),
                const Spacer(),
                StatusChip('By Score', color: AppColors.onSurfaceVariant),
              ]),
              const SizedBox(height: 12),
              for (final s in Mock.students)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _StudentRow(student: s),
                ),
            ],
          ),
        );
      }),
      bottomBar: null,
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.delta,
    required this.progress,
    required this.progressColor,
  });
  final String label, value, delta;
  final double progress;
  final Color progressColor;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.surfaceContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FieldLabel(label),
          Row(crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic, children: [
            Text(value, style: AppTheme.mono(34, FontWeight.w700,
                color: AppColors.onSurface, ls: -1)),
            const SizedBox(width: 10),
            Text(delta, style: AppTheme.mono(12, FontWeight.w600,
                color: AppColors.success)),
          ]),
          const SizedBox(height: 14),
          ProgressLine(progress, color: progressColor, height: 6),
        ],
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  const _ExamCard({required this.exam});
  final Exam exam;

  (String, Color) get _status => switch (exam.status) {
        ExamStatus.published => ('Published', AppColors.success),
        ExamStatus.gradingNeeded => ('Grading Needed', AppColors.secondary),
        ExamStatus.draft => ('Draft', AppColors.muted),
        ExamStatus.completed => ('Completed', AppColors.teal),
      };

  @override
  Widget build(BuildContext context) {
    final (label, color) = _status;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            StatusChip(label, color: color),
            const Spacer(),
            Text(exam.board, style: AppTheme.mono(10, FontWeight.w500)),
          ]),
          const SizedBox(height: 14),
          Text(exam.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Row(children: [
            Icon(
                exam.status == ExamStatus.gradingNeeded
                    ? Icons.edit_note
                    : Icons.schedule,
                size: 14,
                color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                exam.status == ExamStatus.gradingNeeded
                    ? '15 pending proofs'
                    : exam.subtitle,
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),
          const SizedBox(height: 18),
          if (exam.status == ExamStatus.published)
            AppButton('Monitor',
                kind: AppBtnKind.ghost,
                expand: true,
                onPressed: () => context.go('/live/console'))
          else if (exam.status == ExamStatus.gradingNeeded)
            AppButton('Grade Now',
                kind: AppBtnKind.secondary,
                expand: true,
                onPressed: () => context.go('/grading/submissions'))
          else
            AppButton('Continue Editing',
                kind: AppBtnKind.ghost,
                expand: true,
                onPressed: () => context.go('/wizard/details')),
        ],
      ),
    );
  }
}

class _StudentRow extends StatelessWidget {
  const _StudentRow({required this.student});
  final Student student;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: () => context.push('/analytics/student/${student.id}'),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          InitialsAvatar(student.name, size: 42, color: student.color),
          const SizedBox(width: 14),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.name,
                    style: Theme.of(context).textTheme.titleMedium),
                Text(student.tag,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (MediaQuery.sizeOf(context).width > 620) ...[
            Column(children: [
              Sparkline(student.trend, color: student.color ?? AppColors.primary),
              Text('7-DAY TREND', style: AppTheme.mono(8, FontWeight.w500)),
            ]),
            const SizedBox(width: 20),
          ],
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${student.score}%',
                style: AppTheme.mono(18, FontWeight.w700,
                    color: AppColors.onSurface)),
            Text(student.status,
                style: AppTheme.mono(9, FontWeight.w600, color: student.color)),
          ]),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: AppColors.muted),
        ]),
      ),
    );
  }
}
