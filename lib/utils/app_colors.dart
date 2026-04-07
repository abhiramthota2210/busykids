import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF16161E);
  static const Color surfaceLight = Color(0xFF1E1E2A);
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF9D97FF);
  static const Color accent = Color(0xFFFF6584);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0C4);
  static const Color textMuted = Color(0xFF606070);

  // Game-specific palettes
  static const List<Color> bubbleColors = [
    Color(0xFFFF6B6B), Color(0xFF4ECDC4), Color(0xFFFFE66D),
    Color(0xFF6C63FF), Color(0xFFFF8E53), Color(0xFF2ECC71),
  ];

  static const Color blockColor1 = Color(0xFF6C63FF);
  static const Color blockColor2 = Color(0xFFFF6584);
  static const Color blockColor3 = Color(0xFF4ECDC4);
  static const Color blockColor4 = Color(0xFFFFE66D);
  static const Color blockColor5 = Color(0xFFFF8E53);

  static const Color wordHighlight = Color(0xFF6C63FF);
  static const Color wordFound = Color(0xFF2ECC71);
  static const Color wordSelect = Color(0xFFFFE66D);
}