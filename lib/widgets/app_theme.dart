// lib/core/theme/app_theme.dart
// Central theme definition for ArthroCare app.
// Import this file in every module to ensure visual consistency.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────
// COLOUR PALETTE
// ─────────────────────────────────────────────
class AppColors {
  AppColors._();

  // Primary teal family (brand)
  static const Color primary        = Color(0xFF1B5F5F);
  static const Color primaryLight   = Color(0xFF2D8B8B);
  static const Color primarySurface = Color(0xFFE8F5F5);
  static const Color primaryBorder  = Color(0xFFB2DFDF);

  // Backgrounds
  static const Color bgPage         = Color(0xFFF7FAFA);
  static const Color bgCard         = Color(0xFFFFFFFF);
  static const Color bgSection      = Color(0xFFF0F6F6);

  // Text
  static const Color textPrimary    = Color(0xFF1A2E2E);
  static const Color textSecondary  = Color(0xFF4A6464);
  static const Color textMuted      = Color(0xFF8AABAB);
  static const Color textOnPrimary  = Color(0xFFFFFFFF);

  // RAPID3 Tier colours (matches Firebase schema)
  static const Color tierRemission  = Color(0xFF10B981); // 🟢
  static const Color tierLow        = Color(0xFFF59E0B); // 🟡
  static const Color tierModerate   = Color(0xFFF97316); // 🟠
  static const Color tierHigh       = Color(0xFFEF4444); // 🔴

  static const Color tierRemissionBg = Color(0xFFD1FAE5);
  static const Color tierLowBg       = Color(0xFFFEF3C7);
  static const Color tierModerateBg  = Color(0xFFFFEDD5);
  static const Color tierHighBg      = Color(0xFFFEE2E2);

  // Semantic colours
  static const Color success        = Color(0xFF10B981);
  static const Color warning        = Color(0xFFF59E0B);
  static const Color error          = Color(0xFFEF4444);
  static const Color info           = Color(0xFF3B82F6);

  // Borders & dividers
  static const Color border         = Color(0xFFD4E8E8);
  static const Color divider        = Color(0xFFEAF2F2);

  // Joint heat-map
  static const Color jointNormal    = Color(0xFFD4E8E8);
  static const Color jointMild      = Color(0xFFFEF3C7);
  static const Color jointSevere    = Color(0xFFFEE2E2);
  static const Color jointSelected  = Color(0xFFEF4444);
}

// ─────────────────────────────────────────────
// TYPOGRAPHY
// ─────────────────────────────────────────────
class AppTextStyles {
  AppTextStyles._();

  // Display / Hero numbers
  static TextStyle heroScore(Color color) => GoogleFonts.dmMono(
    fontSize: 56, fontWeight: FontWeight.w700, color: color, letterSpacing: -2,
  );

  static TextStyle scoreMedium(Color color) => GoogleFonts.dmMono(
    fontSize: 32, fontWeight: FontWeight.w700, color: color, letterSpacing: -1,
  );

  // Section & page titles
  static TextStyle pageTitle() => GoogleFonts.plusJakartaSans(
    fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
  );

  static TextStyle sectionTitle() => GoogleFonts.plusJakartaSans(
    fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
  );

  static TextStyle cardTitle() => GoogleFonts.plusJakartaSans(
    fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );

  // Labels & captions
  static TextStyle label() => GoogleFonts.plusJakartaSans(
    fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary,
    letterSpacing: 0.8,
  );

  static TextStyle labelCaps() => GoogleFonts.plusJakartaSans(
    fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted,
    letterSpacing: 1.2, height: 1,
  );

  static TextStyle caption() => GoogleFonts.plusJakartaSans(
    fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary,
  );

  // Body
  static TextStyle body() => GoogleFonts.plusJakartaSans(
    fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary,
  );

  static TextStyle bodySmall() => GoogleFonts.plusJakartaSans(
    fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary,
  );

  // Buttons
  static TextStyle buttonPrimary() => GoogleFonts.plusJakartaSans(
    fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white,
  );

  static TextStyle buttonSecondary() => GoogleFonts.plusJakartaSans(
    fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary,
  );
}

