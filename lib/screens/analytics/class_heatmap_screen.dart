import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/repo.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/common.dart';

class ClassHeatmapScreen extends StatefulWidget {
  const ClassHeatmapScreen({super.key});

  @override
  State<ClassHeatmapScreen> createState() => _ClassHeatmapScreenState();
}

class _ClassHeatmapScreenState extends State<ClassHeatmapScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _data = const {};

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
      final data = await Repo.classAnalytics();
      if (!mounted) return;
      setState(() {
        _data = data;
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

  static Color _heat(int v) {
    if (v >= 80) return AppColors.success;
    if (v >= 55) return AppColors.secondary;
    return AppColors.errorStrong;
  }

  /// Backend sends fractions (0..1); render as whole percentages.
  static int? _pct(dynamic frac) =>
      frac == null ? null : ((frac as num) * 100).round();

  List<Map<String, dynamic>> get _topics =>
      ((_data['topics'] as List<dynamic>?) ?? const [])
          .cast<Map<String, dynamic>>();

  List<Map<String, dynamic>> get _subjects =>
      ((_data['subjects'] as List<dynamic>?) ?? const [])
          .cast<Map<String, dynamic>>();

  String? get _insight {
    if (_topics.length < 2) return null;
    // Topics arrive sorted by overall performance, best first.
    final best = _topics.first['topic'] as String;
    final worst = _topics.last['topic'] as String;
    if (best == worst) return null;
    return 'Academic Insight: Class is performing strongest in $best and '
        'weakest in $worst. Focused problem sets recommended.';
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      brand: 'OlympiadPro',
      currentRoute: '/analytics/class',
      title: 'Class Analytics',
      actions: [
        AppButton('Manage Roster', kind: AppBtnKind.ghost,
            icon: Icons.group_add_outlined,
            onPressed: () => context.push('/roster')),
        const SizedBox(width: 10),
        TopAction(Icons.notifications_outlined,
            onTap: () => context.push('/notifications')),
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
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _kpiRow(),
                        const SizedBox(height: 20),
                        _panels(context),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _kpiRow() {
    final avg = _pct(_data['avg_pct']);
    final students = (_data['students'] as num?)?.toInt() ?? 0;
    final graded = (_data['submissions_graded'] as num?)?.toInt() ?? 0;
    final total = (_data['submissions_total'] as num?)?.toInt() ?? 0;
    return LayoutBuilder(builder: (context, c) {
      final cross = c.maxWidth >= 720 ? 3 : 1;
      return GridView.count(
        crossAxisCount: cross,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: cross == 1 ? 2.8 : 2.6,
        children: [
          StatBlock(label: 'Average Score',
              value: avg == null ? '—' : '$avg%',
              delta: 'all graded exams', deltaColor: AppColors.muted,
              valueColor: AppColors.onSurface),
          StatBlock(label: 'Students', value: '$students',
              delta: 'enrolled', deltaColor: AppColors.muted,
              valueColor: AppColors.primary),
          StatBlock(label: 'Submissions Graded', value: '$graded/$total',
              delta: total == 0
                  ? 'no submissions yet'
                  : '${(graded / total * 100).round()}% complete',
              deltaColor: AppColors.muted, valueColor: AppColors.teal),
        ],
      );
    });
  }

  Widget _panels(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 880;
      return Flex(
        direction: wide ? Axis.horizontal : Axis.vertical,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: wide ? 3 : 0, child: _heatmapCard(context)),
          SizedBox(width: wide ? 16 : 0, height: wide ? 0 : 16),
          Expanded(flex: wide ? 2 : 0, child: _masteryCard(context)),
        ],
      );
    });
  }

  Widget _heatmapCard(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
                child: Text('Topic Performance Heatmap',
                    style: Theme.of(context).textTheme.titleLarge)),
            _legend('Low', AppColors.errorStrong),
            const SizedBox(width: 8),
            _legend('High', AppColors.success),
          ]),
          const SizedBox(height: 18),
          Row(children: const [
            Expanded(flex: 3, child: _HCell('Topic Name')),
            Expanded(flex: 2, child: _HCell('Top 20%')),
            Expanded(flex: 2, child: _HCell('Mid 60%')),
            Expanded(flex: 2, child: _HCell('Bottom 20%')),
            Expanded(flex: 2, child: _HCell('Overall')),
          ]),
          const SizedBox(height: 8),
          if (_topics.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(
                  child: Text('No graded submissions yet.',
                      style: Theme.of(context).textTheme.bodyMedium)),
            ),
          for (final t in _topics)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(children: [
                Expanded(flex: 3,
                    child: Text(t['topic'] as String? ?? '',
                        style: Theme.of(context).textTheme.bodyLarge
                            ?.copyWith(fontSize: 14))),
                for (final band in const ['top20', 'mid60', 'bottom20'])
                  Expanded(flex: 2, child: _bandCell(_pct(t[band]))),
                Expanded(flex: 2,
                    child: Text(
                        _pct(t['overall']) == null
                            ? '—'
                            : '${_pct(t['overall'])}%',
                        textAlign: TextAlign.center,
                        style: AppTheme.mono(13, FontWeight.w700,
                            color: AppColors.onSurface))),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _bandCell(int? v) =>
      v == null ? const _EmptyCell() : _HeatCell(v, _heat(v));

  Widget _masteryCard(BuildContext context) {
    const colors = [AppColors.primary, AppColors.teal, AppColors.success];
    final insight = _insight;
    return AppCard(
      color: AppColors.surfaceContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Subject Mastery',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 18),
          if (_subjects.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text('No graded submissions yet.',
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
          for (final (i, s) in _subjects.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(s['subject'] as String? ?? '',
                        style: Theme.of(context).textTheme.bodyLarge
                            ?.copyWith(fontSize: 14))),
                    Text('${_pct(s['pct']) ?? 0}%',
                        style: AppTheme.mono(13, FontWeight.w700,
                            color: colors[i % colors.length])),
                  ]),
                  const SizedBox(height: 8),
                  ProgressLine(((s['pct'] as num?) ?? 0).toDouble(),
                      color: colors[i % colors.length], height: 8),
                ],
              ),
            ),
          if (insight != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(insight,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(fontStyle: FontStyle.italic)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _legend(String label, Color color) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 10, height: 10,
            decoration: BoxDecoration(color: color,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: AppTheme.mono(10, FontWeight.w500)),
      ]);
}

class _HCell extends StatelessWidget {
  const _HCell(this.text);
  final String text;
  @override
  Widget build(BuildContext context) =>
      Text(text, textAlign: text == 'Topic Name' ? TextAlign.left : TextAlign.center,
          style: AppTheme.mono(9.5, FontWeight.w600, ls: 0.5));
}

class _HeatCell extends StatelessWidget {
  const _HeatCell(this.value, this.color);
  final int value;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        height: 34,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Text('$value',
            style: AppTheme.mono(13, FontWeight.w700, color: Colors.black87, ls: 0)),
      );
}

/// Band has no students (e.g. small classes leave some quintiles empty).
class _EmptyCell extends StatelessWidget {
  const _EmptyCell();
  @override
  Widget build(BuildContext context) => Container(
        height: 34,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Text('—', style: AppTheme.mono(13, FontWeight.w600)),
      );
}
