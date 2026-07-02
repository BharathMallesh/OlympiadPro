import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/exam_scope.dart';
import '../../data/repo.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/common.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _me;
  Map<String, dynamic>? _stats;
  List<dynamic> _exams = [];
  List<dynamic> _students = [];
  String? _error;
  bool _loading = true;

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
      final results = await Future.wait([
        Repo.me(),
        Repo.dashboard(),
        Repo.exams(),
        Repo.students(),
      ]);
      if (!mounted) return;
      setState(() {
        _me = results[0] as Map<String, dynamic>;
        _stats = results[1] as Map<String, dynamic>;
        _exams = results[2] as List<dynamic>;
        _students = results[3] as List<dynamic>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
      if (e.toString() == 'unauthorized' && mounted) context.go('/login');
    }
  }

  /// One-tap exam paper from a stored format blueprint (JEE/NEET/CET/PUC).
  Future<void> _fromFormatDialog() async {
    List<dynamic> classes = const [];
    try {
      classes = await Repo.classes();
    } catch (_) {/* optional targeting */}
    if (!mounted) return;
    String exam = ExamScope.exams.first;
    final titleCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();
    final selClasses = <String>{};
    bool busy = false;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Generate paper from format'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Exam'),
                DropdownButton<String>(
                  value: exam,
                  isExpanded: true,
                  items: ExamScope.exams
                      .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text('$e · ${ExamScope.curriculumFor(e)}')))
                      .toList(),
                  onChanged: (v) => setLocal(() => exam = v ?? exam),
                ),
                const SizedBox(height: 8),
                TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Title', hintText: 'e.g. JEE Mock 1', isDense: true)),
                const SizedBox(height: 8),
                TextField(
                    controller: subjectCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Subject (PUC only, optional)', isDense: true)),
                if (classes.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text('Assign to classes (optional)'),
                  for (final c in classes)
                    Row(children: [
                      Expanded(child: Text(c['name']?.toString() ?? 'Class')),
                      Checkbox(
                        value: selClasses.contains((c as Map)['id']),
                        onChanged: (v) => setLocal(() => v == true
                            ? selClasses.add(c['id'] as String)
                            : selClasses.remove(c['id'])),
                      ),
                    ]),
                ],
                const SizedBox(height: 8),
                Text(
                    "You'll preview the questions with the answer key before "
                    'publishing.',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: busy ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            TextButton(
              onPressed: busy
                  ? null
                  : () async {
                      setLocal(() => busy = true);
                      try {
                        final r = await Repo.examFromFormat(
                          exam: exam,
                          title: titleCtrl.text.trim().isEmpty
                              ? '$exam Paper'
                              : titleCtrl.text.trim(),
                          subject: subjectCtrl.text,
                          classIds: selClasses.toList(),
                          publish: false, // draft → preview → publish
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          context.push('/exam-preview/${r['exam_id']}');
                        }
                      } catch (e) {
                        setLocal(() => busy = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                              content: Text(e.toString()),
                              backgroundColor: AppColors.error));
                        }
                      }
                    },
              child: Text(busy ? 'Generating…' : 'Generate'),
            ),
          ],
        ),
      ),
    );
    titleCtrl.dispose();
    subjectCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teacherName = _me?['full_name'] as String? ?? '·';
    return AppShell(
      brand: 'Vidyora',
      currentRoute: '/dashboard',
      title: 'Dashboard',
      actions: [
        TopAction(Icons.refresh, tooltip: 'Refresh', onTap: _load),
        TopAction(Icons.notifications_outlined,
            tooltip: 'Alerts',
            onTap: () => context.push('/notifications')),
        const SizedBox(width: 8),
        InitialsAvatar(teacherName, size: 34),
        const SizedBox(width: 8),
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: LayoutBuilder(builder: (context, c) {
                    final wide = c.maxWidth >= 760;
                    // Cap content on large monitors so the dashboard stays
                    // centred and aligned instead of stretching edge-to-edge.
                    final contentWidth =
                        c.maxWidth > 1100 ? 1100.0 : c.maxWidth;
                    final stats = _stats ?? {};
                    final studentCount = (stats['students'] as num?)?.toInt() ?? 0;
                    final pendingGrading =
                        (stats['pending_grading'] as num?)?.toInt() ?? 0;
                    final activeExams =
                        (stats['exams_active'] as num?)?.toInt() ?? 0;
                    final totalExams =
                        (stats['exams_total'] as num?)?.toInt() ?? 0;
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1100),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flex(
                            direction: wide ? Axis.horizontal : Axis.vertical,
                            children: [
                              Expanded(
                                flex: wide ? 1 : 0,
                                child: _MetricCard(
                                  label: 'Students Enrolled',
                                  value: '$studentCount',
                                  delta:
                                      '${(stats['classes'] as num?)?.toInt() ?? 0} classes',
                                  progress:
                                      (studentCount / 100).clamp(0.05, 1.0),
                                  progressColor: AppColors.primary,
                                ),
                              ),
                              SizedBox(width: wide ? 16 : 0, height: wide ? 0 : 16),
                              Expanded(
                                flex: wide ? 1 : 0,
                                child: _MetricCard(
                                  label: 'Active Exams',
                                  value: '$activeExams/$totalExams',
                                  delta: pendingGrading > 0
                                      ? '$pendingGrading to grade'
                                      : 'all graded',
                                  progress: totalExams == 0
                                      ? 0.05
                                      : (activeExams / totalExams)
                                          .clamp(0.05, 1.0),
                                  progressColor: pendingGrading > 0
                                      ? AppColors.secondary
                                      : AppColors.success,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          Row(children: [
                            Text('Exams',
                                style:
                                    Theme.of(context).textTheme.headlineSmall),
                            const Spacer(),
                            Flexible(
                              child: Wrap(
                                alignment: WrapAlignment.end,
                                children: [
                                  TextButton(
                                      onPressed: _fromFormatDialog,
                                      child: const Text('+ Format')),
                                  TextButton(
                                      onPressed: () =>
                                          context.push('/wizard/topic-exam'),
                                      child: const Text('+ Topic Exam')),
                                  TextButton(
                                      onPressed: () =>
                                          context.go('/wizard/details'),
                                      child: const Text('+ New Exam')),
                                ],
                              ),
                            ),
                          ]),
                          const SizedBox(height: 12),
                          if (_exams.isEmpty)
                            Text(
                                'No exams yet. Create one to publish to your classes.',
                                style: Theme.of(context).textTheme.bodyMedium),
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              for (final exam in _exams)
                                SizedBox(
                                  width: wide
                                      ? (contentWidth - 48 - 32) / 3
                                      : contentWidth - 48,
                                  child: _ExamCard(
                                      exam: exam as Map<String, dynamic>),
                                ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          Row(children: [
                            Text('Students',
                                style:
                                    Theme.of(context).textTheme.headlineSmall),
                            const Spacer(),
                            TextButton(
                                onPressed: () => context.push('/roster'),
                                child: const Text('Full Roster')),
                          ]),
                          const SizedBox(height: 12),
                          if (_students.isEmpty)
                            Text(
                                'No students yet. Add them from the roster screen.',
                                style: Theme.of(context).textTheme.bodyMedium),
                          for (final s in _students.take(8))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child:
                                  _StudentRow(student: s as Map<String, dynamic>),
                            ),
                        ],
                      ),
                      ),
                      ),
                      ),
                    );
                  }),
                ),
      bottomBar: null,
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off, color: AppColors.muted, size: 40),
          const SizedBox(height: 12),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          AppButton('Retry', onPressed: onRetry),
        ]),
      );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.delta,
    required this.progress,
    required this.progressColor,
  });
  final String label, value, delta;
  final double progress;
  final Color progressColor;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.surfaceContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FieldLabel(label),
          Row(crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic, children: [
            Text(value, style: AppTheme.mono(34, FontWeight.w700,
                color: AppColors.onSurface, ls: -1)),
            const SizedBox(width: 10),
            Text(delta, style: AppTheme.mono(12, FontWeight.w600,
                color: AppColors.success)),
          ]),
          const SizedBox(height: 14),
          ProgressLine(progress, color: progressColor, height: 6),
        ],
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  const _ExamCard({required this.exam});
  final Map<String, dynamic> exam;

  (String, Color) get _status => switch (exam['status'] as String?) {
        'published' => ('Published', AppColors.success),
        'grading_needed' => ('Grading Needed', AppColors.secondary),
        'completed' => ('Completed', AppColors.teal),
        _ => ('Draft', AppColors.muted),
      };

  @override
  Widget build(BuildContext context) {
    final (label, color) = _status;
    final id = exam['id'] as String;
    final status = exam['status'] as String?;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            StatusChip(label, color: color),
            const Spacer(),
            Text(exam['board'] as String? ?? '',
                style: AppTheme.mono(10, FontWeight.w500)),
          ]),
          const SizedBox(height: 14),
          Text(exam['title'] as String? ?? '',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Row(children: [
            Icon(Icons.schedule, size: 14, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${exam['duration_min']} min · ${exam['total_marks']} marks',
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),
          const SizedBox(height: 18),
          if (status == 'published')
            AppButton('Monitor',
                kind: AppBtnKind.ghost,
                expand: true,
                onPressed: () =>
                    context.push('/grading/submissions?exam=$id'))
          else
            AppButton(status == 'grading_needed' ? 'Grade Now' : 'Open',
                kind: status == 'grading_needed'
                    ? AppBtnKind.secondary
                    : AppBtnKind.ghost,
                expand: true,
                onPressed: () =>
                    context.push('/grading/submissions?exam=$id')),
        ],
      ),
    );
  }
}

class _StudentRow extends StatelessWidget {
  const _StudentRow({required this.student});
  final Map<String, dynamic> student;

  @override
  Widget build(BuildContext context) {
    final name = student['full_name'] as String? ?? '';
    final rollNo = student['roll_no'] as String? ?? '';
    final tag = student['tag'] as String?;
    final accessCode = student['access_code'] as String? ?? '';
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        InitialsAvatar(name, size: 42),
        const SizedBox(width: 14),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: Theme.of(context).textTheme.titleMedium),
              Text(tag == null || tag.isEmpty ? rollNo : '$rollNo · $tag',
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(accessCode,
              style: AppTheme.mono(13, FontWeight.w700,
                  color: AppColors.teal)),
          Text('ACCESS CODE', style: AppTheme.mono(8, FontWeight.w500)),
        ]),
      ]),
    );
  }
}
