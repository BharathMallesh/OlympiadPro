import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/api.dart';
import '../../data/exam_scope.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Toggle an exam in the target set. A student can prepare for several exams
  /// at once (e.g. NEET + JEE). The curricula are derived from whichever exams
  /// are selected (NEET/JEE→NCERT, CET→State Board), so practice scoping stays
  /// consistent and the profile can never hold a contradictory board/curriculum
  /// pair.
  Future<void> _toggleExam(String exam) async {
    final boards = _boards.any((b) => ExamScope.normalize(b) == exam)
        ? _boards.where((b) => ExamScope.normalize(b) != exam).toList()
        : [..._boards, exam];
    final curricula = {for (final b in boards) ExamScope.curriculumFor(b)}.toList();
    setState(() => _boards = boards);
    try {
      final sb = await Repo.setStudentBoards(boards);
      await Repo.setStudentCurricula(curricula);
      if (mounted) setState(() => _boards = sb);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Could not save: $e'),
            backgroundColor: AppColors.error));
      }
    }
  }

  /// "NEET, JEE · NCERT syllabus" — the selected exams and their distinct
  /// curricula. Empty when nothing is selected.
  String _scopeLabel() {
    final sels = ExamScope.exams
        .where((e) => _boards.any((b) => ExamScope.normalize(b) == e))
        .toList();
    if (sels.isEmpty) return '';
    final curs = {for (final e in sels) ExamScope.curriculumFor(e)}.toList();
    return '${sels.join(', ')} · ${curs.join(' + ')} syllabus';
  }

  Future<void> _load() async {
    try {
      _boards = await Repo.studentBoards();
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
            const StudentSection('Target Exam', icon: Icons.flag_outlined),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'Pick the exams you’re preparing for — you can choose more '
                      'than one. NEET & JEE follow the NCERT syllabus; CET follows '
                      'the State Board syllabus — your practice is scoped '
                      'accordingly.',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final e in ExamScope.exams)
                        Builder(builder: (_) {
                          final sel =
                              _boards.any((b) => ExamScope.normalize(b) == e);
                          return InkWell(
                            onTap: _loading ? null : () => _toggleExam(e),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 9),
                              decoration: BoxDecoration(
                                color: sel
                                    ? AppColors.teal
                                    : AppColors.surfaceContainer,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                                border: Border.all(
                                    color: sel
                                        ? AppColors.teal
                                        : AppColors.outlineStrong),
                              ),
                              child: Text(e,
                                  style: TextStyle(
                                      color: sel
                                          ? AppColors.onPrimary
                                          : AppColors.onSurface,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                            ),
                          );
                        }),
                    ],
                  ),
                  if (_boards.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(children: [
                      const Icon(Icons.menu_book_outlined,
                          size: 15, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(_scopeLabel(),
                            style: AppTheme.mono(12, FontWeight.w700,
                                color: AppColors.onSurface)),
                      ),
                    ]),
                  ],
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
                      '/student/interests?edit=1'),
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
                      // Refresh on return: editing Academic Interests saves the
                      // target exams on another screen, so re-pull them so the
                      // Target Exam picker doesn't show stale selections.
                      onTap: () async {
                        await context.push(route);
                        if (!mounted) return;
                        try {
                          final sb = await Repo.studentBoards();
                          if (mounted) setState(() => _boards = sb);
                        } catch (_) {}
                      },
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
