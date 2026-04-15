// import 'package:flutter/material.dart';
//
// ThemeData lightMode = ThemeData(
//   brightness: Brightness.light,
//   colorScheme: ColorScheme.light(
//     background: const Color(0xFFF4F1FF),
//     surface: const Color(0xFFFFFFFF),
//     primary: const Color(0xFF8B5FBF),
//     secondary: const Color(0xFFE879F9),
//     onBackground: const Color(0xFF2D1B69),
//     onSurface: const Color(0xFFA5A3C7),
//     outline: const Color(0xFF3B4070)
//
//
//   )
// );
//
// ThemeData darkMode = ThemeData(
//     brightness: Brightness.dark,
//   colorScheme: ColorScheme.dark(
//     background: const Color(0xFF0A0B1E),
//     surface: const Color(0xFF1A1B3A),
//     primary: const Color(0xFF8B5FBF),
//     secondary: const Color(0xFFE879F9),
//     onBackground:const  Color(0xFFE8E6FF),
//     onSurface:const Color(0xFF6B6394),
//     outline: const Color(0xFFE1DCFF),
//   )
// );

import 'package:flutter/material.dart';

// Light theme with pastel colors
ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    background: Color(0xFFF4F6F8),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFF417FB1),
    secondary: Color(0xFF89C2A5),
    onBackground: Color(0xFF15232D),
    onSurface: Color(0xFF3C4F60),
    outline: Color(0xFFC5CED6),
    tertiary: Color(0xFFF2F7F9),
    onTertiary: Color(0xFF243645),
    error: Color(0xFFFF9999),
    onError: Color(0xFFFFFFFF),
    inversePrimary: Color(0xFF9AD8B8),
    surfaceVariant: Color(0xFFE3EBF1),
    onSurfaceVariant: Color(0xFF4C6170),
    primaryContainer: Color(0xFFB1CDE0),
    onPrimaryContainer: Color(0xFF132B3C),
  ),

  // Card theme
  cardTheme: const CardThemeData(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
  ),
  // Elevated button theme
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      backgroundColor: Color(0xFF7AB2D3), // Pastel blue for buttons
      foregroundColor: Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  // Input decoration theme
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFDCE1E6)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFDCE1E6)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF7AB2D3), width: 2),
    ),
  ),
  // Typography
  textTheme: const TextTheme(
    headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A2E35)),
    bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF4A5B66)),
  ),
);

// Dark theme with pastel colors
ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    // Main background - Deep professional dark (0F172A)
    // background: Color(0xFF0F0D15),
    background: Color(0xFF121212),

    // Surface colors - Layered dark surfaces (1E293B)
    // surface: Color(0xFF1D1A26),
    surface: Color(0xFF1E1E1E),

    // Primary brand color - Bright teal for dark mode (14B8A6)  60A5FA {{3B82F6}}
    // primary: Color(0xff1e95d4),
    primary: Color(0xFF0079bf),

    // Secondary accent - Vibrant orange
    // secondary: Color(0xFFFB923C),
    secondary: Color(0xFF71AFE5),

    // Text colors
    onBackground: Color(0xFFF8FAFC),
    onSurface: Color(0xFFCBD5E1),

    // Border and outline colors
    outline: Color(0xFF475569),

    // Additional colors
    tertiary: Color(0xFF334155),
    onTertiary: Color(0xFF94A3B8),

    // Error colors
    error: Color(0xFFF87171),
    onError: Color(0xFF1F2937),

    // Success/positive colors
    inversePrimary: Color(0xFF10B981),

    // Additional semantic colors
    surfaceVariant: Color(0xFF475569),
    onSurfaceVariant: Color(0xFF94A3B8),
    primaryContainer: Color(0xFF134E4A),
    onPrimaryContainer: Color(0xFFCCFDF7),
  ),

  // Card theme
  cardTheme: const CardThemeData(
    elevation: 0,
    color: Color(0xFF1E293B),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
  ),

  // Elevated button theme
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),

  // Input decoration theme
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF475569)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF475569)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF14B8A6), width: 2),
    ),
  ),
);

// Professional color constants with pastel tones
class AppColors {
  // Light mode colors
  static const lightPrimary = Color(0xFF7AB2D3); // Pastel blue
  static const lightSecondary = Color(0xFFA8D5BA); // Pastel mint green
  static const lightBackground = Color(0xFFF5F6F5); // Pastel off-white
  static const lightSurface = Color(0xFFFFFFFF); // Pure white
  static const lightSuccess = Color(0xFFB2E4C9); // Soft green
  static const lightWarning = Color(0xFFFBCFAB); // Soft peach
  static const lightError = Color(0xFFFF9999); // Soft coral
  static const lightInfo = Color(0xFFB3CDE0); // Light pastel blue

  // Dark mode colors
  static const darkPrimary = Color(0xFF7AB2D3); // Pastel blue
  static const darkSecondary = Color(0xFFA8D5BA); // Pastel mint green
  static const darkBackground = Color(0xFF1C2526); // Deep charcoal
  static const darkSurface = Color(0xFF2E3A3B); // Dark gray
  static const darkSuccess = Color(0xFFB2E4C9); // Soft green
  static const darkWarning = Color(0xFFFBCFAB); // Soft peach
  static const darkError = Color(0xFFFF9999); // Soft coral
  static const darkInfo = Color(0xFFB3CDE0); // Light pastel blue

  // Neutral colors
  static const neutral50 = Color(0xFFF8FAFB);
  static const neutral100 = Color(0xFFEFF3F5);
  static const neutral200 = Color(0xFFDCE1E6);
  static const neutral300 = Color(0xFFB0C4D0);
  static const neutral400 = Color(0xFF8A9CA8);
  static const neutral500 = Color(0xFF5E7380);
  static const neutral600 = Color(0xFF4A5B66);
  static const neutral700 = Color(0xFF3A4B4D);
  static const neutral800 = Color(0xFF2E3A3B);
  static const neutral900 = Color(0xFF1C2526);

  // Status colors
  static const statusSuccess = Color(0xFFB2E4C9); // Soft green
  static const statusWarning = Color(0xFFFBCFAB); // Soft peach
  static const statusError = Color(0xFFFF9999); // Soft coral
  static const statusInfo = Color(0xFFB3CDE0); // Light pastel blue
}