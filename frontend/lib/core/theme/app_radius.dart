import 'package:flutter/material.dart';

/// Centralized corner-radius scale for KrushiMitra.
///
/// Use moderate rounding consistently; avoid pill shapes unless they
/// communicate a meaningful selected/status state.
class AppRadius {
  AppRadius._();

  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;

  static BorderRadius smRadius = BorderRadius.circular(sm);
  static BorderRadius mdRadius = BorderRadius.circular(md);
  static BorderRadius lgRadius = BorderRadius.circular(lg);
  static BorderRadius xlRadius = BorderRadius.circular(xl);
}