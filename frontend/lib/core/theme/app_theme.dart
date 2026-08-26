import 'package:flutter/material.dart';

/// A dark, "liquid glass" look echoing the reference site: deep navy/black
/// background, a violet/cyan accent gradient, translucent frosted cards.
class AppColors {
  static const background = Color(0xFF0B0D14);
  static const surface = Color(0xFF12151F);
  static const glassFill = Color(0x14FFFFFF); // translucent white
  static const glassBorder = Color(0x26FFFFFF);
  static const accentStart = Color(0xFF7C5CFF);
  static const accentEnd = Color(0xFF34D5E0);
  static const textPrimary = Color(0xFFF5F6FA);
  static const textSecondary = Color(0xFFA3A8BD);

  static const accentGradient = LinearGradient(
    colors: [accentStart, accentEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

ThemeData buildAppTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.accentStart,
      secondary: AppColors.accentEnd,
      surface: AppColors.surface,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.glassFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accentEnd, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentStart,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}

/// Responsive breakpoints shared by the public site and admin panel.
class Breakpoints {
  static const mobile = 600.0;
  static const tablet = 1000.0;

  static bool isMobile(double width) => width < mobile;
  static bool isTablet(double width) => width >= mobile && width < tablet;
  static bool isDesktop(double width) => width >= tablet;
}
