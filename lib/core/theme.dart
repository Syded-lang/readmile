import 'package:flutter/material.dart';
import 'package:readmile/core/constants.dart';

class AppTheme {
  static const Color primaryColor = Color(AppConstants.primaryColorHex);
  static const Color accentColor = Color(AppConstants.accentColorHex);

  static ThemeData get lightTheme => ThemeData(
    primaryColor: primaryColor,
    colorScheme: ColorScheme.fromSwatch().copyWith(secondary: accentColor),
    cardTheme: CardThemeData(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      shadowColor: primaryColor.withOpacity(0.2),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: accentColor,
      unselectedLabelColor: Colors.white70,
      indicatorColor: accentColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 2,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: primaryColor,
      contentTextStyle: TextStyle(color: Colors.white),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryColor,
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    primaryColor: primaryColor,
    colorScheme: ColorScheme.fromSwatch().copyWith(
      secondary: accentColor,
      brightness: Brightness.dark,
    ),
    cardTheme: CardThemeData(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.grey[800],
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 2,
      centerTitle: true,
    ),
  );

  // Text Styles for ReadMile
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: primaryColor,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: primaryColor,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: Colors.black87,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: Colors.black54,
    height: 1.4,
  );

  // Reading-specific text styles
  static TextStyle getReadingTextStyle(double fontSize, bool isDarkMode) {
    return TextStyle(
      fontSize: fontSize,
      height: 1.6,
      color: isDarkMode ? Colors.white70 : Colors.black87,
      letterSpacing: 0.1,
    );
  }

  static TextStyle getChapterTitleStyle(double fontSize, bool isDarkMode) {
    return TextStyle(
      fontSize: fontSize + 8,
      fontWeight: FontWeight.bold,
      color: isDarkMode ? Colors.white : primaryColor,
      height: 1.3,
    );
  }
}
