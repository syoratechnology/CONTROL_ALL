import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  // Primary palette
  static const Color primary = Color(0xFF6C63FF);
  static const Color accent = Color(0xFF00D4AA);
  static const Color danger = Color(0xFFFF5757);

  // Dark Mode
  static const Color darkBg = Color(0xFF0F0F13);
  static const Color darkSurface = Color(0xFF1A1A23);
  static const Color darkCard = Color(0xFF22222E);
  static const Color darkTextPrimary = Color(0xFFF0F0F5);
  static const Color darkTextSecondary = Color(0xFF8E8EA0);
  static const Color darkDivider = Color(0xFF2A2A38);

  // Compatibilidad (apuntan a Dark por ahora, pero se debe usar el tema)
  static const Color background = darkBg;
  static const Color surface = darkSurface;
  static const Color card = darkCard;
  static const Color textPrimary = darkTextPrimary;
  static const Color textSecondary = darkTextSecondary;
  static const Color divider = darkDivider;

  // Light Mode
  static const Color lightBg = Color(0xFFF8F9FF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1A1A23);
  static const Color lightTextSecondary = Color(0xFF6B6B7C);
  static const Color lightDivider = Color(0xFFE5E7EB);

  static const List<Color> proyectoColors = [
    Color(0xFF6C63FF),
    Color(0xFF00D4AA),
    Color(0xFFFF6B6B),
    Color(0xFFFFBB35),
    Color(0xFF4ECDC4),
    Color(0xFFFF79C6),
    Color(0xFF50FA7B),
    Color(0xFF8BE9FD),
  ];
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    return _build(
      brightness: Brightness.light,
      bg: AppColors.lightBg,
      surface: AppColors.lightSurface,
      textPrimary: AppColors.lightTextPrimary,
      textSecondary: AppColors.lightTextSecondary,
      divider: AppColors.lightDivider,
    );
  }

  static ThemeData dark() {
    return _build(
      brightness: Brightness.dark,
      bg: AppColors.darkBg,
      surface: AppColors.darkSurface,
      textPrimary: AppColors.darkTextPrimary,
      textSecondary: AppColors.darkTextSecondary,
      divider: AppColors.darkDivider,
    );
  }

  static ThemeData _build({
    required Brightness brightness,
    required Color bg,
    required Color surface,
    required Color textPrimary,
    required Color textSecondary,
    required Color divider,
  }) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.accent,
        onSecondary: Colors.white,
        error: AppColors.danger,
        onError: Colors.white,
        surface: surface,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ).copyWith(
        displayLarge: GoogleFonts.outfit(
            color: textPrimary, fontSize: 32, fontWeight: FontWeight.w700),
        titleLarge: GoogleFonts.outfit(
            color: textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
        bodyMedium: GoogleFonts.outfit(
            color: textSecondary, fontSize: 15),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
            color: textPrimary, fontSize: 22, fontWeight: FontWeight.w700),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: isDark ? AppColors.darkCard : Colors.white,
        elevation: isDark ? 0 : 2,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkCard : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        labelStyle: TextStyle(color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: surface,
        headerBackgroundColor: AppColors.primary,
        headerForegroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        dayStyle: GoogleFonts.outfit(),
      ),
      dividerTheme: DividerThemeData(
        color: divider,
        thickness: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.1),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12);
          }
          return GoogleFonts.outfit(color: textSecondary, fontSize: 12);
        }),
      ),
    );
  }
}
