import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../data/repo.dart';
import '../../widgets/common.dart';
import '../../widgets/math_text.dart';

/// Board-exam STUDY mode (not a quiz). The student browses their board's
/// content by subject → chapter, then reads each question WITH its answer and
/// worked solution shown, and can tap "Ask AI" on any doubt. Scoped to one board
/// (e.g. 2nd PUC / PUC) passed in from the hub.
class BoardStudyScreen extends StatefulWidget {
  const BoardStudyScreen({super.key, required this.board, required this.label});

  /// The board tag used to scope the bank (e.g. 'PUC', 'DHSE', 'HSC', 'CBSE').
  final String board;

  /// The friendly name shown in the header (e.g. '2nd PUC').
  final String label;

  @override
  State<BoardStudyScreen> createState() => _BoardStudyScreenState();
}

class _BoardStudyScreenState extends State<BoardStudyScreen> {
  bool _loading = true;
  String? _error;

  // subject -> ordered list of chapter names (from /practice/topics).
  final Map<String, List<String>> _byChapter = {};
  String? _subject;

  String? _chapter; // the chapter currently being studied
  bool _loadingCards = false;
  List<Map<String, dynamic>> _cards = const [];

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
      final rows = await Repo.practiceTopics(boards: [widget.board]);
      _byChapter.clear();
      for (final r in rows.cast<Map<String, dynamic>>()) {
        final subj = (r['subject'] as String?)?.trim() ?? 'General';
        final chap = (r['chapter'] as String?)?.trim() ?? 'General';
        final list = _byChapter.putIfAbsent(subj, () => []);
        if (!list.contains(chap)) list.add(chap);
      }
      if (!mounted) return;
      setState(() {
        _loading = false;
        _subject = _byChapter.keys.isNotEmpty ? _byChapter.keys.first : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openChapter(String chapter) async {
    setState(() {
      _chapter = chapter;
      _loadingCards = true;
      _cards = const [];
    });
    try {
      final rows = await Repo.studyQuestions(
          subject: _subject!, chapter: chapter, boards: [widget.board]);
      if (!mounted) return;
      setState(() {
        _cards = rows.cast<Map<String, dynamic>>();
        _loadingCards = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingCards = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_chapter == null ? 'Board Study' : _chapter!,
                style: Theme.of(context).textTheme.titleLarge),
            Text('${widget.label} · study mode',
                style: AppTheme.mono(9, FontWeight.w600, color: AppColors.gold)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Back out of a chapter to its list first, then leave the screen.
            if (_chapter != null) {
              setState(() {
                _chapter = null;
                _cards = const [];
              });
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
              : _chapter == null
                  ? _chapterBrowser()
                  : _studyList(),
    );
  }

  // ---- Browse: subject chips + chapter list ----
  Widget _chapterBrowser() {
    if (_byChapter.isEmpty) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No board content available yet.')));
    }
    final chapters = _subject == null ? const <String>[] : (_byChapter[_subject] ?? const []);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Text('PICK A CHAPTER TO STUDY',
              style: AppTheme.mono(10, FontWeight.w700, ls: 1)),
        ),
        // Subject selector.
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final s in _byChapter.keys)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(s),
                    selected: _subject == s,
                    onSelected: (_) => setState(() => _subject = s),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: chapters.length,
            separatorBuilder: (_, i) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) => AppCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                title: Text(chapters[i],
                    style: Theme.of(context).textTheme.bodyLarge),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openChapter(chapters[i]),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---- Study: Q + answer + solution cards ----
  Widget _studyList() {
    if (_loadingCards) return const Center(child: CircularProgressIndicator());
    if (_cards.isEmpty) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No questions in this chapter yet.')));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _cards.length,
      itemBuilder: (ctx, i) => _StudyCard(card: _cards[i], index: i),
    );
  }
}

/// One study card: question, options (correct highlighted), stored solution, and
/// an "Ask AI" action for a fuller worked explanation.
class _StudyCard extends StatefulWidget {
  const _StudyCard({required this.card, required this.index});
  final Map<String, dynamic> card;
  final int index;

  @override
  State<_StudyCard> createState() => _StudyCardState();
}

class _StudyCardState extends State<_StudyCard> {
  bool _askingAi = false;
  Map<String, dynamic>? _ai;
  String? _aiError;

