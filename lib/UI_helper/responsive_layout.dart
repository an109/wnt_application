import 'package:flutter/material.dart';

class Responsive {
  // Get screen dimensions
  static double screenWidth(BuildContext context) => MediaQuery.of(context).size.width;
  static double screenHeight(BuildContext context) => MediaQuery.of(context).size.height;

  // Responsive width (percentage based - pass value like 90 for 90%)
  static double wp(BuildContext context, double percentage) => screenWidth(context) * percentage / 100;

  // Responsive height (percentage based - pass value like 5 for 5%)
  static double hp(BuildContext context, double percentage) => screenHeight(context) * percentage / 100;

  // Responsive font size (based on screen width)
  static double sp(BuildContext context, double size) {
    double scaleFactor = screenWidth(context) / 375; // 375 is base design width (iPhone SE)
    return (size * scaleFactor).clamp(size * 0.8, size * 1.5);
  }

  // Device type check
  static bool isMobile(BuildContext context) => screenWidth(context) < 600;
  static bool isTablet(BuildContext context) => screenWidth(context) >= 600 && screenWidth(context) < 1200;
  static bool isDesktop(BuildContext context) => screenWidth(context) >= 1200;

  // Orientation check
  static bool isPortrait(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.portrait;
  static bool isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;
}

// Extension for easier usage throughout the app
extension ResponsiveExtension on BuildContext {
  // Screen dimensions
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  double get statusBarHeight => MediaQuery.of(this).padding.top;
  double get bottomBarHeight => MediaQuery.of(this).padding.bottom;

  // Device type
  bool get isMobile => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 1200;
  bool get isDesktop => screenWidth >= 1200;

  // Orientation
  bool get isPortrait => MediaQuery.of(this).orientation == Orientation.portrait;
  bool get isLandscape => MediaQuery.of(this).orientation == Orientation.landscape;

  // Responsive sizing methods
  double wp(double percentage) => screenWidth * percentage / 100;
  double hp(double percentage) => screenHeight * percentage / 100;

  // Responsive font size (base design width: 375)
  double sp(double size, {double baseWidth = 375}) {
    double scaleFactor = screenWidth / baseWidth;
    return (size * scaleFactor).clamp(size * 0.8, size * 1.5);
  }

  // Responsive padding based on device type
  EdgeInsets get responsivePadding {
    if (isMobile) return const EdgeInsets.all(12);
    if (isTablet) return const EdgeInsets.all(20);
    return const EdgeInsets.all(24);
  }

  EdgeInsets get horizontalPadding {
    if (isMobile) return const EdgeInsets.symmetric(horizontal: 16);
    if (isTablet) return const EdgeInsets.symmetric(horizontal: 24);
    return const EdgeInsets.symmetric(horizontal: 32);
  }

  EdgeInsets get verticalPadding {
    if (isMobile) return const EdgeInsets.symmetric(vertical: 12);
    if (isTablet) return const EdgeInsets.symmetric(vertical: 20);
    return const EdgeInsets.symmetric(vertical: 24);
  }

  // Responsive margins
  EdgeInsets get sectionMargin {
    if (isMobile) return const EdgeInsets.only(bottom: 16);
    if (isTablet) return const EdgeInsets.only(bottom: 24);
    return const EdgeInsets.only(bottom: 32);
  }

  // Responsive gaps/spacing
  double get gapSmall => isMobile ? 8 : (isTablet ? 12 : 16);
  double get gapMedium => isMobile ? 12 : (isTablet ? 16 : 20);
  double get gapLarge => isMobile ? 16 : (isTablet ? 24 : 32);

  // Responsive border radius
  double get borderRadius {
    if (isMobile) return 12;
    if (isTablet) return 16;
    return 20;
  }

  // Responsive font sizes
  double get headlineLarge => sp(32);
  double get headlineMedium => sp(28);
  double get headlineSmall => sp(24);
  double get titleLarge => sp(20);
  double get titleMedium => sp(18);
  double get titleSmall => sp(16);
  double get bodyLarge => sp(16);
  double get bodyMedium => sp(14);
  double get bodySmall => sp(12);
  double get labelLarge => sp(14);
  double get labelMedium => sp(12);
  double get labelSmall => sp(10);

  // Responsive icon sizes
  double get iconSmall => isMobile ? 16 : (isTablet ? 20 : 24);
  double get iconMedium => isMobile ? 20 : (isTablet ? 24 : 28);
  double get iconLarge => isMobile ? 24 : (isTablet ? 28 : 32);

  // Responsive button sizes
  Size get buttonSize {
    if (isMobile) return const Size(120, 40);
    if (isTablet) return const Size(140, 48);
    return const Size(160, 56);
  }

  double get buttonHeight => isMobile ? 40 : (isTablet ? 48 : 56);
  double get buttonWidth => isMobile ? 120 : (isTablet ? 140 : 160);

  // Responsive form field height
  double get formFieldHeight => isMobile ? 48 : (isTablet ? 52 : 60);

  // Responsive container constraints
  BoxConstraints get responsiveConstraints {
    if (isMobile) return const BoxConstraints();
    if (isTablet) return const BoxConstraints(maxWidth: 600);
    return const BoxConstraints(maxWidth: 400);
  }

  // Responsive grid configuration
  int get gridCrossAxisCount {
    if (isMobile) return 2;
    if (isTablet) return 3;
    return 4;
  }

  double get gridChildAspectRatio {
    if (isMobile) return 0.8;
    if (isTablet) return 0.9;
    return 1.0;
  }

  // Scroll physics based on device
  ScrollPhysics get scrollPhysics => isMobile
      ? const BouncingScrollPhysics()
      : const ClampingScrollPhysics();
}