import 'package:flutter/material.dart';

class AppTheme {
  static const Color backgroundColor = Color(0xFF1A2A36);
  static const Color cardColor = Color(0xFF253540);
  static const Color textColor = Colors.white;
  static const Color accentColor = Color(0xFFBFC9D1);

  static ThemeData get theme {
    return ThemeData(
      scaffoldBackgroundColor: backgroundColor,
      primaryColor: accentColor,
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textColor, fontSize: 20),
        bodyMedium: TextStyle(color: textColor, fontSize: 16),
      ),
    );
  }
}
