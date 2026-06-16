import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/store.dart';
import '../../widgets/common.dart';

/// #15 — Settings for both roles. Toggles persist via AppStore (#13).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.role = 'teacher'});
  final String role;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    final isStudent = widget.role == 'student';
    final home = isStudent ? '/student/hub' : '/dashboard';
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
          title:
              Text('Settings', style: Theme.of(context).textTheme.titleLarge),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // Account
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    InitialsAvatar(isStudent ? 'Rohan Iyer' : 'Aris Thorne',
                        size: 48,
                        color: isStudent ? AppColors.teal : AppColors.primaryStrong),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isStudent ? 'Rohan Iyer' : 'Dr. Aris Thorne',
                              style: Theme.of(context).textTheme.titleMedium),
                          Text(
                              isStudent
                                  ? 'rohan.iyer@student.edu · Class 10'
                                  : 'a.thorne@excellence.edu · Senior Math Lead',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),

                FieldLabel('Notifications'),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(children: [
                    for (final (key, title, sub) in [
                      ('notif_exams', 'Exam reminders',
                          'Countdown alerts 24h before a scheduled exam.'),
                      if (isStudent)
                        ('notif_results', 'Results & feedback',
                            'When results or graded feedback are published.')
                      else
                        ('notif_submissions', 'Submission alerts',
                            'When new submissions arrive for grading.'),
                      if (!isStudent)
                        ('notif_proctor', 'Proctoring alerts',
                            'Immediate alerts for flagged candidates.'),
                      ('notif_digest', 'Weekly digest',
                          'Performance summary every Monday.'),
                    ])
                      SwitchListTile(
                        value: AppStore.getFlag(key),
                        activeThumbColor: Colors.white,
                        activeTrackColor:
                            isStudent ? AppColors.tealStrong : AppColors.primaryStrong,
                        title: Text(title,
                            style: Theme.of(context).textTheme.bodyLarge),
                        subtitle: Text(sub,
                            style: Theme.of(context).textTheme.bodySmall),
                        onChanged: (v) =>
                            setState(() => AppStore.setFlag(key, v)),
                      ),
                  ]),
                ),
                const SizedBox(height: 16),

                FieldLabel('Preferences'),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(children: [
                    ListTile(
                      leading: const Icon(Icons.translate,
                          size: 20, color: AppColors.onSurfaceVariant),
                      title: Text('Language',
                          style: Theme.of(context).textTheme.bodyLarge),
                      trailing: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _language,
                          dropdownColor: AppColors.surfaceHigh,
                          style: AppTheme.mono(12, FontWeight.w600,
                              color: AppColors.onSurface),
                          items: const [
                            DropdownMenuItem(
                                value: 'English', child: Text('English')),
                            DropdownMenuItem(value: 'हिन्दी', child: Text('हिन्दी')),
                            DropdownMenuItem(value: 'தமிழ்', child: Text('தமிழ்')),
                          ],
                          onChanged: (v) =>
                              setState(() => _language = v ?? 'English'),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.dark_mode_outlined,
                          size: 20, color: AppColors.onSurfaceVariant),
                      title: Text('Theme',
                          style: Theme.of(context).textTheme.bodyLarge),
                      subtitle: Text('Academic Dark (OLED-optimized)',
                          style: Theme.of(context).textTheme.bodySmall),
                      trailing:
                          StatusChip('Always On', color: AppColors.onSurfaceVariant),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),

                AppCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading:
                        const Icon(Icons.logout, size: 20, color: AppColors.error),
                    title: Text('Sign Out',
                        style: Theme.of(context).textTheme.bodyLarge
                            ?.copyWith(color: AppColors.error)),
                    onTap: () => context.go('/login'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
