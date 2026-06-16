import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../data/repo.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';

/// Exam analytics, driven entirely by the backend
/// (`GET /v1/analytics/exam/:id`): KPIs, subject-wise performance, the
/// submission breakdown, and the hardest questions. The teacher picks which
/// exam to analyse from the dropdown.
class ExamAnalyticsScreen extends StatefulWidget {
  const ExamAnalyticsScreen({super.key});
  @override
  State<ExamAnalyticsScreen> createState() => _ExamAnalyticsScreenState();
}

class _ExamAnalyticsScreenState extends State<ExamAnalyticsScreen> {
  List<dynamic> _exams = [];
  String? _examId;
  Map<String, dynamic>? _report;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final exams = await Repo.exams();
      if (!mounted) return;
      _exams = exams;
      if (exams.isEmpty) {
        setState(() => _loading = false);
        return;
      }
      _examId = exams.first['id'] as String;
      await _loadReport();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadReport() async {
    if (_examId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await Repo.examAnalytics(_examId!);
      if (!mounted) return;
      setState(() {
        _report = r;
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

  @override
  Widget build(BuildContext context) {
    return AppShell(
      brand: 'OlympiadPro',
      currentRoute: '/analytics/exam',
      title: 'Exam Analytics',
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_error!, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          AppButton('Retry', onPressed: _loadExams),
        ]),
      );
    }
    if (_exams.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.bar_chart, color: AppColors.muted, size: 40),
          const SizedBox(height: 10),
          Text('No exams yet — publish an exam to see its analytics.',
              style: Theme.of(context).textTheme.bodyMedium),
        ]),
      );
    }

    final r = _report ?? {};
    final avg = r['avg_pct'];
    final top = r['top_pct'];
    final completion = r['completion_pct'];
    final submitted = (r['submitted'] as num?)?.toInt() ?? 0;
    final graded = (r['graded'] as num?)?.toInt() ?? 0;
    final pending = (r['pending'] as num?)?.toInt() ?? 0;
    final totalStudents = (r['total_students'] as num?)?.toInt() ?? 0;
    final topics = (r['topics'] as List?) ?? [];
    final gaps = (r['gaps'] as List?) ?? [];

    String pctStr(dynamic v) => v == null ? '—' : '${(v as num).round()}%';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exam selector + meta
          _examSelector(context),
          const SizedBox(height: 4),
          Text(
              '${r['title'] ?? ''}${r['board'] != null ? ' · ${r['board']}' : ''}'
              '  ·  $totalStudents student${totalStudents == 1 ? '' : 's'} assigned',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 20),

          // KPI row
          LayoutBuilder(builder: (context, c) {
            final cross = c.maxWidth >= 720 ? 3 : 1;
            return GridView.count(
              crossAxisCount: cross,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              // Single-column phone cards need more height: the sub-line on
              // Top Score / Completion overflowed at 2.8.
              childAspectRatio: cross == 1 ? 2.3 : 2.6,
              children: [
                _KpiCard(label: 'Avg Score', value: pctStr(avg),
                    icon: Icons.bar_chart, color: AppColors.primary),
                _KpiCard(label: 'Top Score', value: pctStr(top),
                    sub: 'Highest in cohort',
                    icon: Icons.emoji_events_outlined, color: AppColors.secondary),
                _KpiCard(label: 'Completion', value: pctStr(completion),
                    sub: '$submitted/$totalStudents submitted',
                    icon: Icons.check_circle_outline, color: AppColors.success),
              ],
            );
          }),
          const SizedBox(height: 20),

          // Topic performance + submission breakdown
          LayoutBuilder(builder: (context, c) {
            final wide = c.maxWidth >= 820;
            return Flex(
              direction: wide ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: wide ? 3 : 0,
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                              child: Text('Subject-wise Performance',
                                  style: Theme.of(context).textTheme.titleLarge)),
                          _legend('Avg Score', AppColors.primary),
                        ]),
                        const SizedBox(height: 20),
                        if (topics.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text('No graded answers yet for this exam.',
                                style: Theme.of(context).textTheme.bodyMedium),
                          )
                        else
                          for (final t in topics)
                            _TopicBar(
                                name: t['name'] as String? ?? '—',
                                score: ((t['score'] as num?) ?? 0).toDouble(),
                                count: (t['count'] as num?)?.toInt() ?? 0),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: wide ? 16 : 0, height: wide ? 0 : 16),
                Expanded(
                  flex: wide ? 2 : 0,
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Submission Status',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 16),
                        Center(
                          child: _submissionDonut(
                              graded, submitted, pending, totalStudents),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _legendStat('$graded', 'GRADED', AppColors.success),
                            _legendStat('${(submitted - graded).clamp(0, submitted)}',
                                'TO GRADE', AppColors.primary),
                            _legendStat('$pending', 'PENDING', AppColors.muted),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 24),

          // Critical gaps
          Row(children: [
            const Icon(Icons.warning_amber, color: AppColors.secondary, size: 18),
            const SizedBox(width: 8),
            Text('Critical Gaps — Hardest Questions',
                style: Theme.of(context).textTheme.titleLarge),
          ]),
          const SizedBox(height: 12),
          if (gaps.isEmpty)
            AppCard(
              child: Text('No answered questions to analyse yet.',
                  style: Theme.of(context).textTheme.bodyMedium),
            )
          else
            LayoutBuilder(builder: (context, c) {
              final cross = c.maxWidth >= 720 ? 2 : 1;
              return GridView.count(
                crossAxisCount: cross,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: cross == 1 ? 3.2 : 3.4,
                children: [
                  for (final g in gaps)
                    _GapCard(
                      title: g['title'] as String? ?? '—',
                      subject: g['subject'] as String? ?? '—',
                      rate: ((g['success_rate'] as num?) ?? 0).toDouble(),
                      attempts: (g['attempts'] as num?)?.toInt() ?? 0,
                    ),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _examSelector(BuildContext context) {
    return Row(children: [
      Text('Exam:', style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(width: 10),
      Flexible(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.outline),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _examId,
              isExpanded: true,
              dropdownColor: AppColors.surfaceHigh,
              style: Theme.of(context).textTheme.bodyMedium,
              items: [
                for (final e in _exams)
                  DropdownMenuItem(
                    value: e['id'] as String,
                    child: Text(e['title'] as String? ?? 'Untitled',
                        overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) {
                if (v == null || v == _examId) return;
                setState(() => _examId = v);
                _loadReport();
              },
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _submissionDonut(int graded, int submitted, int pending, int total) {
    if (total <= 0) {
      return SizedBox(
        height: 160,
        child: Center(
            child: Text('No students assigned',
                style: AppTheme.mono(10, FontWeight.w500))),
      );
    }
    final toGrade = (submitted - graded).clamp(0, submitted);
    final segments = <(double, Color)>[
      (graded / total, AppColors.success),
      (toGrade / total, AppColors.primary),
      (pending / total, AppColors.surfaceHighest),
    ];
    return DonutChart(
      segments,
      size: 160,
      center: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$submitted/$total',
              style: AppTheme.mono(18, FontWeight.w700, color: AppColors.onSurface)),
          Text('SUBMITTED', style: AppTheme.mono(8, FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _legend(String label, Color color) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 10, height: 10,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: AppTheme.mono(10, FontWeight.w500)),
      ]);

  Widget _legendStat(String value, String label, Color color) => Column(children: [
        Text(value, style: AppTheme.mono(16, FontWeight.w700, color: color)),
        Text(label, style: AppTheme.mono(8, FontWeight.w500)),
      ]);
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label, required this.value, required this.icon, required this.color,
    this.sub,
  });
  final String label, value;
  final IconData icon;
  final Color color;
  final String? sub;
  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.surfaceContainer,
      accentTop: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: FieldLabel(label)),
            Icon(icon, size: 16, color: color),
          ]),
          const SizedBox(height: 6),
          Text(value, style: AppTheme.mono(30, FontWeight.w700,
              color: AppColors.onSurface, ls: -1)),
          if (sub != null)
            Text(sub!, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _TopicBar extends StatelessWidget {
  const _TopicBar({required this.name, required this.score, required this.count});
  final String name;
  final double score; // 0..1
  final int count;
  @override
  Widget build(BuildContext context) {
    final color = score >= 0.75
        ? AppColors.success
        : score >= 0.5
            ? AppColors.secondary
            : AppColors.error;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text('$name  ($count Q)',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 14))),
            Text('${(score * 100).round()}%',
                style: AppTheme.mono(12, FontWeight.w600, color: AppColors.onSurfaceVariant)),
          ]),
          const SizedBox(height: 8),
          ProgressLine(score, color: color, height: 8),
        ],
      ),
    );
  }
}

class _GapCard extends StatelessWidget {
  const _GapCard({required this.title, required this.subject, required this.rate, required this.attempts});
  final String title, subject;
  final double rate; // 0..1 success rate
  final int attempts;
  @override
  Widget build(BuildContext context) {
    final color = rate < 0.5
        ? AppColors.error
        : rate < 0.75
            ? AppColors.secondary
            : AppColors.success;
    return AppCard(
      padding: const EdgeInsets.all(14),
      borderColor: color.withValues(alpha: 0.4),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm)),
          child: Icon(Icons.help_outline, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              Text('$subject · $attempts attempt${attempts == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${(rate * 100).round()}%',
              style: AppTheme.mono(16, FontWeight.w700, color: color)),
          Text('SUCCESS', style: AppTheme.mono(8, FontWeight.w500)),
        ]),
      ]),
    );
  }
}
