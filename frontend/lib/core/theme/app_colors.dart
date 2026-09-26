import 'package:flutter/material.dart';

/// Centralized color palette for KrushiMitra.
///
/// Widgets should reference these constants (directly or via
/// [Theme.of(context).colorScheme]) rather than hard-coding colors.
class AppColors {
  AppColors._();

  // Agricultural greens
  static const Color primaryGreen = Color(0xFF2F6B3C);
  static const Color primaryGreenDark = Color(0xFF24552F);

  // Warm accent
  static const Color accentGold = Color(0xFFE5A24A);

  // Surfaces
  static const Color background = Color(0xFFF7F5EF);
  static const Color surface = Color(0xFFFFFDF8);

  // Text
  static const Color textPrimary = Color(0xFF172019);
  static const Color textSecondary = Color(0xFF667067);

  // Status
  static const Color success = Color(0xFF2F8F5B);
  static const Color warning = Color(0xFFD99532);
  static const Color error = Color(0xFFC95F5F);
  static const Color info = Color(0xFF4B8FBF);
}