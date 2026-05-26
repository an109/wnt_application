import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF0054A0);
  static const accent = Color(0xFFFF3B30);
  static const lightBg = Color(0xFFF7F9FC);
  static const white = Colors.white;
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF666666);
  static const textLight = Color(0xFF999999);
  static const divider = Color(0xFFE0E0E0);
  static const shadow = Color(0x1A000000);

  static const chipGradient = LinearGradient(
    colors: [Color(0xFF5B86E5), Color(0xFF36D1DC)],
  );

  static const cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0054A0), Color(0xFF0077CC)],
  );
}