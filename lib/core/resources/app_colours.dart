import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF0054A0);
  // static const AppBlue = Color(0xff0066CB);
  static const AppBlue = Color(0xff00A1E4);
  static const accent = Color(0xFFFF3B30);
  static const lightBg = Color(0xFFF7F9FC);
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF666666);
  static const textLight = Color(0xFF999999);
  static const divider = Color(0xFFE0E0E0);
  static const shadow = Color(0x1A000000);
  static const OrangeColor = Color(0xFFFF6600);
  static const lightblue = Color(0xFFBAE6FD);
  static const orange = Color(0xffF97316);
  static const navy = Color(0xff07163B);
  static const muted = Color(0xff6B7280);
  static const grey = Color(0xFF6D6D6D);
  static const subhead = Color(0xFF757575);
  static const lightsubhead = Color(0xFFCCCCCC);

  static const fieldFill = Color(0xffF6F7FB);
  static const fieldBorder = Color(0xffECEEF4);

  static const chipGradient = LinearGradient(
    colors: [Color(0xFF5B86E5), Color(0xFF36D1DC)],
  );

  static const cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0054A0), Color(0xFF0077CC)],
  );

  // ---------------------------------------------------------------- splash
  // Sampled from the Wander Nova splash / auth designs.
  static const splashTop = Color(0xFFD4F2FF);
  static const splashBottom = Color(0xFFFFFFFF);

  static const splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [splashTop, splashBottom],
    stops: [0.0, 0.95],
  );

  /// The third colour of the brand mark, beside [AppBlue] and [OrangeColor].
  static const brandTeal = Color(0xFF0FA3A1);

  // ------------------------------------------------------------ auth forms
  static const authInk = Color(0xFF0F1010);
  static const authSubtle = Color(0xFF6E6E73);
  static const authFieldBorder = Color(0xFFE6E6E6);
  static const authFieldLabel = Color(0xFF8E8E93);
  static const authHint = Color(0xFF9A9A9F);
  static const authFieldIcon = Color(0xFFC3C3C7);
}