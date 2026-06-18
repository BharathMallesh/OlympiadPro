import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/stores.dart';
import '../../models/models.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/common.dart';
import '../../widgets/math_text.dart';

/// #1 — Question Bank library: browse, search, and reuse questions across
/// exams; entry point for manual authoring (#11).
class QuestionBankScreen extends StatefulWidget {
  const QuestionBankScreen({super.key});
  @override
  State<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends State<QuestionBankScreen> {
  String _query = '';
  String _typeFilter = 'All';

  static const _typeFilters = ['All', 'Multiple Choice', 'Numeric', 'Short Answer'];

  @override
  void initState() {
    super.initState();
    questionStore.loadFromApi();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      brand: 'MathKraft',
      currentRoute: '/bank',
      title: 'Question Bank',
      actions: [
        AppButton('Add Question',
            kind: AppBtnKind.secondary,
            icon: Icons.add,
            onPressed: () => context.push('/wizard/edit-question/new?from=/bank')),
        const SizedBox(width: 12),
      ],
      body: ListenableBuilder(
        listenable: questionStore,
        builder: (context, _) {
          if (questionStore.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = questionStore.questions;
          // Keep each match's original index so the edit route still points
          // at the right entry in questionStore.questions.
          final items = <(int, QuestionItem)>[];
          for (var i = 0; i < all.length; i++) {
            final q = all[i];
            final matchesQuery = _query.isEmpty ||
                q.prompt.toLowerCase().contains(_query.toLowerCase());
            final matchesType = _typeFilter == 'All' || q.type == _typeFilter;
            if (matchesQuery && matchesType) items.add((i, q));
          }

          // Lazily build rows (the bank can hold hundreds of LaTeX questions;
          // a non-lazy list renders them all up front and janks the UI).
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: items.length + 1,
            itemBuilder: (context, row) {
              if (row > 0) {
                final (origIndex, q) = items[row - 1];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _BankRow(index: origIndex, q: q),
                );
              }
              return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search + filters
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 300,
                      child: TextField(
                        onChanged: (v) => setState(() => _query = v),
                        style: const TextStyle(
                            color: AppColors.onSurface, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Search LaTeX or keywords...',
                          hintStyle: const TextStyle(color: AppColors.muted),
                          prefixIcon: const Icon(Icons.search,
                              size: 18, color: AppColors.muted),
                          filled: true,
                          fillColor: AppColors.scaffold,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            borderSide: const BorderSide(
                                color: AppColors.outlineStrong),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 2),
                          ),
                        ),
                      ),
                    ),
                    for (final f in _typeFilters)
                      InkWell(
                        onTap: () => setState(() => _typeFilter = f),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: _typeFilter == f
                                ? AppColors.primaryStrong.withValues(alpha: 0.2)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                                color: _typeFilter == f
                                    ? AppColors.primary
                                    : AppColors.outline),
                          ),
                          child: Text(f,
                              style: AppTheme.mono(11, FontWeight.w600,
                                  color: _typeFilter == f
                                      ? AppColors.primary
                                      : AppColors.muted)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Text('${items.length} of ${all.length} questions',
                      style: AppTheme.mono(11, FontWeight.w500)),
                  const Spacer(),
                  StatusChip('Reusable across exams', color: AppColors.teal),
                ]),
                const SizedBox(height: 14),

                if (items.isEmpty)
                  AppCard(
                    child: Column(children: [
                      const Icon(Icons.search_off,
                          color: AppColors.muted, size: 36),
                      const SizedBox(height: 10),
                      Text('No questions match your filters.',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ]),
                  ),
              ],
              );
            },
          );
        },
      ),
    );
  }
}

class _BankRow extends StatelessWidget {
  const _BankRow({required this.index, required this.q});
  final int index;
  final QuestionItem q;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(q.label,
                style: AppTheme.mono(13, FontWeight.w700, color: AppColors.primary)),
            const SizedBox(width: 10),
            // Flexible + Wrap absorbs free space and lets chips spill onto a
            // second line on narrow phones instead of overflowing the row.
            Expanded(
              child: Wrap(spacing: 8, runSpacing: 6, children: [
                StatusChip(q.type, color: AppColors.onSurfaceVariant),
                if (q.images.isNotEmpty || q.imageUrls.isNotEmpty)
                  StatusChip('${q.images.length + q.imageUrls.length} img',
                      color: AppColors.teal, icon: Icons.image_outlined),
              ]),
            ),
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.muted),
              onPressed: () =>
                  context.push('/wizard/edit-question/$index?from=/bank'),
            ),
            IconButton(
              tooltip: 'Use in current exam',
              icon: const Icon(Icons.playlist_add, size: 20, color: AppColors.muted),
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${q.label} added to the current exam draft.'))),
            ),
          ]),
          const SizedBox(height: 10),
          MixedMathText(q.prompt.isEmpty ? '-' : q.prompt, fontSize: 15),
          // Question image(s) shown centered, directly below the prompt.
          if (q.imageUrls.isNotEmpty || q.images.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8, runSpacing: 8, children: [
              for (final url in q.imageUrls)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Image.network(url,
                      height: 150, fit: BoxFit.contain,
                      loadingBuilder: (c, child, p) => p == null
                          ? child
                          : Container(
                              height: 150, width: 200,
                              alignment: Alignment.center,
                              color: AppColors.surfaceHigh,
                              child: const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2))),
                      errorBuilder: (c, e, s) => Container(
                          height: 150, width: 200,
                          alignment: Alignment.center,
                          color: AppColors.surfaceHigh,
                          child: const Icon(Icons.broken_image_outlined,
                              color: AppColors.muted))),
                ),
              for (final bytes in q.images)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Image.memory(bytes, height: 150, fit: BoxFit.contain),
                ),
            ])),
          ],
          if (q.options.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 6, children: [
              for (var i = 0; i < q.options.length; i++)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: q.options[i].correct
                        ? AppColors.success.withValues(alpha: 0.12)
                        : AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                        color: q.options[i].correct
                            ? AppColors.success.withValues(alpha: 0.5)
                            : AppColors.outline),
                  ),
                  child: Text(
                      '${String.fromCharCode(65 + i)}. ${q.options[i].text}',
                      style: AppTheme.mono(11, FontWeight.w500,
                          color: q.options[i].correct
                              ? AppColors.success
                              : AppColors.onSurfaceVariant,
                          ls: 0)),
                ),
            ]),
          ],
        ],
      ),
    );
  }
}
