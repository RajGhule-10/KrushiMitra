import 'package:flutter/material.dart';

/// Centralized color palette for KrushiMitra — "Warm Agricultural
/// Intelligence": a warm cream/earth foundation with a restrained deep
/// leaf green, warm wheat/amber accents, and a small set of distinct
/// data colors (teal, coral, water blue) for status and metrics.
///
/// Widgets should reference these constants rather than hard-coding
/// colors.
class AppColors {
  AppColors._();

  // Warm foundation
  static const Color background = Color(0xFFF5F0E6); // warm cream
  static const Color surface = Color(0xFFFFF9EF); // warm surface
  static const Color charcoal = Color(0xFF151713); // deep charcoal

  // Agricultural greens
  static const Color primaryGreen = Color(0xFF456B24); // deep leaf
  static const Color primaryGreenDark = Color(0xFF344F1B);
  static const Color olive = Color(0xFF718B32);

  // Warm accents
  static const Color accentGold = Color(0xFFD89A3D); // warm wheat
  static const Color softAmber = Color(0xFFE9A85A);

  // Distinct data / status colors
  static const Color healthyTeal = Color(0xFF20A982);
  static const Color attentionCoral = Color(0xFFD66F68);
  static const Color waterBlue = Color(0xFF4199B5);

  // Text
  static const Color textPrimary = Color(0xFF172019);
  static const Color textSecondary = Color(0xFF667067);
  static const Color textOnDark = Color(0xFFF5F0E6);
  static const Color textOnDarkSecondary = Color(0xFFB8C0B4);

  // Semantic aliases kept stable for existing call sites.
  static const Color success = healthyTeal;
  static const Color warning = softAmber;
  static const Color error = attentionCoral;
  static const Color info = waterBlue;
}
