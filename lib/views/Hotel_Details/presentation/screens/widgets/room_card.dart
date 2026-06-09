import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';
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
  static const _blue = Color(0xFF1769F6);
  static const _navy = Color(0xFF071638);
  static const _muted = Color(0xFF6B7280);
  static const _border = Color(0xFFE2E7F0);

  @override
  Widget build(BuildContext context) {
    print(
      'RoomCard: Building - ${widget.room.roomDisplayName}, Fare: ${widget.room.totalFare}',
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(14)),
        border: Border.all(color: _border, width: 1),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.06),
            blurRadius: context.r(16),
            offset: Offset(0, context.h(10)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRoomHeader(context),
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.w(14),
              context.h(12),
              context.w(14),
              context.h(14),
            ),
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
      final currency = apiCurrency.isNotEmpty
          ? apiCurrency
          : widget.roomCurrency;

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

      // Display amount without any currency sign
      final code = displayCurrency.toUpperCase();
      final intAmount = finalAmount.toInt();

      if (code == 'INR') {
        return _formatIndianNumber(intAmount);
      }
      return intAmount.toStringAsFixed(0);
    } catch (e) {
      print('RoomCard: Price format error: $e');
      // Safe fallback: show original amount without sign
      return amount.toStringAsFixed(0);
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
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFE),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(context.r(14)),
          topRight: Radius.circular(context.r(14)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.meeting_room_outlined, color: _blue, size: context.w(20)),
          SizedBox(width: context.w(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.room.roomDisplayName,
                  style: TextStyle(
                    fontSize: context.fs(15),
                    fontWeight: FontWeight.w800,
                    color: _navy,
                    height: 1.25,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.room.bedInfo,
                  style: TextStyle(
                    fontSize: context.fs(12),
                    color: _muted,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (!widget.room.isRefundable)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.w(9),
                vertical: context.h(6),
              ),
              // decoration: BoxDecoration(
              //   color: const Color(0xFFFFF0F0),
              //   borderRadius: BorderRadius.circular(context.r(10)),
              //   border: Border.all(color: const Color(0xFFFFB3B3)),
              // ),
              child: Text(
                'Non-Refundable',
                style: TextStyle(
                  color: const Color(0xFFD92D20),
                  fontSize: context.fs(10),
                  fontWeight: FontWeight.w800,
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
            Icon(Icons.people_outline, size: context.w(15), color: _muted),
            SizedBox(width: context.w(4)),
            Text(
              '${widget.adults} Guest${widget.adults > 1 ? 's' : ''}${widget.children > 0 ? ', ${widget.children} Child${widget.children > 1 ? 'ren' : ''}' : ''}',
              style: TextStyle(
                fontSize: context.fs(12),
                color: _muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        if (widget.room.withTransfers) ...[
          SizedBox(height: context.h(8)),
          Row(
            children: [
              Icon(Icons.airport_shuttle, size: context.w(15), color: _muted),
              SizedBox(width: context.w(4)),
              Text(
                'Free beach transfer included',
                style: TextStyle(
                  fontSize: context.fs(12),
                  color: _muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildInclusions(BuildContext context) {
    final inclusions = widget.room.inclusion
        .split(',')
        .map((i) => i.trim())
        .where((i) => i.isNotEmpty)
        .toList();

    if (inclusions.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: context.w(8),
      runSpacing: context.h(8),
      children: inclusions.map((inclusion) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.w(8),
            vertical: context.h(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check,
                size: context.w(11),
                color: Colors.green[700],
              ),
              SizedBox(width: context.w(4)),
              Text(
                inclusion,
                style: TextStyle(
                  fontSize: context.fs(11),
                  color: Colors.green[700],
                  fontWeight: FontWeight.w700,
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
    final formattedFare = _formatPrice(
      widget.room.totalFare,
      widget.roomCurrency,
    );
    final formattedTax = _formatPrice(
      widget.room.totalTax,
      widget.roomCurrency,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final stack = constraints.maxWidth < 360;
        final price = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(
                    formattedFare,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.fs(20),
                      fontWeight: FontWeight.w900,
                      color: _navy,
                    ),
                  ),
                ),
                SizedBox(width: context.w(5)),
                Text(
                  '/ night',
                  style: TextStyle(
                    fontSize: context.fs(12),
                    color: _muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: context.h(3)),
            Text(
              '+ $formattedTax taxes',
              style: TextStyle(
                fontSize: context.fs(11),
                color: _muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );

        final button = SizedBox(
          height: context.h(44),
          width: stack ? double.infinity : context.w(150),
          child: ElevatedButton(
            onPressed: () => widget.onSelect(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.r(12)),
              ),
            ),
            child: Text(
              'Book Room',
              style: TextStyle(
                fontSize: context.fs(13),
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        );

        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [price, SizedBox(height: context.h(12)), button],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: price),
            SizedBox(width: context.w(14)),
            button,
          ],
        );
      },
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
