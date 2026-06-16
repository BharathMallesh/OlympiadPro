import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/repo.dart';
import '../../widgets/common.dart';
import '../../widgets/math_text.dart';

/// Runs a generated practice set: one MCQ at a time, multi-select allowed,
/// graded server-side on finish (the answer key never reaches the app).
class PracticeSessionScreen extends StatefulWidget {
  const PracticeSessionScreen({super.key, required this.questions});
  final List<dynamic> questions;

  @override
  State<PracticeSessionScreen> createState() => _PracticeSessionScreenState();
}

class _PracticeSessionScreenState extends State<PracticeSessionScreen> {
  int _index = 0;
  bool _submitting = false;
  final Map<String, Set<int>> _selected = {};

  Map<String, dynamic> get _q => widget.questions[_index] as Map<String, dynamic>;
  String get _qid => _q['question_id'] as String;

  int get _answered =>
      _selected.values.where((s) => s.isNotEmpty).length;

  Future<void> _finish() async {
    if (_answered < widget.questions.length) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surfaceHigh,
          title: const Text('Finish practice?'),
          content: Text(
              '${widget.questions.length - _answered} of '
              '${widget.questions.length} questions are unanswered.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Keep Going')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Finish')),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() => _submitting = true);
    try {
      final result = await Repo.practiceGrade([
        for (final q in widget.questions)
          {
            'question_id': (q as Map<String, dynamic>)['question_id'],
            'selected':
                (_selected[q['question_id']] ?? const <int>{}).toList()..sort(),
          },
      ]);
      if (!mounted) return;
      context.pushReplacement('/student/practice-results', extra: {
        'result': result,
        'questions': widget.questions,
        'selected': {
          for (final e in _selected.entries) e.key: e.value.toList()
        },
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()), backgroundColor: AppColors.error));
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.questions.length;
    final options = (_q['options'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final picked = _selected[_qid] ?? const <int>{};
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close),
            onPressed: () => context.pop()),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Practice Set',
                style: Theme.of(context).textTheme.titleLarge),
            Text('${_q['subject'] ?? ''}'
                '${_q['topic'] != null ? ' · ${_q['topic']}' : ''}',
                style: AppTheme.mono(9, FontWeight.w500)),
          ],
        ),
        actions: [
          StatusChip('${_index + 1} / $total', color: AppColors.teal),
          const SizedBox(width: 14),
        ],
      ),
      body: Column(children: [
        ProgressLine((_index + 1) / total, color: AppColors.teal, height: 3),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      StatusChip('Q${_index + 1}', color: AppColors.primary),
                      const SizedBox(width: 8),
                      StatusChip(
                          'DIFFICULTY ${_q['difficulty'] ?? '-'}/5',
                          color: AppColors.muted),
                    ]),
                    const SizedBox(height: 14),
                    MixedMathText(_q['prompt'] as String? ?? '',
                        fontSize: 18),
                    const SizedBox(height: 18),
                    for (final (i, o) in options.indexed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _optionTile(
                            context, i, o['text'] as String? ?? '',
                            picked.contains(i)),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: Row(children: [
              if (_index > 0)
                Expanded(
                  child: AppButton('Previous', kind: AppBtnKind.ghost,
                      onPressed: () => setState(() => _index--)),
                ),
              if (_index > 0) const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _index < total - 1
                    ? AppButton('Next',
                        trailingIcon: Icons.arrow_forward,
                        onPressed: () => setState(() => _index++))
                    : AppButton(
                        _submitting ? 'Grading…' : 'Finish & Grade',
                        trailingIcon: Icons.check,
                        onPressed: _submitting ? null : _finish),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _optionTile(
      BuildContext context, int index, String text, bool selected) {
    final letter = String.fromCharCode(65 + index);
    return InkWell(
      onTap: () => setState(() {
        final s = _selected.putIfAbsent(_qid, () => <int>{});
        selected ? s.remove(index) : s.add(index);
      }),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryStrong.withValues(alpha: 0.18)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.outline),
        ),
        child: Row(children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary
                  : AppColors.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: Text(letter,
                style: AppTheme.mono(12, FontWeight.w700,
                    color: selected
                        ? AppColors.onPrimary
                        : AppColors.onSurfaceVariant)),
          ),
          const SizedBox(width: 12),
          Expanded(child: MixedMathText(text, fontSize: 15)),
        ]),
      ),
    );
  }
}
