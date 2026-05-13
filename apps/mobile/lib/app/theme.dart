import 'package:flutter/material.dart';

class AppTheme {
  // ─── Base colours ──────────────────────────────────────────────────────────
  static const Color background = Color(0xFF08080F);
  static const Color surface = Color(0xFF111119);
  static const Color surfaceElevated = Color(0xFF1A1A28);
  static const Color border = Color(0xFF1E1E30);

  // ─── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF0F0FF);
  static const Color textSecondary = Color(0xFF6B6B88);
  static const Color textMuted = Color(0xFF3D3D55);

  // ─── Accent ────────────────────────────────────────────────────────────────
  static const Color primaryCyan = Color(0xFF00D9FF);
  static const Color accentOrange = Color(0xFFFF8C42);
  static const Color success = Color(0xFF00E5A0);
  static const Color danger = Color(0xFFFF4D6A);
  static const Color routeInactive = Color(0xFF3A3A55);

  // ─── Card gradients (bento palette) ────────────────────────────────────────
  static const Gradient gradientTeal = LinearGradient(
    colors: [Color(0xFF00B4D8), Color(0xFF0077B6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Gradient gradientPurple = LinearGradient(
    colors: [Color(0xFF7B52FF), Color(0xFFAB47BC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Gradient gradientEmerald = LinearGradient(
    colors: [Color(0xFF00C897), Color(0xFF0096C7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Gradient gradientPink = LinearGradient(
    colors: [Color(0xFFE91E7A), Color(0xFFFF6B6B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Gradient gradientAmber = LinearGradient(
    colors: [Color(0xFFFF8C42), Color(0xFFFF4D6A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Gradient gradientSlate = LinearGradient(
    colors: [Color(0xFF2A2A3D), Color(0xFF1A1A28)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const List<Gradient> cardGradients = [
    gradientTeal,
    gradientPurple,
    gradientEmerald,
    gradientPink,
    gradientAmber,
    gradientSlate,
  ];

  static Gradient cardGradientAt(int index) =>
      cardGradients[index % cardGradients.length];

  // ─── Theme ─────────────────────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: primaryCyan,
          secondary: accentOrange,
          surface: surface,
          error: danger,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
          iconTheme: IconThemeData(color: textPrimary),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
              color: textPrimary,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.0,
              height: 1.1),
          displaySmall: TextStyle(
              color: textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5),
          headlineMedium: TextStyle(
              color: textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3),
          headlineSmall: TextStyle(
              color: textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2),
          titleLarge: TextStyle(
              color: textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1),
          titleMedium: TextStyle(
              color: textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: textPrimary, fontSize: 16, height: 1.5),
          bodyMedium:
              TextStyle(color: textSecondary, fontSize: 14, height: 1.5),
          bodySmall: TextStyle(color: textSecondary, fontSize: 12),
          labelLarge: TextStyle(
              color: textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1),
        ),
        cardColor: surfaceElevated,
        dividerColor: border,
        chipTheme: ChipThemeData(
          backgroundColor: surfaceElevated,
          selectedColor: primaryCyan.withOpacity(0.15),
          labelStyle: const TextStyle(color: textSecondary, fontSize: 13),
          secondaryLabelStyle:
              const TextStyle(color: primaryCyan, fontSize: 13),
          side: const BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceElevated,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: primaryCyan, width: 1.5),
          ),
          hintStyle: const TextStyle(color: textMuted),
          labelStyle: const TextStyle(color: textSecondary),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: primaryCyan,
          inactiveTrackColor: border,
          thumbColor: primaryCyan,
          overlayColor: Color(0x2000D9FF),
          valueIndicatorColor: primaryCyan,
          valueIndicatorTextStyle:
              TextStyle(color: background, fontWeight: FontWeight.w700),
          trackHeight: 3,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryCyan,
            foregroundColor: background,
            minimumSize: const Size(double.infinity, 52),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2),
            elevation: 0,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryCyan,
            side: const BorderSide(color: primaryCyan),
            minimumSize: const Size(double.infinity, 52),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primaryCyan,
            textStyle:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      );
}
