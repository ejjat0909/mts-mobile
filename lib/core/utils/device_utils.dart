import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Device type enumeration
enum DeviceType { phone, phoneFolded, phoneUnfolded, tablet, web }

/// Device screen size utility functions
class DeviceUtils {
  // Breakpoints for device types
  static const double phoneMaxWidth = 600;
  static const double tabletMaxWidth = 1300;

  // Foldable phone breakpoints
  // Folded state: typically 300-400px wide (narrow screen)
  static const double foldedPhoneMaxWidth = 400;
  // Unfolded state: typically 600-900px wide (wider than regular phone, narrower than tablet)
  static const double unfoldedPhoneMinWidth = 500;
  static const double unfoldedPhoneMaxWidth = 852;

  // Aspect ratio thresholds for foldable detection
  static const double foldedAspectRatioMin =
      2.0; // Very tall and narrow when folded
  static const double unfoldedAspectRatioMax =
      1.5; // More square-like when unfolded

  /// Check if the current platform is web
  static bool isWeb() {
    return kIsWeb;
  }

  /// Get the device type based on screen width
  static DeviceType getDeviceType(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;

    // If running on web platform, return web
    if (kIsWeb) {
      return DeviceType.web;
    }

    // Check for foldable phones
    final aspectRatio = height / width;

    // Folded phone detection (narrow screen with high aspect ratio)
    if (width < foldedPhoneMaxWidth && aspectRatio >= foldedAspectRatioMin) {
      return DeviceType.phoneFolded;
    }

    // Unfolded phone detection (wider screen with lower aspect ratio)
    if (width >= unfoldedPhoneMinWidth &&
        width < unfoldedPhoneMaxWidth &&
        aspectRatio <= unfoldedAspectRatioMax) {
      return DeviceType.phoneUnfolded;
    }

    // Otherwise, determine by screen width
    if (width < phoneMaxWidth) {
      return DeviceType.phone;
    } else if (width < tabletMaxWidth) {
      return DeviceType.tablet;
    } else {
      return DeviceType.web;
    }
  }

  /// Check if the device is a phone (including foldable phones)
  static bool isPhone(BuildContext context) {
    final deviceType = getDeviceType(context);
    return deviceType == DeviceType.phone ||
        deviceType == DeviceType.phoneFolded ||
        deviceType == DeviceType.phoneUnfolded;
  }

  /// Check if the device is a regular phone (not foldable)
  static bool isRegularPhone(BuildContext context) {
    return getDeviceType(context) == DeviceType.phone;
  }

  /// Check if the device is a foldable phone in folded state
  static bool isFoldedPhone(BuildContext context) {
    return getDeviceType(context) == DeviceType.phoneFolded;
  }

  /// Check if the device is a foldable phone in unfolded state
  static bool isUnfoldedPhone(BuildContext context) {
    return getDeviceType(context) == DeviceType.phoneUnfolded;
  }

  /// Check if the device is a foldable phone (any state)
  static bool isFoldablePhone(BuildContext context) {
    final deviceType = getDeviceType(context);
    return deviceType == DeviceType.phoneFolded ||
        deviceType == DeviceType.phoneUnfolded;
  }

  /// Check if the device is a tablet
  static bool isTablet(BuildContext context) {
    return getDeviceType(context) == DeviceType.tablet;
  }

  /// Check if the device is web or large screen
  static bool isWebOrLargeScreen(BuildContext context) {
    return getDeviceType(context) == DeviceType.web;
  }

  /// Check if the device is mobile (phone or tablet)
  static bool isMobile(BuildContext context) {
    final deviceType = getDeviceType(context);
    return deviceType == DeviceType.phone ||
        deviceType == DeviceType.phoneFolded ||
        deviceType == DeviceType.phoneUnfolded ||
        deviceType == DeviceType.tablet;
  }

  /// Get device type based on custom width and height
  /// Useful when you want to check without BuildContext
  static DeviceType getDeviceTypeFromSize(double width, double height) {
    if (kIsWeb) {
      return DeviceType.web;
    }

    // Check for foldable phones
    final aspectRatio = height / width;

    // Folded phone detection
    if (width < foldedPhoneMaxWidth && aspectRatio >= foldedAspectRatioMin) {
      return DeviceType.phoneFolded;
    }

    // Unfolded phone detection
    if (width >= unfoldedPhoneMinWidth &&
        width < unfoldedPhoneMaxWidth &&
        aspectRatio <= unfoldedAspectRatioMax) {
      return DeviceType.phoneUnfolded;
    }

    if (width < phoneMaxWidth) {
      return DeviceType.phone;
    } else if (width < tabletMaxWidth) {
      return DeviceType.tablet;
    } else {
      return DeviceType.web;
    }
  }

