import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF4F46E5);
  static const Color primaryPurple = Color(0xFF7C3AED);
  static const Color darkBg = Color(0xFF111827);
  static const Color cardDark = Color(0xFF1F2937);
  static const Color textWhite = Colors.white;
  static const Color textGray = Color(0xFF9CA3AF);

  static LinearGradient get primaryGradient => const LinearGradient(
        colors: [primaryBlue, primaryPurple],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static BoxDecoration get glassBoxDecoration => BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      );
}
