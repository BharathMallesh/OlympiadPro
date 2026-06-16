import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/theme.dart';

/// Breakpoint helper.
bool isWide(BuildContext c) => MediaQuery.sizeOf(c).width >= 900;
bool isCompact(BuildContext c) => MediaQuery.sizeOf(c).width < 600;

/// Makes the Android system back button behave sensibly: pops the navigator
/// when there is something to pop, otherwise redirects to [fallbackRoute]
/// instead of exiting the app. Pass null to keep the default exit behaviour
/// (used on the login screen / dashboard home).
class PopRedirect extends StatelessWidget {
  const PopRedirect({super.key, required this.child, this.fallbackRoute});
  final Widget child;
  final String? fallbackRoute;

  @override
  Widget build(BuildContext context) {
    if (fallbackRoute == null) return child;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final router = GoRouter.of(context);
        if (router.canPop()) {
          router.pop();
        } else {
          context.go(fallbackRoute!);
        }
      },
      child: child,
    );
  }
}

/// Pop if pushed, otherwise fall back to a go() route. Used by explicit
/// back/close buttons on screens that can be reached both ways.
void popOrGo(BuildContext context, String fallbackRoute) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallbackRoute);
  }
}

/// A tonal-layer card with the system's 1px ghost border.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.color,
    this.accentTop,
    this.borderColor,
    this.radius = AppRadius.lg,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final Color? accentTop;
  final Color? borderColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? AppColors.outline),
        gradient: accentTop == null
            ? null
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (accentTop != null)
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: accentTop,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
              ),
            ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

/// Primary / secondary / ghost button matching the design system.
enum AppBtnKind { primary, secondary, ghost, danger }

class AppButton extends StatelessWidget {
  const AppButton(
    this.label, {
    super.key,
    this.onPressed,
    this.kind = AppBtnKind.primary,
    this.icon,
    this.trailingIcon,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppBtnKind kind;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    late Color bg, fg;
    Border? border;
    switch (kind) {
      case AppBtnKind.primary:
        bg = AppColors.primary;
        fg = AppColors.onPrimary;
        break;
      case AppBtnKind.secondary:
        bg = AppColors.secondaryStrong;
        fg = const Color(0xFF3A1500);
        break;
      case AppBtnKind.danger:
        bg = AppColors.errorStrong;
        fg = Colors.white;
        break;
      case AppBtnKind.ghost:
        bg = Colors.transparent;
        fg = AppColors.onSurface;
        border = Border.all(color: AppColors.outline);
        break;
    }

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[Icon(icon, size: 18, color: fg), const SizedBox(width: 8)],
        Text(label.toUpperCase(),
            style: AppTheme.mono(13, FontWeight.w600, color: fg, ls: 0.8)),
        if (trailingIcon != null) ...[
          const SizedBox(width: 8),
          Icon(trailingIcon, size: 18, color: fg)
        ],
      ],
    );

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            border: border,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: content,
        ),
      ),
    );
  }
}

/// Pill status chip ("Easy", "Published", "Flagged"...).
class StatusChip extends StatelessWidget {
  const StatusChip(this.label,
      {super.key, this.color = AppColors.primary, this.icon, this.filled = false});
  final String label;
  final Color color;
  final IconData? icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: filled ? AppColors.onPrimary : color),
          const SizedBox(width: 5)
        ],
        Text(label.toUpperCase(),
            style: AppTheme.mono(10.5, FontWeight.w600,
                color: filled ? AppColors.onPrimary : color, ls: 0.8)),
      ]),
    );
  }
}

/// Small uppercase mono section / field label.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.color});
  final String text;
  final Color? color;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text.toUpperCase(),
            style: AppTheme.mono(11, FontWeight.w500,
                color: color ?? AppColors.muted, ls: 1.2)),
      );
}

/// Styled text input.
class AppInput extends StatelessWidget {
  const AppInput({
    super.key,
    this.hint,
    this.icon,
    this.controller,
    this.obscure = false,
    this.maxLines = 1,
    this.suffix,
    this.onChanged,
  });
  final String? hint;
  final IconData? icon;
  final TextEditingController? controller;
  final bool obscure;
  final int maxLines;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      maxLines: maxLines,
      onChanged: onChanged,
      style: const TextStyle(color: AppColors.onSurface, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.muted),
        prefixIcon: icon == null ? null : Icon(icon, size: 18, color: AppColors.muted),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.scaffold,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.outlineStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}

/// Section heading with leading icon, used inside cards.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.icon, this.color});
  final String title;
  final IconData? icon;
  final Color? color;
  @override
  Widget build(BuildContext context) => Row(children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: color ?? AppColors.primary),
          const SizedBox(width: 10),
        ],
        Text(title,
            style: Theme.of(context).textTheme.titleLarge),
      ]);
}

/// Thin progress bar (wizard / metrics).
class ProgressLine extends StatelessWidget {
  const ProgressLine(this.value, {super.key, this.color = AppColors.primary, this.height = 4});
  final double value;
  final Color color;
  final double height;
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: LinearProgressIndicator(
          value: value,
          minHeight: height,
          backgroundColor: AppColors.surfaceHigh,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      );
}

/// Circle avatar from initials.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar(this.name, {super.key, this.size = 40, this.color});
  final String name;
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'
        : name.substring(0, name.length >= 2 ? 2 : 1);
    final c = color ?? AppColors.primaryStrong;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: c.withValues(alpha: 0.5)),
      ),
      child: Text(initials.toUpperCase(),
          style: AppTheme.mono(size * 0.32, FontWeight.w600, color: c, ls: 0)),
    );
  }
}

/// A stat block: big number + label + optional delta.
class StatBlock extends StatelessWidget {
  const StatBlock({
    super.key,
    required this.label,
    required this.value,
    this.delta,
    this.deltaColor = AppColors.success,
    this.valueColor,
    this.icon,
  });
  final String label;
  final String value;
  final String? delta;
  final Color deltaColor;
  final Color? valueColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: AppColors.surfaceContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: FieldLabel(label)),
            if (icon != null) Icon(icon, size: 16, color: AppColors.muted),
          ]),
          const SizedBox(height: 6),
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text(value,
                style: GoogleFontsHelper.value(valueColor ?? AppColors.onSurface)),
            if (delta != null) ...[
              const SizedBox(width: 8),
              Text(delta!, style: AppTheme.mono(12, FontWeight.w600, color: deltaColor)),
            ],
          ]),
        ],
      ),
    );
  }
}

class GoogleFontsHelper {
  static TextStyle value(Color color) =>
      AppTheme.mono(28, FontWeight.w700, color: color, ls: -0.5);
}
