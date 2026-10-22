import 'package:flutter/material.dart';

/// Centralized color palette for the QuickBite application.
/// Ensures consistent branding, accessibility, and effortless theming.
abstract class AppColors {
  // Primary Brand Colors
  static const Color primary = Color(
    0xFFFF6B35,
  ); // Warm appetizing coral-orange
  static const Color primaryDark = Color(0xFFE85924);
  static const Color primaryLight = Color(0xFFFFEFE9);
  static const Color primarySurface = Color(0xFFFFF6F2);

  // Secondary & Accents
  static const Color secondary = Color(0xFF2EC4B6); // Fresh mint accent
  static const Color secondaryLight = Color(0xFFE7F9F7);
  static const Color accentYellow = Color(0xFFFFB800); // Ratings & badges

  // Neutral Colors (Light Palette)
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3F4F6);

  // Text Colors
  static const Color textPrimary = Color(
    0xFF111827,
  ); // High contrast dark charcoal
  static const Color textSecondary = Color(0xFF6B7280); // Medium gray
  static const Color textMuted = Color(0xFF9CA3AF); // Light gray
  static const Color textInverse = Color(0xFFFFFFFF);

  // Borders & Dividers
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderSubtle = Color(0xFFF3F4F6);
  static const Color divider = Color(0xFFE5E7EB);

  // Dietary Indicators (Industry Standards)
  static const Color vegGreen = Color(0xFF10B981);
  static const Color nonVegRed = Color(0xFFEF4444);

  // Feedback Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Soft Shadows
  static const BoxShadow shadowSm = BoxShadow(
    color: Color(0x0A000000),
    blurRadius: 8,
    offset: Offset(0, 2),
  );

  static const BoxShadow shadowMd = BoxShadow(
    color: Color(0x0F000000),
    blurRadius: 16,
    offset: Offset(0, 4),
  );

  static const BoxShadow shadowLg = BoxShadow(
    color: Color(0x14000000),
    blurRadius: 24,
    offset: Offset(0, 8),
  );

  static const BoxShadow primaryGlow = BoxShadow(
    color: Color(0x33FF6B35),
    blurRadius: 16,
    offset: Offset(0, 6),
  );
}
