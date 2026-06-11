import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/store.dart';
import '../../widgets/common.dart';
import '../../widgets/math_text.dart';

class ExamQuestionScreen extends StatefulWidget {
  const ExamQuestionScreen({super.key});
  @override
  State<ExamQuestionScreen> createState() => _ExamQuestionScreenState();
}

class _ExamQuestionScreenState extends State<ExamQuestionScreen> {
  static const _total = 18;
  static const _options = [r'\pi^2 / 2', r'\pi^2 / 4'];

  int _question = 1;
  final Map<int, int> _answers = {};
  final Set<int> _marked = {};

  int? get _selected => _answers[_question];
  bool get _isMarked => _marked.contains(_question);

  @override
  void initState() {
    super.initState();
    // #14 — restore autosaved progress if a previous attempt was interrupted.
    final saved = AppStore.loadExamProgress();
    if (saved != null) {
      _question = saved.question;
      _answers.addAll(saved.answers);
      _marked.addAll(saved.marked);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Resumed from autosave - your previous answers were restored.')));
        }
      });
    }
  }

  void _autosave() => AppStore.saveExamProgress(
      question: _question, answers: _answers, marked: _marked);

  void _jumpTo(int q) {
    setState(() => _question = q);
    _autosave();
  }

  void _next() {
    if (_question >= _total) {
      _submit();
      return;
    }
    setState(() => _question++);
    _autosave();
  }

  /// #8 - question palette bottom sheet.
  void _showPalette() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceHigh,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Question Palette',
                style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 6),
            Wrap(spacing: 14, children: [
              _legend('Answered', AppColors.success),
              _legend('Marked', AppColors.secondary),
              _legend('Unseen', AppColors.surfaceHighest),
            ]),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 6,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                for (var q = 1; q <= _total; q++)
                  InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      _jumpTo(q);
                    },
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _marked.contains(q)
                            ? AppColors.secondaryStrong.withValues(alpha: 0.3)
                            : _answers.containsKey(q)
                                ? AppColors.success.withValues(alpha: 0.25)
                                : AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(
                            color: q == _question
                                ? AppColors.primary
                                : _marked.contains(q)
                                    ? AppColors.secondary
                                    : _answers.containsKey(q)
                                        ? AppColors.success
                                        : AppColors.outline,
                            width: q == _question ? 2 : 1),
                      ),
                      child: Text('$q',
                          style: AppTheme.mono(13, FontWeight.w600,
                              color: AppColors.onSurface)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  Widget _legend(String label, Color color) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 10, height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: AppTheme.mono(9, FontWeight.w500)),
      ]);

  void _submit() {
    final answered = _answers.length;
    final marked = _marked.length;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        title: const Text('Submit Exam?'),
        content: Text(
            'Answered: $answered / $_total\n'
            'Marked for review: $marked\n'
            'Unanswered: ${_total - answered}\n\n'
            'Once submitted, answers cannot be changed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Keep Working')),
          TextButton(
            onPressed: () {
              AppStore.clearExamProgress();
              AppStore.resultsPublished = false;
              Navigator.pop(ctx);
              context.go('/student/exam-analysis');
            },
            child: const Text('Submit',
                style: TextStyle(color: AppColors.secondary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopRedirect(
      fallbackRoute: '/student/hub',
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          leading: const Icon(Icons.menu_book_outlined, color: AppColors.primary),
          titleSpacing: 0,
          title: Text('JEE Advanced: Paper 1',
              style: Theme.of(context).textTheme.titleLarge),
          actions: [
            IconButton(
              tooltip: 'Question palette',
              onPressed: _showPalette,
              icon: const Icon(Icons.grid_view, size: 20),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppColors.tealStrong.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text('01:42:09',
                  style: AppTheme.mono(13, FontWeight.w700, color: AppColors.teal)),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(44),
            child: Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.outline)),
              ),
              child: Row(children: [
                _SubjectTab('PHYSICS', selected: false),
                _SubjectTab('MATHEMATICS', selected: true),
                _SubjectTab('CHEMISTRY', selected: false),
              ]),
            ),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryStrong.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text('Q$_question',
                          style: AppTheme.mono(12, FontWeight.w700,
                              color: AppColors.primary)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('SINGLE CORRECT TYPE',
                          style: AppTheme.mono(11, FontWeight.w600,
                              color: AppColors.onSurface, ls: 1)),
                    ),
                    const Icon(Icons.translate, size: 16, color: AppColors.muted),
                    const SizedBox(width: 10),
                    const Icon(Icons.info_outline, size: 16, color: AppColors.muted),
                  ]),
                  const SizedBox(height: 4),
                  Text('+4 / -1 Marks',
                      style: AppTheme.mono(10, FontWeight.w500,
                          color: AppColors.success)),
                  const SizedBox(height: 16),
                  Text('If the definite integral I is defined as',
                      style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 12),
                  // LaTeX block on the void panel
                  const MathPanel(
                      r'I = \int_{0}^{\pi} \frac{x\,\sin(x)}{1+\cos^2(x)}\,dx',
                      fontSize: 18, center: true),
                  const SizedBox(height: 12),
                  Text('then find the value of I.',
                      style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 16),
                  // Figure panel
                  Container(
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: Stack(children: [
                      const Center(
                          child: Icon(Icons.show_chart,
                              color: AppColors.primaryStrong, size: 40)),
                      Positioned(
                        left: 12, bottom: 12,
                        child: Text('FIGURE 14.1: FUNCTION VISUALIZATION',
                            style: AppTheme.mono(9, FontWeight.w600, ls: 1)),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  for (var i = 0; i < _options.length; i++)
                    _OptionCard(
                      letter: String.fromCharCode(65 + i),
                      latex: _options[i],
                      selected: _selected == i,
                      onTap: () {
                        setState(() => _answers[_question] = i);
                        _autosave();
                      },
                    ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            border: Border(top: BorderSide(color: AppColors.outline)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(children: [
                _ToolAction(
                  icon: _isMarked ? Icons.bookmark : Icons.bookmark_outline,
                  label: 'MARK REVIEW',
                  color: _isMarked ? AppColors.secondary : AppColors.muted,
                  onTap: () {
                    setState(() => _isMarked
                        ? _marked.remove(_question)
                        : _marked.add(_question));
                    _autosave();
                  },
                ),
                const SizedBox(width: 16),
                _ToolAction(
                  icon: Icons.backspace_outlined,
                  label: 'CLEAR',
                  color: AppColors.muted,
                  onTap: () {
                    setState(() => _answers.remove(_question));
                    _autosave();
                  },
                ),
                const Spacer(),
                AppButton(
                    _question >= _total ? 'Submit Exam' : 'Save & Next',
                    kind: AppBtnKind.primary,
                    onPressed: _next),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _SubjectTab extends StatelessWidget {
  const _SubjectTab(this.label, {required this.selected});
  final String label;
  final bool selected;
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppColors.teal : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Center(
            child: Text(label,
                style: AppTheme.mono(10, FontWeight.w600,
                    color: selected ? AppColors.teal : AppColors.muted, ls: 1)),
          ),
        ),
      );
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.letter, required this.latex,
    required this.selected, required this.onTap,
  });
  final String letter, latex;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primaryStrong.withValues(alpha: 0.12)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
                color: selected ? AppColors.primary : AppColors.outline,
                width: selected ? 1.5 : 1),
          ),
          child: Row(children: [
            Container(
              width: 30, height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.scaffold,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                    color: selected ? AppColors.primary : AppColors.outlineStrong),
              ),
              child: Text(letter,
                  style: AppTheme.mono(13, FontWeight.w700,
                      color: selected ? AppColors.primary : AppColors.muted)),
            ),
            const SizedBox(width: 14),
            Expanded(child: MathText(latex, fontSize: 16)),
            if (selected)
              const Icon(Icons.check_circle, size: 20, color: AppColors.primary),
          ]),
        ),
      ),
    );
  }
}

class _ToolAction extends StatelessWidget {
  const _ToolAction({
    required this.icon, required this.label,
    required this.color, required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 3),
            Text(label, style: AppTheme.mono(8, FontWeight.w600, color: color)),
          ]),
        ),
      );
}
