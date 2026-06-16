import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../widgets/common.dart';

/// Notifications center, shared by both roles. There is no notifications
/// backend yet, so this shows an honest empty state rather than fabricated
/// items. Wire it to a real feed when the backend endpoint exists.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key, this.role = 'teacher'});
  final String role;

  @override
  Widget build(BuildContext context) {
    final home = role == 'student' ? '/student/hub' : '/dashboard';
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
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.muted.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_none,
                      size: 40, color: AppColors.muted),
                ),
                const SizedBox(height: 20),
                Text("You're all caught up",
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 10),
                Text(
                  'No new notifications right now.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
