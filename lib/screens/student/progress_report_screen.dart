import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../data/repo.dart';
import '../../widgets/common.dart';

/// Comprehensive self-improvement report: accuracy by subject / board / chapter
/// / topic (from practice) and per-exam scores. Weakest areas are surfaced
/// first so a student knows exactly where to focus.
class ProgressReportScreen extends StatefulWidget {
  const ProgressReportScreen({super.key});
  @override
  State<ProgressReportScreen> createState() => _ProgressReportScreenState();
}

class _ProgressReportScreenState extends State<ProgressReportScreen> {
  static const _dims = ['Subject', 'Board', 'Chapter', 'Topic', 'Exams'];
  static const _keys = ['by_subject', 'by_board', 'by_chapter', 'by_topic', 'by_exam'];
  String _dim = 'Subject';
  Map<String, dynamic> _data = const {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await Repo.progressReport();
      if (mounted) setState(() { _data = d; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = '$e'; _loading = false; });
    }
  }

  Color _colorFor(double acc) => acc >= 0.7
      ? AppColors.success
      : acc >= 0.4
          ? const Color(0xFFE0A93B)
          : AppColors.error;

  @override
  Widget build(BuildContext context) {
    final key = _keys[_dims.indexOf(_dim)];
    final rows = ((_data[key] as List?) ?? const []).cast<Map<String, dynamic>>();
    final isExam = _dim == 'Exams';
    // Worst-first for practice dimensions so lagging areas surface at the top.
    final items = [...rows];
    if (!isExam) {
      items.sort((a, b) {
        double acc(m) => (m['total'] ?? 0) == 0 ? 1 : (m['correct'] ?? 0) / m['total'];
        return acc(a).compareTo(acc(b));
      });
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Progress Report',
            style: Theme.of(context).textTheme.titleLarge),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Could not load: $_error'))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text(
                          'See where you\'re strong and where to focus — weakest areas are shown first.',
                          style: Theme.of(context).textTheme.bodySmall),
                    ),
                    SizedBox(
                      height: 44,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          for (final d in _dims)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _DimChip(
                                  label: d,
                                  selected: _dim == d,
                                  onTap: () => setState(() => _dim = d)),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: items.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Text(
                                    isExam
                                        ? 'No graded exams yet. Take an assigned exam to see your scores here.'
                                        : 'Practice more questions to build your $_dim breakdown.',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodyMedium),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: items.length,
                              itemBuilder: (_, i) =>
                                  isExam ? _examRow(items[i]) : _row(items[i]),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _row(Map<String, dynamic> m) {
    final total = (m['total'] ?? 0) as int;
    final correct = (m['correct'] ?? 0) as int;
    final acc = total == 0 ? 0.0 : correct / total;
    final color = _colorFor(acc);
    final focus = acc < 0.4 && total >= 2;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${m['label']}',
                      style: Theme.of(context).textTheme.titleMedium),
                  if ((m['sublabel'] ?? '').toString().isNotEmpty)
                    Text('${m['sublabel']}',
                        style: AppTheme.mono(9, FontWeight.w500,
                            color: AppColors.muted)),
                ],
              ),
            ),
            if (focus)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text('Focus here',
                    style: AppTheme.mono(9, FontWeight.w700,
                        color: AppColors.error)),
              ),
            Text('$correct/$total  ${(acc * 100).round()}%',
                style: AppTheme.mono(12, FontWeight.w700, color: color)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: acc,
              minHeight: 7,
              backgroundColor: AppColors.surfaceContainer,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _examRow(Map<String, dynamic> m) {
    final score = (m['score'] ?? 0) as int;
    final max = (m['max_score'] ?? 0) as int;
    final acc = max == 0 ? 0.0 : score / max;
    final color = _colorFor(acc);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Row(children: [
          Expanded(
            child: Text('${m['title']}',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          Text('$score/$max  ${(acc * 100).round()}%',
              style: AppTheme.mono(12, FontWeight.w700, color: color)),
        ]),
      ),
    );
  }
}

class _DimChip extends StatelessWidget {
  const _DimChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.16)
                : AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
                color: selected ? AppColors.primary : AppColors.outline),
          ),
          child: Text(label,
              style: AppTheme.mono(11, FontWeight.w600,
                  color: selected ? AppColors.primary : AppColors.muted)),
        ),
      );
}
