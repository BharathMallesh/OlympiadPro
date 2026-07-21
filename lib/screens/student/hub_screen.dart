import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/api.dart';
import '../../data/exam_scope.dart';
import '../../data/repo.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';
import 'student_shell.dart';

class StudentHubScreen extends StatefulWidget {
  const StudentHubScreen({super.key});
  @override
  State<StudentHubScreen> createState() => _StudentHubScreenState();
}

class _StudentHubScreenState extends State<StudentHubScreen> {
  // Exam focus for AI practice: the student's profile exam (→ syllabus) is shown
  // here; they choose subjects/chapters/topics on the next screen.
  List<String> _boards = const [];
  Map<String, dynamic>? _nextExam;
  bool _loadingExam = true;
  List<dynamic> _activity = [];
  bool _loadingActivity = true;
  int _unread = 0;
  List<dynamic> _notifs = const [];

  @override
  void initState() {
    super.initState();
    _loadNext();
    _loadActivity();
    _loadFocus();
    _loadNotifs();
  }

  bool _smartBusy = false;

  Future<void> _loadNotifs() async {
    try {
      final res = await Repo.notifications();
      if (!mounted) return;
      setState(() {
        _unread = (res['unread'] as num?)?.toInt() ?? 0;
        _notifs = (res['items'] as List<dynamic>?) ?? const [];
      });
    } catch (_) {/* bell just stays empty */}
  }

