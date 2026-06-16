import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/api.dart';
import '../../data/repo.dart';
import '../../widgets/common.dart';
import 'student_shell.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  int _taken = 0;
  int? _avgPct;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final exams = await Repo.studentExams();
      var sum = 0.0;
      var graded = 0;
      var taken = 0;
      for (final e in exams) {
        final m = e as Map<String, dynamic>;
        if (m['submitted_at'] != null) taken++;
        final score = m['score'];
        final max = m['max_score'];
        if (score != null && max != null && (max as num) > 0) {
          sum += (score as num) / max;
          graded++;
        }
      }
      if (!mounted) return;
      setState(() {
        _taken = taken;
        _avgPct = graded > 0 ? (sum / graded * 100).round() : null;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = api.displayName ?? 'Student';
    final subtitle = api.displaySubtitle ?? '';
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
                InitialsAvatar(name, size: 60, color: AppColors.teal),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: Theme.of(context).textTheme.headlineSmall),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(subtitle,
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ],
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: StatBlock(
                      label: 'Avg Score',
                      value: _loading
                          ? '…'
                          : (_avgPct == null ? '—' : '$_avgPct%'),
                      delta: 'graded exams',
                      deltaColor: AppColors.muted)),
              const SizedBox(width: 12),
              Expanded(
                  child: StatBlock(
                      label: 'Exams Taken',
                      value: _loading ? '…' : '$_taken',
                      valueColor: AppColors.teal)),
            ]),
            const SizedBox(height: 20),
            const StudentSection('Account', icon: Icons.settings_outlined),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(children: [
                for (final (icon, label, route) in [
                  (Icons.school_outlined, 'My Classroom', '/student/hub'),
                  (Icons.fact_check_outlined, 'Academic Interests',
                      '/student/interests'),
                  (Icons.group_add_outlined, 'Join a Class',
                      '/student/join-class'),
                  (Icons.assignment_outlined, 'My Exams', '/student/exams'),
                  (Icons.settings_outlined, 'Settings', '/student/settings'),
                ])
                  Column(children: [
                    ListTile(
                      leading: Icon(icon,
                          size: 20, color: AppColors.onSurfaceVariant),
                      title: Text(label,
                          style: Theme.of(context).textTheme.bodyLarge),
                      trailing: const Icon(Icons.chevron_right,
                          size: 18, color: AppColors.muted),
                      onTap: () => context.push(route),
                    ),
                    const Divider(height: 1),
                  ]),
                ListTile(
                  leading: const Icon(Icons.logout,
                      size: 20, color: AppColors.error),
                  title: Text('Sign Out',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: AppColors.error)),
                  onTap: () async {
                    await api.clearSession();
                    if (context.mounted) context.go('/login');
                  },
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
