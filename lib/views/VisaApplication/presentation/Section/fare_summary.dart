import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

class FareSummary extends StatelessWidget {
  final int travellers;
  final double basePrice;
  final String currencySymbol;
  final double? taxesAndCharges;

  const FareSummary({
    Key? key,
    required this.travellers,
    required this.basePrice,
    required this.currencySymbol,
    this.taxesAndCharges = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final total = basePrice * travellers;
    final formattedTotal = total.toStringAsFixed(total % 1 == 0 ? 0 : 2);
    final formattedBasePrice = basePrice.toStringAsFixed(basePrice % 1 == 0 ? 0 : 2);
    final formattedTaxes = taxesAndCharges!.toStringAsFixed(taxesAndCharges! % 1 == 0 ? 0 : 2);

    return Container(
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: context.w(8),
            offset: Offset(0, context.h(2)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Fare Summary',
                style: TextStyle(
                  fontSize: context.fs(12),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '$travellers Traveller${travellers > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: context.fs(10),
                  color: const Color(0xff0D47A1),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(12)),
          _buildPriceRow(
            context,
            label: 'Base Fare',
            amount: '$currencySymbol$formattedBasePrice',
          ),
          SizedBox(height: context.h(4)),
          _buildPriceRow(
            context,
            label: 'Taxes & charges',
            amount: '$currencySymbol$formattedTaxes',
          ),
          Divider(
            height: context.h(12),
            color: Colors.grey,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Grand Total',
                style: TextStyle(
                  fontSize: context.fs(12),
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$currencySymbol$formattedTotal',
                style: TextStyle(
                  fontSize: context.fs(16),
                  fontWeight: FontWeight.w800,
                  color: const Color(0xffFF6B00),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
      BuildContext context, {
        required String label,
        required String amount,
      }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              Icons.add_circle_outline,
              size: context.iconXSmall,
              color: Colors.grey.shade400,
            ),
            SizedBox(width: context.w(6)),
            Text(
              label,
              style: TextStyle(
                fontSize: context.fs(11),
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: context.fs(11),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}