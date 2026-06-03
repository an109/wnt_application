import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Import package

/// A custom widget that replicates the Wander Nova logo style with a shiny glow effect using flutter_animate.
class WanderNovaLogo extends StatelessWidget {
  /// You can change the scale of the logo by adjusting this multiplier.
  final double scaleFactor;

  const WanderNovaLogo({super.key, this.scaleFactor = 1.0});

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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Main Title: "WANDER NOVA"
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "WANDER ",
                    style: TextStyle(
                      color: _kBlueColor,
                      fontSize: 29 * scaleFactor,
                      fontFamily: 'Serif',
                      fontWeight: FontWeight.bold,
                      shadows: _kTextShadow,
                    ),
                  ),
                  TextSpan(
                    text: "NOVA",
                    style: TextStyle(
                      color: _kOrangeColor,
                      fontSize: 29 * scaleFactor,
                      fontFamily: 'Serif',
                      fontWeight: FontWeight.bold,
                      shadows: _kTextShadow,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 2.5 * scaleFactor),

            // Subtitle: "TRAVEL WITH US"
            Text(
              "TRAVEL WITH US",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _kTealColor,
                fontSize: 12.8 * scaleFactor,
                letterSpacing: 3.5,
                fontWeight: FontWeight.normal,
                fontFamily: 'Roboto',
              ),
            ),
          ],
        )
        .animate(
          // Tells the animation engine to play back and forth or repeat indefinitely
          onPlay: (controller) => controller.repeat(),
        )
        .shimmer(
          duration: 2500
              .ms, // Total time taken for the light to cross the entire widget area
          color: Colors.white.withOpacity(
            0.45,
          ), // The brilliance of the reflecting beam shine
          size:
              0.3, // Width thickness of the light sweep lane relative to the text block
          angle: 1.2, // Diagonal slant orientation (expressed in radians)
          curve: Curves
              .easeInOut, // Speed interpolation profile across the animation window
        );
  }
}
