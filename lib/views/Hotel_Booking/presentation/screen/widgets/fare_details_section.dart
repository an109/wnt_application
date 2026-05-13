import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../domain/entities/hotel_booking_entity.dart';


class FareDetailsSection extends StatelessWidget {
  final RoomEntity room;
  final String currency;
  final String bookingCode;

  const FareDetailsSection({
    super.key,
    required this.room,
    required this.currency,
    required this.bookingCode,
  });

  @override
  Widget build(BuildContext context) {
    final baseFare = room.totalFare;
    final taxes = room.totalTax;
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
              child: Column(
                children: [
                  _buildFareRow(context, 'Base Fare', '${currency} ${baseFare.toStringAsFixed(0)}'),
                  const SizedBox(height: 8),
                  _buildFareRow(context, 'Tax & Charges', '${currency} ${taxes.toStringAsFixed(0)}'),
                  const Divider(height: 24),
                  _buildTotalRow(context, 'Total Amount:', '${currency} ${totalAmount.toStringAsFixed(0)}'),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Promo Code',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: context.titleSmall,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[800],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No promo codes available for hotel booking.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: context.sp(12),
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildContinueButton(context),
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
            Text(
              label,
              style: TextStyle(
                fontSize: context.sp(14),
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: context.sp(14),
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalRow(BuildContext context, String label, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: context.titleMedium,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: context.titleMedium,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        print('FareDetailsSection: Continue to Payment pressed');
        print('Booking Code: $bookingCode');
        // Navigate to payment screen
        // Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentScreen(...)));
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red[700],
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        minimumSize: const Size(double.infinity, 50),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Continue to Payment',
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