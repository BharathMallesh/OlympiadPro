import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../widgets/common.dart';

/// Shared wizard frame: header with step label + progress, scrollable content,
/// and a sticky bottom action bar (Back / Save Draft / Continue).
class WizardScaffold extends StatelessWidget {
  const WizardScaffold({
    super.key,
    required this.appTitle,
    required this.stepLabel,
    required this.title,
    required this.progress,
    required this.child,
    this.backRoute,
    this.nextRoute,
    this.nextLabel = 'Save & Continue',
    this.nextKind = AppBtnKind.secondary,
    this.nextIcon = Icons.chevron_right,
    this.onNext,
    this.showSaveDraft = true,
    this.sideRail,
  });

  final String appTitle;
  final String stepLabel;
  final String title;
  final double progress;
  final Widget child;
  final String? backRoute;
  final String? nextRoute;
  final String nextLabel;
  final AppBtnKind nextKind;
  final IconData nextIcon;
  final VoidCallback? onNext;
  final bool showSaveDraft;
  final Widget? sideRail;

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    return PopRedirect(
      fallbackRoute: backRoute ?? '/dashboard',
      child: Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              backRoute != null ? context.go(backRoute!) : context.go('/dashboard'),
        ),
        title: Text(appTitle,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(color: AppColors.primary)),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Step header
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(stepLabel.toUpperCase(),
                                    style: AppTheme.mono(12, FontWeight.w600,
                                        color: AppColors.primary, ls: 1.5)),
                                const SizedBox(height: 6),
                                Text(title,
                                    style: Theme.of(context).textTheme.headlineLarge),
                              ],
                            ),
                          ),
                          Text('${(progress * 100).round()}% Complete',
                              style: AppTheme.mono(12, FontWeight.w600,
                                  color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ProgressLine(progress, height: 5),
                      const SizedBox(height: 24),
                      if (wide && sideRail != null)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: child),
                            const SizedBox(width: 20),
                            Expanded(flex: 1, child: sideRail!),
                          ],
                        )
                      else ...[
                        child,
                        if (sideRail != null) ...[
                          const SizedBox(height: 16),
                          sideRail!,
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          _BottomBar(
            backRoute: backRoute,
            nextRoute: nextRoute,
            nextLabel: nextLabel,
            nextKind: nextKind,
            nextIcon: nextIcon,
            onNext: onNext,
            showSaveDraft: showSaveDraft,
          ),
        ],
      ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    this.backRoute,
    this.nextRoute,
    required this.nextLabel,
    required this.nextKind,
    required this.nextIcon,
    this.onNext,
    required this.showSaveDraft,
  });
  final String? backRoute;
  final String? nextRoute;
  final String nextLabel;
  final AppBtnKind nextKind;
  final IconData nextIcon;
  final VoidCallback? onNext;
  final bool showSaveDraft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.outline)),
      ),
      child: SafeArea(
        top: false,
        child: Row(children: [
          if (backRoute != null)
            AppButton('Back',
                kind: AppBtnKind.ghost,
                icon: Icons.chevron_left,
                onPressed: () => context.go(backRoute!)),
          const Spacer(),
          if (showSaveDraft)
            TextButton(
                onPressed: () => context.go('/dashboard'),
                child: Text('Save Draft',
                    style: AppTheme.mono(12, FontWeight.w500,
                        color: AppColors.onSurfaceVariant))),
          const SizedBox(width: 12),
          AppButton(nextLabel,
              kind: nextKind,
              trailingIcon: nextIcon,
              onPressed: onNext ??
                  (nextRoute == null ? null : () => context.go(nextRoute!))),
        ]),
      ),
    );
  }
}

/// Selectable option chip grid item (categories / formats).
class SelectTile extends StatelessWidget {
  const SelectTile(this.label,
      {super.key, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryStrong.withValues(alpha: 0.16)
              : AppColors.scaffold,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.outlineStrong),
        ),
        child: Text(label,
            style: AppTheme.mono(13, FontWeight.w500,
                color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
                ls: 0.5)),
      ),
    );
  }
}
