import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/services/currency_service.dart';

class FareDetailsSection extends StatelessWidget {
  /// Pre-converted base fare in INR (or original currency if conversion pending).
  final double baseFare;

  /// Pre-converted tax in INR (or original currency if conversion pending).
  final double taxes;

  /// Display currency — shown as symbol (₹ for INR).
  final String currency;

  final String bookingCode;
  final VoidCallback? onContinueToPayment;

  /// True while the parent is fetching the live exchange rate.
  final bool isConverting;

  const FareDetailsSection({
    super.key,
    required this.baseFare,
    required this.taxes,
    required this.currency,
    required this.bookingCode,
    this.onContinueToPayment,
    this.isConverting = false,
  });

  @override
  Widget build(BuildContext context) {
    final sym = CurrencyService.symbol(currency);
    final totalAmount = baseFare + taxes;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: context.responsivePadding,
              child: isConverting
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 10),
                          Text('Fetching live price in ₹...'),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        _buildFareRow(context, 'Base Fare',
                            '$sym ${baseFare.toStringAsFixed(2)}'),
                        const SizedBox(height: 8),
                        _buildFareRow(context, 'Tax & Charges',
                            '$sym ${taxes.toStringAsFixed(2)}'),
                        const Divider(height: 24),
                        _buildTotalRow(context, 'Total Amount:',
                            '$sym ${totalAmount.toStringAsFixed(2)}'),
                        const SizedBox(height: 16),
                        _buildContinueButton(context, sym, totalAmount),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFareRow(BuildContext context, String label, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.add, size: context.sp(14), color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: context.sp(14), color: Colors.grey[700])),
          ],
        ),
        Text(amount,
            style: TextStyle(
                fontSize: context.sp(14), color: Colors.grey[700])),
      ],
    );
  }

  Widget _buildTotalRow(
      BuildContext context, String label, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: context.titleMedium,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
        Text(amount,
            style: TextStyle(
                fontSize: context.titleMedium,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
      ],
    );
  }

  Widget _buildContinueButton(
      BuildContext context, String sym, double total) {
    return ElevatedButton(
      onPressed: onContinueToPayment,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red[700],
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: const Size(double.infinity, 50),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Continue to Payment  $sym ${total.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: context.titleMedium,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward, color: Colors.white),
        ],
      ),
    );
  }
}
