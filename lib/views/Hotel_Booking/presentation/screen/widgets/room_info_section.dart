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
        borderRadius: BorderRadius.circular(context.r(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: context.h(10),
            offset: Offset(0, context.h(2)),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(context.w(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'More Information',
              style: TextStyle(
                fontSize: context.fs(20),
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
            SizedBox(height: context.h(16)),
            _buildSectionTitle(context, 'ROOM DETAILS'),
            _buildInfoRow(context, 'Room:', room.name.isNotEmpty ? room.name.first : 'N/A'),
            _buildInfoRow(context, 'Meal Type:', room.mealType.isNotEmpty ? room.mealType : 'Room Only'),
            _buildInfoRow(context, 'Guests:', '1 Adult'),
            SizedBox(height: context.h(16)),
            if (room.roomPromotion.isNotEmpty) ...[
              _buildSectionTitle(context, 'ROOM PROMOTIONS'),
              ...room.roomPromotion.map((promotion) => _buildPromotionTag(context, promotion)),
              SizedBox(height: context.h(16)),
            ],
            if (room.inclusion.isNotEmpty) ...[
              _buildSectionTitle(context, 'INCLUSIONS'),
              ...room.inclusion.split(',').map((inclusion) => _buildInclusionItem(context, inclusion.trim())),
              SizedBox(height: context.h(14)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.h(8)),
      child: Text(
        title,
        style: TextStyle(
          fontSize: context.fs(15),
          fontWeight: FontWeight.w600,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.h(8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: context.w(100),
            child: Text(
              label,
              style: TextStyle(
                fontSize: context.fs(13),
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: context.fs(13),
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
      margin: EdgeInsets.only(bottom: context.h(8)),
      padding: EdgeInsets.symmetric(
          horizontal: context.w(12),
          vertical: context.h(8)
      ),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(context.r(8)),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Icon(
              Icons.check_circle,
              color: Colors.green[700],
              size: context.w(16)
          ),
          SizedBox(width: context.w(8)),
          Expanded(
            child: Text(
              promotion,
              style: TextStyle(
                fontSize: context.fs(13),
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
      padding: EdgeInsets.only(
          bottom: context.h(8),
          left: context.w(24)
      ),
      child: Row(
        children: [
          Icon(
              Icons.check,
              size: context.w(14),
              color: Colors.grey[600]
          ),
          SizedBox(width: context.w(8)),
          Expanded(
            child: Text(
              inclusion,
              style: TextStyle(
                fontSize: context.fs(14),
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

// Widget _buildMandatoryFee(BuildContext context) {
//   return Container(
//     padding: const EdgeInsets.all(12),
//     decoration: BoxDecoration(
//       color: Colors.amber[50],
//       borderRadius: BorderRadius.circular(8),
//       border: Border.all(color: Colors.amber[200]!),
//     ),
//     child: Row(
//       children: [
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Text(
//                     'City Tax',
//                     style: TextStyle(
//                       fontSize: context.sp(14),
//                       fontWeight: FontWeight.w600,
//                       color: Colors.amber[900],
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                     decoration: BoxDecoration(
//                       color: Colors.amber[100],
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                     child: Text(
//                       'Paid at property',
//                       style: TextStyle(
//                         fontSize: context.sp(11),
//                         color: Colors.amber[800],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 'These charges are collected directly at the property and are not included in the room price.',
//                 style: TextStyle(
//                   fontSize: context.sp(12),
//                   color: Colors.amber[900],
//                 ),
//               ),
//             ],
//           ),
//         ),
//         Text(
//           'AED 10',
//           style: TextStyle(
//             fontSize: context.sp(14),
//             fontWeight: FontWeight.bold,
//             color: Colors.amber[900],
//           ),
//         ),
//       ],
//     ),
//   );
// }
}