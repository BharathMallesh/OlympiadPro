import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../widgets/common.dart';

/// #5 — Proctoring incident detail: evidence timeline + moderator actions.
class IncidentReviewScreen extends StatelessWidget {
  const IncidentReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopRedirect(
      fallbackRoute: '/live/console',
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => popOrGo(context, '/live/console')),
          titleSpacing: 0,
          title: Text('Incident Review',
              style: Theme.of(context).textTheme.titleLarge),
          actions: [
            StatusChip('Open', color: AppColors.error, filled: true),
            const SizedBox(width: 14),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Candidate summary
                  AppCard(
                    accentTop: AppColors.error,
                    child: Row(children: [
                      const InitialsAvatar('Maya Wong',
                          size: 52, color: AppColors.error),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Maya Wong',
                                style: Theme.of(context).textTheme.headlineSmall),
                            Text('ID: 3318-A · JEE Advanced: Phase 1 Mock · Q12/50',
                                style: AppTheme.mono(10, FontWeight.w500)),
                          ],
                        ),
                      ),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('RISK SCORE', style: AppTheme.mono(9, FontWeight.w500)),
                        Text('HIGH',
                            style: AppTheme.mono(18, FontWeight.w700,
                                color: AppColors.error)),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 20),

                  const SectionTitle('Evidence Timeline',
                      icon: Icons.timeline, color: AppColors.error),
                  const SizedBox(height: 8),
                  for (final (time, event, severity, color) in const [
                    ('14:52:08', 'Tab switch detected — left exam window for 4.2s',
                        'HIGH', AppColors.error),
                    ('14:52:14', 'Returned to exam window', 'INFO', AppColors.muted),
                    ('14:58:31', 'Second tab switch — 11.7s away', 'HIGH', AppColors.error),
                    ('15:01:02', 'Face not visible in frame for 8s', 'MEDIUM',
                        AppColors.secondary),
                  ])
                    _TimelineRow(time: time, event: event, severity: severity, color: color),
                  const SizedBox(height: 20),

                  const SectionTitle('Captured Frames', icon: Icons.photo_library_outlined),
                  const SizedBox(height: 8),
                  Row(children: [
                    for (var i = 0; i < 3; i++) ...[
                      Expanded(
                        child: Container(
                          height: 90,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: AppColors.outline),
                          ),
                          child: const Icon(Icons.image_outlined,
                              color: AppColors.outlineStrong, size: 28),
                        ),
                      ),
                      if (i < 2) const SizedBox(width: 10),
                    ],
                  ]),
                  const SizedBox(height: 24),

                  // Moderator actions
                  AppCard(
                    color: AppColors.surfaceContainer,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle('Moderator Actions',
                            icon: Icons.gavel_outlined),
                        const SizedBox(height: 12),
                        Wrap(spacing: 12, runSpacing: 12, children: [
                          AppButton('Dismiss — False Positive',
                              kind: AppBtnKind.ghost,
                              icon: Icons.check,
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Incident dismissed. Candidate unflagged.')));
                                popOrGo(context, '/live/console');
                              }),
                          AppButton('Issue Warning',
                              kind: AppBtnKind.secondary,
                              icon: Icons.warning_amber,
                              onPressed: () => ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                      content: Text(
                                          'Warning sent to candidate screen.')))),
                          AppButton('Terminate Attempt',
                              kind: AppBtnKind.danger,
                              icon: Icons.block,
                              onPressed: () => showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: AppColors.surfaceHigh,
                                      title: const Text('Terminate attempt?'),
                                      content: const Text(
                                          "Maya Wong's exam will end immediately and "
                                          'be flagged for academic review. This cannot '
                                          'be undone.'),
                                      actions: [
                                        TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text('Cancel')),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            popOrGo(context, '/live/console');
                                          },
                                          child: const Text('Terminate',
                                              style: TextStyle(
                                                  color: AppColors.error)),
                                        ),
                                      ],
                                    ),
                                  )),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.time, required this.event,
    required this.severity, required this.color,
  });
  final String time, event, severity;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(time, style: AppTheme.mono(11, FontWeight.w600)),
            const SizedBox(width: 12),
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 8, height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Text(event, style: Theme.of(context).textTheme.bodyMedium)),
            const SizedBox(width: 8),
            StatusChip(severity, color: color),
          ],
        ),
      );
}
