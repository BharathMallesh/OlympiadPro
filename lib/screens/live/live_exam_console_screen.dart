import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/mock.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/common.dart';

class LiveExamConsoleScreen extends StatelessWidget {
  const LiveExamConsoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      brand: 'OlympiadPro',
      currentRoute: '/live/console',
      titleWidget: Row(children: [
        StatusChip('Physics · Deep Teal', color: AppColors.teal),
        const SizedBox(width: 12),
        Text('Live Exam Console',
            style: Theme.of(context).textTheme.titleLarge),
      ]),
      title: 'Live Exam Console',
      actions: [
        AppButton('Terminate Session',
            kind: AppBtnKind.danger, icon: Icons.stop_circle_outlined,
            onPressed: () => context.go('/dashboard')),
        const SizedBox(width: 12),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Live metrics
            LayoutBuilder(builder: (context, c) {
              final cross = c.maxWidth >= 900 ? 4 : (c.maxWidth >= 500 ? 2 : 1);
              return GridView.count(
                crossAxisCount: cross,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 2.4,
                children: const [
                  StatBlock(label: 'Live Participants', value: '124', delta: '/ 450',
                      deltaColor: AppColors.muted, valueColor: AppColors.primary),
                  StatBlock(label: 'Average Progress', value: '45%',
                      valueColor: AppColors.teal),
                  StatBlock(label: 'Submissions', value: '12', delta: 'Target: 450',
                      deltaColor: AppColors.muted, valueColor: AppColors.success),
                  StatBlock(label: 'Time Remaining', value: '01:42:09',
                      valueColor: AppColors.secondary, icon: Icons.timer_outlined),
                ],
              );
            }),
            const SizedBox(height: 24),

            // Active candidates table
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      const Expanded(
                          child: SectionTitle('Active Candidates',
                              icon: Icons.monitor_heart_outlined)),
                      SizedBox(
                        width: 200,
                        child: AppInput(hint: 'Search ID or Name', icon: Icons.search),
                      ),
                    ]),
                  ),
                  const Divider(height: 1),
                  // Five-column table on wide screens; stacked cards on phones
                  // where the columns wouldn't fit.
                  if (!isCompact(context)) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      color: AppColors.surfaceContainer,
                      child: Row(children: const [
                        Expanded(flex: 3, child: _H('Candidate')),
                        Expanded(flex: 2, child: _H('Status')),
                        Expanded(flex: 2, child: _H('Current Q')),
                        Expanded(flex: 2, child: _H('Proctor Alerts')),
                        Expanded(flex: 2, child: _H('Action')),
                      ]),
                    ),
                    for (final (name, id, status, q) in Mock.liveCandidates)
                      _CandidateRow(name: name, id: id, status: status, question: q),
                  ] else
                    for (final (name, id, status, q) in Mock.liveCandidates)
                      _CandidateCard(name: name, id: id, status: status, question: q),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      Text('Showing 1-4 of 124 candidates',
                          style: Theme.of(context).textTheme.bodySmall),
                      const Spacer(),
                      IconButton(onPressed: () {},
                          icon: const Icon(Icons.chevron_left, size: 18)),
                      IconButton(onPressed: () => context.push('/live/proctoring'),
                          icon: const Icon(Icons.chevron_right, size: 18)),
                    ]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppButton('Open Proctoring Grid',
                kind: AppBtnKind.ghost,
                icon: Icons.grid_view_outlined,
                onPressed: () => context.push('/live/proctoring')),
          ],
        ),
      ),
    );
  }
}

class _H extends StatelessWidget {
  const _H(this.text);
  final String text;
  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: AppTheme.mono(10, FontWeight.w600, ls: 0.8));
}

class _CandidateRow extends StatelessWidget {
  const _CandidateRow({
    required this.name, required this.id, required this.status, required this.question,
  });
  final String name, id, status, question;

  (Color, IconData) get _statusStyle => switch (status) {
        'Flagged' => (AppColors.error, Icons.flag),
        'Submitted' => (AppColors.success, Icons.check_circle),
        _ => (AppColors.teal, Icons.play_circle_outline),
      };

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _statusStyle;
    final flagged = status == 'Flagged';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.outline)),
      ),
      child: Row(children: [
        Expanded(
          flex: 3,
          child: Row(children: [
            InitialsAvatar(name, size: 32, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                  Text('ID: $id', style: AppTheme.mono(9, FontWeight.w500)),
                ],
              ),
            ),
          ]),
        ),
        Expanded(
          flex: 2,
          child: Row(children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(status,
                  style: TextStyle(color: color, fontSize: 12),
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
        ),
        Expanded(
            flex: 2,
            child: Text(question,
                style: AppTheme.mono(12, FontWeight.w500, color: AppColors.onSurface))),
        Expanded(
          flex: 2,
          child: flagged
              ? StatusChip('Tab Switch', color: AppColors.error, filled: true)
              : Text('—', style: Theme.of(context).textTheme.bodyMedium),
        ),
        Expanded(
          flex: 2,
          child: flagged
              ? InkWell(
                  onTap: () => context.push('/live/incident'),
                  child: Text('Review',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppColors.secondary)))
              : const Text('—', style: TextStyle(color: AppColors.muted)),
        ),
      ]),
    );
  }
}

/// Stacked candidate layout used below the 600px breakpoint, where the
/// five-column table cannot fit.
class _CandidateCard extends StatelessWidget {
  const _CandidateCard({
    required this.name, required this.id, required this.status, required this.question,
  });
  final String name, id, status, question;

  @override
  Widget build(BuildContext context) {
    final flagged = status == 'Flagged';
    final submitted = status == 'Submitted';
    final color = flagged
        ? AppColors.error
        : submitted
            ? AppColors.success
            : AppColors.teal;
    final icon = flagged
        ? Icons.flag
        : submitted
            ? Icons.check_circle
            : Icons.play_circle_outline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.outline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            InitialsAvatar(name, size: 36, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                  Text('ID: $id', style: AppTheme.mono(9, FontWeight.w500)),
                ],
              ),
            ),
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(status, style: TextStyle(color: color, fontSize: 12)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Text(question,
                style: AppTheme.mono(12, FontWeight.w500, color: AppColors.onSurface)),
            const Spacer(),
            if (flagged) ...[
              StatusChip('Tab Switch', color: AppColors.error, filled: true),
              const SizedBox(width: 10),
              InkWell(
                  onTap: () => context.push('/live/incident'),
                  child: Text('Review',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppColors.secondary))),
            ],
          ]),
        ],
      ),
    );
  }
}
