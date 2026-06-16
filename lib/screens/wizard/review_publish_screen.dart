import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/stores.dart';
import '../../data/repo.dart';
import '../../widgets/common.dart';

class ReviewPublishScreen extends StatefulWidget {
  const ReviewPublishScreen({super.key});
  @override
  State<ReviewPublishScreen> createState() => _ReviewPublishScreenState();
}

class _ReviewPublishScreenState extends State<ReviewPublishScreen> {
  bool _confirmed = false;
  bool _publishing = false;

  /// Creates the exam on the backend, attaches the reviewed questions,
  /// targets the selected classes, and (optionally) publishes.
  Future<void> _persistExam({required bool publish}) async {
    if (_publishing) return;
    setState(() => _publishing = true);
    final d = examDraft;
    try {
      if (d.title.trim().isEmpty) {
        throw 'Exam title is missing — set it in step 1.';
      }
      final exam = await Repo.createExam(
        title: d.title.trim(),
        board: d.board,
        description: d.description,
        format: d.format,
        durationMin: d.duration,
      );
      d.examId = exam['id'] as String;

      final items = <Map<String, dynamic>>[];
      var pos = 1;
      for (final q in questionStore.questions) {
        if (q.id != null) {
          items.add({'question_id': q.id, 'position': pos, 'marks': q.marks});
          pos++;
        }
      }
      if (items.isNotEmpty) await Repo.setExamQuestions(d.examId!, items);

      final classIds = [
        for (final name in d.targetClasses)
          if (d.classIdsByName[name] != null) d.classIdsByName[name]!
      ];
      if (classIds.isNotEmpty) await Repo.setExamTargets(d.examId!, classIds);

      if (publish) {
        if (classIds.isEmpty) {
          throw 'Select at least one target class before publishing.';
        }
        await Repo.publishExam(d.examId!);
      }

      d.questions = items.length;
      d.marks = items.fold(0, (a, b) => a + (b['marks'] as int));
      if (mounted) context.go(publish ? '/wizard/success' : '/dashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopRedirect(
      fallbackRoute: '/wizard/finalize',
      child: Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('OlympiadPro',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text('WIZARD: REVIEW & PUBLISH',
                  style: AppTheme.mono(11, FontWeight.w600, ls: 1)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text('STEP 5 OF 5',
                            style: AppTheme.mono(12, FontWeight.w600,
                                color: AppColors.onSurfaceVariant, ls: 1.5)),
                        const Spacer(),
                        Text('FINALIZING',
                            style: AppTheme.mono(12, FontWeight.w600,
                                color: AppColors.onSurfaceVariant, ls: 1.5)),
                      ]),
                      const SizedBox(height: 12),
                      const ProgressLine(1.0, height: 5),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (final (label, active) in const [
                            ('CONFIG', false), ('QUESTIONS', false),
                            ('SETTINGS', false), ('REVIEW', true),
                          ])
                            Text(label,
                                style: AppTheme.mono(10, FontWeight.w600,
                                    color: active ? AppColors.primary : AppColors.muted,
                                    ls: 1)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Hero summary
                      AppCard(
                        accentTop: AppColors.primary,
                        color: AppColors.surfaceContainer,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  StatusChip('Verification Pending',
                                      color: AppColors.onSurfaceVariant),
                                  const SizedBox(height: 14),
                                  Text(
                                      examDraft.title.isEmpty
                                          ? 'Untitled Exam'
                                          : examDraft.title,
                                      style: Theme.of(context).textTheme.headlineMedium),
                                  const SizedBox(height: 8),
                                  Text(
                                      'Final validation of the examination structure, '
                                      'targeting parameters, and question distribution '
                                      'for the upcoming JEE simulation.',
                                      style: Theme.of(context).textTheme.bodyMedium),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Icon(Icons.fact_check_outlined,
                                size: 56, color: AppColors.outlineStrong),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Expandable sections
                      _Section(
                        icon: Icons.info_outline,
                        title: 'Primary Information',
                        initiallyExpanded: true,
                        child: Row(children: [
                          _KV('Board', examDraft.board),
                          _KV('Duration', '${examDraft.duration} mins'),
                          _KV('Category', examDraft.format),
                        ]),
                      ),
                      _Section(
                        icon: Icons.groups_outlined,
                        iconColor: AppColors.success,
                        title: 'Targeting & Audience',
                        child: Row(children: [
                          _KV('Classes',
                              '${examDraft.targetClasses.length} selected'),
                          _KV('Total Reach', '${examDraft.reach} students'),
                          const _KV('Mode', 'All'),
                        ]),
                      ),
                      _Section(
                        icon: Icons.quiz_outlined,
                        title: 'Question Bank Summary',
                        trailing:
                            '${questionStore.questions.length} QUESTIONS · '
                            '${questionStore.questions.fold(0, (a, q) => a + q.marks)} MARKS',
                        child: Row(children: [
                          _KV('Parsed',
                              '${questionStore.questions.where((q) => q.id != null).length}'),
                          _KV('Needs Review',
                              '${questionStore.questions.where((q) => q.warning != null).length}'),
                          _KV('With Images',
                              '${questionStore.questions.where((q) => q.imageUrls.isNotEmpty).length}'),
                        ]),
                      ),
                      const SizedBox(height: 20),

                      // Confirmation
                      InkWell(
                        onTap: () => setState(() => _confirmed = !_confirmed),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _confirmed,
                              activeColor: AppColors.primary,
                              checkColor: AppColors.onPrimary,
                              onChanged: (v) => setState(() => _confirmed = v ?? false),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(
                                    'I confirm that this examination paper adheres to the '
                                    'internal academic standards of OlympiadPro and follows '
                                    'the JEE curriculum guidelines. I acknowledge that '
                                    'publishing this exam will notify all registered '
                                    'candidates in the selected categories.',
                                    style: Theme.of(context).textTheme.bodyMedium),
                              ),
                            ),
                          ],
                        ),
                      ),
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
              child: LayoutBuilder(builder: (context, c) {
                final tight = c.maxWidth < 720;
                final back = AppButton('Back to Settings',
                    kind: AppBtnKind.ghost,
                    icon: Icons.chevron_left,
                    onPressed: () => context.go('/wizard/finalize'));
                final draft = AppButton(
                    _publishing ? 'Saving…' : 'Save Draft',
                    kind: AppBtnKind.ghost,
                    onPressed: () => _persistExam(publish: false));
                final publish = AppButton(
                    _publishing ? 'Publishing…' : 'Publish Exam',
                    kind: AppBtnKind.secondary,
                    trailingIcon: Icons.rocket_launch_outlined,
                    onPressed:
                        _confirmed ? () => _persistExam(publish: true) : null);
                if (!tight) {
                  return Row(children: [back, const Spacer(), draft,
                      const SizedBox(width: 12), publish]);
                }
                return Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(children: [back, const Spacer(), draft]),
                  const SizedBox(height: 10),
                  SizedBox(width: double.infinity, child: publish),
                ]);
              }),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon, required this.title, required this.child,
    this.iconColor = AppColors.primary, this.trailing,
    this.initiallyExpanded = false,
  });
  final IconData icon;
  final String title;
  final Widget child;
  final Color iconColor;
  final String? trailing;
  final bool initiallyExpanded;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: initiallyExpanded,
            iconColor: AppColors.muted,
            collapsedIconColor: AppColors.muted,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: Icon(icon, size: 18, color: iconColor),
            title: Row(children: [
              Expanded(
                child: Text(title.toUpperCase(),
                    style: AppTheme.mono(12, FontWeight.w600,
                        color: AppColors.onSurface, ls: 0.8)),
              ),
              if (trailing != null)
                Text(trailing!,
                    style: AppTheme.mono(10.5, FontWeight.w500, color: AppColors.muted)),
            ]),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [child],
          ),
        ),
      ),
    );
  }
}

class _KV extends StatelessWidget {
  const _KV(this.k, this.v);
  final String k, v;
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FieldLabel(k),
            Text(v,
                style: AppTheme.mono(18, FontWeight.w700, color: AppColors.onSurface)),
          ],
        ),
      );
}
