import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const primaryColor = Color(0xFF2196F3);
  static const secondaryColor = Color(0xFF03DAC6);
  static const errorColor = Color(0xFFB00020);
  static const backgroundColor = Color(0xFFF5F5F5);
  static const cardColor = Colors.white;
  static const surfaceColor = Colors.white;

  // Dark Theme Colors
  static const darkPrimaryColor = Color(0xFF1E88E5);
  static const darkSecondaryColor = Color(0xFF00BFA5);
  static const darkErrorColor = Color(0xFFCF6679);
  static const darkBackgroundColor = Color(0xFF121212);
  static const darkCardColor = Color(0xFF1E1E1E);
  static const darkSurfaceColor = Color(0xFF1E1E1E);

  // Text Styles
  static const TextStyle headlineStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle titleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 14,
  );

  // Shadows
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get buttonShadow => [
        BoxShadow(
          color: primaryColor.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  // Border Radius
  static BorderRadius defaultBorderRadius = BorderRadius.circular(12);
  static BorderRadius buttonBorderRadius = BorderRadius.circular(8);
  static BorderRadius cardBorderRadius = BorderRadius.circular(16);

  // Light Theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      error: errorColor,
      background: backgroundColor,
      surface: surfaceColor,
    ),
    scaffoldBackgroundColor: backgroundColor,
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: cardBorderRadius,
      ),
      color: cardColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: buttonBorderRadius,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: buttonBorderRadius,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: buttonBorderRadius,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: buttonBorderRadius,
      ),
      filled: true,
      fillColor: Colors.white,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey.shade200,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    dividerTheme: const DividerThemeData(
      space: 24,
      thickness: 1,
    ),
  );

  // Dark Theme
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: darkPrimaryColor,
      secondary: darkSecondaryColor,
      error: darkErrorColor,
      background: darkBackgroundColor,
      surface: darkSurfaceColor,
    ),
    scaffoldBackgroundColor: darkBackgroundColor,
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: cardBorderRadius,
      ),
      color: darkCardColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkPrimaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: buttonBorderRadius,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: buttonBorderRadius,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: buttonBorderRadius,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: buttonBorderRadius,
      ),
      filled: true,
      fillColor: darkCardColor,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey.shade800,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    dividerTheme: const DividerThemeData(
      space: 24,
      thickness: 1,
    ),
  );
}
