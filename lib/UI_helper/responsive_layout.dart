import 'package:flutter/material.dart';

class Responsive {
  // Get screen dimensions
  static double screenWidth(BuildContext context) => MediaQuery.of(context).size.width;
  static double screenHeight(BuildContext context) => MediaQuery.of(context).size.height;

  // Get safe area heights
  static double safeTop(BuildContext context) => MediaQuery.of(context).padding.top;
  static double safeBottom(BuildContext context) => MediaQuery.of(context).padding.bottom;

  // Get available height after removing safe areas
  static double availableHeight(BuildContext context) =>
      screenHeight(context) - safeTop(context) - safeBottom(context);

  // Responsive width (percentage based - pass value like 90 for 90%)
  static double wp(BuildContext context, double percentage) => screenWidth(context) * percentage / 100;

  // Responsive height (percentage based - pass value like 5 for 5%)
  static double hp(BuildContext context, double percentage) => screenHeight(context) * percentage / 100;

  // Responsive font size (based on screen width)
  static double sp(BuildContext context, double size, {double baseWidth = 375}) {
    double scaleFactor = screenWidth(context) / baseWidth;
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
  double get availableHeight => screenHeight - statusBarHeight - bottomBarHeight;

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
    if (isMobile) return EdgeInsets.all(wp(3)); // ~12px on 400px
    if (isTablet) return EdgeInsets.all(wp(3.5)); // ~21px on 600px
    return EdgeInsets.all(wp(3)); // ~36px on 1200px
  }

  EdgeInsets get horizontalPadding {
    if (isMobile) return EdgeInsets.symmetric(horizontal: wp(4)); // ~16px on 400px
    if (isTablet) return EdgeInsets.symmetric(horizontal: wp(4)); // ~24px on 600px
    return EdgeInsets.symmetric(horizontal: wp(2.7)); // ~32px on 1200px
  }

  EdgeInsets get verticalPadding {
    if (isMobile) return EdgeInsets.symmetric(vertical: hp(1.5)); // ~12px on 800px
    if (isTablet) return EdgeInsets.symmetric(vertical: hp(1.7)); // ~20px on 1200px
    return EdgeInsets.symmetric(vertical: hp(1.5)); // ~24px on 1600px
  }

  // Responsive margins
  EdgeInsets get sectionMargin {
    if (isMobile) return EdgeInsets.only(bottom: hp(2)); // ~16px on 800px
    if (isTablet) return EdgeInsets.only(bottom: hp(2)); // ~24px on 1200px
    return EdgeInsets.only(bottom: hp(2)); // ~32px on 1600px
  }

  // Responsive gaps/spacing
  double get gapXXSmall => isMobile ? wp(1) : (isTablet ? wp(1.5) : wp(1.2)); // 4px, 9px, 14px
  double get gapXSmall => isMobile ? wp(1.5) : (isTablet ? wp(2) : wp(1.7)); // 6px, 12px, 20px
  double get gapSmall => isMobile ? wp(2) : (isTablet ? wp(2.5) : wp(2.2)); // 8px, 15px, 26px
  double get gapMedium => isMobile ? wp(3) : (isTablet ? wp(3.5) : wp(3.2)); // 12px, 21px, 38px
  double get gapLarge => isMobile ? wp(4) : (isTablet ? wp(5) : wp(4.5)); // 16px, 30px, 54px
  double get gapXLarge => isMobile ? wp(5) : (isTablet ? wp(6) : wp(5.5)); // 20px, 36px, 66px
  double get gapXXLarge => isMobile ? wp(6) : (isTablet ? wp(8) : wp(7)); // 24px, 48px, 84px

  // Responsive border radius
  double get borderRadiusSmall => isMobile ? wp(2) : (isTablet ? wp(2.5) : wp(2.2)); // 8px, 15px, 26px
  double get borderRadiusMedium => isMobile ? wp(3) : (isTablet ? wp(3.5) : wp(3.2)); // 12px, 21px, 38px
  double get borderRadiusLarge => isMobile ? wp(5) : (isTablet ? wp(6) : wp(5.5)); // 20px, 36px, 66px
  double get borderRadius => isMobile ? wp(3) : (isTablet ? wp(3.5) : wp(3.2)); // 12px, 21px, 38px

  // Responsive font sizes (base on 375px design)
  double get displayLarge => sp(57); // 57px
  double get displayMedium => sp(45); // 45px
  double get displaySmall => sp(36); // 36px
  double get headlineLarge => sp(32); // 32px
  double get headlineMedium => sp(28); // 28px
  double get headlineSmall => sp(24); // 24px
  double get titleLarge => sp(20); // 20px
  double get titleMedium => sp(18); // 18px
  double get titleSmall => sp(16); // 16px
  double get bodyLarge => sp(16); // 16px
  double get bodyMedium => sp(14); // 14px
  double get bodySmall => sp(12); // 12px
  double get labelLarge => sp(14); // 14px
  double get labelMedium => sp(12); // 12px
  double get labelSmall => sp(11); // 11px
  double get caption => sp(12); // 12px
  double get overline => sp(10); // 10px