  /// Check if width and height represent a phone
  static bool isPhoneSize(double width, double height) {
    final deviceType = getDeviceTypeFromSize(width, height);
    return deviceType == DeviceType.phone ||
        deviceType == DeviceType.phoneFolded ||
        deviceType == DeviceType.phoneUnfolded;
  }

  /// Check if width and height represent a folded phone
  static bool isFoldedPhoneSize(double width, double height) {
    final aspectRatio = height / width;
    return width < foldedPhoneMaxWidth && aspectRatio >= foldedAspectRatioMin;
  }

  /// Check if width and height represent an unfolded phone
  static bool isUnfoldedPhoneSize(double width, double height) {
    final aspectRatio = height / width;
    return width >= unfoldedPhoneMinWidth &&
        width < unfoldedPhoneMaxWidth &&
        aspectRatio <= unfoldedAspectRatioMax;
  }

  /// Check if width and height represent a tablet
  static bool isTabletSize(double width, double height) {
    return width >= phoneMaxWidth && width < tabletMaxWidth;
  }

  /// Check if width and height represent a web/large screen
  static bool isWebSize(double width, double height) {
    return width >= tabletMaxWidth;
  }

  /// Get a responsive value based on device type
  /// Example: getResponsiveValue(context, phone: 12.0, tablet: 16.0, web: 20.0)
  static T getResponsiveValue<T>({
    required BuildContext context,
    required T phone,
    required T tablet,
    required T web,
    T? phoneFolded,
    T? phoneUnfolded,
  }) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.phone:
        return phone;
      case DeviceType.phoneFolded:
        return phoneFolded ?? phone;
      case DeviceType.phoneUnfolded:
        return phoneUnfolded ?? tablet;
      case DeviceType.tablet:
        return tablet;
      case DeviceType.web:
        return web;
    }
  }

  /// Get device type as a readable string
  static String getDeviceTypeName(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.phone:
        return 'Phone';
      case DeviceType.phoneFolded:
        return 'Phone (Folded)';
      case DeviceType.phoneUnfolded:
        return 'Phone (Unfolded)';
      case DeviceType.tablet:
        return 'Tablet';
      case DeviceType.web:
        return 'Web';
    }
  }

  /// Check if the screen is small (phone)
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < phoneMaxWidth;
  }

  /// Check if the screen is medium (tablet)
  static bool isMediumScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= phoneMaxWidth && width < tabletMaxWidth;
  }

  /// Check if the screen is large (web/desktop)
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletMaxWidth;
  }

  /// Get the number of columns for a grid based on device type
  static int getGridColumns(
    BuildContext context, {
    int phoneColumns = 2,
    int? phoneFoldedColumns,
    int? phoneUnfoldedColumns,
    int tabletColumns = 3,
    int webColumns = 4,
  }) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.phone:
        return phoneColumns;
      case DeviceType.phoneFolded:
        return phoneFoldedColumns ??
            1; // Default to 1 column for narrow folded screen
      case DeviceType.phoneUnfolded:
        return phoneUnfoldedColumns ??
            tabletColumns; // Default to tablet columns
      case DeviceType.tablet:
        return tabletColumns;
      case DeviceType.web:
        return webColumns;
    }
  }

  /// Get responsive font size based on device type
  static double getResponsiveFontSize(
    BuildContext context, {
    double phoneFontSize = 14.0,
    double? phoneFoldedFontSize,
    double? phoneUnfoldedFontSize,
    double tabletFontSize = 16.0,
    double webFontSize = 18.0,
  }) {
    return getResponsiveValue(
      context: context,
      phone: phoneFontSize,
      phoneFolded: phoneFoldedFontSize,
      phoneUnfolded: phoneUnfoldedFontSize,
      tablet: tabletFontSize,
      web: webFontSize,
    );
  }

  /// Get responsive padding based on device type
  static EdgeInsets getResponsivePadding(
    BuildContext context, {
    EdgeInsets phonePadding = const EdgeInsets.all(8.0),
    EdgeInsets? phoneFoldedPadding,
    EdgeInsets? phoneUnfoldedPadding,
    EdgeInsets tabletPadding = const EdgeInsets.all(16.0),
    EdgeInsets webPadding = const EdgeInsets.all(24.0),
  }) {
    return getResponsiveValue(
      context: context,
      phone: phonePadding,
      phoneFolded: phoneFoldedPadding,
      phoneUnfolded: phoneUnfoldedPadding,
      tablet: tabletPadding,
      web: webPadding,
    );
  }

  /// Get screen orientation info for foldable devices
  static Map<String, dynamic> getFoldableInfo(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final aspectRatio = height / width;
    final deviceType = getDeviceType(context);

    return {
      'isFoldable': isFoldablePhone(context),
      'isFolded': isFoldedPhone(context),
      'isUnfolded': isUnfoldedPhone(context),
      'deviceType': deviceType,
      'width': width,
      'height': height,
      'aspectRatio': aspectRatio,
    };
  }
}
