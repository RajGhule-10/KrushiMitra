import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';

/// Centralized ThemeData for KrushiMitra.
///
/// Consumes [AppColors], [AppSpacing], and [AppRadius] rather than
/// duplicating raw values inside widgets.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final colorScheme = const ColorScheme.light(
      primary: AppColors.primaryGreen,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryGreenDark,
      onPrimaryContainer: Colors.white,
      secondary: AppColors.accentGold,
      onSecondary: AppColors.textPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.background,
      onSurfaceVariant: AppColors.textSecondary,
      error: AppColors.error,
      onError: Colors.white,
    );

    final textTheme = _buildTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shadowColor: AppColors.textPrimary.withValues(alpha: 0.08),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdRadius,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primaryGreen.withValues(
            alpha: 0.4,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.smRadius,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.smRadius,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.smRadius,
          borderSide: BorderSide(
            color: AppColors.textSecondary.withValues(alpha: 0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.smRadius,
          borderSide: BorderSide(
            color: AppColors.textSecondary.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.smRadius,
          borderSide: const BorderSide(color: AppColors.primaryGreen),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.textSecondary.withValues(alpha: 0.15),
        thickness: 1,
        space: AppSpacing.xxl,
      ),
    );
  }

  static TextTheme _buildTextTheme() {
    const base = TextStyle(
      color: AppColors.textPrimary,
      fontFamily: 'Roboto',
    );

    return const TextTheme(
      // Large greeting / hero text
      displaySmall: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        height: 1.2,
        color: AppColors.textPrimary,
      ),
      // Headline for a screen
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: AppColors.textPrimary,
      ),
      // Section title
      titleLarge: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AppColors.textPrimary,
      ),
      // Card title
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AppColors.textPrimary,
      ),
      // Body text
      bodyLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: AppColors.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: AppColors.textSecondary,
      ),
      // Buttons
      labelLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),
      // Supporting / caption text
      labelSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: AppColors.textSecondary,
      ),
    ).apply(bodyColor: base.color, displayColor: base.color);
  }
}