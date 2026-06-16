import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/store.dart';
import '../../widgets/common.dart';

/// #6 — Notifications center, shared by both roles. Read state persists via
/// AppStore (#13).
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, this.role = 'teacher'});
  final String role;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late bool _allRead = AppStore.notificationsRead;

  List<(IconData, Color, String, String, String)> get _items =>
      widget.role == 'student'
          ? [
              if (AppStore.resultsPublished)
                (Icons.grading, AppColors.success, 'Results published',
                    'Your JEE Main Mock 4 results are ready — tap to view your analysis.',
                    '2m ago'),
              (Icons.assignment_outlined, AppColors.teal, 'New exam assigned',
                  'Dr. Thorne assigned "Weekly Physics Quiz" — due in 2 days.',
                  '1h ago'),
              (Icons.auto_awesome, AppColors.primary, 'Practice set ready',
                  'Your AI-generated Calculus practice set is ready to start.',
                  '3h ago'),
              (Icons.trending_up, AppColors.success, 'Streak milestone',
                  'You have practiced 5 days in a row. Keep it up!', '1d ago'),
            ]
          : [
              (Icons.flag_outlined, AppColors.error, 'Proctoring alert',
                  'Maya Wong was flagged for repeated tab switching in JEE Mock.',
                  '5m ago'),
              (Icons.assignment_turned_in_outlined, AppColors.teal,
                  'New submissions',
                  '4 new submissions in JEE Main Mock 4 await grading.', '45m ago'),
              (Icons.person_add_outlined, AppColors.primary,
                  'Join request',
                  'Rohan Iyer requested to join Advanced Calculus - Section A.',
                  '2h ago'),
              (Icons.schedule, AppColors.secondary, 'Exam starting soon',
                  'Advanced Physics - JEE Mock 1 starts in 24 hours.', '1d ago'),
            ];

  @override
  Widget build(BuildContext context) {
    final home = widget.role == 'student' ? '/student/hub' : '/dashboard';
    return PopRedirect(
      fallbackRoute: home,
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          leading: IconButton(
              tooltip: 'Back',
              icon: const Icon(Icons.arrow_back),
              onPressed: () => popOrGo(context, home)),
          titleSpacing: 0,
          title: Text('Notifications',
              style: Theme.of(context).textTheme.titleLarge),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => _allRead = true);
                AppStore.notificationsRead = true;
              },
              child: const Text('Mark all read'),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                for (final (icon, color, title, body, time) in _items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      onTap: () {
                        if (title == 'Results published') {
                          context.push('/student/exam-analysis');
                        } else if (title == 'Proctoring alert') {
                          context.push('/live/incident');
                        } else if (title == 'New submissions') {
                          context.go('/grading/submissions');
                        } else if (title == 'Join request') {
                          context.push('/roster');
                        }
                      },
                      child: AppCard(
                        padding: const EdgeInsets.all(14),
                        borderColor:
                            _allRead ? null : color.withValues(alpha: 0.35),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: Icon(icon, size: 18, color: color),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Expanded(
                                      child: Text(title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium),
                                    ),
                                    if (!_allRead)
                                      Container(
                                        width: 8, height: 8,
                                        decoration: BoxDecoration(
                                            color: color, shape: BoxShape.circle),
                                      ),
                                  ]),
                                  const SizedBox(height: 3),
                                  Text(body,
                                      style:
                                          Theme.of(context).textTheme.bodyMedium),
                                  const SizedBox(height: 6),
                                  Text(time,
                                      style: AppTheme.mono(9, FontWeight.w500)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
