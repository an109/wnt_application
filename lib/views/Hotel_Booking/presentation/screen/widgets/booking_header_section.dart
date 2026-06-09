import 'package:flutter/material.dart';

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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHotelInfo(context),
          const Divider(height: 1, color: _border),
          _buildBookingDetails(context),
        ],
      ),
    );
  }

  Widget _buildHotelInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: MediaQuery.sizeOf(context).width - 110,
                child: Text(
                  hotelName,
                  style: const TextStyle(
                    fontSize: 25,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFB3B3)),
                  ),
                  child: const Text(
                    'Non-Refundable',
                    style: TextStyle(
                      color: Color(0xFFD92D20),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStarRating(context, hotelRating),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$hotelRating Star',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, size: 18, color: _muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  address,
                  style: const TextStyle(
                    fontSize: 15,
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
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              hotelImage,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 150,
                  color: Colors.grey[200],
                  child: const Icon(Icons.hotel, size: 64, color: Colors.grey),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 150,
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
          size: 17,
        );
      }),
    );
  }

  Widget _buildBookingDetails(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFE),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
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
            return Wrap(
              spacing: 10,
              runSpacing: 12,
              children: items
                  .map(
                    (item) => SizedBox(
                      width: constraints.maxWidth < 390
                          ? (constraints.maxWidth - 10) / 2
                          : (constraints.maxWidth - 20) / 3,
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
          style: const TextStyle(
            fontSize: 11,
            color: BookingHeaderSection._muted,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            color: BookingHeaderSection._navy,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}
