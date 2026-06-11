import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../widgets/common.dart';
import 'student_shell.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StudentShell(
      title: 'Profile',
      currentTab: 3,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              accentTop: AppColors.teal,
              child: Row(children: [
                const InitialsAvatar('Rohan Iyer', size: 60, color: AppColors.teal),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rohan Iyer',
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 4),
                      Text('Class 10 · Excellence Academy',
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, children: [
                        StatusChip('JEE Track', color: AppColors.teal),
                        StatusChip('Elite Tier', color: AppColors.secondary),
                      ]),
                    ],
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            Row(children: const [
              Expanded(
                  child: StatBlock(
                      label: 'Avg Score', value: '85', delta: 'Top 5%',
                      deltaColor: AppColors.success)),
              SizedBox(width: 12),
              Expanded(
                  child: StatBlock(
                      label: 'Percentile', value: '95th',
                      valueColor: AppColors.teal)),
            ]),
            const SizedBox(height: 20),
            const StudentSection('Account', icon: Icons.settings_outlined),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(children: [
                for (final (icon, label, route) in [
                  (Icons.school_outlined, 'My Classroom', '/student/hub'),
                  (Icons.fact_check_outlined, 'Academic Interests', '/student/interests'),
                  (Icons.group_add_outlined, 'Join a Class', '/student/join-class'),
                  (Icons.bar_chart_outlined, 'My Results', '/student/practice-results'),
                  (Icons.settings_outlined, 'Settings', '/student/settings'),
                ])
                  Column(children: [
                    ListTile(
                      leading: Icon(icon, size: 20, color: AppColors.onSurfaceVariant),
                      title: Text(label,
                          style: Theme.of(context).textTheme.bodyLarge),
                      trailing: const Icon(Icons.chevron_right,
                          size: 18, color: AppColors.muted),
                      onTap: () => context.push(route),
                    ),
                    const Divider(height: 1),
                  ]),
                ListTile(
                  leading: const Icon(Icons.logout, size: 20, color: AppColors.error),
                  title: Text('Sign Out',
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(color: AppColors.error)),
                  onTap: () => context.go('/login'),
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
