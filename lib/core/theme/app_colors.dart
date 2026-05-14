import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary palette - Deep Indigo/Purple
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF9D97FF);
  static const Color primaryDark = Color(0xFF4A42E8);
  static const Color primarySurface = Color(0xFFF0EEFF);

  // Secondary palette - Warm Coral
  static const Color secondary = Color(0xFFFF6B6B);
  static const Color secondaryLight = Color(0xFFFF9B9B);
  static const Color secondaryDark = Color(0xFFE84545);

  // Accent palette - Teal
  static const Color accent = Color(0xFF2EC4B6);
  static const Color accentLight = Color(0xFF5EDFD3);
  static const Color accentDark = Color(0xFF1A9E91);

  // Neutral palette
  static const Color darkBg = Color(0xFF0F0E17);
  static const Color darkSurface = Color(0xFF1A1930);
  static const Color darkCard = Color(0xFF232247);
  static const Color darkElevated = Color(0xFF2D2B55);

  static const Color lightBg = Color(0xFFF8F7FF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF5F3FF);

  // Text colors
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textMedium = Color(0xFF4A4A6A);
  static const Color textLight = Color(0xFF8888AA);
  static const Color textOnDark = Color(0xFFF8F7FF);
  static const Color textOnDarkMedium = Color(0xFFB8B8D0);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFB74D);
  static const Color error = Color(0xFFEF5350);
  static const Color info = Color(0xFF42A5F5);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, Color(0xFF38D9A9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFFC947)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [darkBg, Color(0xFF1A1940)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF4A42E8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
