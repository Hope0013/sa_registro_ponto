import 'package:flutter/material.dart';

class AppTheme {
  // Cores principais do tema azul escuro
  static const Color darkBlueBg = Color(0xFF0F172A);      // Fundo principal escuro
  static const Color cardDarkBlue = Color(0xFF1E293B);    // Cor de cartoes e componentes
  static const Color accentBlue = Color(0xFF2563EB);      // Azul intermediario para botoes
  static const Color lightBlue = Color(0xFF38BDF8);       // Azul claro para detalhes e destaques
  static const Color textLight = Color(0xFFF8FAFC);       // Texto claro
  static const Color textMuted = Color(0xFF94A3B8);       // Texto secundario
  static const Color successGreen = Color(0xFF10B981);    // Indicador de dentro dos 100m
  static const Color errorRed = Color(0xFFEF4444);        // Indicador de fora dos 100m

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: darkBlueBg,
      colorScheme: const ColorScheme.dark(
        primary: accentBlue,
        secondary: lightBlue,
        surface: cardDarkBlue,
        error: errorRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBlueBg,
        foregroundColor: textLight,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardDarkBlue,
        hintStyle: const TextStyle(color: textMuted),
        labelStyle: const TextStyle(color: textMuted),
        prefixIconColor: lightBlue,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBlue, width: 1.5),
        ),
      ),
      cardTheme: const CardThemeData(
        color: cardDarkBlue,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }
}
