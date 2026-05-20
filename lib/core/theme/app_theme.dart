import 'package:flutter/material.dart';

// classe responsavel pelo tema visual do app
class AppTheme {
  const AppTheme._();

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      // azul medio como cor primaria — gera toda a paleta do material 3 a partir dele
      seedColor: const Color(0xFF1976D2),
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
    );
  }
}
