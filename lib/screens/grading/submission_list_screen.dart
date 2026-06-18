import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/repo.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/common.dart';

class SubmissionListScreen extends StatefulWidget {
  const SubmissionListScreen({super.key, this.examId});
  final String? examId;
  @override
  State<SubmissionListScreen> createState() => _SubmissionListScreenState();
}

class _SubmissionListScreenState extends State<SubmissionListScreen> {
  int _filter = 0; // 0 all, 1 pending, 2 graded
  String _query = '';
  String? _examId;
  String _examTitle = '';
  List<dynamic> _subs = [];
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
      _examId = widget.examId;
      final exams = await Repo.exams();
      if (_examId == null) {
        // Default to the most recent non-draft exam.
        final active = exams.firstWhere((e) => e['status'] != 'draft',
            orElse: () => exams.isEmpty ? null : exams.first);
        _examId = active?['id'] as String?;
        _examTitle = active?['title'] as String? ?? '';
      } else {
        final match =
            exams.where((e) => e['id'] == _examId).toList();
        _examTitle =
            match.isEmpty ? '' : match.first['title'] as String? ?? '';
      }
      final subs =
          _examId == null ? <dynamic>[] : await Repo.submissionsForExam(_examId!);
      if (!mounted) return;
      setState(() {
        _subs = subs;
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

  bool _isGraded(Map<String, dynamic> s) =>
      s['status'] == 'graded' || s['status'] == 'auto_graded';

  bool _isPending(Map<String, dynamic> s) =>
      s['status'] == 'submitted' || s['status'] == 'manual_review';

  @override
  Widget build(BuildContext context) {
    final items = _subs.where((raw) {
      final s = raw as Map<String, dynamic>;
      if (_filter == 1 && !_isPending(s)) return false;
      if (_filter == 2 && !_isGraded(s)) return false;
      if (_query.isNotEmpty &&
          !(s['student_name'] as String)
              .toLowerCase()
              .contains(_query.toLowerCase()) &&
          !(s['roll_no'] as String)
              .toLowerCase()
              .contains(_query.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    final submitted = _subs
        .where((s) => (s as Map<String, dynamic>)['submitted_at'] != null)
        .length;
    final graded =
        _subs.where((s) => _isGraded(s as Map<String, dynamic>)).length;
    final scores = [
      for (final s in _subs)
        if ((s as Map<String, dynamic>)['score'] != null)
          (s['score'] as num).toDouble()
    ];
    final avg = scores.isEmpty
        ? '--'
        : (scores.reduce((a, b) => a + b) / scores.length).toStringAsFixed(1);

    return AppShell(
      brand: 'Vidyora',
      currentRoute: '/grading/submissions',
      titleWidget: Row(children: [
        Text('Exams',
            style: AppTheme.mono(12, FontWeight.w500, color: AppColors.muted)),
        const Icon(Icons.chevron_right, size: 16, color: AppColors.muted),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
              _examTitle.isEmpty ? 'Submissions' : 'Submissions: $_examTitle',
              style: Theme.of(context).textTheme.titleLarge,
              overflow: TextOverflow.ellipsis),
        ),
      ]),
      title: 'Submissions',
      actions: [
        TopAction(Icons.refresh, tooltip: 'Refresh', onTap: _load),
        const SizedBox(width: 12),
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error!, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 12),
                  AppButton('Retry', onPressed: _load),
                ]))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          SizedBox(
                            width: 280,
                            child: AppInput(
                                hint: 'Search student name or roll no...',
                                icon: Icons.search,
                                onChanged: (v) => setState(() => _query = v)),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(color: AppColors.outline),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              for (final (i, label) in const [
                                (0, 'All'),
                                (1, 'Pending Grading'),
                                (2, 'Graded')
                              ])
                                InkWell(
                                  onTap: () => setState(() => _filter = i),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _filter == i
                                          ? AppColors.primaryStrong
                                              .withValues(alpha: 0.22)
                                          : null,
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.sm),
                                    ),
                                    child: Text(label,
                                        style: AppTheme.mono(11, FontWeight.w600,
                                            color: _filter == i
                                                ? AppColors.primary
                                                : AppColors.muted)),
                                  ),
                                ),
                            ]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (items.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 30),
                          child: Center(
                              child: Text('No submissions match.',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium)),
                        ),
                      for (final s in items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _SubmissionRow(sub: s as Map<String, dynamic>),
                        ),
                      const SizedBox(height: 16),
                      LayoutBuilder(builder: (context, c) {
                        final wide = c.maxWidth >= 700;
                        return Flex(
                          direction: wide ? Axis.horizontal : Axis.vertical,
                          children: [
                            Expanded(
                                flex: wide ? 1 : 0,
                                child: StatBlock(
                                    label: 'Total Submissions',
                                    value: '$submitted',
                                    delta: '/ ${_subs.length} students',
                                    deltaColor: AppColors.muted)),
                            SizedBox(width: wide ? 16 : 0, height: wide ? 0 : 12),
                            Expanded(
                                flex: wide ? 1 : 0,
                                child: StatBlock(
                                    label: 'Grading Progress',
                                    value: '$graded',
                                    delta: 'completed',
                                    deltaColor: AppColors.success,
                                    valueColor: AppColors.success)),
                            SizedBox(width: wide ? 16 : 0, height: wide ? 0 : 12),
                            Expanded(
                                flex: wide ? 1 : 0,
                                child: StatBlock(
                                    label: 'Average Score',
                                    value: avg,
                                    delta: 'graded so far',
                                    valueColor: AppColors.primary)),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
    );
  }
}

class _SubmissionRow extends StatelessWidget {
  const _SubmissionRow({required this.sub});
  final Map<String, dynamic> sub;

  (String, Color, IconData) get _chip => switch (sub['status'] as String?) {
        'graded' => ('Graded', AppColors.success, Icons.check_circle),
        'auto_graded' => ('Auto-Graded', AppColors.success, Icons.bolt),
        'manual_review' => (
            'Pending Proof Grading',
            AppColors.secondary,
            Icons.pending_outlined
          ),
        'submitted' => ('Submitted', AppColors.primary, Icons.inbox),
        'in_progress' => ('In Progress', AppColors.teal, Icons.timelapse),
        _ => ('Not Started', AppColors.muted, Icons.circle_outlined),
      };

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = _chip;
    final name = sub['student_name'] as String? ?? '';
    final score = sub['score'];
    final max = sub['max_score'];
    final pending = sub['status'] == 'manual_review';
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: () => context.push('/grading/manual/${sub['id']}'),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        borderColor:
            pending ? AppColors.secondary.withValues(alpha: 0.4) : null,
        child: Row(children: [
          InitialsAvatar(name, size: 42),
          const SizedBox(width: 14),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium),
                Text('Roll: ${sub['roll_no']}',
                    style: AppTheme.mono(10, FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('SCORE', style: AppTheme.mono(9, FontWeight.w500)),
            Text(score != null ? '$score/${max ?? '--'}' : '--',
                style: AppTheme.mono(18, FontWeight.w700,
                    color: score != null
                        ? AppColors.onSurface
                        : AppColors.muted)),
          ]),
          const SizedBox(width: 16),
          StatusChip(label, color: color, icon: icon),
          const SizedBox(width: 12),
          const Icon(Icons.chevron_right, color: AppColors.muted),
        ]),
      ),
    );
  }
}
