import 'package:flutter/material.dart';

/// Breakpoints for small/medium/large devices.
enum DeviceSize { small, medium, large }

/// Helper that provides common responsive values based on width.
class ResponsiveHelper {
  const ResponsiveHelper._();

  static DeviceSize deviceSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return DeviceSize.small;
    if (width <= 480) return DeviceSize.medium;
    return DeviceSize.large;
  }

  /// Scales padding according to device size.
  static EdgeInsets pagePadding(BuildContext context) {
    switch (deviceSize(context)) {
      case DeviceSize.small:
        return const EdgeInsets.all(8);
      case DeviceSize.medium:
        return const EdgeInsets.all(12);
      case DeviceSize.large:
        return const EdgeInsets.all(16);
    }
  }

  /// Scales font size with a base size.
  static double font(BuildContext context, {double base = 16}) { // Increased base from 14 to 16
    switch (deviceSize(context)) {
      case DeviceSize.small:
        return base * 0.95;
      case DeviceSize.medium:
        return base;
      case DeviceSize.large:
        return base * 1.1;
    }
  }

  /// Common card elevation and radius helpers.
  static double cardElevation(BuildContext context) {
    switch (deviceSize(context)) {
      case DeviceSize.small:
        return 1.5;
      case DeviceSize.medium:
        return 2.0;
      case DeviceSize.large:
        return 3.0;
    }
  }

  static double iconSize(BuildContext context) {
    switch (deviceSize(context)) {
      case DeviceSize.small:
        return 20;
      case DeviceSize.medium:
        return 24;
      case DeviceSize.large:
        return 28;
    }
  }

  /// Grid-specific helpers for responsive layouts
  static int gridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 1; // Very small screens
    if (width < 600) return 2; // Small to medium screens
    if (width < 900) return 3; // Large screens
    return 4; // Extra large screens
  }

  static double gridChildAspectRatio(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    
    // Calculate aspect ratio based on device characteristics
    // Lower aspect ratio means taller cards (more height relative to width)
    
    // For very small screens or short devices
    if (width < 360 || height < 600) {
      return 0.6; // Taller cards to accommodate content
    } 
    // For small to medium screens
    else if (width < 480) {
      return 0.65; // Slightly taller cards
    } 
    // For medium to large screens
    else if (width < 600) {
      return 0.7; // Balanced cards
    } 
    // For large screens
    else {
      return 0.75; // More balanced cards
    }
  }

  static double gridSpacing(BuildContext context) {
    switch (deviceSize(context)) {
      case DeviceSize.small:
        return 8;
      case DeviceSize.medium:
        return 12;
      case DeviceSize.large:
        return 16;
    }
  }

  /// Responsive text sizes for product cards
  static double productTitleSize(BuildContext context) {
    switch (deviceSize(context)) {
      case DeviceSize.small:
        return 14; // Increased from 11
      case DeviceSize.medium:
        return 16; // Increased from 13
      case DeviceSize.large:
        return 18; // Increased from 14
    }
  }

  static double productSubtitleSize(BuildContext context) {
    switch (deviceSize(context)) {
      case DeviceSize.small:
        return 12; // Increased from 9
      case DeviceSize.medium:
        return 13; // Increased from 11
      case DeviceSize.large:
        return 14; // Increased from 12
    }
  }

  static double productPriceSize(BuildContext context) {
    switch (deviceSize(context)) {
      case DeviceSize.small:
        return 15; // Increased from 13
      case DeviceSize.medium:
        return 17; // Increased from 15
      case DeviceSize.large:
        return 19; // Increased from 16
    }
  }

  /// Additional responsive text sizes for other UI elements
  static double titleSize(BuildContext context) {
    switch (deviceSize(context)) {
      case DeviceSize.small:
        return 18;
      case DeviceSize.medium:
        return 20;
      case DeviceSize.large:
        return 22;
    }
  }

  static double subtitleSize(BuildContext context) {
    switch (deviceSize(context)) {
      case DeviceSize.small:
        return 14;
      case DeviceSize.medium:
        return 16;
      case DeviceSize.large:
        return 18;
    }
  }

  static double bodyTextSize(BuildContext context) {
    switch (deviceSize(context)) {
      case DeviceSize.small:
        return 14;
      case DeviceSize.medium:
        return 16;
      case DeviceSize.large:
        return 18;
    }
  }

  /// Determines if we should use compact layout based on available space
  static bool shouldUseCompactLayout(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.height < 600 || size.width < 360;
  }

  /// Adaptive spacing that reduces on constrained devices
  static double adaptiveSpacing(BuildContext context, {double base = 8}) {
    if (shouldUseCompactLayout(context)) {
      return base * 0.5;
    }
    switch (deviceSize(context)) {
      case DeviceSize.small:
        return base * 0.75;
      case DeviceSize.medium:
        return base;
      case DeviceSize.large:
        return base * 1.25;
    }
  }

  /// Specific spacing for product card internal elements
  static double productCardSpacing(BuildContext context, {double base = 4}) {
    switch (deviceSize(context)) {
      case DeviceSize.small:
        return base;
      case DeviceSize.medium:
        return base * 1.25;
      case DeviceSize.large:
        return base * 1.5;
    }
  }

  /// Product card padding that scales appropriately
  static EdgeInsets productCardPadding(BuildContext context) {
    switch (deviceSize(context)) {
      case DeviceSize.small:
        return const EdgeInsets.all(6);
      case DeviceSize.medium:
        return const EdgeInsets.all(8);
      case DeviceSize.large:
        return const EdgeInsets.all(10);
    }
  }

  /// Recommended product card dimensions (smaller than main product cards)
  static double recommendedCardWidth(BuildContext context) {
    switch (deviceSize(context)) {
      case DeviceSize.small:
        return 130;
      case DeviceSize.medium:
        return 145;
      case DeviceSize.large:
        return 160;
    }
  }

  static double recommendedCardHeight(BuildContext context) {
    switch (deviceSize(context)) {
      case DeviceSize.small:
        return 200;
      case DeviceSize.medium:
        return 210;
      case DeviceSize.large:
        return 220;
    }
  }
}
