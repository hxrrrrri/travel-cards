import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF080A12);
  static const Color surface = Color(0xFF111421);
  static const Color surfaceElevated = Color(0xFF1A1E2E);
  static const Color primaryCyan = Color(0xFF00D7FF);
  static const Color accentOrange = Color(0xFFFF8A2A);
  static const Color textPrimary = Color(0xFFF5F7FA);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color success = Color(0xFF2EE59D);
  static const Color danger = Color(0xFFFF4D5E);
  static const Color routeInactive = Color(0xFF4B5563);
  static const Color border = Color(0xFF252A3D);

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        fontFamily: 'Roboto',
        colorScheme: const ColorScheme.dark(
          primary: primaryCyan,
          secondary: accentOrange,
          surface: surface,
          error: danger,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: surface,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          iconTheme: IconThemeData(color: textPrimary),
        ),
        textTheme: const TextTheme(
          displaySmall: TextStyle(color: textPrimary, fontSize: 28, fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(color: textPrimary, fontSize: 22, fontWeight: FontWeight.w600),
          headlineSmall: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
          bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
          bodySmall: TextStyle(color: textSecondary, fontSize: 12),
          labelLarge: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        cardColor: surfaceElevated,
        dividerColor: border,
        chipTheme: ChipThemeData(
          backgroundColor: surfaceElevated,
          selectedColor: const Color(0x2000D7FF),
          labelStyle: const TextStyle(color: textSecondary, fontSize: 12),
          secondaryLabelStyle: const TextStyle(color: primaryCyan, fontSize: 12),
          side: const BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceElevated,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryCyan),
          ),
          hintStyle: const TextStyle(color: textSecondary),
          labelStyle: const TextStyle(color: textSecondary),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: primaryCyan,
          inactiveTrackColor: border,
          thumbColor: primaryCyan,
          overlayColor: Color(0x2000D7FF),
          valueIndicatorColor: primaryCyan,
          valueIndicatorTextStyle: TextStyle(color: background, fontWeight: FontWeight.w600),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          dragHandleColor: border,
          showDragHandle: true,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primaryCyan,
          foregroundColor: background,
          elevation: 8,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryCyan,
            foregroundColor: background,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            elevation: 0,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryCyan,
            side: const BorderSide(color: primaryCyan),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primaryCyan,
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      );
}