  // Responsive icon sizes
  double get iconXSmall => isMobile ? wp(3) : (isTablet ? wp(3.5) : wp(2.8)); // 12px, 21px, 34px
  double get iconSmall => isMobile ? wp(4) : (isTablet ? wp(4.5) : wp(3.8)); // 16px, 27px, 46px
  double get iconMedium => isMobile ? wp(5) : (isTablet ? wp(5.5) : wp(4.8)); // 20px, 33px, 58px
  double get iconLarge => isMobile ? wp(6) : (isTablet ? wp(7) : wp(6.5)); // 24px, 42px, 78px
  double get iconXLarge => isMobile ? wp(8) : (isTablet ? wp(9) : wp(8.5)); // 32px, 54px, 102px

  // Responsive button sizes
  Size get buttonSizeSmall => Size(wp(25), hp(5)); // 100x40 on 400px
  Size get buttonSizeMedium => Size(wp(30), hp(6)); // 120x48 on 400px
  Size get buttonSizeLarge => Size(wp(35), hp(7)); // 140x56 on 400px

  double get buttonHeightSmall => hp(5); // 40px on 800px
  double get buttonHeightMedium => hp(6); // 48px on 800px
  double get buttonHeightLarge => hp(7); // 56px on 800px
  double get buttonHeight => isMobile ? hp(5) : (isTablet ? hp(6) : hp(7)); // 40, 48, 56

  double get buttonWidthSmall => wp(25); // 100px on 400px
  double get buttonWidthMedium => wp(30); // 120px on 400px
  double get buttonWidthLarge => wp(35); // 140px on 400px
  double get buttonWidth => isMobile ? wp(30) : (isTablet ? wp(25) : wp(20));

  // Responsive form field height
  double get formFieldHeight => isMobile ? hp(6) : (isTablet ? hp(6.5) : hp(7)); // 48, 52, 56

  // Responsive container constraints
  BoxConstraints get responsiveConstraints {
    if (isMobile) return const BoxConstraints();
    if (isTablet) return BoxConstraints(maxWidth: wp(150)); // 900px on 600px
    return BoxConstraints(maxWidth: wp(100)); // 1200px on 1200px
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

  // Responsive image height
  double get imageHeightSmall => hp(25); // 200px on 800px
  double get imageHeightMedium => hp(31); // 250px on 800px
  double get imageHeightLarge => hp(37); // 300px on 800px
  double get imageHeight => isMobile ? hp(25) : (isTablet ? hp(31) : hp(37));

  // Responsive card height
  double get cardHeightSmall => hp(50); // 400px on 800px
  double get cardHeightMedium => hp(56); // 450px on 800px
  double get cardHeightLarge => hp(60); // 480px on 800px
  double get cardHeight => isMobile ? hp(50) : (isTablet ? hp(56) : hp(60));

  double responsiveFontSize(double desktop, double tablet, double mobile) {
    if (isDesktop) return desktop;
    if (isTablet) return tablet;
    return mobile;
  }

  // Dialog specific sizes
  double get dialogBorderRadius => isMobile ? wp(4) : (isTablet ? wp(4.5) : wp(4)); // 16, 27, 48
  double get dialogContentPadding => isMobile ? wp(5) : (isTablet ? wp(5.5) : wp(5)); // 20, 33, 60
  double get dialogActionSpacing => isMobile ? wp(2) : (isTablet ? wp(3) : wp(2.5)); // 8, 18, 30

  // Radio button specific
  double get radioSize => isMobile ? wp(5) : (isTablet ? wp(6) : wp(5.5)); // 20, 36, 66

  // Divider thickness
  double get dividerThin => hp(0.1);
  double get dividerMedium => hp(0.15);
  double get dividerThick => hp(0.2);

  // Shadow offsets
  Offset get shadowOffsetSmall => Offset(0, hp(0.6)); // ~5px
  Offset get shadowOffsetMedium => Offset(0, hp(1.2)); // ~10px
  Offset get shadowOffsetLarge => Offset(0, hp(2.5)); // ~20px

  // Avatar/Icon button sizes
  double get avatarRadius => isMobile ? wp(5) : (isTablet ? wp(6) : wp(5.5)); // 20, 36, 66

  // Specific to your search card
  double get swapButtonRadius => iconMedium + wp(0.5); // Responsive swap button size

  // Letter spacing
  double get letterSpacingTight => -0.5;
  double get letterSpacingNormal => 0;
  double get letterSpacingWide => 0.5;
  double get letterSpacingWider => 1;
  double get letterSpacingWidest => 1.5;
}