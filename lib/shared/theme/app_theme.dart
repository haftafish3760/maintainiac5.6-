import 'package:flutter/material.dart';

class AppColors {
  static const backgroundTop = Color(0xFF202422);
  static const backgroundBottom = Color(0xFF101312);
  static const panel = Color(0xFF303532);
  static const panelLight = Color(0xFF555C56);
  static const panelDark = Color(0xFF1B1F1D);
  static const field = Color(0xFFAAB4B9);
  static const fieldAlt = Color(0xFF8F9BA1);
  static const text = Color(0xFFF3F0E6);
  static const ink = Color(0xFF111413);
  static const label = Color(0xFFE9E4D6);
  static const blue = Color(0xFF1976B9);
  static const green = Color(0xFF28A745);
  static const red = Color(0xFFE3342F);
  static const yellow = Color(0xFFE0B42D);
  static const orange = Color(0xFFF47C20);
}

ThemeData buildMaintaniacTheme() {
  const utilityButtonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(5)),
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.blue,
      brightness: Brightness.dark,
      surface: AppColors.panel,
    ),
    fontFamily: 'Roboto',
  );

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.backgroundBottom,
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.field,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      labelStyle: const TextStyle(
        color: AppColors.ink,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      floatingLabelStyle: const TextStyle(
        color: AppColors.ink,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
      hintStyle: TextStyle(color: AppColors.ink.withValues(alpha: 0.65)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(3)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(3),
        borderSide: const BorderSide(color: Color(0xFF858176), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(3),
        borderSide: const BorderSide(color: AppColors.green, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(shape: utilityButtonShape),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(shape: utilityButtonShape),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(shape: utilityButtonShape),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(shape: utilityButtonShape),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    ),
  );
}
