import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/repo.dart';
import '../../widgets/common.dart';
import '../../widgets/math_text.dart';

/// Re-opens a past AI-practice session from the dashboard's Recent Activity.
/// Shows the score, per-subject accuracy, and a question-by-question review
/// where each question can reveal an on-demand AI worked solution.
class PracticeReviewScreen extends StatefulWidget {
  const PracticeReviewScreen({super.key, required this.sessionId});
  final String sessionId;

  @override
  State<PracticeReviewScreen> createState() => _PracticeReviewScreenState();
}

class _PracticeReviewScreenState extends State<PracticeReviewScreen> {
  Map<String, dynamic>? _session;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await Repo.practiceSession(widget.sessionId);
      if (!mounted) return;
      setState(() {
        _session = s;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load this session.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/student/hub')),
        title: Text('Session Review',
            style: Theme.of(context).textTheme.titleLarge),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(_error!,
                      style: Theme.of(context).textTheme.bodyMedium))
              : _body(context),
    );
  }

  Widget _body(BuildContext context) {
    final s = _session!;
    final total = (s['total'] as num?)?.toInt() ?? 0;
    final correct = (s['correct'] as num?)?.toInt() ?? 0;
    final pct = (s['score_pct'] as num?)?.round() ?? 0;
    final bySubject = ((s['by_subject'] as List<dynamic>?) ?? const [])
        .cast<Map<String, dynamic>>();
    final details = ((s['details'] as List<dynamic>?) ?? const [])
        .cast<Map<String, dynamic>>();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            AppCard(
              accentTop: pct >= 60 ? AppColors.success : AppColors.error,
              child: Column(children: [
                Text('${s['subjects'] ?? 'Practice'}'.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: AppTheme.mono(10, FontWeight.w600, ls: 1.2)),
                const SizedBox(height: 10),
                Text('$correct / $total',
                    style: Theme.of(context)
                        .textTheme
                        .displaySmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                StatusChip('$pct% correct',
                    color: pct >= 60 ? AppColors.success : AppColors.error),
              ]),
            ),
            const SizedBox(height: 16),
            if (bySubject.isNotEmpty) ...[
              const SectionTitle('Subject Breakdown',
                  icon: Icons.donut_small_outlined),
              const SizedBox(height: 10),
              AppCard(
                child: Column(children: [
                  for (final sub in bySubject)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                                child: Text(sub['subject'] as String? ?? '',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge)),
                            Text('${sub['correct']}/${sub['total']}',
                                style: AppTheme.mono(13, FontWeight.w700,
                                    color: AppColors.teal)),
                          ]),
                          const SizedBox(height: 6),
                          ProgressLine(
                              (sub['total'] as num? ?? 0) == 0
                                  ? 0
                                  : ((sub['correct'] as num? ?? 0) /
                                          (sub['total'] as num))
                                      .toDouble(),
                              color: AppColors.teal,
                              height: 6),
                        ],
                      ),
                    ),
                ]),
              ),
              const SizedBox(height: 16),
            ],
            const SectionTitle('Question Review',
                icon: Icons.fact_check_outlined),
            const SizedBox(height: 10),
            for (final (i, d) in details.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _QuestionReviewCard(index: i, detail: d),
              ),
            const SizedBox(height: 10),
            AppButton('Back to Hub',
                expand: true, onPressed: () => context.go('/student/hub')),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _QuestionReviewCard extends StatefulWidget {
  const _QuestionReviewCard({required this.index, required this.detail});
  final int index;
  final Map<String, dynamic> detail;

  @override
  State<_QuestionReviewCard> createState() => _QuestionReviewCardState();
}

class _QuestionReviewCardState extends State<_QuestionReviewCard> {
  bool _expanded = false;
  bool _loading = false;
  Map<String, dynamic>? _ai;
  String? _aiError;