  Future<void> _askAi() async {
    setState(() {
      _askingAi = true;
      _aiError = null;
    });
    try {
      final r = await Repo.explainQuestion(widget.card['id'] as String);
      if (!mounted) return;
      setState(() {
        _ai = r;
        _askingAi = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _aiError = e.toString();
        _askingAi = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.card;
    final options = (q['options'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final sol = (q['solution']?.toString() ?? '').trim();
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('Q${widget.index + 1}',
                style: AppTheme.mono(12, FontWeight.w700, color: AppColors.primary)),
            const Spacer(),
            if ((q['topic']?.toString() ?? '').isNotEmpty &&
                q['topic'] != 'General')
              Text(q['topic'].toString(),
                  style: AppTheme.mono(9, FontWeight.w500)),
          ]),
          const SizedBox(height: 8),
          MixedMathText(q['prompt']?.toString() ?? '', fontSize: 15),
          const SizedBox(height: 10),
          // Options — the correct one highlighted (study mode shows the answer).
          for (var i = 0; i < options.length; i++)
            _optionRow(context, options[i],
                correct: options[i]['correct'] == true, index: i),
          if (sol.isNotEmpty) ...[
            const SizedBox(height: 6),
            _expander(context, 'Solution', MixedMathText(sol, fontSize: 13)),
          ],
          const SizedBox(height: 6),
          // Ask AI for any doubt.
          if (_ai == null)
            Align(
              alignment: Alignment.centerLeft,
              child: AppButton(
                _askingAi ? 'Asking AI…' : 'Any doubt? Ask AI',
                kind: AppBtnKind.ghost,
                trailingIcon: Icons.auto_awesome,
                onPressed: _askingAi ? null : _askAi,
              ),
            ),
          if (_aiError != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Could not reach AI: $_aiError',
                  style: TextStyle(color: AppColors.error, fontSize: 12)),
            ),
          if (_ai != null) _aiBlock(context, _ai!),
        ],
      ),
    );
  }

  Widget _optionRow(BuildContext context, Map<String, dynamic> o,
      {required bool correct, required int index}) {
    final letter = String.fromCharCode(65 + index); // A, B, C, D
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: correct
            ? AppColors.success.withValues(alpha: 0.12)
            : AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
            color: correct ? AppColors.success : AppColors.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$letter. ',
              style: AppTheme.mono(12, FontWeight.w700,
                  color: correct ? AppColors.success : AppColors.muted)),
          Expanded(
              child: MixedMathText(o['text']?.toString() ?? '', fontSize: 13)),
          if (correct)
            const Icon(Icons.check_circle, size: 16, color: AppColors.success),
        ],
      ),
    );
  }

  Widget _aiBlock(BuildContext context, Map<String, dynamic> ai) {
    final answer = (ai['answer']?.toString() ?? '').trim();
    final explanation = (ai['explanation']?.toString() ?? '').trim();
    final steps = (ai['steps'] as List<dynamic>? ?? const [])
        .map((s) => s.toString())
        .toList();
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.auto_awesome, size: 14, color: AppColors.gold),
            const SizedBox(width: 6),
            Text('AI EXPLANATION',
                style: AppTheme.mono(10, FontWeight.w700, color: AppColors.gold)),
          ]),
          if (answer.isNotEmpty) ...[
            const SizedBox(height: 8),
            MixedMathText('Answer: $answer', fontSize: 13),
          ],
          for (var i = 0; i < steps.length; i++) ...[
            const SizedBox(height: 6),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${i + 1}. ', style: AppTheme.mono(12, FontWeight.w700)),
              Expanded(child: MixedMathText(steps[i], fontSize: 13)),
            ]),
          ],
          if (explanation.isNotEmpty) ...[
            const SizedBox(height: 8),
            MixedMathText(explanation, fontSize: 13),
          ],
        ],
      ),
    );
  }

  Widget _expander(BuildContext context, String title, Widget child) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        title: Text(title,
            style: AppTheme.mono(11, FontWeight.w700, color: AppColors.primary)),
        children: [Align(alignment: Alignment.centerLeft, child: child)],
      ),
    );
  }
}
