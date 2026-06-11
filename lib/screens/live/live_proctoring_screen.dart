import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../widgets/common.dart';

class LiveProctoringScreen extends StatelessWidget {
  const LiveProctoringScreen({super.key});

  static const _candidates = <(String, String, String, double, String)>[
    ('Aracelai S.', '1129-A', 'In Progress', 0.62, ''),
    ('Sarah Jin', '2210-X', 'In Progress', 0.40, ''),
    ('Rohan R.', '3318-T', 'In Progress', 0.55, ''),
    ('Leo S.', '4892-X', 'Submitted', 1.0, ''),
    ('Vikram Das', '5512-K', 'In Progress', 0.48, ''),
    ('Elena K.', '6029-P', 'In Progress', 0.71, ''),
    ('Unknown User', '----', 'Flagged', 0.30, 'Multiple Faces Detected'),
    ('Jenna Wang', '7741-M', 'In Progress', 0.66, ''),
  ];

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
        title: Text('OlympiadPro Console',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
        actions: [
          AppButton('Broadcast Alert',
              kind: AppBtnKind.ghost, icon: Icons.campaign_outlined, onPressed: () {}),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('JEE Advanced: Phase 1 Mock',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text('Mathematics & Physics · Commenced 14:45',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              StatusChip('Active Phase', color: AppColors.success, icon: Icons.circle),
            ]),
            const SizedBox(height: 16),
            // Quick metrics
            Wrap(spacing: 12, runSpacing: 12, children: [
              _mini('124 Live', AppColors.primary, Icons.person),
              _mini('2 Alerts', AppColors.error, Icons.warning_amber),
              _mini('20/45 Time', AppColors.secondary, Icons.timer_outlined),
              _mini('99.2% Integrity', AppColors.success, Icons.shield_outlined),
            ]),
            const SizedBox(height: 20),
            Text('Proctoring Grid',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            LayoutBuilder(builder: (context, c) {
              final cross = c.maxWidth >= 1000
                  ? 4
                  : c.maxWidth >= 700
                      ? 3
                      : c.maxWidth >= 460
                          ? 2
                          : 1;
              return GridView.count(
                crossAxisCount: cross,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.82,
                children: [
                  for (final cand in _candidates) _ProctorTile(cand: cand),
                ],
              );
            }),
          ],
        ),
      ),
    ),
    );
  }

  Widget _mini(String text, Color color, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Text(text, style: AppTheme.mono(12, FontWeight.w600, color: AppColors.onSurface)),
        ]),
      );
}

class _ProctorTile extends StatelessWidget {
  const _ProctorTile({required this.cand});
  final (String, String, String, double, String) cand;
  @override
  Widget build(BuildContext context) {
    final (name, id, status, progress, alert) = cand;
    final flagged = status == 'Flagged';
    final submitted = status == 'Submitted';
    final accent = flagged
        ? AppColors.error
        : submitted
            ? AppColors.success
            : AppColors.teal;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
            color: flagged ? AppColors.error : AppColors.outline,
            width: flagged ? 1.5 : 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // "Webcam" feed area
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: Colors.black,
                  child: Icon(
                      flagged ? Icons.no_photography_outlined : Icons.videocam_outlined,
                      color: flagged ? AppColors.error : AppColors.outlineStrong,
                      size: 30),
                ),
                if (alert.isNotEmpty)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      color: AppColors.error.withValues(alpha: 0.85),
                      child: Text(alert,
                          textAlign: TextAlign.center,
                          style: AppTheme.mono(9, FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                Positioned(
                  top: 8, left: 8,
                  child: Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                  ),
                ),
                if (submitted)
                  Positioned(
                    top: 8, right: 8,
                    child: StatusChip('Submitted', color: AppColors.success, filled: true),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: Theme.of(context).textTheme.bodyLarge
                        ?.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
                Text('ID: $id', style: AppTheme.mono(9, FontWeight.w500)),
                const SizedBox(height: 8),
                ProgressLine(progress, color: accent, height: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
