import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

class BookingHeaderSection extends StatelessWidget {
  final String hotelImage;
  final String hotelName;
  final int hotelRating;
  final String address;
  final String checkIn;
  final String checkOut;
  final int adults;
  final int children;
  final String roomName;
  final bool isRefundable;
  static const _navy = Color(0xFF071638);
  static const _border = Color(0xFFE2E7F0);
  static const _muted = Color(0xFF6B7280);

  const BookingHeaderSection({
    super.key,
    required this.hotelImage,
    required this.hotelName,
    required this.hotelRating,
    required this.address,
    required this.checkIn,
    required this.checkOut,
    required this.adults,
    required this.children,
    required this.roomName,
    required this.isRefundable,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.06),
            blurRadius: context.h(24),
            offset: Offset(0, context.h(14)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHotelInfo(context),
          Divider(height: context.h(1), color: _border),
          _buildBookingDetails(context),
        ],
      ),
    );
  }

  Widget _buildHotelInfo(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.w(17),
        context.h(15),
        context.w(15),
        context.h(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: context.w(10),
            runSpacing: context.h(10),
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: context.screenWidth - context.w(110),
                child: Text(
                  hotelName,
                  style: TextStyle(
                    fontSize: context.fs(22),
                    fontWeight: FontWeight.w800,
                    color: _navy,
                    height: 1.18,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isRefundable)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(2),
                  ),
                  child: Text(
                    'Non-Refundable',
                    style: TextStyle(
                      color: const Color(0xFFD92D20),
                      fontSize: context.fs(12),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: context.h(8)),
          Row(
            children: [
              _buildStarRating(context, hotelRating),
            ],
          ),
          SizedBox(height: context.h(12)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on, size: context.w(18), color: _muted),
              SizedBox(width: context.w(8)),
              Expanded(
                child: Text(
                  address,
                  style: TextStyle(
                    fontSize: context.fs(15),
                    color: _muted,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(13)),
          ClipRRect(
            // borderRadius: BorderRadius.circular(context.r(10)),
            child: Image.network(
              hotelImage,
              height: context.h(180),
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: context.h(150),
                  color: Colors.grey[200],
                  child: Icon(Icons.hotel, size: context.w(64), color: Colors.grey),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: context.h(150),
                  color: Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating(BuildContext context, int rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: context.w(17),
        );
      }),
    );
  }

  Widget _buildBookingDetails(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.w(15),
        context.h(13),
        context.w(15),
        context.h(18),
      ),
      child: Container(
        padding: EdgeInsets.all(context.w(12)),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFE),
          // borderRadius: BorderRadius.circular(context.r(18)),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: _navy.withValues(alpha: 0.06),
              blurRadius: context.h(24),
              offset: Offset(0, context.h(14)),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final items = [
              _InfoItem(label: 'Check-in', value: checkIn),
              _InfoItem(label: 'Check-out', value: checkOut),
              _InfoItem(
                label: 'Guests',
                value:
                '$adults Adult${adults > 1 ? 's' : ''}${children > 0 ? ', $children Child${children > 1 ? 'ren' : ''}' : ''}',
              ),
            ];

            // Responsive breakpoint based on screen width
            final isNarrowScreen = constraints.maxWidth < context.w(390);

            return Wrap(
              spacing: context.w(10),
              runSpacing: context.h(12),
              children: items
                  .map(
                    (item) => SizedBox(
                  width: isNarrowScreen
                      ? (constraints.maxWidth - context.w(10)) / 2
                      : (constraints.maxWidth - context.w(20)) / 3,
                  child: item,
                ),
              )
                  .toList(),
            );
          },
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: context.fs(11),
            color: BookingHeaderSection._muted,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: context.h(6)),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: context.fs(15),
            color: BookingHeaderSection._navy,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}