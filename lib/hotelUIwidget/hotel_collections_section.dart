import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../common_widgets/fast_network_image_cache_manager.dart';
import '../views/ExclusiveDeals/domain/entities/exclusive_deal_entity.dart';
import '../views/ExclusiveDeals/presentation/bloc/exclusive_deals_bloc.dart';
import '../views/ExclusiveDeals/presentation/bloc/exclusive_deals_state.dart';
import '../views/ExclusiveDeals/presentation/screen/dealDetails_Screen.dart';
import 'hotel_deal_filter.dart';

/// "Collections" photo mosaic — redesigned to match
/// `AkHotelCollectionsSection` (the Akbar results screen's equivalent):
/// the same Courier Prime heading, tapered gold-gradient star divider, and
/// cached-image tiles with a gradient name-label overlay.
///
/// Built entirely from real hotel deals already fetched by the
/// [ExclusiveDealsBloc] that [DealsSection] loads elsewhere on this screen
/// (a `BlocProvider<ExclusiveDealsBloc>` must be an ancestor) — there's no
/// separate Collections API, so this reuses that already-loaded data instead
/// of static/marketing imagery. Needs 4+ distinct hotel deals with a photo
/// to lay out the 1-big + 3-small grid without faking a tile; renders
/// nothing until then rather than showing a partial/fake mosaic.
class HotelCollectionsSection extends StatelessWidget {
  static const minDealsRequired = 4;

  const HotelCollectionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExclusiveDealsBloc, ExclusiveDealsState>(
      builder: (context, state) {
        if (state is! ExclusiveDealsLoaded) return const SizedBox.shrink();

        final deals = hotelCategoryDeals(state.deals);
        if (deals.length < minDealsRequired) return const SizedBox.shrink();

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: context.wp(4)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Collections',
                style: GoogleFonts.courierPrime(
                  fontSize: context.fs(22),
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                  height: 1.0,
                  letterSpacing: 0.7,
                ),
              ),
              _buildCollectionsDivider(context),
              SizedBox(
                height: context.h(190),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 5, child: _tile(context, deals[0])),
                    SizedBox(width: context.w(8)),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(flex: 3, child: _tile(context, deals[1])),
                          SizedBox(height: context.h(8)),
                          Expanded(
                            flex: 2,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: _tile(context, deals[2])),
                                SizedBox(width: context.w(8)),
                                Expanded(child: _tile(context, deals[3])),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _buildCollectionsDivider(context),
            ],
          ),
        );
      },
    );
  }

  Widget _tile(BuildContext context, ExclusiveDealEntity deal) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DealDetailsScreen(deal: deal)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.r(10)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: deal.imageUrl,
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
                  deal.title,
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
      height: context.h(24),
      margin: EdgeInsets.symmetric(vertical: context.h(12)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            size: Size(double.infinity, context.h(24)),
            painter: _TaperedDividerPainter(
              startColor: const Color(0xFFFDD835),
              endColor: const Color(0xFFF4B400),
              lineHeight: 3.0,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, size: context.w(10), color: const Color(0xFFF4B400)),
                SizedBox(width: context.w(4)),
                Icon(Icons.star, size: context.w(18), color: const Color(0xFFF4B400)),
                SizedBox(width: context.w(4)),
                Icon(Icons.star, size: context.w(10), color: const Color(0xFFF4B400)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Same thin, long, tapered gold gradient line (with a gap for the stars) as
/// `AkHotelCollectionsSection`'s own painter — duplicated rather than shared
/// since that one is a private implementation detail of the Akbar flow.
class _TaperedDividerPainter extends CustomPainter {
  final Color startColor;
  final Color endColor;
  final double lineHeight;

  _TaperedDividerPainter({
    required this.startColor,
    required this.endColor,
    this.lineHeight = 3.0,
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

    const gapWidth = 60.0;
    final gapStart = (size.width / 2) - (gapWidth / 2);
    final gapEnd = (size.width / 2) + (gapWidth / 2);

    final leftPath = Path()
      ..moveTo(0, centerY)
      ..lineTo(gapStart, centerY - halfLineHeight)
      ..lineTo(gapStart, centerY + halfLineHeight)
      ..close();

    final rightPath = Path()
      ..moveTo(size.width, centerY)
      ..lineTo(gapEnd, centerY - halfLineHeight)
      ..lineTo(gapEnd, centerY + halfLineHeight)
      ..close();

    canvas.drawPath(leftPath, paint);
    canvas.drawPath(rightPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
