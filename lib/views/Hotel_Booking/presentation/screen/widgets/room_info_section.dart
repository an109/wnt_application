import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../domain/entities/hotel_booking_entity.dart';


class RoomInfoSection extends StatelessWidget {
  final RoomEntity room;
  final String currency;

  const RoomInfoSection({
    super.key,
    required this.room,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: context.responsivePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'More Information',
              style: TextStyle(
                fontSize: context.headlineSmall,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionTitle(context, 'ROOM DETAILS'),
            _buildInfoRow(context, 'Room:', room.name.isNotEmpty ? room.name.first : 'N/A'),
            _buildInfoRow(context, 'Meal Type:', room.mealType.isNotEmpty ? room.mealType : 'Room Only'),
            _buildInfoRow(context, 'Guests:', '1 Adult'),
            const SizedBox(height: 16),
            if (room.roomPromotion.isNotEmpty) ...[
              _buildSectionTitle(context, 'ROOM PROMOTIONS'),
              ...room.roomPromotion.map((promotion) => _buildPromotionTag(context, promotion)),
              const SizedBox(height: 16),
            ],
            if (room.inclusion.isNotEmpty) ...[
              _buildSectionTitle(context, 'INCLUSIONS'),
              ...room.inclusion.split(',').map((inclusion) => _buildInclusionItem(context, inclusion.trim())),
              const SizedBox(height: 16),
            ],
            _buildSectionTitle(context, 'MANDATORY FEES AT PROPERTY'),
            _buildMandatoryFee(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: context.titleSmall,
          fontWeight: FontWeight.w600,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: context.sp(14),
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: context.sp(14),
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionTag(BuildContext context, String promotion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green[700], size: context.sp(16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              promotion,
              style: TextStyle(
                fontSize: context.sp(13),
                color: Colors.green[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInclusionItem(BuildContext context, String inclusion) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 24),
      child: Row(
        children: [
          Icon(Icons.check, size: context.sp(14), color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              inclusion,
              style: TextStyle(
                fontSize: context.sp(14),
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMandatoryFee(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'City Tax',
                      style: TextStyle(
                        fontSize: context.sp(14),
                        fontWeight: FontWeight.w600,
                        color: Colors.amber[900],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Paid at property',
                        style: TextStyle(
                          fontSize: context.sp(11),
                          color: Colors.amber[800],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'These charges are collected directly at the property and are not included in the room price.',
                  style: TextStyle(
                    fontSize: context.sp(12),
                    color: Colors.amber[900],
                  ),
                ),
              ],
            ),
          ),
          Text(
            'AED 10',
            style: TextStyle(
              fontSize: context.sp(14),
              fontWeight: FontWeight.bold,
              color: Colors.amber[900],
            ),
          ),
        ],
      ),
    );
  }
}