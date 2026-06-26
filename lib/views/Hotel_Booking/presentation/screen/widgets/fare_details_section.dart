import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../../../UI_helper/currency_converter.dart';

class FareDetailsSection extends StatelessWidget {
  /// Pre-converted base fare in original currency (USD/AED/etc)
  final double baseFare;

  /// Pre-converted tax in original currency (USD/AED/etc)
  final double taxes;

  /// Original currency from API (USD/AED/etc)
  final String originalCurrency;

  /// User's preferred currency (INR/USD/AED etc)
  final String preferredCurrency;

  final String bookingCode;
  final VoidCallback? onContinueToPayment;

  /// True while the parent is fetching the live exchange rate
  final bool isConverting;

  const FareDetailsSection({
    super.key,
    required this.baseFare,
    required this.taxes,
    required this.originalCurrency,
    required this.preferredCurrency,
    required this.bookingCode,
    this.onContinueToPayment,
    this.isConverting = false,
  });

  @override
  Widget build(BuildContext context) {
    // Convert amounts to preferred currency
    final convertedBaseFare = isConverting
        ? baseFare
        : CurrencyConverter.convert(
      amount: baseFare,
      fromCurrency: originalCurrency,
      toCurrency: preferredCurrency,
    );

    final convertedTaxes = isConverting
        ? taxes
        : CurrencyConverter.convert(
      amount: taxes,
      fromCurrency: originalCurrency,
      toCurrency: preferredCurrency,
    );

    final totalAmount = convertedBaseFare + convertedTaxes;
    final sym = CurrencyConverter.getSymbol(preferredCurrency); // You'll need to add this method

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: context.h(10),
            offset: Offset(0, context.h(-2)),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(context.w(16)),
              child: isConverting
                  ? Padding(
                padding: EdgeInsets.symmetric(vertical: context.h(16)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: context.w(18),
                      height: context.h(18),
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: context.w(10)),
                    const Text('Fetching live price in your currency...'),
                  ],
                ),
              )
                  : Column(
                children: [
                  _buildFareRow(context, 'Base Fare',
                      '${convertedBaseFare.toStringAsFixed(2)}'),
                  SizedBox(height: context.h(8)),
                  _buildFareRow(context, 'Tax & Charges',
                      '${convertedTaxes.toStringAsFixed(2)}'),
                  Divider(height: context.h(24)),
                  _buildTotalRow(context, 'Total Amount:',
                      '${totalAmount.toStringAsFixed(2)}'),
                  SizedBox(height: context.h(16)),
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
            Icon(Icons.add, size: context.w(13), color: Colors.grey[600]),
            SizedBox(width: context.w(4)),
            Text(label,
                style: TextStyle(
                    fontSize: context.fs(13), color: Colors.grey[700])),
          ],
        ),
        Text(amount,
            style: TextStyle(
                fontSize: context.fs(13), color: Colors.grey[700])),
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
                fontSize: context.fs(17),
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
        Text(amount,
            style: TextStyle(
                fontSize: context.fs(17),
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
        padding: EdgeInsets.symmetric(vertical: context.h(16)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(8))),
        minimumSize: Size(double.infinity, context.h(50)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Continue to Payment  ${total.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: context.fs(17),
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(width: context.w(10)),
          const Icon(Icons.arrow_forward, color: Colors.white),
        ],
      ),
    );
  }
}