import 'package:flutter/material.dart';
import '../../UI_helper/responsive_layout.dart';

enum PaymentGateway {
  ccavenue,
  razorpay,
}

class PaymentGatewaySelectionDialog extends StatelessWidget {
  const PaymentGatewaySelectionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.borderRadius),
      ),
      child: Container(
        padding: EdgeInsets.all(context.w(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Payment Method',
              style: TextStyle(
                fontSize: context.titleLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: context.gapLarge),
            _buildPaymentOption(
              context,
              title: 'CCAvenue',
              subtitle: 'Credit/Debit Card, Net Banking, UPI',
              icon: Icons.credit_card,
              gateway: PaymentGateway.ccavenue,
            ),
            SizedBox(height: context.gapMedium),
            _buildPaymentOption(
              context,
              title: 'Razorpay',
              subtitle: 'UPI, Cards, Wallets, Net Banking',
              icon: Icons.payment,
              gateway: PaymentGateway.razorpay,
            ),
            SizedBox(height: context.gapMedium),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: context.bodyMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required PaymentGateway gateway,
      }) {
    return InkWell(
      onTap: () => Navigator.pop(context, gateway),
      borderRadius: BorderRadius.circular(context.borderRadius),
      child: Container(
        padding: EdgeInsets.all(context.w(12)),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(context.borderRadius),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(context.w(8)),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.indigo),
            ),
            SizedBox(width: context.gapMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: context.bodyLarge,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: context.bodySmall,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}