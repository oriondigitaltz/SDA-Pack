import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Warm cream/orange palette: cream scaffold, white cards and a strong
/// orange accent in light mode; deep neutral surfaces with the same
/// orange accent in dark mode.
///
/// Legacy member names (mustard, cream, darkGreen…) are kept because
/// screens reference them directly; their values now map onto the
/// new palette.
class AppColors {
  /// Primary accent (buttons, links, highlights).
  static const orange = Color(0xFFD97706);
  static const orangeDark = Color(0xFFB45309);
  static const orangeLight = Color(0xFFF59E0B);

  /// Pale orange chip/tint background used behind tile icons.
  static const orangeSoft = Color(0xFFFDF0DC);

  /// Hero card gradient (top-left → bottom-right).
  static const heroGradientStart = Color(0xFFE8830C);
  static const heroGradientEnd = Color(0xFFC05F06);

  // Legacy names — remapped to the new palette.
  static const mustard = orange;
  static const mustardDark = orangeDark;
  static const mustardLight = orangeLight;

  /// Cream app background.
  static const cream = Color(0xFFFDF8EF);

  static const darkGreen = Color(0xFF191613);
  static const darkGreenCard = Color(0xFF262119);
  static const navyBar = Color(0xFF1B1B1E);

  static const ink = Color(0xFF241C10);
  static const inkSoft = Color(0x99241C10); // ~60% ink

  /// Card surface in light mode.
  static const cardLight = Colors.white;
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.orange,
        brightness: Brightness.light,
        primary: AppColors.orange,
        surface: AppColors.cardLight,
      ),
      scaffoldBackgroundColor: AppColors.cream,
      useMaterial3: true,
    );
    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardLight,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(18)),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
        ),
      ),
      navigationBarTheme: _navBarTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
      ),
      iconTheme: const IconThemeData(color: AppColors.ink),
      dividerColor: Colors.black.withValues(alpha: 0.08),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: Colors.white,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.orange,
        brightness: Brightness.dark,
        primary: AppColors.orangeLight,
        surface: AppColors.darkGreenCard,
      ),
      scaffoldBackgroundColor: AppColors.darkGreen,
      useMaterial3: true,
    );
    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.darkGreenCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18))),
      ),
      navigationBarTheme: _navBarTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      dividerColor: Colors.white.withValues(alpha: 0.08),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: Colors.white,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
      ),
    );
  }

  static NavigationBarThemeData _navBarTheme() {
    return NavigationBarThemeData(
      backgroundColor: AppColors.navyBar,
      indicatorColor: AppColors.orange.withValues(alpha: 0.22),
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11.5,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppColors.orangeLight : Colors.white54,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? AppColors.orangeLight : Colors.white54,
        );
      }),
    );
  }
}
