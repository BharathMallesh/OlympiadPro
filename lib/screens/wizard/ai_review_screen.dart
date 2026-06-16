import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/stores.dart';
import '../../data/repo.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../../widgets/math_text.dart';

class AiReviewScreen extends StatefulWidget {
  const AiReviewScreen({super.key});
  @override
  State<AiReviewScreen> createState() => _AiReviewScreenState();
}

class _AiReviewScreenState extends State<AiReviewScreen> {
  bool _parsing = false;
  String? _parseError;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    final jobId = examDraft.importJobId;
    if (jobId != null && examDraft.importedQuestionIds.isEmpty) {
      _parsing = true;
      _poll(jobId);
    } else if (examDraft.importedQuestionIds.isNotEmpty) {
      questionStore.loadFromApi(onlyIds: examDraft.importedQuestionIds);
    } else {
      questionStore.loadFromApi();
    }
  }

  void _poll(String jobId) {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (t) async {
      try {
        final job = await Repo.importStatus(jobId);
        final status = job['status'] as String?;
        if (status == 'done') {
          t.cancel();
          examDraft.importedQuestionIds =
              (job['question_ids'] as List).cast<String>();
          await questionStore.loadFromApi(
              onlyIds: examDraft.importedQuestionIds);
          if (mounted) setState(() => _parsing = false);
        } else if (status == 'failed') {
          t.cancel();
          if (mounted) {
            setState(() {
              _parsing = false;
              _parseError = job['error'] as String? ?? 'Parsing failed';
            });
          }
        }
      } catch (_) {
        // transient poll failure; keep trying
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_parsing) {
      return Scaffold(
        backgroundColor: AppColors.scaffold,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 18),
            Text('AI is parsing your paper…',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text('Extracting questions, options, and LaTeX. ~30 seconds.',
                style: Theme.of(context).textTheme.bodyMedium),
          ]),
        ),
      );
    }
    if (_parseError != null) {
      return Scaffold(
        backgroundColor: AppColors.scaffold,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 40),
            const SizedBox(height: 12),
            Text(_parseError!, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 14),
            AppButton('Back to Upload',
                onPressed: () => context.go('/wizard/upload')),
          ]),
        ),
      );
    }
    return PopRedirect(
      fallbackRoute: '/wizard/upload',
      child: Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/wizard/upload')),
        title: Text('AI Review & Edit',
            style: Theme.of(context).textTheme.titleLarge),
      ),
      body: ListenableBuilder(
        listenable: questionStore,
        builder: (context, _) {
          final questions = questionStore.questions;
          final reviewed = questions.where((q) => q.status == QStatus.parsed).length;
          return Column(
            children: [
              // Review progress bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.outline)),
                ),
                child: Row(children: [
                  Text('Questions', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(width: 16),
                  Text('$reviewed of ${questions.length} reviewed',
                      style: AppTheme.mono(12, FontWeight.w500, color: AppColors.muted)),
                  const SizedBox(width: 16),
                  Expanded(
                      child: ProgressLine(questions.isEmpty
                          ? 0
                          : reviewed / questions.length)),
                ]),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Column(
                        children: [
                          for (var i = 0; i < questions.length; i++) ...[
                            _QuestionCard(index: i, q: questions[i]),
                            const SizedBox(height: 16),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  border: Border(top: BorderSide(color: AppColors.outline)),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(children: [
                    AppButton('Add Question',
                        kind: AppBtnKind.ghost,
                        icon: Icons.add,
                        onPressed: () =>
                            context.push('/wizard/edit-question/new')),
                    const Spacer(),
                    AppButton('Save & Continue',
                        kind: AppBtnKind.secondary,
                        trailingIcon: Icons.arrow_forward,
                        onPressed: () => context.go('/wizard/finalize')),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.index, required this.q});
  final int index;
  final QuestionItem q;

  @override
  Widget build(BuildContext context) {
    final parsed = q.status == QStatus.parsed;
    final statusColor = parsed ? AppColors.success : AppColors.secondary;
    return AppCard(
      borderColor: q.warning != null ? AppColors.secondary.withValues(alpha: 0.4) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(q.label,
                style: AppTheme.mono(13, FontWeight.w700, color: AppColors.primary)),
            const SizedBox(width: 12),
            StatusChip(parsed ? 'Auto-Parsed' : 'Review Needed',
                color: statusColor,
                icon: parsed ? Icons.check : Icons.visibility),
          ]),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MixedMathText(q.prompt, fontSize: 16),
                    const SizedBox(height: 8),
                    Text(q.type, style: Theme.of(context).textTheme.bodySmall),
                    // Attached images (added in the edit screen)
                    if (q.images.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final bytes in q.images) _MiniThumb(bytes),
                        ],
                      ),
                    ],
                    // Options preview
                    if (q.options.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      for (var i = 0; i < q.options.length; i++)
                        _OptionPreview(index: i, option: q.options[i]),
                    ],
                  ],
                ),
              ),
              if (q.hasGraph) ...[
                const SizedBox(width: 14),
                Column(children: [
                  Container(
                    width: 150,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: const Icon(Icons.show_chart, color: AppColors.primary, size: 32),
                  ),
                  const SizedBox(height: 6),
                  Text('Cropped Integral Graph',
                      style: AppTheme.mono(9, FontWeight.w500)),
                ]),
              ],
            ],
          ),
          if (q.warning != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(children: [
                const Icon(Icons.warning_amber, color: AppColors.secondary, size: 16),
                const SizedBox(width: 10),
                Expanded(child: Text(q.warning!, style: Theme.of(context).textTheme.bodySmall)),
              ]),
            ),
          ],
          const SizedBox(height: 14),
          Row(children: [
            AppButton('Edit',
                kind: AppBtnKind.ghost,
                icon: Icons.edit_outlined,
                onPressed: () => context.push('/wizard/edit-question/$index')),
          ]),
        ],
      ),
    );
  }
}

class _OptionPreview extends StatelessWidget {
  const _OptionPreview({required this.index, required this.option});
  final int index;
  final QuestionOption option;
  @override
  Widget build(BuildContext context) {
    final letter = String.fromCharCode(65 + index);
    final correct = option.correct;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: correct ? AppColors.success.withValues(alpha: 0.1) : AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
            color: correct ? AppColors.success.withValues(alpha: 0.5) : AppColors.outline),
      ),
      child: Row(children: [
        Text('$letter.',
            style: AppTheme.mono(12, FontWeight.w700,
                color: correct ? AppColors.success : AppColors.muted)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(option.text.isEmpty ? '—' : option.text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 14)),
        ),
        if (correct)
          const Icon(Icons.check_circle, size: 16, color: AppColors.success),
      ]),
    );
  }
}

class _MiniThumb extends StatelessWidget {
  const _MiniThumb(this.bytes);
  final Uint8List bytes;
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Image.memory(bytes, width: 80, height: 80, fit: BoxFit.cover),
      );
}