// ─────────────────────────────────────────────
// SPACING
// ─────────────────────────────────────────────
class AppSpacing {
  AppSpacing._();
  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 12;
  static const double base= 16;
  static const double lg  = 20;
  static const double xl  = 24;
  static const double xxl = 32;
  static const double xxxl= 40;
}

// ─────────────────────────────────────────────
// RADIUS
// ─────────────────────────────────────────────
class AppRadius {
  AppRadius._();
  static const double sm   = 8;
  static const double md   = 12;
  static const double lg   = 16;
  static const double xl   = 20;
  static const double xxl  = 24;
  static const double pill = 100;
}

// ─────────────────────────────────────────────
// SHADOWS
// ─────────────────────────────────────────────
class AppShadows {
  AppShadows._();

  static List<BoxShadow> card() => [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.06),
      blurRadius: 12, offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> elevated() => [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.12),
      blurRadius: 20, offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> subtle() => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8, offset: const Offset(0, 2),
    ),
  ];
}

// ─────────────────────────────────────────────
// TIER HELPERS
// ─────────────────────────────────────────────
class AppTierHelper {
  AppTierHelper._();

  static Color color(String tier) {
    switch (tier.toUpperCase()) {
      case 'REMISSION': return AppColors.tierRemission;
      case 'LOW':       return AppColors.tierLow;
      case 'MODERATE':  return AppColors.tierModerate;
      case 'HIGH':      return AppColors.tierHigh;
      default:          return AppColors.textMuted;
    }
  }

  static Color bgColor(String tier) {
    switch (tier.toUpperCase()) {
      case 'REMISSION': return AppColors.tierRemissionBg;
      case 'LOW':       return AppColors.tierLowBg;
      case 'MODERATE':  return AppColors.tierModerateBg;
      case 'HIGH':      return AppColors.tierHighBg;
      default:          return AppColors.bgSection;
    }
  }

  static String emoji(String tier) {
    switch (tier.toUpperCase()) {
      case 'REMISSION': return '🟢';
      case 'LOW':       return '🟡';
      case 'MODERATE':  return '🟠';
      case 'HIGH':      return '🔴';
      default:          return '⚪';
    }
  }

  static String label(String tier) {
    switch (tier.toUpperCase()) {
      case 'REMISSION': return 'Remission';
      case 'LOW':       return 'Low Activity';
      case 'MODERATE':  return 'Moderate Activity';
      case 'HIGH':      return 'High Activity / Flare';
      default:          return tier;
    }
  }
}

// ─────────────────────────────────────────────
// THEME DATA
// ─────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.primaryLight,
      surface: AppColors.bgCard,
      background: AppColors.bgPage,
    ),
    scaffoldBackgroundColor: AppColors.bgPage,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.bgCard,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: AppColors.border,
      centerTitle: false,
      titleTextStyle: AppTextStyles.sectionTitle(),
      iconTheme: const IconThemeData(color: AppColors.primary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        textStyle: AppTextStyles.buttonPrimary(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        textStyle: AppTextStyles.buttonSecondary(),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      // side is set here, not inside shape (Flutter 3.7+)
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bgSection,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      labelStyle: AppTextStyles.caption(),
      hintStyle: AppTextStyles.caption(),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.primary,
      inactiveTrackColor: AppColors.primaryBorder,
      thumbColor: AppColors.primary,
      overlayColor: AppColors.primary.withValues(alpha: 0.12),
      valueIndicatorColor: AppColors.primary,
      valueIndicatorTextStyle: const TextStyle(color: Colors.white),
      trackHeight: 6,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.bgCard,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textMuted,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.divider, thickness: 1, space: 0,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
      linearTrackColor: AppColors.primaryBorder,
    ),
    textTheme: TextTheme(
      displayLarge: AppTextStyles.heroScore(AppColors.textPrimary),
      headlineMedium: AppTextStyles.pageTitle(),
      titleLarge: AppTextStyles.sectionTitle(),
      titleMedium: AppTextStyles.cardTitle(),
      bodyLarge: AppTextStyles.body(),
      bodyMedium: AppTextStyles.bodySmall(),
      labelSmall: AppTextStyles.labelCaps(),
    ),
  );
}