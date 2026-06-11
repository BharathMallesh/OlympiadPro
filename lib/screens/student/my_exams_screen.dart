import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/store.dart';
import '../../widgets/common.dart';
import 'student_shell.dart';

/// #7 — Student exams list: upcoming / live / past with statuses, closing the
/// teacher-publishes -> student-takes loop.
class MyExamsScreen extends StatefulWidget {
  const MyExamsScreen({super.key});
  @override
  State<MyExamsScreen> createState() => _MyExamsScreenState();
}

class _MyExamsScreenState extends State<MyExamsScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final resultsOut = AppStore.resultsPublished;
    return StudentShell(
      title: 'My Exams',
      currentTab: 2,
      body: Column(children: [
        // Upcoming / Past segmented
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.outline),
            ),
            child: Row(children: [
              for (final (i, label) in const [(0, 'Upcoming'), (1, 'Past')])
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _tab = i),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _tab == i
                            ? AppColors.tealStrong.withValues(alpha: 0.25)
                            : null,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(label,
                          style: AppTheme.mono(12, FontWeight.w600,
                              color:
                                  _tab == i ? AppColors.teal : AppColors.muted)),
                    ),
                  ),
                ),
            ]),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: _tab == 0
                ? [
                    _ExamTile(
                      title: 'JEE Advanced: Paper 1',
                      sub: 'Dr. Aris Thorne · 18 questions · 180 min',
                      chip: 'LIVE NOW',
                      chipColor: AppColors.success,
                      filled: true,
                      action: AppButton('Enter',
                          kind: AppBtnKind.secondary,
                          onPressed: () => context.push('/student/exam')),
                    ),
                    _ExamTile(
                      title: 'Weekly Physics Quiz',
                      sub: 'Dr. Thorne · due in 2 days',
                      chip: 'SCHEDULED',
                      chipColor: AppColors.teal,
                      action: AppButton('Take Now',
                          kind: AppBtnKind.ghost,
                          onPressed: () => context.push('/student/exam')),
                    ),
                    _ExamTile(
                      title: 'Chemistry Mid-term',
                      sub: 'Opens 28 Nov, 09:00 · countdown 24h prior',
                      chip: 'UPCOMING',
                      chipColor: AppColors.muted,
                    ),
                  ]
                : [
                    _ExamTile(
                      title: 'JEE Main Mock 4',
                      sub: 'Submitted 2h ago · 18 questions',
                      chip: resultsOut ? 'GRADED · 84%' : 'AWAITING RESULTS',
                      chipColor:
                          resultsOut ? AppColors.success : AppColors.secondary,
                      action: resultsOut
                          ? AppButton('View Analysis',
                              onPressed: () =>
                                  context.push('/student/exam-analysis'))
                          : null,
                    ),
                    _ExamTile(
                      title: 'Calculus Practice Set',
                      sub: 'AI-generated · completed yesterday',
                      chip: 'SCORED 85/100',
                      chipColor: AppColors.primary,
                      action: AppButton('Results',
                          kind: AppBtnKind.ghost,
                          onPressed: () =>
                              context.push('/student/practice-results')),
                    ),
                    _ExamTile(
                      title: 'Mock IIT-JEE Full #16',
                      sub: 'Mar 14 · 284/300',
                      chip: 'PASSED',
                      chipColor: AppColors.success,
                      action: AppButton('Solutions',
                          kind: AppBtnKind.ghost,
                          onPressed: () => context.push('/student/solution')),
                    ),
                  ],
          ),
        ),
      ]),
    );
  }
}

class _ExamTile extends StatelessWidget {
  const _ExamTile({
    required this.title, required this.sub,
    required this.chip, required this.chipColor,
    this.action, this.filled = false,
  });
  final String title, sub, chip;
  final Color chipColor;
  final Widget? action;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        accentTop: chipColor == AppColors.muted ? null : chipColor,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(title,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              StatusChip(chip, color: chipColor, filled: filled),
            ]),
            const SizedBox(height: 4),
            Text(sub, style: Theme.of(context).textTheme.bodySmall),
            if (action != null) ...[
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerRight, child: action!),
            ],
          ],
        ),
      ),
    );
  }
}
