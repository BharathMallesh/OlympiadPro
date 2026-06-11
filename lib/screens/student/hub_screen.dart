import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';
import 'student_shell.dart';

class StudentHubScreen extends StatefulWidget {
  const StudentHubScreen({super.key});
  @override
  State<StudentHubScreen> createState() => _StudentHubScreenState();
}

class _StudentHubScreenState extends State<StudentHubScreen> {
  String _subject = 'Math';
  String _difficulty = 'Hard';

  @override
  Widget build(BuildContext context) {
    return StudentShell(
      title: 'OlympiadPro',
      currentTab: 0,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const StudentSection('My Classroom', icon: Icons.school_outlined),
            // Assigned quiz card
            AppCard(
              accentTop: AppColors.teal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    StatusChip('Physics', color: AppColors.teal),
                    const Spacer(),
                    const Icon(Icons.timer_outlined,
                        size: 16, color: AppColors.teal),
                  ]),
                  const SizedBox(height: 12),
                  Text('Weekly Physics Quiz',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text('Assigned by Dr. Thorne',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 16),
                  Row(children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('DUE IN', style: AppTheme.mono(9, FontWeight.w500)),
                      Text('2 days',
                          style: AppTheme.mono(14, FontWeight.w700,
                              color: AppColors.error)),
                    ]),
                    const Spacer(),
                    AppButton('Take Now',
                        kind: AppBtnKind.secondary,
                        onPressed: () => context.push('/student/exam')),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Join a class
            InkWell(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              onTap: () => context.push('/student/join-class'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.outlineStrong),
                ),
                child: Column(children: [
                  const Icon(Icons.group_add_outlined,
                      color: AppColors.muted, size: 28),
                  const SizedBox(height: 8),
                  Text('Join a Class',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text("Enter your instructor's code to unlock assignments.",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall),
                ]),
              ),
            ),
            const SizedBox(height: 24),

            const StudentSection('Smart Practice', icon: Icons.auto_awesome),
            AppCard(
              color: AppColors.surfaceContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Practice Generator',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                      'Our engine selects optimized question sets from our elite '
                      'question bank based on your focus areas and performance '
                      'history.',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 18),
                  Row(children: [
                    Text('SUBJECT:', style: AppTheme.mono(10, FontWeight.w600)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Wrap(spacing: 8, children: [
                        for (final s in ['Math', 'Physics', 'Bio'])
                          _MiniChip(s, _subject == s,
                              () => setState(() => _subject = s)),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Text('DIFFICULTY:', style: AppTheme.mono(10, FontWeight.w600)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Wrap(spacing: 8, children: [
                        for (final d in ['Easy', 'Hard'])
                          _MiniChip(d, _difficulty == d,
                              () => setState(() => _difficulty = d),
                              color: AppColors.teal),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 18),
                  AppButton('Generate Practice Set',
                      expand: true,
                      onPressed: () => context.push('/student/practice-generator')),
                  const SizedBox(height: 24),
                  Center(
                    child: DonutChart(
                      const [(0.72, AppColors.teal), (0.28, AppColors.surfaceHigh)],
                      size: 120,
                      center: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text('72%',
                            style: AppTheme.mono(20, FontWeight.w700,
                                color: AppColors.onSurface)),
                        Text('READY', style: AppTheme.mono(8, FontWeight.w500)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text('IOI PREP STATUS',
                        style: AppTheme.mono(10, FontWeight.w600,
                            color: AppColors.teal, ls: 1)),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                        "Complete 5 more Bio-mechanics modules to reach "
                        "'Advanced' level.",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            StudentSection('Recent Activity',
                icon: Icons.history,
                trailing: TextButton(
                    onPressed: () => context.go('/student/practice-results'),
                    child: const Text('VIEW ALL'))),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.outline)),
                  ),
                  child: Row(children: [
                    Expanded(
                        child: Text('EXAM / QUIZ',
                            style: AppTheme.mono(9, FontWeight.w600, ls: 0.8))),
                    Text('TYPE', style: AppTheme.mono(9, FontWeight.w600, ls: 0.8)),
                  ]),
                ),
                for (final (name, type, color) in const [
                  ('Coordinate Geometry - Set 4', 'AI GENERATED', AppColors.primary),
                  ('Thermodynamics Mid-term', 'CLASSROOM', AppColors.teal),
                  ('Organic Chem Basics', 'AI GENERATED', AppColors.primary),
                ])
                  InkWell(
                    onTap: () => context.push('/student/exam-analysis'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 13),
                      decoration: const BoxDecoration(
                        border:
                            Border(bottom: BorderSide(color: AppColors.outline)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.description_outlined,
                            size: 16, color: AppColors.muted),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(name,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(fontSize: 14)),
                        ),
                        StatusChip(type, color: color),
                      ]),
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip(this.label, this.selected, this.onTap,
      {this.color = AppColors.primary});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.2) : AppColors.scaffold,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
                color: selected ? color : AppColors.outlineStrong),
          ),
          child: Text(label,
              style: AppTheme.mono(11, FontWeight.w600,
                  color: selected ? color : AppColors.muted)),
        ),
      );
}
