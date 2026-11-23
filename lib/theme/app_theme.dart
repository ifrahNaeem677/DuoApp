import 'package:flutter/material.dart';

/// All the colours used in the app, in one place.
class AppColors {
  static const primary = Color(0xFF0E8C6B); // emerald green
  static const primaryDark = Color(0xFF075E54); // deep teal
  static const accent = Color(0xFF14B8A6); // bright teal
  static const gold = Color(0xFFF5B841); // trophy gold
  static const bg = Color(0xFFF2F7F5); // soft mint background
  static const textDark = Color(0xFF12332B);
  static const textMuted = Color(0xFF6B8A82);

  static const gradient = LinearGradient(
    colors: [primaryDark, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.accent,
    ),
    scaffoldBackgroundColor: AppColors.bg,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
      ),
    ),
  );
}

/// Rounded, filled text-field style used across the app.
InputDecoration fieldDecoration(String hint, IconData icon) {
  return InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, color: AppColors.primary),
    filled: true,
    fillColor: AppColors.bg,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
  );
}

/// White rounded card with a soft shadow.
BoxDecoration cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    boxShadow: [
      BoxShadow(
        color: AppColors.primaryDark.withAlpha(18),
        blurRadius: 18,
        offset: const Offset(0, 6),
      ),
    ],
  );
}
