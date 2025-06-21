import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hexcolor/hexcolor.dart';

class ThemeManager extends ChangeNotifier {
  static final ThemeManager _instance = ThemeManager._internal();
  factory ThemeManager() => _instance;
  ThemeManager._internal();

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  // Initialize theme from SharedPreferences
  Future<void> initializeTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }

  // Toggle theme and save to SharedPreferences
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  // Set specific theme mode
  Future<void> setThemeMode(bool isDark) async {
    _isDarkMode = isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }
}

class AppTheme {
  static HexColor primaryColor = HexColor('#901018');
  
  // Light theme colors
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Colors.white;
  static const Color lightCardBackground = Colors.white;
  static const Color lightTextPrimary = Color(0xFF2D3748);
  static const Color lightTextSecondary = Color(0xFF718096);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightDivider = Color(0xFFEDF2F7);
  
  // Dark theme colors
  static const Color darkBackground = Color(0xFF1A202C);
  static const Color darkSurface = Color(0xFF2D3748);
  static const Color darkCardBackground = Color(0xFF2D3748);
  static const Color darkTextPrimary = Color(0xFFF7FAFC);
  static const Color darkTextSecondary = Color(0xFFA0AEC0);
  static const Color darkBorder = Color(0xFF4A5568);
  static const Color darkDivider = Color(0xFF4A5568);

  // Get current theme colors
  static Color getBackgroundColor(bool isDarkMode) {
    return isDarkMode ? darkBackground : lightBackground;
  }

  static Color getSurfaceColor(bool isDarkMode) {
    return isDarkMode ? darkSurface : lightSurface;
  }

  static Color getCardBackgroundColor(bool isDarkMode) {
    return isDarkMode ? darkCardBackground : lightCardBackground;
  }

  static Color getTextPrimaryColor(bool isDarkMode) {
    return isDarkMode ? darkTextPrimary : lightTextPrimary;
  }

  static Color getTextSecondaryColor(bool isDarkMode) {
    return isDarkMode ? darkTextSecondary : lightTextSecondary;
  }

  static Color getBorderColor(bool isDarkMode) {
    return isDarkMode ? darkBorder : lightBorder;
  }

  static Color getDividerColor(bool isDarkMode) {
    return isDarkMode ? darkDivider : lightDivider;
  }

  // Gradient colors for backgrounds
  static List<Color> getGradientColors(bool isDarkMode) {
    if (isDarkMode) {
      return [
        primaryColor.withOpacity(0.15),
        darkBackground,
        primaryColor.withOpacity(0.08),
      ];
    } else {
      return [
        primaryColor.withOpacity(0.1),
        Colors.white,
        primaryColor.withOpacity(0.05),
      ];
    }
  }

  // Shadow colors
  static Color getShadowColor(bool isDarkMode) {
    return isDarkMode 
        ? Colors.black.withOpacity(0.3)
        : Colors.black.withOpacity(0.1);
  }

  // App bar theme
  static AppBarTheme getAppBarTheme(bool isDarkMode) {
    return AppBarTheme(
      backgroundColor: getSurfaceColor(isDarkMode),
      foregroundColor: getTextPrimaryColor(isDarkMode),
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: getTextPrimaryColor(isDarkMode),
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(
        color: getTextPrimaryColor(isDarkMode),
      ),
    );
  }

  // Card theme
  static CardTheme getCardTheme(bool isDarkMode) {
    return CardTheme(
      color: getCardBackgroundColor(isDarkMode),
      elevation: isDarkMode ? 8 : 4,
      shadowColor: getShadowColor(isDarkMode),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  // Input decoration theme
  static InputDecorationTheme getInputDecorationTheme(bool isDarkMode) {
    return InputDecorationTheme(
      filled: true,
      fillColor: getSurfaceColor(isDarkMode),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: getBorderColor(isDarkMode)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: getBorderColor(isDarkMode)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      labelStyle: TextStyle(color: getTextSecondaryColor(isDarkMode)),
      hintStyle: TextStyle(color: getTextSecondaryColor(isDarkMode)),
    );
  }

  // Complete theme data
  static ThemeData getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primarySwatch: MaterialColor(primaryColor.value, {
        50: primaryColor.withOpacity(0.1),
        100: primaryColor.withOpacity(0.2),
        200: primaryColor.withOpacity(0.3),
        300: primaryColor.withOpacity(0.4),
        400: primaryColor.withOpacity(0.5),
        500: primaryColor,
        600: primaryColor.withOpacity(0.7),
        700: primaryColor.withOpacity(0.8),
        800: primaryColor.withOpacity(0.9),
        900: primaryColor,
      }),
      primaryColor: primaryColor,
      scaffoldBackgroundColor: lightBackground,
      appBarTheme: getAppBarTheme(false),
      cardTheme: getCardTheme(false),
      inputDecorationTheme: getInputDecorationTheme(false),
      dividerColor: lightDivider,
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: lightTextPrimary),
        bodyMedium: TextStyle(color: lightTextPrimary),
        titleLarge: TextStyle(color: lightTextPrimary),
        titleMedium: TextStyle(color: lightTextPrimary),
        titleSmall: TextStyle(color: lightTextSecondary),
      ),
    );
  }

  static ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primarySwatch: MaterialColor(primaryColor.value, {
        50: primaryColor.withOpacity(0.1),
        100: primaryColor.withOpacity(0.2),
        200: primaryColor.withOpacity(0.3),
        300: primaryColor.withOpacity(0.4),
        400: primaryColor.withOpacity(0.5),
        500: primaryColor,
        600: primaryColor.withOpacity(0.7),
        700: primaryColor.withOpacity(0.8),
        800: primaryColor.withOpacity(0.9),
        900: primaryColor,
      }),
      primaryColor: primaryColor,
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: getAppBarTheme(true),
      cardTheme: getCardTheme(true),
      inputDecorationTheme: getInputDecorationTheme(true),
      dividerColor: darkDivider,
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: darkTextPrimary),
        bodyMedium: TextStyle(color: darkTextPrimary),
        titleLarge: TextStyle(color: darkTextPrimary),
        titleMedium: TextStyle(color: darkTextPrimary),
        titleSmall: TextStyle(color: darkTextSecondary),
      ),
    );
  }
}
