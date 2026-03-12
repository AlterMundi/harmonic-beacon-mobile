import 'package:flutter/material.dart';

/// Harmonic Beacon Design System — ported from constants/Colors.ts
class AppColors {
  AppColors._();

  // Primary — deep calming purples/blues
  static const primary50  = Color(0xFFF0F0FF);
  static const primary100 = Color(0xFFE4E4FF);
  static const primary200 = Color(0xFFCCCBFF);
  static const primary300 = Color(0xFFA9A4FF);
  static const primary400 = Color(0xFF8274FF);
  static const primary500 = Color(0xFF6346FF); // main brand
  static const primary600 = Color(0xFF5423F7);
  static const primary700 = Color(0xFF4614E3);
  static const primary800 = Color(0xFF3A12BE);
  static const primary900 = Color(0xFF30119B);
  static const primary950 = Color(0xFF1C0869);

  // Accent — warm amber
  static const accent400 = Color(0xFFFBBF24);
  static const accent500 = Color(0xFFF59E0B);
  static const accent600 = Color(0xFFD97706);

  // Backgrounds
  static const bgDefault   = Color(0xFF0A0A1A);
  static const bgSecondary = Color(0xFF12122A);
  static const bgCard      = Color(0x0DFFFFFF); // 5% white
  static const bgCardHover = Color(0x14FFFFFF); // 8% white

  // Text
  static const textPrimary   = Colors.white;
  static const textSecondary = Color(0xB3FFFFFF); // 70% white
  static const textMuted     = Color(0x66FFFFFF); // 40% white

  // Borders
  static const borderSubtle = Color(0x14FFFFFF); // 8% white
  static const borderActive = Color(0x806346FF); // 50% primary500

  // Status colors
  static const live     = Color(0xFFEF4444); // red — live stream
  static const playlist = Color(0xFFF59E0B); // amber — playlist stream
  static const offline  = Color(0x66FFFFFF); // muted — no stream
  static const success  = Color(0xFF22C55E); // green — connected
  static const error    = Color(0xFFEF4444); // red — errors
}

class AppGradients {
  AppGradients._();

  static const background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.bgDefault, AppColors.bgSecondary],
  );

  static const primaryButton = LinearGradient(
    colors: [AppColors.primary500, AppColors.primary400],
  );
}

ThemeData buildAppTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bgDefault,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary500,
      secondary: AppColors.accent400,
      surface: AppColors.bgSecondary,
      error: AppColors.error,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.primary500,
      inactiveTrackColor: AppColors.borderSubtle,
      thumbColor: Colors.white,
      overlayColor: AppColors.primary500.withValues(alpha: 0.2),
      trackHeight: 4,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.bgSecondary,
      selectedItemColor: AppColors.primary400,
      unselectedItemColor: AppColors.textMuted,
      type: BottomNavigationBarType.fixed,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.bgSecondary,
      contentTextStyle: TextStyle(color: AppColors.textPrimary),
    ),
  );
}
