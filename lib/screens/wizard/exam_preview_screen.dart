import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/repo.dart';
import '../../widgets/common.dart';
import '../../widgets/math_text.dart';

/// Previews a generated exam paper — every question with its answer key — so the
/// teacher can confirm it's correct BEFORE publishing to students.
class ExamPreviewScreen extends StatefulWidget {
  const ExamPreviewScreen({super.key, required this.examId});
  final String examId;

  @override
  State<ExamPreviewScreen> createState() => _ExamPreviewScreenState();
}

class _ExamPreviewScreenState extends State<ExamPreviewScreen> {
  bool _loading = true;
  bool _busy = false;
  String? _error;
  List<dynamic> _questions = const [];

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
      final qs = await Repo.examQuestions(widget.examId);
      if (!mounted) return;
      setState(() {
        _questions = qs;
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

  Future<void> _publish() async {
    setState(() => _busy = true);
    try {
      await Repo.publishExam(widget.examId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Published to the assigned classes.'),
          backgroundColor: AppColors.success));
      context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()), backgroundColor: AppColors.error));
      }
    }
  }

  int get _totalMarks => _questions.fold(
      0, (a, q) => a + ((q as Map)['marks'] as num? ?? 0).toInt());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/dashboard')),
        titleSpacing: 0,
        title: Text('Preview paper', style: Theme.of(context).textTheme.titleLarge),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error!, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 12),
                  AppButton('Retry', onPressed: _load),
                ]))
              : Column(children: [
                  Container(
                    width: double.infinity,
                    color: AppColors.surfaceContainer,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Text(
                        '${_questions.length} questions · $_totalMarks marks · review the '
                        'answer key below, then publish.',
                        style: AppTheme.mono(11, FontWeight.w600,
                            color: AppColors.onSurface)),
                  ),
                  Expanded(
                    child: _questions.isEmpty
                        ? Center(
                            child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                                'No questions matched this format in the bank yet. '
                                'Add more questions, then regenerate.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium),
                          ))
                        : ListView.builder(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            itemCount: _questions.length,
                            itemBuilder: (ctx, i) =>
                                _questionCard(ctx, i, _questions[i] as Map),
                          ),
                  ),
                ]),
      bottomNavigationBar: _loading || _error != null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(children: [
                  Expanded(
                    child: AppButton('Keep as draft',
                        kind: AppBtnKind.ghost,
                        onPressed:
                            _busy ? null : () => context.go('/dashboard')),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(_busy ? 'Publishing…' : 'Publish',
                        trailingIcon: Icons.publish,
                        onPressed: _busy || _questions.isEmpty ? null : _publish),
                  ),
                ]),
              ),
            ),
    );
  }

  Widget _questionCard(BuildContext context, int i, Map q) {
    final options = (q['options'] as List? ?? []);
    final marks = (q['marks'] as num? ?? 0).toInt();
    final qtype = (q['qtype'] as String? ?? '').replaceAll('_', ' ');
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('Q${i + 1}',
                style: AppTheme.mono(12, FontWeight.w700, color: AppColors.primary)),
            const Spacer(),
            Text('$qtype · $marks mark${marks == 1 ? '' : 's'}',
                style: AppTheme.mono(9, FontWeight.w500)),
          ]),
          const SizedBox(height: 8),
          MixedMathText(q['prompt']?.toString() ?? '', fontSize: 15),
          if (options.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (var o = 0; o < options.length; o++)
              _optionRow(options[o] as Map, o),
          ],
          if ((q['answer_text']?.toString() ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Answer: ${q['answer_text']}',
                style: AppTheme.mono(11, FontWeight.w600, color: AppColors.success)),
          ],
        ],
      ),
    );
  }

  Widget _optionRow(Map opt, int idx) {
    final correct = opt['correct'] == true;
    final label = String.fromCharCode(65 + idx);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(correct ? Icons.check_circle : Icons.circle_outlined,
            size: 16, color: correct ? AppColors.success : AppColors.muted),
        const SizedBox(width: 6),
        Text('$label. ',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: correct ? AppColors.success : AppColors.onSurfaceVariant)),
        Expanded(
          child: MixedMathText(opt['text']?.toString() ?? '',
              fontSize: 13,
              color: correct ? AppColors.success : AppColors.onSurface),
        ),
      ]),
    );
  }
}
