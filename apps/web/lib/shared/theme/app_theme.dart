import 'package:flutter/material.dart';

// Colores base de AXIIA — light theme
// Se definen una sola vez acá y se usan en toda la app vía nombres semánticos.
// Marca: navy + azul #005BFE sobre fondos claros.
class AppColors {
  AppColors._();

  static const background   = Color(0xFFF6F8FF); // fondo principal (claro con tinte azul)
  static const surface      = Color(0xFFFFFFFF); // cards y paneles
  static const surfaceLight = Color(0xFFEEF2FB); // inputs / hover
  static const border       = Color(0xFFE7ECF7); // bordes suaves
  static const primary      = Color(0xFF005BFE); // acento principal (azul de marca AXIIA)
  static const primaryLight = Color(0xFF4D8BFF); // acento hover
  static const textPrimary  = Color(0xFF0B1635); // texto principal (navy)
  static const textSecondary= Color(0xFF5C6B8A); // texto secundario (slate)
  static const success      = Color(0xFF16A34A); // verde
  static const warning      = Color(0xFFF59E0B); // amarillo
  static const danger       = Color(0xFFDC2626); // rojo
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.light(
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
