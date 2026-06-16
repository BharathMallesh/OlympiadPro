import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/repo.dart';
import '../../widgets/common.dart';
import 'student_shell.dart';

/// Student exams list, live from the backend: upcoming (not started /
/// in progress) and past (submitted / graded) with real scores.
class MyExamsScreen extends StatefulWidget {
  const MyExamsScreen({super.key});
  @override
  State<MyExamsScreen> createState() => _MyExamsScreenState();
}

class _MyExamsScreenState extends State<MyExamsScreen> {
  int _tab = 0;
  List<dynamic> _exams = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final exams = await Repo.studentExams();
      if (!mounted) return;
      setState(() {
        _exams = exams;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  bool _isPast(Map<String, dynamic> e) =>
      e['status'] == 'submitted' ||
      e['status'] == 'auto_graded' ||
      e['status'] == 'manual_review' ||
      e['status'] == 'graded';

  @override
  Widget build(BuildContext context) {
    final upcoming = _exams
        .where((e) => !_isPast(e as Map<String, dynamic>))
        .cast<Map<String, dynamic>>()
        .toList();
    final past = _exams
        .where((e) => _isPast(e as Map<String, dynamic>))
        .cast<Map<String, dynamic>>()
        .toList();

    return StudentShell(
      title: 'My Exams',
      currentTab: 2,
      body: Column(children: [
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
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(_error!,
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 12),
                      AppButton('Retry', onPressed: _load),
                    ]))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        children: [
                          if ((_tab == 0 ? upcoming : past).isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 60),
                              child: Center(
                                child: Text(
                                    _tab == 0
                                        ? 'No upcoming exams. Pull to refresh.'
                                        : 'No completed exams yet.',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                              ),
                            ),
                          for (final e in (_tab == 0 ? upcoming : past))
                            _ExamTile(exam: e),
                        ],
                      ),
                    ),
        ),
      ]),
    );
  }
}

class _ExamTile extends StatelessWidget {
  const _ExamTile({required this.exam});
  final Map<String, dynamic> exam;

  @override
  Widget build(BuildContext context) {
    final status = exam['status'] as String?;
    final examId = exam['exam_id'] as String;
    final title = exam['title'] as String? ?? '';
    final sub =
        '${exam['board']} · ${exam['duration_min']} min · ${exam['total_marks']} marks';

    final (chip, chipColor, action) = switch (status) {
      'not_started' => (
          'READY',
          AppColors.success,
          AppButton('Start Exam',
              kind: AppBtnKind.secondary,
              onPressed: () => context.push('/student/exam?exam=$examId')),
        ),
      'in_progress' => (
          'IN PROGRESS',
          AppColors.teal,
          AppButton('Resume',
              kind: AppBtnKind.secondary,
              onPressed: () => context.push('/student/exam?exam=$examId')),
        ),
      'graded' || 'auto_graded' => (
          'GRADED · ${exam['score']}/${exam['max_score']}',
          AppColors.success,
          null,
        ),
      'manual_review' || 'submitted' => (
          'AWAITING RESULTS',
          AppColors.secondary,
          null,
        ),
      _ => ('UPCOMING', AppColors.muted, null),
    };

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
              StatusChip(chip, color: chipColor, filled: status == 'not_started'),
            ]),
            const SizedBox(height: 4),
            Text(sub, style: Theme.of(context).textTheme.bodySmall),
            if (action != null) ...[
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerRight, child: action),
            ],
          ],
        ),
      ),
    );
  }
}
