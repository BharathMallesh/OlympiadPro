import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/api.dart';
import '../../data/stores.dart';
import '../../widgets/common.dart';

class PublishSuccessScreen extends StatelessWidget {
  const PublishSuccessScreen({super.key});

  /// A deep link to the published exam that a student can open in the app.
  String? get _examLink {
    final id = examDraft.examId;
    if (id == null || id.isEmpty) return null;
    return '${ApiClient.baseUrl}/student/exam?exam=$id';
  }

  Future<void> _shareLink(BuildContext context) async {
    final link = _examLink;
    if (link == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Exam link is not available yet.')));
      return;
    }
    await Clipboard.setData(ClipboardData(text: link));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Exam link copied to clipboard')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    return PopRedirect(
      fallbackRoute: '/dashboard',
      child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Vidyora Console',
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
                    'Your exam has been published and is now available to the '
                    'assigned students. Share the link below or head back to your '
                    'dashboard to track submissions.',
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
                            Text(
                                examDraft.title.isEmpty
                                    ? 'Your exam'
                                    : examDraft.title,
                                style: Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 16),
                            Row(children: [
                              _Meta('Exam Board', examDraft.board,
                                  Icons.account_balance_outlined),
                              const SizedBox(width: 24),
                              _Meta('Duration', '${examDraft.duration} min',
                                  Icons.timer_outlined),
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
                          Text('${examDraft.reach}',
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
                    AppButton('Share Link',
                        kind: AppBtnKind.ghost,
                        icon: Icons.link,
                        onPressed: () => _shareLink(context)),
                    AppButton('Back to Dashboard',
                        kind: AppBtnKind.secondary,
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
