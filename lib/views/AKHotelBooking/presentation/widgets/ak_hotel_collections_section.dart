import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../UI_helper/responsive_layout.dart';
import '../../../../common_widgets/fast_network_image_cache_manager.dart';
import '../../../../core/resources/app_colours.dart';
import '../../../Hotel_api/domain/entities/hotel_ui_entity.dart';

/// "Collections" photo mosaic from the Figma reference — but built entirely
/// from real, already-loaded hotel photos (the top-rated hotels of this
/// search) rather than any static/marketing imagery. Each tile opens that
/// hotel exactly like every other card on the results screen.
///
/// Needs a full set of 4 distinct photographed hotels to lay out the
/// reference's 1-big + 3-small grid without faking a tile — callers should
/// only render this when [hotels] has 4+ entries (see [minHotelsRequired]).
class AkHotelCollectionsSection extends StatelessWidget {
  static const minHotelsRequired = 4;

  final List<HotelUiModel> hotels;
  final ValueChanged<HotelUiModel> onSelect;

  const AkHotelCollectionsSection({super.key, required this.hotels, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    if (hotels.length < minHotelsRequired) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: context.gapMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.gapLarge),
            child: Text(
              'Collections',
              style: GoogleFonts.courierPrime(  // or GoogleFonts.spaceMono()
                fontSize: context.fs(22),
                fontWeight: FontWeight.w400,
                color: Colors.black,
                height: 1.0,
                letterSpacing: 0.7,
              ),
            ),
          ),
          // SizedBox(height: context.gapSmall),
          _buildCollectionsDivider(context),
          // SizedBox(height: context.gapSmall),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.gapLarge),
            child: SizedBox(
              height: context.h(190),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 5, child: _tile(context, hotels[0])),
                  SizedBox(width: context.gapSmall),
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 3, child: _tile(context, hotels[1])),
                        SizedBox(height: context.gapSmall),
                        Expanded(
                          flex: 2,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: _tile(context, hotels[2])),
                              SizedBox(width: context.gapSmall),
                              Expanded(child: _tile(context, hotels[3])),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildCollectionsDivider(context),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, HotelUiModel hotel) {
    final imageUrl = hotel.images.isNotEmpty ? hotel.images.first : hotel.image;
    return GestureDetector(
      onTap: () => onSelect(hotel),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.r(10)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            imageUrl.isEmpty
                ? Container(color: Colors.grey.shade200)
                : CachedNetworkImage(
                    imageUrl: imageUrl,
                    cacheManager: FastNetworkImageCacheManager.instance,
                    fit: BoxFit.cover,
                    memCacheWidth: 500,
                    fadeInDuration: const Duration(milliseconds: 150),
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey.shade200,
                      highlightColor: Colors.grey.shade100,
                      child: Container(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => Container(color: Colors.grey.shade200),
                  ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: context.w(8), vertical: context.h(6)),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withValues(alpha: 0.55), Colors.transparent],
                  ),
                ),
                child: Text(
                  hotel.hotelName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: context.fs(11)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionsDivider(BuildContext context) {
    return Container(
      // Container is tall enough to hold the large star, but the line itself is thin
      height: context.h(24),
      margin: EdgeInsets.symmetric(horizontal: context.gapLarge, vertical: context.h(12)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // The thin, long, tapered gradient lines
          CustomPaint(
            size: Size(double.infinity, context.h(24)),
            painter: _TaperedDividerPainter(
              startColor: const Color(0xFFFDD835), // Lighter yellow
              endColor: const Color(0xFFF4B400),   // Golden yellow
              lineHeight: 3.0, // Keep the line very thin
            ),
          ),
          // The three stars centered perfectly in the white gap
          Positioned(
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Small left star
                Icon(Icons.star, size: context.w(10), color: const Color(0xFFF4B400)),
                SizedBox(width: context.w(4)),
                // Large middle star
                Icon(Icons.star, size: context.w(18), color: const Color(0xFFF4B400)),
                SizedBox(width: context.w(4)),
                // Small right star
                Icon(Icons.star, size: context.w(10), color: const Color(0xFFF4B400)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


/// Custom painter to draw the exact thin, long, tapered line with a gap for stars.
class _TaperedDividerPainter extends CustomPainter {
  final Color startColor;
  final Color endColor;
  final double lineHeight; // Max thickness of the line near the stars

  _TaperedDividerPainter({
    required this.startColor,
    required this.endColor,
    this.lineHeight = 3.0, // Very thin line
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [startColor, endColor],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final centerY = size.height / 2;
    final halfLineHeight = lineHeight / 2;

    // Fixed gap width for the stars (adjust if needed, e.g., 50-70px)
    final gapWidth = 60.0;
    final gapStart = (size.width / 2) - (gapWidth / 2);
    final gapEnd = (size.width / 2) + (gapWidth / 2);

    // Left tapered line: starts at a sharp point on the far left, gets thicker towards the gap
    final leftPath = Path();
    leftPath.moveTo(0, centerY); // Far left sharp point
    leftPath.lineTo(gapStart, centerY - halfLineHeight); // Top edge at gap
    leftPath.lineTo(gapStart, centerY + halfLineHeight); // Bottom edge at gap
    leftPath.close();

    // Right tapered line: starts thick at the gap, tapers to a sharp point on the far right
    final rightPath = Path();
    rightPath.moveTo(size.width, centerY); // Far right sharp point
    rightPath.lineTo(gapEnd, centerY - halfLineHeight); // Top edge at gap
    rightPath.lineTo(gapEnd, centerY + halfLineHeight); // Bottom edge at gap
    rightPath.close();

    canvas.drawPath(leftPath, paint);
    canvas.drawPath(rightPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}