  Future<void> _explain() async {
    setState(() => _expanded = !_expanded);
    if (!_expanded || _ai != null || _loading) return;
    setState(() {
      _loading = true;
      _aiError = null;
    });
    try {
      final qid = widget.detail['question_id'] as String;
      final res = await Repo.explainQuestion(qid);
      if (!mounted) return;
      setState(() {
        _ai = res;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _aiError = 'Could not generate an explanation right now.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.detail;
    final correct = d['correct'] as bool? ?? false;
    final options = ((d['options'] as List<dynamic>?) ?? const [])
        .cast<Map<String, dynamic>>();
    final picked = ((d['selected'] as List<dynamic>?) ?? const [])
        .map((e) => (e as num).toInt())
        .toSet();

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(correct ? Icons.check_circle : Icons.cancel,
                size: 18,
                color: correct ? AppColors.success : AppColors.error),
            const SizedBox(width: 8),
            Expanded(
                child: Text(
                    'Q${widget.index + 1} · ${d['subject'] ?? ''}'
                    '${d['topic'] != null ? ' · ${d['topic']}' : ''}',
                    style: AppTheme.mono(10, FontWeight.w600, ls: 0.5))),
          ]),
          const SizedBox(height: 8),
          MixedMathText(d['prompt'] as String? ?? '', fontSize: 15),
          const SizedBox(height: 10),
          for (final (i, o) in options.indexed)
            _optionRow(i, o, picked.contains(i),
                o['correct'] as bool? ?? false),
          const SizedBox(height: 10),
          InkWell(
            onTap: _explain,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.4)),
              ),
              child: Row(children: [
                const Icon(Icons.psychology_outlined,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                      correct ? 'Show worked solution' : 'How to solve this',
                      style: AppTheme.mono(11, FontWeight.w600,
                          color: AppColors.primary)),
                ),
                Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18, color: AppColors.primary),
              ]),
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 10),
            // Stored answer key / worked solution — instant, no AI wait.
            if (((d['solution'] as String?)?.trim() ?? '').isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: const Border(
                      left: BorderSide(color: AppColors.success, width: 3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('SOLUTION', AppColors.success),
                    const SizedBox(height: 6),
                    MixedMathText((d['solution'] as String).trim(),
                        fontSize: 14),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Row(children: [
                  SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 10),
                  Text('Generating explanation…'),
                ]),
              )
            else if (_aiError != null)
              Text(_aiError!,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.error))
            else if (_ai != null)
              _aiReport(context, _ai!),
          ],
        ],
      ),
    );
  }

  Widget _optionRow(int i, Map<String, dynamic> o, bool picked, bool isKey) {
    final letter = String.fromCharCode(65 + i);
    Color? bg;
    Color border = AppColors.outline;
    IconData? badge;
    Color badgeColor = AppColors.muted;
    if (isKey) {
      bg = AppColors.success.withValues(alpha: 0.10);
      border = AppColors.success.withValues(alpha: 0.5);
      badge = Icons.check_circle;
      badgeColor = AppColors.success;
    } else if (picked) {
      bg = AppColors.error.withValues(alpha: 0.10);
      border = AppColors.error.withValues(alpha: 0.5);
      badge = Icons.cancel;
      badgeColor = AppColors.error;
    }
    final why = (o['why'] as String?)?.trim() ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$letter.',
              style: AppTheme.mono(12, FontWeight.w700,
                  color: AppColors.onSurfaceVariant)),
          const SizedBox(width: 8),
          Expanded(
              child: MixedMathText(o['text'] as String? ?? '', fontSize: 14)),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Icon(badge, size: 16, color: badgeColor),
          ],
          if (picked) ...[
            const SizedBox(width: 6),
            Text('YOU',
                style: AppTheme.mono(8, FontWeight.w700,
                    color: AppColors.onSurfaceVariant, ls: 0.5)),
          ],
        ]),
        // Why this option is right / wrong (from the stored answer key).
        if (why.isNotEmpty) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: MixedMathText(
                why.startsWith('is ') ? 'This option $why' : why,
                fontSize: 12.5,
                color: isKey ? AppColors.success : AppColors.muted),
          ),
        ],
      ]),
    );
  }

  Widget _aiReport(BuildContext context, Map<String, dynamic> ai) {
    final answer = ai['answer'] as String?;
    final hint = ai['hint'] as String?;
    final explanation = ai['explanation'] as String?;
    final steps =
        ((ai['steps'] as List<dynamic>?) ?? const []).map((e) => '$e').toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border(
            left: BorderSide(color: AppColors.primary, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.auto_awesome, size: 15, color: AppColors.primary),
            const SizedBox(width: 6),
            Text('AI TUTOR',
                style: AppTheme.mono(10, FontWeight.w700,
                    color: AppColors.primary, ls: 1)),
          ]),
          if (hint != null && hint.isNotEmpty) ...[
            const SizedBox(height: 12),
            _label('HINT', AppColors.secondary),
            const SizedBox(height: 4),
            MixedMathText(hint, fontSize: 14),
          ],
          if (answer != null && answer.isNotEmpty) ...[
            const SizedBox(height: 12),
            _label('ANSWER', AppColors.success),
            const SizedBox(height: 4),
            MixedMathText(answer, fontSize: 14),
          ],
          if (steps.isNotEmpty) ...[
            const SizedBox(height: 12),
            _label('STEP-BY-STEP', AppColors.primary),
            const SizedBox(height: 6),
            for (final (n, step) in steps.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Text('${n + 1}',
                            style: AppTheme.mono(10, FontWeight.w700,
                                color: AppColors.primary)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: MixedMathText(step, fontSize: 14)),
                    ]),
              ),
          ],
          if (explanation != null && explanation.isNotEmpty) ...[
            const SizedBox(height: 8),
            _label('WHY', AppColors.onSurfaceVariant),
            const SizedBox(height: 4),
            MixedMathText(explanation, fontSize: 14),
          ],
        ],
      ),
    );
  }

  Widget _label(String t, Color c) =>
      Text(t, style: AppTheme.mono(9, FontWeight.w700, color: c, ls: 1));
}
