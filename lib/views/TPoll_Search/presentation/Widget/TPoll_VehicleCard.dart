import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../domain/entities/TPollSearchEntity.dart';

class TpollVehicleCard extends StatelessWidget {
  final SearchResultEntity result;
  final String currencySymbol;
  final String currencyCode;
  final VoidCallback onTap;

  // Design constants matching website
  static const _primaryBlue = Color(0xff1663F7);
  static const _primaryOrange = Color(0xffF97316);
  static const _darkNavy = Color(0xff0D1B3D);
  static const _successGreen = Color(0xff10B981);

  const TpollVehicleCard({
    super.key,
    required this.result,
    required this.currencySymbol,
    required this.currencyCode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: context.hp(1.5)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: result.bookable
              ? Border.all(color: _primaryOrange.withOpacity(0.25), width: 1.5)
              : Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top badges row ─────────────────────────────
            _buildTopBadgesRow(context),

            Padding(
              padding: EdgeInsets.fromLTRB(
                context.wp(4),
                0,
                context.wp(4),
                context.hp(1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Main content: image + details ──────────
                  _buildMainContent(context),
                  SizedBox(height: context.hp(1.5)),

                  // ── Amenities chips ────────────────────────
                  if (result.amenities.isNotEmpty)
                    _buildAmenitiesSection(context),

                  SizedBox(height: context.hp(1.5)),

                  // ── Divider ────────────────────────────────
                  Divider(color: Colors.grey.shade100, height: 1),
                  SizedBox(height: context.hp(1.5)),

                  // ── Trust signals row ──────────────────────
                  _buildTrustSignals(context),

                  SizedBox(height: context.hp(1.5)),

                  // ── Price + Book button ────────────────────
                  _buildPriceAndBookRow(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Top colored strip with category badge + optional "Bookable" tag
  Widget _buildTopBadgesRow(BuildContext context) {
    final categoryColor = _getCategoryColor(result.vehicleType);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.wp(4),
        vertical: context.hp(0.8),
      ),
      decoration: BoxDecoration(
        color: categoryColor.withOpacity(0.06),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          // Vehicle type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: categoryColor.withOpacity(0.3)),
            ),
            child: Text(
              result.vehicleType,  // ← From API: "Sedan", "Bus", etc.
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: categoryColor,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Vehicle name sub-badge (FROM API)
          if (result.vehicleName?.isNotEmpty == true)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                result.vehicleName!,  // ← "Standard", "Luxury", etc.
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
          const Spacer(),
          // Bookable star badge
          if (result.bookable)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _primaryOrange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, size: 11, color: Colors.white),
                  const SizedBox(width: 3),
                  Text(
                    'Bookable',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  /// Vehicle image on left, details on right
  Widget _buildMainContent(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Vehicle image
        Container(
          width: context.wp(28),
          height: context.hp(13),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildVehicleImage(context),
          ),
        ),
        SizedBox(width: context.wp(4)),
        // Details column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Provider row: logo + name + rating
              _buildProviderRow(context),
              SizedBox(height: context.hp(0.6)),
              // Capacity chips
              _buildCapacityRow(context),
              SizedBox(height: context.hp(0.8)),
              // Travel time estimate (from step details)
              _buildTravelTimeRow(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProviderRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            result.providerName,
            style: TextStyle(
              fontSize: context.titleSmall,
              fontWeight: FontWeight.w700,
              color: _darkNavy,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Rating badge (static 5.0 like website — replace with real data if available)
        Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, size: 11, color: Colors.amber.shade600),
              const SizedBox(width: 2),
              Text(
                '5.0',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.amber.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCapacityRow(BuildContext context) {
    return Wrap(
      spacing: context.wp(3),
      runSpacing: 4,
      children: [
        _iconLabel(
          context,
          icon: Icons.person_outline,
          label: 'Up to ${result.maxPassengers} pax',
        ),
        _iconLabel(
          context,
          icon: Icons.luggage_outlined,
          label: '${result.maxBags} bags',
        ),
      ],
    );
  }

  Widget _buildTravelTimeRow(BuildContext context) {
    // "Flight info needed" / "45 min included" — static for now,
    // extend if your entity has departure_datetime or step time
    return Wrap(
      spacing: context.wp(3),
      runSpacing: 4,
      children: [
        _iconLabel(
          context,
          icon: Icons.access_time_outlined,
          label: '25 min',
          color: Colors.grey.shade500,
        ),
        _iconLabel(
          context,
          icon: Icons.flight_land_outlined,
          label: 'Flight info needed',
          color: Colors.grey.shade500,
        ),
      ],
    );
  }

  Widget _iconLabel(
      BuildContext context, {
        required IconData icon,
        required String label,
        Color? color,
      }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color ?? Colors.grey.shade600),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color ?? Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Amenities chips — matching website style
  Widget _buildAmenitiesSection(BuildContext context) {
    final included =
    result.amenities.where((a) => a.included).take(3).toList();
    final chargeable =
    result.amenities.where((a) => a.chargeable && !a.included).take(2).toList();
    final allToShow = [...included, ...chargeable];

    if (allToShow.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: allToShow.map((amenity) {
        final isIncluded = amenity.included;
        return Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isIncluded
                ? _primaryBlue.withOpacity(0.08)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(4),
            border: isIncluded
                ? null
                : Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isIncluded) ...[
                const Icon(Icons.check, size: 11, color: _primaryBlue),
                const SizedBox(width: 3),
              ],
              Text(
                isIncluded ? amenity.name : '${amenity.name} (+)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                  isIncluded ? FontWeight.w600 : FontWeight.w400,
                  color: isIncluded
                      ? _primaryBlue
                      : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Trust signals: Free cancellation, No hidden fees, SMS notifications etc.
  Widget _buildTrustSignals(BuildContext context) {
    return Wrap(
      spacing: context.wp(4),
      runSpacing: 4,
      children: [
        _trustItem(
          icon: Icons.cancel_outlined,
          label: 'Free cancellation',
          color: _successGreen,
        ),
        _trustItem(
          icon: Icons.visibility_off_outlined,
          label: 'No hidden fees',
          color: _successGreen,
        ),
        _trustItem(
          icon: Icons.sms_outlined,
          label: 'SMS notifications',
          color: Colors.grey.shade600,
        ),
      ],
    );
  }

  Widget _trustItem(
      {required IconData icon,
        required String label,
        required Color color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Price display + Book Now button
  Widget _buildPriceAndBookRow(BuildContext context) {
    final price = double.tryParse(result.totalPriceAmount) ?? 0;
    final formattedPrice =
    price > 0 ? price.toStringAsFixed(0) : result.totalPriceAmount;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Price block
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currencyCode,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  formattedPrice,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _darkNavy,
                    height: 1.1,
                  ),
                ),
              ],
            ),
            Text(
              'per trip',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        const Spacer(),
        // Book Now button
        SizedBox(
          height: 44,
          child: ElevatedButton(
            onPressed: result.bookable ? onTap : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
              result.bookable ? _primaryOrange : Colors.grey.shade300,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: context.wp(6)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  result.bookable ? 'Book Now' : 'Unavailable',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (result.bookable) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward, size: 16),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleImage(BuildContext context) {
    if (result.vehicleImageUrl.isEmpty) {
      return Container(
        color: Colors.grey.shade100,
        child: Center(
          child: Icon(
            Icons.directions_car,
            size: context.iconLarge,
            color: Colors.grey.shade300,
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: result.vehicleImageUrl,
      fit: BoxFit.contain,
      placeholder: (context, url) => Container(
        color: Colors.grey.shade100,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _primaryOrange,
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey.shade100,
        child: Center(
          child: Icon(
            Icons.directions_car,
            size: context.iconLarge,
            color: Colors.grey.shade300,
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String vehicleType) {
    switch (vehicleType.toLowerCase()) {
      case 'private car':
      case 'sedan':
        return _primaryBlue;
      case 'shared shuttle':
        return const Color(0xff8B5CF6);
      case 'bus':
      case 'bus / coach':
        return _successGreen;
      case 'minivan':
      case 'suv':
      case 'minivan / suv':
        return const Color(0xffF59E0B);
      case 'premium':
        return const Color(0xffDC2626);
      default:
        return Colors.grey.shade600;
    }
  }
}