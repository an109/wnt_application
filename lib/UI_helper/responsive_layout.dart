import 'package:flutter/material.dart';

class Responsive {
  // Base design size (change this to your Figma/XD design width)
  static const double designWidth = 375;  // Standard mobile design width
  static const double designHeight = 812; // Optional: for height-based scaling

  // Get screen dimensions
  static double screenWidth(BuildContext context) => MediaQuery.of(context).size.width;
  static double screenHeight(BuildContext context) => MediaQuery.of(context).size.height;

  // Get safe area heights
  static double safeTop(BuildContext context) => MediaQuery.of(context).padding.top;
  static double safeBottom(BuildContext context) => MediaQuery.of(context).padding.bottom;

  // Get available height after removing safe areas
  static double availableHeight(BuildContext context) =>
      screenHeight(context) - safeTop(context) - safeBottom(context);

  // PIXEL-PERFECT scaling based on design width
  static double wp(BuildContext context, double percentage) =>
      screenWidth(context) * percentage / 100;

  // NEW: Pixel-perfect width scaling (use this instead of wp for most cases)
  static double px(BuildContext context, double designPixels) {
    return (designPixels / designWidth) * screenWidth(context);
  }

  // NEW: Pixel-perfect height scaling
  static double py(BuildContext context, double designPixels) {
    return (designPixels / designHeight) * screenHeight(context);
  }

  // Responsive font size (pixel-perfect)
  static double sp(BuildContext context, double designPixels, {double? baseWidth}) {
    double scaleFactor = screenWidth(context) / (baseWidth ?? designWidth);
    double scaledSize = designPixels * scaleFactor;
    // Clamp to prevent extreme sizes (optional)
    return scaledSize.clamp(designPixels * 0.8, designPixels * 1.5);
  }

  // Device type check (using same logic)
  static bool isMobile(BuildContext context) => screenWidth(context) < 600;
  static bool isTablet(BuildContext context) => screenWidth(context) >= 600 && screenWidth(context) < 1200;
  static bool isDesktop(BuildContext context) => screenWidth(context) >= 1200;

  // Orientation check
  static bool isPortrait(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.portrait;
  static bool isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;
}

// COMPLETE REPLACEMENT EXTENSION - Pixel Perfect
extension ResponsiveExtension on BuildContext {
  // Screen dimensions (unchanged)
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  double get statusBarHeight => MediaQuery.of(this).padding.top;
  double get bottomBarHeight => MediaQuery.of(this).padding.bottom;
  double get availableHeight => screenHeight - statusBarHeight - bottomBarHeight;

  // Base design size (change to match your Figma/XD)
  static const double _designWidth = 375;
  static const double _designHeight = 812;

  // ============ PIXEL-PERFECT SCALING METHODS ============

  /// Scale width from design pixels to actual screen pixels
  /// Use this for ALL widths, horizontal paddings, horizontal margins
  /// Example: w(16) will be exactly 16px on 375px screen, scaled on others
  double w(double designPixels) => (designPixels / _designWidth) * screenWidth;

  /// Scale height from design pixels to actual screen pixels
  /// Use this for ALL heights, vertical paddings, vertical margins
  /// Example: h(24) will be exactly 24px on 812px screen, scaled on others
  double h(double designPixels) => (designPixels / _designHeight) * screenHeight;

  /// Scale font size from design pixels
  /// Example: fs(16) for 16px font on design
  double fs(double designPixels) {
    double scaled = (designPixels / _designWidth) * screenWidth;
    return scaled.clamp(designPixels * 0.8, designPixels * 1.5);
  }

  /// Scale radius from design pixels
  /// Example: r(8) for 8px border radius
  double r(double designPixels) => w(designPixels); // Use width-based scaling

  /// Scale for square elements (uses shortest side for perfect squares)
  double sq(double designPixels) {
    double shortestSide = screenWidth < screenHeight ? screenWidth : screenHeight;
    return (designPixels / _designWidth) * shortestSide;
  }

  // ============ LEGACY SUPPORT (Keep all old methods for compatibility) ============

  // Old percentage-based methods (still work but avoid using them for new code)
  double wp(double percentage) => screenWidth * percentage / 100;
  double hp(double percentage) => screenHeight * percentage / 100;

  double sp(double size, {double baseWidth = 375}) {
    double scaleFactor = screenWidth / baseWidth;
    return (size * scaleFactor).clamp(size * 0.8, size * 1.5);
  }

  // Device type (unchanged)
  bool get isMobile => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 1200;
  bool get isDesktop => screenWidth >= 1200;

  bool get isPortrait => MediaQuery.of(this).orientation == Orientation.portrait;
  bool get isLandscape => MediaQuery.of(this).orientation == Orientation.landscape;

  // ============ UPDATED RESPONSIVE VALUES (Now pixel-perfect) ============

