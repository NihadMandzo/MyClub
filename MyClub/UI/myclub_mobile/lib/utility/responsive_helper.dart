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
  static double font(BuildContext context, {double base = 14}) {
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
}
