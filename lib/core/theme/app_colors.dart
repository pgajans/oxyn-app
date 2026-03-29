import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Background
  static const Color background = Color(0xFF0A0E1A);
  static const Color surface = Color(0xFF141B2D);
  static const Color surfaceLight = Color(0xFF1C2438);

  // Primary - Oxygen Blue (Neon Cyan)
  static const Color primary = Color(0xFF00E5FF);
  static const Color primaryDark = Color(0xFF00B8D4);
  static const Color primaryLight = Color(0xFF4DFFFF);

  // Secondary - Orange (Warning/Energy)
  static const Color secondary = Color(0xFFFF6B35);
  static const Color secondaryLight = Color(0xFFFF8F60);

  // Tertiary - Electric Purple (Premium)
  static const Color tertiary = Color(0xFFB388FF);
  static const Color tertiaryDark = Color(0xFF7C4DFF);

  // Semantic
  static const Color success = Color(0xFF00E676);
  static const Color danger = Color(0xFFFF5252);
  static const Color warning = Color(0xFFFFAB40);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8892A0);
  static const Color textTertiary = Color(0xFF5A6270);

  // Score gradient
  static const List<Color> scoreGradientGood = [
    Color(0xFF00E676),
    Color(0xFF00E5FF),
  ];

  static const List<Color> scoreGradientMedium = [
    Color(0xFFFFAB40),
    Color(0xFFFF6B35),
  ];

  static const List<Color> scoreGradientBad = [
    Color(0xFFFF5252),
    Color(0xFFFF6B35),
  ];

  static List<Color> scoreGradient(int score) {
    if (score >= 70) return scoreGradientGood;
    if (score >= 40) return scoreGradientMedium;
    return scoreGradientBad;
  }
}
