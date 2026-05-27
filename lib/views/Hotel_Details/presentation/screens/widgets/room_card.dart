import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../../../UI_helper/currency_converter.dart';
import '../../../../../core/utils/storage/shared_preference.dart';
import '../../../../../injection_container.dart';
import '../../../domain/entities/rooms_entity.dart';

class RoomCard extends StatefulWidget {
  final RoomEntity room;
  final int adults;
  final int children;
  final VoidCallback onSelect;
  final String roomCurrency;

  const RoomCard({
    super.key,
    required this.room,
    required this.adults,
    required this.children,
    required this.onSelect,
    required this.roomCurrency,
  });

  @override
  State<RoomCard> createState() => _RoomCardState();
}

class _RoomCardState extends State<RoomCard> {

  @override
  Widget build(BuildContext context) {
    print('RoomCard: Building - ${widget.room.roomDisplayName}, Fare: ${widget.room.totalFare}');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveExtension(context).borderRadius),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRoomHeader(context),
          Padding(
            padding: ResponsiveExtension(context).responsivePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRoomDetails(context),
                const SizedBox(height: 6),
                _buildInclusions(context),
                if (widget.room.roomPromotion.isNotEmpty) ...[
                  // const SizedBox(height: 12),
                  // _buildPromotions(context),
                ],
                // const SizedBox(height: 16),
                _buildPriceAndButton(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double amount, String apiCurrency) {
    try {
      // 🔹 Use currency passed from parent (more reliable than entity field)
      final currency = apiCurrency.isNotEmpty ? apiCurrency : widget.roomCurrency;

      double finalAmount = amount;
      String displayCurrency = currency;

      // Get user's preferred currency (defaults to INR)
      final prefs = sl<PreferencesManager>();
      final targetCurrency = prefs.getPreferredCurrency() ?? 'INR';

      // Convert only if different and we have valid currency codes
      if (currency.isNotEmpty &&
          targetCurrency.isNotEmpty &&
          currency.toUpperCase() != targetCurrency.toUpperCase()) {

        finalAmount = CurrencyConverter.convert(
          amount: amount,
          fromCurrency: currency,
          toCurrency: targetCurrency,
        );
        displayCurrency = targetCurrency;
      }

      // Format with symbol based on DISPLAY currency (after conversion)
      final code = displayCurrency.toUpperCase();
      final intAmount = finalAmount.toInt();

      if (code == 'INR') {
        return '₹${_formatIndianNumber(intAmount)}';
      } else if (code == 'USD') {
        return '\$${intAmount.toStringAsFixed(0)}';
      } else if (code == 'EUR') {
        return '€${intAmount.toStringAsFixed(0)}';
      } else if (code == 'GBP') {
        return '£${intAmount.toStringAsFixed(0)}';
      } else if (code == 'AED') {
        return 'د.إ ${intAmount.toStringAsFixed(0)}';
      }
      // Fallback: show code + amount
      return '$code ${intAmount.toStringAsFixed(0)}';

    } catch (e) {
      print('RoomCard: Price format error: $e');
      // Safe fallback: show original amount with passed currency
      final code = apiCurrency.isNotEmpty ? apiCurrency : widget.roomCurrency;
      return '$code ${amount.toStringAsFixed(0)}';
    }
  }

  //  REUSE: Indian number formatting (1,00,000 style)
  String _formatIndianNumber(int num) {
    if (num < 1000) return num.toString();
    final str = num.toString();
    final lastThree = str.substring(str.length - 3);
    final remaining = str.substring(0, str.length - 3);
    var formatted = '';
    for (int i = 0; i < remaining.length; i++) {
      if (i > 0 && (remaining.length - i) % 2 == 0) {
        formatted += ',';
      }
      formatted += remaining[i];
    }
    return '$formatted,$lastThree';
  }

  Widget _buildRoomHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Color(0xFFF9F9F9),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.meeting_room,
            color: Colors.blue,
            size: ResponsiveExtension(context).sp(20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.room.roomDisplayName,
                  style: TextStyle(
                    fontSize: ResponsiveExtension(context).sp(16),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  widget.room.bedInfo,
                  style: TextStyle(
                    fontSize: ResponsiveExtension(context).sp(12),
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (!widget.room.isRefundable)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Text(
                'Non-Refundable',
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: ResponsiveExtension(context).sp(10),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRoomDetails(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.people, size: ResponsiveExtension(context).sp(16), color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              '${widget.adults} Guest${widget.adults > 1 ? 's' : ''}${widget.children > 0 ? ', ${widget.children} Child${widget.children > 1 ? 'ren' : ''}' : ''}',
              style: TextStyle(
                fontSize: ResponsiveExtension(context).sp(14),
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        if (widget.room.withTransfers) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.airport_shuttle, size: ResponsiveExtension(context).sp(16), color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'Free beach transfer included',
                style: TextStyle(
                  fontSize: ResponsiveExtension(context).sp(14),
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildInclusions(BuildContext context) {
    final inclusions = widget.room.inclusion.split(',').map((i) => i.trim()).where((i) => i.isNotEmpty).toList();

    if (inclusions.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: inclusions.map((inclusion) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check,
                size: ResponsiveExtension(context).sp(12),
                color: Colors.green[700],
              ),
              const SizedBox(width: 4),
              Text(
                inclusion,
                style: TextStyle(
                  fontSize: ResponsiveExtension(context).sp(12),
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Widget _buildPriceAndButton(BuildContext context) {
  //   return Row(
  //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //     children: [
  //       Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Row(
  //             crossAxisAlignment: CrossAxisAlignment.baseline,
  //             textBaseline: TextBaseline.alphabetic,
  //             children: [
  //               Text(
  //                 widget.room.totalFare.toLocaleString(),
  //                 style: TextStyle(
  //                   fontSize: ResponsiveExtension(context).sp(24),
  //                   fontWeight: FontWeight.bold,
  //                   color: Colors.black87,
  //                 ),
  //               ),
  //               Text(
  //                 ' / night',
  //                 style: TextStyle(
  //                   fontSize: ResponsiveExtension(context).sp(14),
  //                   color: Colors.grey[600],
  //                 ),
  //               ),
  //             ],
  //           ),
  //           Text(
  //             '+ ${widget.room.totalTax.toLocaleString()} taxes',
  //             style: TextStyle(
  //               fontSize: ResponsiveExtension(context).sp(12),
  //               color: Colors.grey[600],
  //             ),
  //           ),
  //         ],
  //       ),
  //       ElevatedButton(
  //         onPressed: () => widget.onSelect(),
  //         style: ElevatedButton.styleFrom(
  //           backgroundColor: Colors.red[700],
  //           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  //           shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.circular(8),
  //           ),
  //         ),
  //         child: Text(
  //           'Book Room',
  //           style: TextStyle(
  //             fontSize: ResponsiveExtension(context).sp(14),
  //             fontWeight: FontWeight.w600,
  //             color: Colors.white,
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildPriceAndButton(BuildContext context) {
    // 🔹 Pass the currency from parent widget
    final formattedFare = _formatPrice(widget.room.totalFare, widget.roomCurrency);
    final formattedTax = _formatPrice(widget.room.totalTax, widget.roomCurrency);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  formattedFare,
                  style: TextStyle(
                    fontSize: ResponsiveExtension(context).sp(24),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  ' / night',
                  style: TextStyle(
                    fontSize: ResponsiveExtension(context).sp(14),
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            Text(
              '+ $formattedTax taxes',
              style: TextStyle(
                fontSize: ResponsiveExtension(context).sp(12),
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        ElevatedButton(
          onPressed: () => widget.onSelect(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[700],
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Book Room',
            style: TextStyle(
              fontSize: ResponsiveExtension(context).sp(14),
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

// Extension for number formatting
extension NumberFormatting on num {
  String toLocaleString() {
    return toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }
}