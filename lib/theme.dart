import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF4F46E5);
  static const Color primaryPurple = Color(0xFF7C3AED);

  // Fallback for custom components that need a direct dark value
  static const Color darkBg = Color(0xFF111827);
  static const Color cardDark = Color(0xFF1F2937);

  static LinearGradient get primaryGradient => const LinearGradient(
        colors: [primaryBlue, primaryPurple],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static BoxDecoration glassBoxDecoration(BuildContext context) => BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      );
      
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF9FAFB), // light gray background
    cardColor: Colors.white, // white cards
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryPurple,
      brightness: Brightness.light,
      background: const Color(0xFFF9FAFB),
      surface: Colors.white,
      onSurface: Colors.black87,
      onSurfaceVariant: Colors.black54,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black87),
      titleTextStyle: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black87),
      titleLarge: TextStyle(color: Colors.black87),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF111827), // darkBg
    cardColor: const Color(0xFF1F2937), // cardDark
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryPurple,
      brightness: Brightness.dark,
      background: const Color(0xFF111827),
      surface: const Color(0xFF1F2937),
      onSurface: Colors.white,
      onSurfaceVariant: const Color(0xFF9CA3AF), // textGray
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white),
      titleLarge: TextStyle(color: Colors.white),
    ),
  );
}
