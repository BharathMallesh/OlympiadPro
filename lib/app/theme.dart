import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central design tokens derived from the Vidyora / MathKraft
/// "Academic Dark" design system.
class AppColors {
  // Vidyora brand: navy + gold on a cream/light surface.
  static const navy = Color(0xFF14365A); // sidebar / deep brand
  static const gold = Color(0xFFC9A24B); // brand accent

  // Surfaces (light, warm)
  static const background = Color(0xFFFBF9F3); // app bars / elevated
  static const scaffold = Color(0xFFF3EFE6); // page / content background
  static const surface = Color(0xFFFFFFFF); // cards
  static const surfaceContainer = Color(0xFFFAF6EC);
  static const surfaceHigh = Color(0xFFF0EBDD);
  static const surfaceHighest = Color(0xFFE8E2D2);
  static const surfaceVariant = Color(0xFFEFEADD);

  // Content (dark navy ink on light)
  static const onSurface = Color(0xFF1E2A3A);
  static const onSurfaceVariant = Color(0xFF42506A);
  static const muted = Color(0xFF6B7480);

  // Brand accents
  static const primary = Color(0xFF1C4E86); // navy-blue (links/buttons/icons)
  static const primaryStrong = Color(0xFF14365A);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFFDCE6F4);

  static const secondary = Color(0xFFB5851F); // gold (actions/timers)
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryStrong = Color(0xFF9A6F12);

  // Accent is gold. `teal` names kept as aliases so existing usages flip to
  // gold without touching ~60 call sites.
  static const teal = Color(0xFFB5851F);
  static const tealStrong = Color(0xFF9A6F12);

  static const success = Color(0xFF15924B);
  static const onSuccess = Color(0xFFFFFFFF);

  static const warning = Color(0xFFC77C0A);
  static const error = Color(0xFFDC2626);
  static const errorStrong = Color(0xFFB91C1C);

  // Lines
  static const outline = Color(0x14000000); // 8% black "ghost border"
  static const outlineStrong = Color(0xFFD8D0BC);
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
    final base = ThemeData.light(useMaterial3: true);

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
      colorScheme: const ColorScheme.light(
        surface: AppColors.surface,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        error: AppColors.error,
        onError: Colors.white,
        onSurface: AppColors.onSurface,
      ),
      textTheme: textTheme,
      dividerColor: AppColors.outline,
      iconTheme: const IconThemeData(color: AppColors.onSurfaceVariant),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(AppRadius.md)),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
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
