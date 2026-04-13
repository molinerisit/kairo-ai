import 'package:flutter/material.dart';

// Colores base de Kairo AI — dark theme
// Se definen una sola vez acá y se usan en toda la app.
// Si mañana cambia el color primario, cambiamos solo esta línea.
class AppColors {
  AppColors._();

  static const background   = Color(0xFF0A0A0F); // fondo principal
  static const surface      = Color(0xFF13131A); // cards y paneles
  static const surfaceLight = Color(0xFF1C1C27); // hover, inputs
  static const border       = Color(0xFF2A2A3A); // bordes sutiles
  static const primary      = Color(0xFF6C63FF); // acento principal (violeta)
  static const primaryLight = Color(0xFF8B85FF); // acento hover
  static const textPrimary  = Color(0xFFF0F0F5); // texto principal
  static const textSecondary= Color(0xFF8888AA); // texto secundario
  static const success      = Color(0xFF22C55E); // verde
  static const warning      = Color(0xFFF59E0B); // amarillo
  static const danger       = Color(0xFFEF4444); // rojo
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary:   AppColors.primary,
      surface:   AppColors.surface,
      onPrimary: Colors.white,
      onSurface: AppColors.textPrimary,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
      bodyMedium: TextStyle(fontSize: 14, color: AppColors.textSecondary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
