import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central design tokens derived from the OlympiadPro / MathKraft
/// "Academic Dark" design system.
class AppColors {
  // Surfaces (Deep Space tonal layers)
  static const background = Color(0xFF0B1326);
  static const scaffold = Color(0xFF080E1C);
  static const surface = Color(0xFF131B2E);
  static const surfaceContainer = Color(0xFF171F33);
  static const surfaceHigh = Color(0xFF222A3D);
  static const surfaceHighest = Color(0xFF2D3449);
  static const surfaceVariant = Color(0xFF2D3449);

  // Content
  static const onSurface = Color(0xFFDAE2FD);
  static const onSurfaceVariant = Color(0xFFC7C4D7);
  static const muted = Color(0xFF908FA0);

  // Brand accents
  static const primary = Color(0xFFC0C1FF); // Indigo (light, on dark)
  static const primaryStrong = Color(0xFF8083FF);
  static const onPrimary = Color(0xFF1000A9);
  static const primaryContainer = Color(0xFF1A237E);

  static const secondary = Color(0xFFFFB691); // Amber (actions/timers)
  static const onSecondary = Color(0xFF552000);
  static const secondaryStrong = Color(0xFFFF8A4C);

  static const teal = Color(0xFF6BD8CB);
  static const tealStrong = Color(0xFF29A195);

  static const success = Color(0xFF4EDEA3);
  static const onSuccess = Color(0xFF003824);

  static const warning = Color(0xFFFFC107);
  static const error = Color(0xFFFFB4AB);
  static const errorStrong = Color(0xFFE11D48);

  // Lines
  static const outline = Color(0x1FFFFFFF); // 12% white "ghost border"
  static const outlineStrong = Color(0xFF464554);
}

class AppRadius {
  static const sm = 4.0;
  static const md = 6.0;
  static const lg = 8.0;
  static const xl = 12.0;
  static const pill = 999.0;
}

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);

    // Geist isn't on Google Fonts; Sora is a close geometric STEM stand-in.
    TextStyle head(double size, FontWeight w, {double? lh, double ls = -0.2}) =>
        GoogleFonts.sora(
            fontSize: size,
            fontWeight: w,
            height: lh == null ? null : lh / size,
            letterSpacing: ls,
            color: AppColors.onSurface);

    final textTheme = TextTheme(
      displaySmall: head(32, FontWeight.w700),
      headlineLarge: head(28, FontWeight.w700),
      headlineMedium: head(24, FontWeight.w600),
      headlineSmall: head(20, FontWeight.w600),
      titleLarge: head(18, FontWeight.w600, ls: 0),
      titleMedium: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.onSurface),
      bodyLarge: GoogleFonts.inter(
          fontSize: 16, color: AppColors.onSurface, height: 1.5),
      bodyMedium: GoogleFonts.inter(
          fontSize: 14, color: AppColors.onSurfaceVariant, height: 1.5),
      bodySmall: GoogleFonts.inter(
          fontSize: 12, color: AppColors.muted, height: 1.4),
      labelLarge: mono(14, FontWeight.w500),
      labelMedium: mono(12, FontWeight.w500),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.scaffold,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.surface,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        error: AppColors.errorStrong,
        onSurface: AppColors.onSurface,
      ),
      textTheme: textTheme,
      dividerColor: AppColors.outline,
      iconTheme: const IconThemeData(color: AppColors.onSurfaceVariant),
      tooltipTheme: const TooltipThemeData(
        decoration: BoxDecoration(color: AppColors.surfaceHighest),
      ),
    );
  }

  /// JetBrains Mono — labels, metadata, counters.
  static TextStyle mono(double size, FontWeight w,
          {Color? color, double ls = 0.5}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: w,
        letterSpacing: ls,
        color: color ?? AppColors.muted,
      );
}
