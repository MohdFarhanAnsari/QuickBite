import 'package:flutter/material.dart';

/// Centralized spacing and border radius constants for QuickBite.
/// Provides a consistent 4-point/8-point grid system.
abstract class AppSpacing {
  // Spacing Units
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 40.0;

  // Edge Insets Convenience
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets pagePaddingDense = EdgeInsets.symmetric(
    horizontal: md,
  );
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets cardPaddingLg = EdgeInsets.all(lg);

  // Border Radii
  static const double radiusXs = 6.0;
  static const double radiusSm = 10.0;
  static const double radiusMd = 14.0;
  static const double radiusLg = 18.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 999.0;

  // BorderRadius Convenience
  static const BorderRadius roundedXs = BorderRadius.all(
    Radius.circular(radiusXs),
  );
  static const BorderRadius roundedSm = BorderRadius.all(
    Radius.circular(radiusSm),
  );
  static const BorderRadius roundedMd = BorderRadius.all(
    Radius.circular(radiusMd),
  );
  static const BorderRadius roundedLg = BorderRadius.all(
    Radius.circular(radiusLg),
  );
  static const BorderRadius roundedXl = BorderRadius.all(
    Radius.circular(radiusXl),
  );
  static const BorderRadius roundedFull = BorderRadius.all(
    Radius.circular(radiusFull),
  );

  // Common UI Dimensions
  static const double buttonHeight = 48.0;
  static const double buttonHeightSm = 36.0;
  static const double searchBarHeight = 50.0;
  static const double restaurantCardWidth = 250.0;
  static const double restaurantCardHeight = 265.0;
  static const double restaurantCardImageHeight = 135.0;
  static const double foodCardImageSize = 84.0;
  static const double promoBannerHeight = 165.0;
}
