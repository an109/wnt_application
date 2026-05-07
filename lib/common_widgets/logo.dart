import 'package:flutter/material.dart';

/// A custom widget that replicates the Wander Nova logo style.
class WanderNovaLogo extends StatelessWidget {
  /// You can change the scale of the logo by adjusting this multiplier.
  final double scaleFactor;

  const WanderNovaLogo({
    super.key,
    this.scaleFactor = 1.0,
  });

  // Define the specific colors extracted from the image
  static const Color _kBlueColor = Color(0xFF0054A0);
  static const Color _kOrangeColor = Color(0xFFFF7200);
  static const Color _kTealColor = Color(0xFF009999);

  // Shadow style for the main text to match the image
  static const List<Shadow> _kTextShadow = [
    Shadow(
      offset: Offset(1.5, 1.5),
      blurRadius: 2.0,
      color: Color.fromRGBO(0, 0, 0, 0.25),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min, // Ensure it doesn't take infinite height
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Main Title: "WANDER NOVA"
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: "WANDER ", // Note the space at the end
                style: TextStyle(
                  color: _kBlueColor,
                  fontSize: 28 * scaleFactor,
                  fontFamily: 'Serif', // Use a serif font like Georgia or Times New Roman
                  fontWeight: FontWeight.bold,
                  shadows: _kTextShadow,
                ),
              ),
              TextSpan(
                text: "NOVA",
                style: TextStyle(
                  color: _kOrangeColor,
                  fontSize: 28 * scaleFactor,
                  fontFamily: 'Serif',
                  fontWeight: FontWeight.bold,
                  shadows: _kTextShadow,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 2 * scaleFactor),

        // Subtitle: "TRAVEL WITH US"
        Text(
          "TRAVEL WITH US",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _kTealColor,
            fontSize: 12 * scaleFactor,
            letterSpacing: 3.5, // Wide spacing like the image
            fontWeight: FontWeight.normal,
            // Optional: Make this sans-serif for contrast, matching the image
            fontFamily: 'Roboto',
          ),
        ),
      ],
    );
  }
}