import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../data/repo.dart';
import '../../widgets/common.dart';
import 'student_shell.dart';

/// Student "Insights" (#4/#9/#10): board-bank sizes, progress + class rank, and
/// strength/weakness by chapter — all from the live analytics endpoints.
class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _boards = const [];
  Map<String, dynamic> _strengths = const {};
  Map<String, dynamic> _progress = const {};

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
      final board = await Repo.boardBank();
      final str = await Repo.practiceStrengths();
      final prog = await Repo.practiceProgress();
      if (!mounted) return;
      setState(() {
        _boards = board.cast<Map<String, dynamic>>();
        _strengths = str;
        _progress = prog;
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
    return StudentShell(
      title: 'Vidyora',
      currentTab: 4,
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
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      Text('Student Hub  /  Insights',
                          style: AppTheme.mono(10, FontWeight.w500, ls: 0.5)),
                      const SizedBox(height: 8),
                      Text('Your Progress',
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 16),
                      _progressCard(context),
                      const SizedBox(height: 16),
                      _boardCard(context),
                      const SizedBox(height: 16),
                      _chaptersCard(context, 'Focus areas (weakest)',
                          _list(_strengths['weakest']), AppColors.error),
                      const SizedBox(height: 16),
                      _chaptersCard(context, 'Strengths', _list(_strengths['strongest']),
                          AppColors.teal),
                    ],
                  ),
                ),
    );
  }

  List<Map<String, dynamic>> _list(dynamic v) =>
      (v as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();

  Widget _progressCard(BuildContext context) {
    final acc = (_progress['overall_accuracy'] as num?)?.round() ?? 0;
    final rank = _progress['rank'] ?? '-';
    final size = _progress['class_size'] ?? '-';
    final trend = _list(_progress['trend']);
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('OVERALL', style: AppTheme.mono(10, FontWeight.w700, ls: 1)),
        const SizedBox(height: 10),
        Row(children: [
          _stat('$acc%', 'Accuracy', AppColors.primary),
          _stat('#$rank', 'Class rank', AppColors.teal),
          _stat('$size', 'Classmates', AppColors.muted),
        ]),
        if (trend.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('RECENT SESSIONS', style: AppTheme.mono(9, FontWeight.w600, ls: 1)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final t in trend)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(children: [
                      Container(
                        height: 6 +
                            ((t['accuracy'] as num?)?.toDouble() ?? 0) / 100 * 54,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('${(t['accuracy'] as num?)?.round() ?? 0}',
                          style: AppTheme.mono(8, FontWeight.w500)),
                    ]),
                  ),
                ),
            ],
          ),
        ],
      ]),
    );
  }

  Widget _stat(String value, String label, Color color) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: AppTheme.mono(9, FontWeight.w500)),
        ]),
      );

  Widget _boardCard(BuildContext context) => AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('QUESTION BANK BY EXAM',
              style: AppTheme.mono(10, FontWeight.w700, ls: 1)),
          const SizedBox(height: 12),
          if (_boards.isEmpty)
            Text('No questions in your bank yet.',
                style: Theme.of(context).textTheme.bodyMedium)
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final b in _boards)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('${b['board']}',
                          style: AppTheme.mono(12, FontWeight.w700,
                              color: AppColors.primary)),
                      const SizedBox(width: 8),
                      Text('${b['count']}',
                          style: AppTheme.mono(12, FontWeight.w500)),
                    ]),
                  ),
              ],
            ),
        ]),
      );

  Widget _chaptersCard(
      BuildContext context, String title, List<Map<String, dynamic>> rows, Color color) {
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title.toUpperCase(),
            style: AppTheme.mono(10, FontWeight.w700, ls: 1)),
        const SizedBox(height: 6),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text('Practise a few chapters to see this.',
                style: Theme.of(context).textTheme.bodyMedium),
          )
        else
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${r['chapter']}',
                            style: Theme.of(context).textTheme.bodyLarge),
                        Text('${r['subject']} · ${r['total']} attempted',
                            style: AppTheme.mono(9, FontWeight.w500)),
                      ]),
                ),
                Text('${(r['accuracy'] as num?)?.round() ?? 0}%',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800, color: color)),
              ]),
            ),
      ]),
    );
  }
}
