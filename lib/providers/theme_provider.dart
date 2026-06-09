import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ThemeProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider(this._prefs) {
    _loadTheme();
  }

  void _loadTheme() {
    final isDark = _prefs.getBool('isDarkMode') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await _prefs.setBool('isDarkMode', _themeMode == ThemeMode.dark);
    notifyListeners();
  }

  // Define Light Theme Data
  ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppConstants.primaryTeal,
      scaffoldBackgroundColor: AppConstants.lightBg,
      cardColor: AppConstants.lightCard,
      dividerColor: AppConstants.lightBorder,
      colorScheme: const ColorScheme.light(
        primary: AppConstants.primaryTeal,
        secondary: AppConstants.primaryTealLight,
        background: AppConstants.lightBg,
        surface: AppConstants.lightCard,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: AppConstants.lightTextPrimary),
        titleTextStyle: TextStyle(
          color: AppConstants.lightTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppConstants.lightTextPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: AppConstants.lightTextSecondary, fontSize: 14),
        titleLarge: TextStyle(color: AppConstants.lightTextPrimary, fontSize: 20, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: AppConstants.lightTextPrimary, fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  // Define Dark Theme Data (Total Black matching reference image)
  ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppConstants.primaryTeal,
      scaffoldBackgroundColor: AppConstants.darkBg,
      cardColor: AppConstants.darkCard,
      dividerColor: AppConstants.darkBorder,
      colorScheme: const ColorScheme.dark(
        primary: AppConstants.primaryTeal,
        secondary: AppConstants.primaryTealDark,
        background: AppConstants.darkBg,
        surface: AppConstants.darkCard,
        surfaceVariant: AppConstants.darkCardHover,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppConstants.darkBg,
        elevation: 0,
        iconTheme: IconThemeData(color: AppConstants.darkTextPrimary),
        titleTextStyle: TextStyle(
          color: AppConstants.darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppConstants.darkTextPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: AppConstants.darkTextSecondary, fontSize: 14),
        titleLarge: TextStyle(color: AppConstants.darkTextPrimary, fontSize: 22, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: AppConstants.darkTextPrimary, fontSize: 16, fontWeight: FontWeight.w600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryTeal,
          foregroundColor: Colors.black, // Dark text on light button matching image
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
