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
  List<String> _boards = [];
  static const _boardOptions = ['JEE', 'NEET', 'CET', 'CBSE', 'State Board'];
  List<String> _curricula = [];
  static const _curriculumOptions = [
    'NCERT', 'CBSE', 'State Board', 'ICSE', 'IB', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _toggleBoard(String b) async {
    final next = List<String>.from(_boards);
    next.contains(b) ? next.remove(b) : next.add(b);
    setState(() => _boards = next);
    try {
      final saved = await Repo.setStudentBoards(next);
      if (mounted) setState(() => _boards = saved);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Could not save: $e'),
            backgroundColor: AppColors.error));
      }
    }
  }

  Future<void> _toggleCurriculum(String c) async {
    final next = List<String>.from(_curricula);
    next.contains(c) ? next.remove(c) : next.add(c);
    setState(() => _curricula = next);
    try {
      final saved = await Repo.setStudentCurricula(next);
      if (mounted) setState(() => _curricula = saved);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Could not save: $e'),
            backgroundColor: AppColors.error));
      }
    }
  }

  Future<void> _load() async {
    try {
      _boards = await Repo.studentBoards();
      _curricula = await Repo.studentCurricula();
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
            const StudentSection('Target Exam Boards', icon: Icons.flag_outlined),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'Pick the exams you’re preparing for — your AI practice is '
                      'tailored to these (plus general questions).',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final b in _boardOptions)
                        InkWell(
                          onTap: _loading ? null : () => _toggleBoard(b),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 9),
                            decoration: BoxDecoration(
                              color: _boards.contains(b)
                                  ? AppColors.teal
                                  : AppColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              border: Border.all(
                                  color: _boards.contains(b)
                                      ? AppColors.teal
                                      : AppColors.outlineStrong),
                            ),
                            child: Text(b,
                                style: TextStyle(
                                    color: _boards.contains(b)
                                        ? AppColors.onPrimary
                                        : AppColors.onSurface,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const StudentSection('Curriculum / Syllabus', icon: Icons.menu_book_outlined),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'Pick the curriculum you follow — your AI practice is '
                      'scoped to these (plus general questions).',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in _curriculumOptions)
                        InkWell(
                          onTap: _loading ? null : () => _toggleCurriculum(c),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 9),
                            decoration: BoxDecoration(
                              color: _curricula.contains(c)
                                  ? AppColors.primary
                                  : AppColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              border: Border.all(
                                  color: _curricula.contains(c)
                                      ? AppColors.primary
                                      : AppColors.outlineStrong),
                            ),
                            child: Text(c,
                                style: TextStyle(
                                    color: _curricula.contains(c)
                                        ? AppColors.onPrimary
                                        : AppColors.onSurface,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
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
