import 'package:flutter/material.dart';

// Shared surface styling for the redesigned screens (Home, Flight…), so the
// raised-card shadow stays identical everywhere.

/// Raised-card shadow: the Figma geometry (X 0, Y 6, blur 24, spread 0)
/// in #E2F6FF at 84% (0xD6 alpha), so white cards lift off the white page.
const List<BoxShadow> kRaisedCardShadow = [
  BoxShadow(
    color: Color(0xD6E2F6FF),
    offset: Offset(0, 6),
    blurRadius: 24,
  ),
];
