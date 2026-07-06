import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../../../UI_helper/currency_converter.dart';

class FareDetailsSection extends StatelessWidget {
  final double baseFare;
  final double taxes;
  final String originalCurrency;
  final String preferredCurrency;
  final String bookingCode;
  final VoidCallback? onContinueToPayment;
  final bool isConverting;
  final double promoDiscount;

  const FareDetailsSection({
    super.key,
    required this.baseFare,
    required this.taxes,
    required this.originalCurrency,
    required this.preferredCurrency,
    required this.bookingCode,
    this.onContinueToPayment,
    this.promoDiscount = 0.0,
    this.isConverting = false,
  });

  @override
  Widget build(BuildContext context) {
    // Note: Ensure CurrencyConverter.convert handles async/sync correctly.
    // If it's async, you might need a FutureBuilder or handle it in the parent state.
    // Assuming for now it returns a double synchronously or is pre-calculated.

    double convertedBase = baseFare;
    double convertedTax = taxes;

    if (!isConverting && originalCurrency != preferredCurrency) {
      try {
        // If CurrencyConverter.convert is async, this part needs refactoring in the parent
        // to pass pre-converted values. For now, assuming sync or immediate return.
        convertedBase = CurrencyConverter.convert(
          amount: baseFare,
          fromCurrency: originalCurrency,
          toCurrency: preferredCurrency,
        );
        convertedTax = CurrencyConverter.convert(
          amount: taxes,
          fromCurrency: originalCurrency,
          toCurrency: preferredCurrency,
        );
      } catch (e) {
        // Fallback to original if conversion fails
        convertedBase = baseFare;
        convertedTax = taxes;
      }
    }

    final subtotal = convertedBase + convertedTax;
    final totalAmount = subtotal - promoDiscount;
    final sym = CurrencyConverter.getSymbol(preferredCurrency);

    const primaryBlue = Color(0xff1663F7);
    const successGreen = Color(0xff10B981);
    const darkNavy = Color(0xff0D1B3D);

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
                    const Text('Fetching live price...'),
                  ],
                ),
              )
                  : Column(
                children: [
                  // Base Fare
                  _buildFareRow(
                    context,
                    'Base Fare',
                    '${sym}${convertedBase.toStringAsFixed(2)}',
                  ),
                  SizedBox(height: context.h(8)),

                  // Tax & Charges
                  _buildFareRow(
                    context,
                    'Tax & Charges',
                    '${sym}${convertedTax.toStringAsFixed(2)}',
                  ),
                  SizedBox(height: context.h(8)),

                  // Promo Discount Section
                  if (promoDiscount > 0) ...[
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.w(8),
                        vertical: context.h(6),
                      ),
                      decoration: BoxDecoration(
                        color: successGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(context.r(6)),
                        border: Border.all(color: successGreen.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.local_offer,
                                size: context.w(14),
                                color: successGreen,
                              ),
                              SizedBox(width: context.w(4)),
                              Text(
                                'Promo Discount',
                                style: TextStyle(
                                  fontSize: context.fs(13),
                                  fontWeight: FontWeight.w600,
                                  color: successGreen,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '-${sym}${promoDiscount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: context.fs(13),
                              fontWeight: FontWeight.w700,
                              color: successGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: context.h(8)),
                  ],

                  Divider(height: context.h(24), color: Colors.grey.shade200),

                  // Total Amount
                  _buildTotalRow(
                    context,
                    'Total Payable',
                    '${sym}${totalAmount.toStringAsFixed(2)}',
                    isDiscounted: promoDiscount > 0,
                  ),

                  // Savings Message
                  if (promoDiscount > 0) ...[
                    SizedBox(height: context.h(6)),
                    Center(
                      child: Text(
                        'You saved ${sym}${promoDiscount.toStringAsFixed(2)}!',
                        style: TextStyle(
                          fontSize: context.fs(11),
                          fontWeight: FontWeight.w500,
                          color: successGreen,
                        ),
                      ),
                    ),
                    SizedBox(height: context.h(6)),
                  ],

                  SizedBox(height: context.h(16)),

                  // Continue Button
                  _buildContinueButton(
                    context,
                    sym,
                    totalAmount,
                    hasDiscount: promoDiscount > 0,
                  ),
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
        Text(
          label,
          style: TextStyle(fontSize: context.fs(13), color: Colors.grey[700]),
        ),
        Text(
          amount,
          style: TextStyle(fontSize: context.fs(13), color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildTotalRow(BuildContext context, String label, String amount,
      {bool isDiscounted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: context.fs(16),
            fontWeight: FontWeight.bold,
            color: isDiscounted ? const Color(0xff10B981) : Colors.black87,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: context.fs(16),
            fontWeight: FontWeight.bold,
            color: isDiscounted ? const Color(0xff10B981) : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton(BuildContext context, String sym, double total,
      {bool hasDiscount = false}) {
    return ElevatedButton(
      onPressed: onContinueToPayment,
      style: ElevatedButton.styleFrom(
        backgroundColor: hasDiscount ? const Color(0xff10B981) : const Color(0xffF97316), // Green if discounted, Orange otherwise
        padding: EdgeInsets.symmetric(vertical: context.h(16)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(8))),
        minimumSize: Size(double.infinity, context.h(50)),
        elevation: hasDiscount ? 2 : 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (hasDiscount) ...[
            const Icon(Icons.savings, color: Colors.white, size: 20),
            SizedBox(width: context.w(8)),
          ],
          Text(
            'Pay ${sym}${total.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: context.fs(16),
              fontWeight: FontWeight.w700,
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