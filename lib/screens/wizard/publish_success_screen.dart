import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/api.dart';
import '../../widgets/common.dart';

class PublishSuccessScreen extends StatelessWidget {
  const PublishSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    return PopRedirect(
      fallbackRoute: '/dashboard',
      child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('OlympiadPro Console',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
        actions: [
          Text(api.displaySubtitle ?? 'Educator',
              style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          const SizedBox(width: 12),
          InitialsAvatar(api.displayName ?? 'Educator', size: 32),
          const SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: Center(
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                          color: AppColors.success, shape: BoxShape.circle),
                      child: const Icon(Icons.check, color: AppColors.onSuccess, size: 28),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Exam Published Successfully!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 10),
                Text(
                    'The mock examination has been processed and distributed to the '
                    'candidate pool. All proctoring nodes are now on standby.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 28),
                Flex(
                  direction: wide ? Axis.horizontal : Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: wide ? 3 : 0,
                      child: AppCard(
                        accentTop: AppColors.success,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('EXAM IDENTIFIER',
                                style: AppTheme.mono(11, FontWeight.w600,
                                    color: AppColors.success, ls: 1)),
                            const SizedBox(height: 8),
                            Text('Advanced Physics - JEE Mock 1',
                                style: Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 16),
                            Row(children: const [
                              _Meta('Subject Domain', 'Physics', Icons.science_outlined),
                              SizedBox(width: 24),
                              _Meta('Exam Board', 'JEE', Icons.account_balance_outlined),
                            ]),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: wide ? 16 : 0, height: wide ? 0 : 16),
                    Expanded(
                      flex: wide ? 2 : 0,
                      child: AppCard(
                        color: AppColors.surfaceContainer,
                        child: Column(children: [
                          const Icon(Icons.groups, color: AppColors.primary, size: 28),
                          const SizedBox(height: 8),
                          Text('450',
                              style: AppTheme.mono(40, FontWeight.w700,
                                  color: AppColors.primary, ls: -1)),
                          Text('STUDENTS NOTIFIED',
                              style: AppTheme.mono(10, FontWeight.w500, ls: 0.8)),
                        ]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    AppButton('Go to Live Console',
                        kind: AppBtnKind.secondary,
                        icon: Icons.sensors,
                        onPressed: () => context.go('/live/console')),
                    AppButton('Share via Link',
                        kind: AppBtnKind.ghost,
                        icon: Icons.share_outlined,
                        onPressed: () {}),
                    AppButton('Back to Dashboard',
                        kind: AppBtnKind.ghost,
                        icon: Icons.arrow_back,
                        onPressed: () => context.go('/dashboard')),
                  ],
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

class _Meta extends StatelessWidget {
  const _Meta(this.label, this.value, this.icon);
  final String label, value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: AppTheme.mono(9.5, FontWeight.w500, ls: 0.8)),
          const SizedBox(height: 4),
          Row(children: [
            Icon(icon, size: 14, color: AppColors.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ]),
        ],
      );
}
