// lib/widgets/app_theme.dart
// App colours in one place.

import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF142D4E); // navy (original app colour)
  static const background = Color(0xFFF2F5F9); // light grey-blue
  static const success = Color(0xFF2E7D32); // green
  static const warning = Color(0xFFEF6C00); // orange
  static const danger = Color(0xFFC62828); // red
  static const muted = Colors.black54;
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );
}
