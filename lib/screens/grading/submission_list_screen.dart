import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/mock.dart';
import '../../data/store.dart';
import '../../models/models.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/common.dart';

class SubmissionListScreen extends StatefulWidget {
  const SubmissionListScreen({super.key});
  @override
  State<SubmissionListScreen> createState() => _SubmissionListScreenState();
}

class _SubmissionListScreenState extends State<SubmissionListScreen> {
  int _filter = 0; // 0 all, 1 pending, 2 graded
  bool _published = AppStore.resultsPublished;

  /// #9 - publish graded results to students (persisted via AppStore).
  void _publishResults() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        title: const Text('Publish Results?'),
        content: const Text(
            'All 142 students will be notified and can view their scores, '
            'analysis, and solutions. Pending-grading submissions will show '
            'as "awaiting" until graded.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _published = true);
              AppStore.resultsPublished = true;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text(
                      'Results published - 142 students notified.')));
            },
            child: const Text('Publish',
                style: TextStyle(color: AppColors.secondary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = Mock.submissions.where((s) {
      if (_filter == 1) return !s.graded;
      if (_filter == 2) return s.graded;
      return true;
    }).toList();

    return AppShell(
      brand: 'OlympiadPro',
      currentRoute: '/grading/submissions',
      titleWidget: Row(children: [
        Text('Exams',
            style: AppTheme.mono(12, FontWeight.w500, color: AppColors.muted)),
        const Icon(Icons.chevron_right, size: 16, color: AppColors.muted),
        const SizedBox(width: 4),
        Text('Submissions: JEE Main Mock 4',
            style: Theme.of(context).textTheme.titleLarge),
      ]),
      title: 'Submissions',
      actions: [
        if (_published)
          StatusChip('Results Published', color: AppColors.success,
              icon: Icons.check_circle)
        else
          AppButton('Publish Results',
              kind: AppBtnKind.secondary,
              icon: Icons.campaign_outlined,
              onPressed: _publishResults),
        const SizedBox(width: 12),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter bar
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 280,
                  child: AppInput(hint: 'Search student name or ID...', icon: Icons.search),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    for (final (i, label) in const [
                      (0, 'All'), (1, 'Pending Grading'), (2, 'Graded')
                    ])
                      InkWell(
                        onTap: () => setState(() => _filter = i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: _filter == i
                                ? AppColors.primaryStrong.withValues(alpha: 0.22)
                                : null,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(label,
                              style: AppTheme.mono(11, FontWeight.w600,
                                  color: _filter == i ? AppColors.primary : AppColors.muted)),
                        ),
                      ),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Submission rows
            for (final s in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SubmissionRow(sub: s),
              ),
            const SizedBox(height: 16),

            // Footer stats
            LayoutBuilder(builder: (context, c) {
              final wide = c.maxWidth >= 700;
              return Flex(
                direction: wide ? Axis.horizontal : Axis.vertical,
                children: [
                  Expanded(
                      flex: wide ? 1 : 0,
                      child: const StatBlock(
                          label: 'Total Submissions', value: '142', delta: '/ 150 students',
                          deltaColor: AppColors.muted)),
                  SizedBox(width: wide ? 16 : 0, height: wide ? 0 : 12),
                  Expanded(
                      flex: wide ? 1 : 0,
                      child: const StatBlock(
                          label: 'Grading Progress', value: '88', delta: 'completed',
                          deltaColor: AppColors.success, valueColor: AppColors.success)),
                  SizedBox(width: wide ? 16 : 0, height: wide ? 0 : 12),
                  Expanded(
                      flex: wide ? 1 : 0,
                      child: const StatBlock(
                          label: 'Average Score', value: '64.2', delta: '↑ 5.2% vs Mock 3',
                          valueColor: AppColors.primary)),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _SubmissionRow extends StatelessWidget {
  const _SubmissionRow({required this.sub});
  final Submission sub;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: () => context.push('/grading/manual/${sub.student.id}'),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        borderColor: sub.graded ? null : AppColors.secondary.withValues(alpha: 0.4),
        child: Row(children: [
          InitialsAvatar(sub.student.name, size: 42, color: sub.student.color),
          const SizedBox(width: 14),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sub.student.name,
                    style: Theme.of(context).textTheme.titleMedium),
                Text('ID: ${sub.student.id} · Submitted ${sub.submittedAgo}',
                    style: AppTheme.mono(10, FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('SCORE', style: AppTheme.mono(9, FontWeight.w500)),
            Text(sub.score != null ? '${sub.score}/100' : '--',
                style: AppTheme.mono(18, FontWeight.w700,
                    color: sub.score != null ? AppColors.onSurface : AppColors.muted)),
          ]),
          const SizedBox(width: 16),
          sub.graded
              ? StatusChip('Graded', color: AppColors.success, icon: Icons.check_circle)
              : StatusChip('Pending Proof Grading',
                  color: AppColors.secondary, icon: Icons.pending_outlined),
          const SizedBox(width: 12),
          const Icon(Icons.chevron_right, color: AppColors.muted),
        ]),
      ),
    );
  }
}
