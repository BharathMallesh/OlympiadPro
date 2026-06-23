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
  String _filter = 'all'; // all | review | parsed

  /// Re-hydrate the shared store from the backend (after a regenerate/fix).
  Future<void> _reload() => questionStore.loadFromApi(
      onlyIds: examDraft.importedQuestionIds.isEmpty
          ? null
          : examDraft.importedQuestionIds);

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
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Filter questions',
            icon: Icon(Icons.filter_list,
                color: _filter == 'all'
                    ? AppColors.onSurfaceVariant
                    : AppColors.primary),
            initialValue: _filter,
            onSelected: (v) => setState(() => _filter = v),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'all', child: Text('All questions')),
              PopupMenuItem(value: 'review', child: Text('Needs review')),
              PopupMenuItem(value: 'parsed', child: Text('Auto-parsed')),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListenableBuilder(
        listenable: questionStore,
        builder: (context, _) {
          final all = questionStore.questions;
          final reviewed = all.where((q) => q.status == QStatus.parsed).length;
          bool show(QuestionItem q) => _filter == 'all'
              ? true
              : _filter == 'review'
                  ? q.status == QStatus.reviewNeeded
                  : q.status == QStatus.parsed;
          final visible = all.where(show).length;
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
                  Text(
                      _filter == 'all'
                          ? '$reviewed of ${all.length} reviewed'
                          : '$visible of ${all.length} shown',
                      style: AppTheme.mono(12, FontWeight.w500, color: AppColors.muted)),
                  const SizedBox(width: 16),
                  Expanded(
                      child: ProgressLine(all.isEmpty
                          ? 0
                          : reviewed / all.length)),
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
                          if (visible == 0 && all.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(32),
                              child: Text('No questions match this filter.',
                                  style: Theme.of(context).textTheme.bodyMedium),
                            ),
                          // Keep `index` aligned with the store so the edit
                          // screen edits the right question even when filtered.
                          for (var i = 0; i < all.length; i++)
                            if (show(all[i])) ...[
                              _QuestionCard(
                                  index: i, q: all[i], onReload: _reload),
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
                    AppButton('Add',
                        kind: AppBtnKind.ghost,
                        icon: Icons.add,
                        onPressed: () =>
                            context.push('/wizard/edit-question/new')),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton('Save & Continue',
                          kind: AppBtnKind.secondary,
                          trailingIcon: Icons.arrow_forward,
                          expand: true,
                          onPressed: () => context.go('/wizard/finalize')),
                    ),
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

class _QuestionCard extends StatefulWidget {
  const _QuestionCard(
      {required this.index, required this.q, required this.onReload});
  final int index;
  final QuestionItem q;
  final Future<void> Function() onReload;

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  bool _busy = false;

  /// Run a backend rewrite (regenerate / AI-fix), then refresh the store.
  Future<void> _run(
      Future<Map<String, dynamic>> Function() action, String okMsg) async {
    if (widget.q.id == null) return;
    setState(() => _busy = true);
    try {
      await action();
      await widget.onReload();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(okMsg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('$e'), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Show the verbatim source the question was parsed from; when [compare] is
  /// true, show it side-by-side with the parsed question.
  Future<void> _viewOriginal({bool compare = false}) async {
    if (widget.q.id == null) return;
    try {
      final src = await Repo.questionSource(widget.q.id!);
      final source = (src['source_text'] as String?)?.trim();
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(compare ? 'Compare with original' : 'Original source'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (compare) ...[
                    Text('PARSED QUESTION',
                        style: AppTheme.mono(10, FontWeight.w700,
                            color: AppColors.primary, ls: 1)),
                    const SizedBox(height: 6),
                    MixedMathText(widget.q.prompt,
                        fontSize: 14, color: AppColors.onSurface),
                    const SizedBox(height: 16),
                  ],
                  Text('ORIGINAL (FROM PAPER)',
                      style: AppTheme.mono(10, FontWeight.w700,
                          color: AppColors.secondary, ls: 1)),
                  const SizedBox(height: 6),
                  Text(
                      source == null || source.isEmpty
                          ? 'No original source was captured for this question. '
                              'Only questions imported after source capture was '
                              'enabled include the original text.'
                          : source,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close')),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('$e'), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.q;
    final index = widget.index;
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
                    MixedMathText(q.prompt,
                        fontSize: 16, color: AppColors.onSurface),
                    const SizedBox(height: 8),
                    Text(q.type, style: Theme.of(context).textTheme.bodySmall),
                    // Attached images — already-uploaded (urls) + freshly added.
                    if (q.images.isNotEmpty || q.imageUrls.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final url in q.imageUrls) _MiniThumb(url: url),
                          for (final bytes in q.images) _MiniThumb(bytes: bytes),
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
              // The paper references a figure/diagram but nothing is attached
              // yet — offer to add the cropped image (no more hardcoded mock).
              if (q.hasGraph && q.images.isEmpty && q.imageUrls.isEmpty) ...[
                const SizedBox(width: 14),
                InkWell(
                  onTap: () => context.push('/wizard/edit-question/$index'),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    width: 150,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.outlineStrong),
                    ),
                    child: Column(children: [
                      const Icon(Icons.add_photo_alternate_outlined,
                          color: AppColors.primary, size: 28),
                      const SizedBox(height: 8),
                      Text('References a figure',
                          textAlign: TextAlign.center,
                          style: AppTheme.mono(9.5, FontWeight.w600,
                              color: AppColors.onSurface)),
                      const SizedBox(height: 2),
                      Text('Tap to add the cropped image',
                          textAlign: TextAlign.center,
                          style: AppTheme.mono(8.5, FontWeight.w500,
                              color: AppColors.muted)),
                    ]),
                  ),
                ),
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
          if (_busy)
            Row(children: const [
              SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 10),
              Text('Asking AI…'),
            ])
          else
            Wrap(spacing: 10, runSpacing: 10, children: [
              AppButton('Edit',
                  kind: AppBtnKind.ghost,
                  icon: Icons.edit_outlined,
                  onPressed: () => context.push('/wizard/edit-question/$index')),
              AppButton('View Original',
                  kind: AppBtnKind.ghost,
                  icon: Icons.description_outlined,
                  onPressed: () => _viewOriginal()),
              AppButton('Regenerate',
                  kind: AppBtnKind.ghost,
                  icon: Icons.refresh,
                  onPressed: () => _run(
                      () => Repo.regenerateQuestion(q.id!),
                      'Question regenerated')),
              if (q.warning != null) ...[
                AppButton('Compare',
                    kind: AppBtnKind.ghost,
                    icon: Icons.compare_arrows,
                    onPressed: () => _viewOriginal(compare: true)),
                AppButton('AI Fix',
                    kind: AppBtnKind.secondary,
                    icon: Icons.auto_fix_high,
                    onPressed: () =>
                        _run(() => Repo.aiFixQuestion(q.id!), 'Question fixed')),
              ],
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
          child: option.text.isEmpty
              ? Text('—',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontSize: 14))
              : MixedMathText(option.text,
                  fontSize: 14, color: AppColors.onSurface),
        ),
        const SizedBox(width: 8),
        if (correct)
          const Icon(Icons.check_circle, size: 16, color: AppColors.success),
      ]),
    );
  }
}

class _MiniThumb extends StatelessWidget {
  const _MiniThumb({this.bytes, this.url});
  final Uint8List? bytes;
  final String? url;
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: bytes != null
            ? Image.memory(bytes!, width: 80, height: 80, fit: BoxFit.cover)
            : Image.network(url!,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                    width: 80,
                    height: 80,
                    color: AppColors.surfaceContainer,
                    child: const Icon(Icons.broken_image,
                        color: AppColors.muted, size: 18))),
      );
}