  // Responsive padding (now using pixel-perfect scaling)
  EdgeInsets get responsivePadding {
    if (isMobile) return EdgeInsets.all(w(16)); // 16px on design
    if (isTablet) return EdgeInsets.all(w(24)); // 24px on design
    return EdgeInsets.all(w(32)); // 32px on design
  }

  EdgeInsets get horizontalPadding {
    if (isMobile) return EdgeInsets.symmetric(horizontal: w(16));
    if (isTablet) return EdgeInsets.symmetric(horizontal: w(24));
    return EdgeInsets.symmetric(horizontal: w(32));
  }

  EdgeInsets get verticalPadding {
    if (isMobile) return EdgeInsets.symmetric(vertical: h(12));
    if (isTablet) return EdgeInsets.symmetric(vertical: h(20));
    return EdgeInsets.symmetric(vertical: h(24));
  }

  EdgeInsets get sectionMargin {
    if (isMobile) return EdgeInsets.only(bottom: h(16));
    if (isTablet) return EdgeInsets.only(bottom: h(24));
    return EdgeInsets.only(bottom: h(32));
  }

  // Responsive gaps (pixel-perfect)
  double get gapXXSmall => w(4);
  double get gapXSmall => w(6);
  double get gapSmall => w(8);
  double get gapMedium => w(12);
  double get gapLarge => w(16);
  double get gapXLarge => w(20);
  double get gapXXLarge => w(24);

  // Border radius (pixel-perfect)
  double get borderRadiusSmall => r(8);
  double get borderRadiusMedium => r(12);
  double get borderRadiusLarge => r(20);
  double get borderRadius => r(12);

  // Font sizes (pixel-perfect based on design)
  double get displayLarge => fs(57);
  double get displayMedium => fs(45);
  double get displaySmall => fs(36);
  double get headlineLarge => fs(32);
  double get headlineMedium => fs(28);
  double get headlineSmall => fs(24);
  double get titleLarge => fs(20);
  double get titleMedium => fs(18);
  double get titleSmall => fs(16);
  double get bodyLarge => fs(16);
  double get bodyMedium => fs(14);
  double get bodySmall => fs(12);
  double get labelLarge => fs(14);
  double get labelMedium => fs(12);
  double get labelSmall => fs(11);
  double get caption => fs(12);
  double get overline => fs(10);

  // Icon sizes (pixel-perfect)
  double get iconXSmall => w(12);
  double get iconSmall => w(16);
  double get iconMedium => w(20);
  double get iconLarge => w(24);
  double get iconXLarge => w(32);

  // Button sizes (pixel-perfect)
  Size get buttonSizeSmall => Size(w(100), h(40));
  Size get buttonSizeMedium => Size(w(120), h(48));
  Size get buttonSizeLarge => Size(w(140), h(56));

  double get buttonHeightSmall => h(40);
  double get buttonHeightMedium => h(48);
  double get buttonHeightLarge => h(56);
  double get buttonHeight => isMobile ? h(40) : (isTablet ? h(48) : h(56));

  double get buttonWidthSmall => w(100);
  double get buttonWidthMedium => w(120);
  double get buttonWidthLarge => w(140);
  double get buttonWidth => isMobile ? w(120) : (isTablet ? w(150) : w(200));

  double get formFieldHeight => isMobile ? h(48) : (isTablet ? h(52) : h(56));

  BoxConstraints get responsiveConstraints {
    if (isMobile) return const BoxConstraints();
    if (isTablet) return BoxConstraints(maxWidth: w(900));
    return BoxConstraints(maxWidth: w(1200));
  }

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

  ScrollPhysics get scrollPhysics => isMobile
      ? const BouncingScrollPhysics()
      : const ClampingScrollPhysics();

  double get imageHeightSmall => h(200);
  double get imageHeightMedium => h(250);
  double get imageHeightLarge => h(300);
  double get imageHeight => isMobile ? h(200) : (isTablet ? h(250) : h(300));

  double get cardHeightSmall => h(400);
  double get cardHeightMedium => h(450);
  double get cardHeightLarge => h(480);
  double get cardHeight => isMobile ? h(400) : (isTablet ? h(450) : h(480));

  double responsiveFontSize(double desktop, double tablet, double mobile) {
    if (isDesktop) return desktop;
    if (isTablet) return tablet;
    return mobile;
  }

  double get dialogBorderRadius => r(16);
  double get dialogContentPadding => w(20);
  double get dialogActionSpacing => w(8);

  double get radioSize => w(20);

  double get dividerThin => h(1);
  double get dividerMedium => h(1.5);
  double get dividerThick => h(2);

  Offset get shadowOffsetSmall => Offset(0, h(5));
  Offset get shadowOffsetMedium => Offset(0, h(10));
  Offset get shadowOffsetLarge => Offset(0, h(20));

  double get avatarRadius => w(20);
  double get swapButtonRadius => iconMedium + w(4);

  double get letterSpacingTight => -0.5;
  double get letterSpacingNormal => 0;
  double get letterSpacingWide => 0.5;
  double get letterSpacingWider => 1;
  double get letterSpacingWidest => 1.5;
}