  Future<void> _openNotifications() async {
    // Show what we have, then clear the unread badge.
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: _notifs.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(28),
                child: Center(child: Text('No notifications yet')))
            : ListView(
                shrinkWrap: true,
                children: [
                  for (final n in _notifs)
                    ListTile(
                      leading: Icon(
                          (n['read'] == true)
                              ? Icons.notifications_none
                              : Icons.notifications_active,
                          color: (n['read'] == true)
                              ? AppColors.muted
                              : AppColors.primary),
                      title: Text('${n['title'] ?? ''}'),
                      subtitle: Text('${n['body'] ?? ''}'),
                    ),
                ],
              ),
      ),
    );
    try {
      await Repo.markNotificationsRead();
    } catch (_) {}
    if (mounted) setState(() => _unread = 0);
  }

  Future<void> _loadFocus() async {
    try {
      final boards = await Repo.studentBoards();
      if (!mounted) return;
      setState(() => _boards = boards);
    } catch (_) {/* leave empty; practice falls back to everything */}
  }

  /// Adaptive revision: pulls a set weighted to the student's weak topics and
  /// drops them straight into a practice session.
  Future<void> _smartRevision() async {
    setState(() => _smartBusy = true);
    try {
      final exam = ExamScope.examOf(_boards);
      final res = await Repo.smartRevision(
        boards: exam != null ? [exam] : const [],
        curricula: exam != null ? [ExamScope.curriculumFor(exam)] : const [],
      );
      final qs = (res['questions'] as List<dynamic>?) ?? const [];
      if (!mounted) return;
      setState(() => _smartBusy = false);
      if (qs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Not enough questions yet — try Generate Practice Set.'),
            backgroundColor: AppColors.error));
        return;
      }
      await context.push('/student/practice-session', extra: qs);
      _loadActivity();
    } catch (e) {
      if (mounted) {
        setState(() => _smartBusy = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()), backgroundColor: AppColors.error));
      }
    }
  }


  Future<void> _loadNext() async {
    try {
      final exams = await Repo.studentExams();
      final pending = exams.cast<Map<String, dynamic>>().where((e) =>
          e['status'] == 'not_started' || e['status'] == 'in_progress');
      if (!mounted) return;
      setState(() {
        _nextExam = pending.isEmpty ? null : pending.first;
        _loadingExam = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingExam = false);
    }
  }

  Future<void> _loadActivity() async {
    try {
      final hist = await Repo.practiceHistory();
      if (!mounted) return;
      setState(() {
        _activity = hist;
        _loadingActivity = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingActivity = false);
    }
  }

  String _ago(String? iso) {
    if (iso == null) return '';
    final t = DateTime.tryParse(iso)?.toLocal();
    if (t == null) return '';
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    if (d.inDays < 7) return '${d.inDays}d ago';
    return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return StudentShell(
      title: 'Vidyora',
      currentTab: 0,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text('Hi, ${api.displayName ?? 'Student'}',
                    style: Theme.of(context).textTheme.headlineSmall),
              ),
              // Notifications bell with an unread badge.
              Stack(clipBehavior: Clip.none, children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  tooltip: 'Notifications',
                  onPressed: _openNotifications,
                ),
                if (_unread > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                          color: AppColors.error, shape: BoxShape.circle),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text('$_unread',
                          textAlign: TextAlign.center,
                          style: AppTheme.mono(9, FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ),
              ]),
              if ((api.displaySubtitle ?? '').isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.school,
                        size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(api.displaySubtitle!,
                        style: AppTheme.mono(12, FontWeight.w700,
                            color: AppColors.primary)),
                  ]),
                ),
            ]),
            const SizedBox(height: 16),
            const StudentSection('My Classroom', icon: Icons.school_outlined),
            // Next assigned exam (live from the backend)
            AppCard(
              accentTop: AppColors.teal,
              child: _loadingExam
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                          child: SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))),
                    )
                  : _nextExam == null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              StatusChip('All caught up',
                                  color: AppColors.success,
                                  icon: Icons.check_circle),
                            ]),
                            const SizedBox(height: 12),
                            Text('No pending exams',
                                style:
                                    Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 4),
                            Text(
                                'New exams from your teacher will appear here.',
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              StatusChip(
                                  _nextExam!['board'] as String? ?? 'Exam',
                                  color: AppColors.teal),
                              const Spacer(),
                              const Icon(Icons.timer_outlined,
                                  size: 16, color: AppColors.teal),
                            ]),
                            const SizedBox(height: 12),
                            Text(_nextExam!['title'] as String? ?? '',
                                style:
                                    Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 4),
                            Text(
                                '${_nextExam!['duration_min']} min · '
                                '${_nextExam!['total_marks']} marks',
                                style: Theme.of(context).textTheme.bodySmall),
                            const SizedBox(height: 16),
                            Row(children: [
                              Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text('STATUS',
                                        style: AppTheme.mono(
                                            9, FontWeight.w500)),
                                    Text(
                                        _nextExam!['status'] == 'in_progress'
                                            ? 'In progress'
                                            : 'Ready',
                                        style: AppTheme.mono(
                                            14, FontWeight.w700,
                                            color: AppColors.teal)),
                                  ]),
                              const Spacer(),
                              AppButton(
                                  _nextExam!['status'] == 'in_progress'
                                      ? 'Resume'
                                      : 'Take Now',
                                  kind: AppBtnKind.secondary,
                                  onPressed: () => context.push(
                                      '/student/exam?exam=${_nextExam!['exam_id']}')),
                            ]),
                          ],
                        ),
            ),
            const SizedBox(height: 24),

            const StudentSection('Smart Practice', icon: Icons.auto_awesome),
            AppCard(
              color: AppColors.surfaceContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Practice Generator',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                      'Our engine selects optimized question sets from our elite '
                      'question bank based on your focus areas and performance '
                      'history.',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 18),
                  if (ExamScope.examOf(_boards) == null)
                    Text(
                        'Set your target exam in Profile to focus your practice — '
                        'for now it draws from everything.',
                        style: AppTheme.mono(10.5, FontWeight.w500,
                            color: AppColors.muted))
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.outline),
                      ),
                      child: Row(children: [
                        const Icon(Icons.menu_book_outlined,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                              'Preparing for ${ExamScope.examOf(_boards)}  ·  '
                              '${ExamScope.curriculumFor(ExamScope.examOf(_boards)!)} syllabus',
                              style: AppTheme.mono(12, FontWeight.w700,
                                  color: AppColors.onSurface)),
                        ),
                      ]),
                    ),
                  const SizedBox(height: 18),
                  AppButton('Generate Practice Set',
                      expand: true,
                      onPressed: () async {
                        // Carry the profile's exam to the next screen, which
                        // scopes subjects/chapters/topics to its syllabus.
                        final exam = ExamScope.examOf(_boards);
                        final qp = <String>[
                          if (exam != null) 'boards=$exam',
                          if (exam != null)
                            'curricula=${Uri.encodeComponent(ExamScope.curriculumFor(exam))}',
                        ];
                        final q = qp.isEmpty ? '' : '?${qp.join("&")}';
                        await context.push('/student/practice-generator$q');
                        // Refresh recent activity when returning from a session.
                        _loadActivity();
                      }),
                  const SizedBox(height: 10),
                  AppButton(
                      _smartBusy ? 'Preparing…' : 'Smart Revision (weak topics)',
                      expand: true,
                      kind: AppBtnKind.ghost,
                      trailingIcon: Icons.auto_awesome,
                      onPressed: _smartBusy ? null : _smartRevision),
                  const SizedBox(height: 10),
                  AppButton('Previous Years (last 5)',
                      expand: true,
                      kind: AppBtnKind.ghost,
                      trailingIcon: Icons.history_edu_outlined,
                      onPressed: () =>
                          context.push('/student/previous-years')),
                  const SizedBox(height: 10),
                  AppButton('Previous Years Test (graded)',
                      expand: true,
                      kind: AppBtnKind.ghost,
                      trailingIcon: Icons.fact_check_outlined,
                      onPressed: () {
                        final exam = ExamScope.examOf(_boards);
                        context.push('/student/practice-generator?pyq=1'
                            '${exam != null ? '&boards=$exam' : ''}');
                      }),
                  const SizedBox(height: 10),
                  AppButton('My Progress Report',
                      expand: true,
                      kind: AppBtnKind.ghost,
                      trailingIcon: Icons.insights_outlined,
                      onPressed: () => context.push('/student/progress')),

                  // ── Board Exam preparation ──────────────────────────────
                  // A separate track from the entrance-exam prep above: a
                  // student's Class-12 board (2nd PUC / Plus Two / HSC / CBSE),
                  // derived from the state their exam belongs to.
                  const SizedBox(height: 26),
                  Row(children: [
                    Container(
                        width: 3,
                        height: 15,
                        decoration: BoxDecoration(
                            color: AppColors.gold,
                            borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 8),
                    Text('BOARD EXAM',
                        style: AppTheme.mono(11, FontWeight.w700, ls: 1.2)),
                  ]),
                  Builder(builder: (_) {
                    final ex = ExamScope.examOf(_boards);
                    final boardExam = ExamScope.boardExamFor(
                        ex != null ? ExamScope.stateFor(ex) : null);
                    final label = ExamScope.label(boardExam);
                    return Column(children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 6, bottom: 12),
                        child: Text(
                            'Practise for your $label board exam — from the board '
                            'textbooks, separate from the entrance-exam prep above.',
                            style: Theme.of(context).textTheme.bodySmall),
                      ),
                      AppButton('Board Practice · $label',
                          expand: true,
                          trailingIcon: Icons.menu_book_outlined,
                          onPressed: () async {
                            await context.push('/student/practice-generator'
                                '?boards=$boardExam'
                                '&curricula=${Uri.encodeComponent(ExamScope.curriculumFor(boardExam))}');
                            _loadActivity();
                          }),
                    ]);
                  }),
                  const SizedBox(height: 24),
                  if (!_loadingActivity && _activity.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Builder(builder: (ctx) {
                      final items = _activity.cast<Map<String, dynamic>>();
                      final avg = items
                              .map((a) => (a['score_pct'] as num?) ?? 0)
                              .fold<num>(0, (s, v) => s + v) /
                          items.length;
                      final pct = avg.round();
                      final fill = (pct / 100.0).clamp(0.0, 1.0);
                      return Column(children: [
                        Center(
                          child: DonutChart(
                            [
                              (fill, AppColors.teal),
                              (1.0 - fill, AppColors.surfaceHigh),
                            ],
                            size: 120,
                            center: Column(mainAxisSize: MainAxisSize.min, children: [
                              Text('$pct%',
                                  style: AppTheme.mono(20, FontWeight.w700,
                                      color: AppColors.onSurface)),
                              Text('ACCURACY',
                                  style: AppTheme.mono(8, FontWeight.w500)),
                            ]),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Text('RECENT PRACTICE ACCURACY',
                              style: AppTheme.mono(10, FontWeight.w600,
                                  color: AppColors.teal, ls: 1)),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                              'Based on your last ${items.length} practice '
                              '${items.length == 1 ? 'session' : 'sessions'}.',
                              textAlign: TextAlign.center,
                              style: Theme.of(ctx).textTheme.bodySmall),
                        ),
                      ]);
                    }),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            StudentSection('Recent Activity',
                icon: Icons.history,
                trailing: TextButton(
                    onPressed: () => context.go('/student/exams'),
                    child: const Text('VIEW ALL'))),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.outline)),
                  ),
                  child: Row(children: [
                    Expanded(
                        child: Text('PRACTICE SESSION',
                            style: AppTheme.mono(9, FontWeight.w600, ls: 0.8))),
                    Text('SCORE', style: AppTheme.mono(9, FontWeight.w600, ls: 0.8)),
                  ]),
                ),
                if (_loadingActivity)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                        child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))),
                  )
                else if (_activity.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                          'No practice yet — generate a set to get started.',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  )
                else
                  for (final a in _activity.cast<Map<String, dynamic>>())
                    InkWell(
                      onTap: () async {
                        await context.push(
                            '/student/practice-review?session=${a['id']}');
                        _loadActivity();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 13),
                        decoration: const BoxDecoration(
                          border: Border(
                              bottom: BorderSide(color: AppColors.outline)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.auto_awesome,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${a['subjects'] ?? 'Practice'} practice',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(fontSize: 14)),
                                Text(
                                    '${a['correct']}/${a['total']} correct · ${_ago(a['created_at'] as String?)}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusChip(
                              '${(a['score_pct'] as num?)?.round() ?? 0}%',
                              color: ((a['score_pct'] as num?) ?? 0) >= 50
                                  ? AppColors.success
                                  : AppColors.secondary),
                          const SizedBox(width: 6),
                          const Icon(Icons.chevron_right,
                              size: 18, color: AppColors.muted),
                        ]),
                      ),
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
