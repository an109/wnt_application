import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'trisha_style.dart';

class TrishaTitle extends StatelessWidget {
  final double size;
  const TrishaTitle({super.key, this.size = 18});

  /// Figma gradient: #0088FF → #00A1E4 → #2563EB (left → right).
  static const LinearGradient _gradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF0088FF),
      Color(0xFF00A1E4),
      Color(0xFF2563EB),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (Rect bounds) =>
          _gradient.createShader(Offset.zero & bounds.size),
      child: Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: 'Thrisha.'),
            TextSpan(
              text: 'AI',
              style: GoogleFonts.dmSans(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        style: TrishaStyle.display(context, size, weight: FontWeight.w400)
            .copyWith(color: Colors.white), // color is required; ShaderMask overrides it
      ),
    );
  }
}