import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/mock.dart';
import '../../widgets/common.dart';

class FinalizeSettingsScreen extends StatelessWidget {
  const FinalizeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    return PopRedirect(
      fallbackRoute: '/wizard/ai-review',
      child: Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
            icon: const Icon(Icons.menu), onPressed: () => context.go('/dashboard')),
        title: Text('OlympiadPro',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PUBLISHING FLOW',
                          style: AppTheme.mono(12, FontWeight.w600,
                              color: AppColors.secondary, ls: 1.5)),
                      const SizedBox(height: 6),
                      Text('Step 3: Finalize Exam',
                          style: Theme.of(context).textTheme.headlineLarge),
                      const SizedBox(height: 24),
                      Flex(
                        direction: wide ? Axis.horizontal : Axis.vertical,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: wide ? 3 : 0,
                            child: AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Summary block
                                  Text(examDraft.title.isEmpty
                                      ? 'Advanced Physics - JEE Mock 1'
                                      : examDraft.title,
                                      style: Theme.of(context).textTheme.titleLarge),
                                  const SizedBox(height: 4),
                                  Text('${examDraft.board} · ${examDraft.questions} questions · ${examDraft.marks} marks',
                                      style: Theme.of(context).textTheme.bodyMedium),
                                  const SizedBox(height: 20),
                                  const Divider(),
                                  const SizedBox(height: 20),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceContainer,
                                      borderRadius: BorderRadius.circular(AppRadius.lg),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(children: [
                                          const Icon(Icons.calendar_month_outlined,
                                              size: 16, color: AppColors.primary),
                                          const SizedBox(width: 8),
                                          Text('SCHEDULING',
                                              style: AppTheme.mono(11, FontWeight.w600,
                                                  color: AppColors.primary, ls: 1)),
                                        ]),
                                        const SizedBox(height: 16),
                                        Row(children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: const [
                                                FieldLabel('Start Date'),
                                                _MiniField('25/11/2024', Icons.calendar_today_outlined),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: const [
                                                FieldLabel('Start Time (EST)'),
                                                _MiniField('09:00 AM', Icons.schedule),
                                              ],
                                            ),
                                          ),
                                        ]),
                                        const SizedBox(height: 12),
                                        Text(
                                            'Students will see a countdown timer 24 hours prior to the start time.',
                                            style: Theme.of(context).textTheme.bodySmall
                                                ?.copyWith(fontStyle: FontStyle.italic)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: wide ? 20 : 0, height: wide ? 0 : 16),
                          Expanded(
                            flex: wide ? 2 : 0,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                                border: Border.all(
                                    color: AppColors.success.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.lightbulb_outline,
                                      color: AppColors.success, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text.rich(TextSpan(
                                      style: Theme.of(context).textTheme.bodyMedium,
                                      children: const [
                                        TextSpan(text: 'Pro-tip: Publishing an exam generates a unique '),
                                        TextSpan(
                                            text: 'EXAM_KEY',
                                            style: TextStyle(
                                                fontFamily: 'monospace',
                                                color: AppColors.success)),
                                        TextSpan(text: ' that you can share directly with candidates.'),
                                      ],
                                    )),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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
                final back = AppButton('Back to Questions',
                    kind: AppBtnKind.ghost,
                    icon: Icons.chevron_left,
                    onPressed: () => context.go('/wizard/ai-review'));
                final draft = AppButton('Save as Draft', kind: AppBtnKind.ghost,
                    icon: Icons.save_outlined,
                    onPressed: () => context.go('/dashboard'));
                final publish = AppButton('Review & Publish',
                    kind: AppBtnKind.secondary,
                    trailingIcon: Icons.rocket_launch_outlined,
                    onPressed: () => context.go('/wizard/review'));
                if (!tight) {
                  return Row(children: [back, const Spacer(), draft,
                      const SizedBox(width: 12), publish]);
                }
                // Phone: primary publish action gets a full-width row of its
                // own so it's never clipped; secondary actions sit above.
                return Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(children: [
                    back,
                    const Spacer(),
                    draft,
                  ]),
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

class _MiniField extends StatelessWidget {
  const _MiniField(this.value, this.icon);
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.scaffold,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.outlineStrong),
        ),
        child: Row(children: [
          Expanded(child: Text(value, style: const TextStyle(color: AppColors.onSurface))),
          Icon(icon, size: 15, color: AppColors.muted),
        ]),
      );
}
