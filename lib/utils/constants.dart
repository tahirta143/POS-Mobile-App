import 'package:flutter/material.dart';

class AppConstants {
  // Global API base link
  static const String apiBaseUrl = 'https://api.pos.afaqmis.com/api';

  // UI Theme Styling Colors (Updated to match reference image)
  static const Color primaryTeal = Color(0xFF14B8A6); // Mint / Cyan (from image)
  static const Color primaryTealDark = Color(0xFF14B8A6); // Teal 600
  static const Color primaryTealLight = Color(0xFF99F6E4); // Teal 200

  // Solid Light Theme colors
  static const Color lightBg = Color(0xFFF8FAFC); // Slate 50
  static const Color lightCard = Colors.white;
  static const Color lightTextPrimary = Color(0xFF0F172A); // Slate 900
  static const Color lightTextSecondary = Color(0xFF64748B); // Slate 500
  static const Color lightBorder = Color(0xFFE2E8F0); // Slate 200

  // Solid Dark Theme colors (Total Black / Dark Grey matching reference)
  static const Color darkBg = Color(0xFF000000); // Pure Black
  static const Color darkCard = Color(0xFF111111); // Very Dark Grey
  static const Color darkCardHover = Color(0xFF1A1A1A); // Slightly lighter for contrast
  static const Color darkTextPrimary = Color(0xFFF8FAFC); // Slate 50
  static const Color darkTextSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color darkBorder = Color(0xFF262626); // Neutral 800

  // Standard border radius (Increased for more rounded look in image)
  static const double borderRadiusLarge = 28.0;
  static const double borderRadiusMedium = 18.0;
  static const double borderRadiusSmall = 12.0;
}
