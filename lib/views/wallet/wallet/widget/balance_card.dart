import 'package:flutter/material.dart';
import '../../../../UI_helper/responsive_layout.dart';

class BalanceCard extends StatelessWidget {
  final double balance;
  final double totalEarnings;
  final String currency;
  final bool isLoading;
  final VoidCallback? onRecharge;
  final String? errorMessage;

  const BalanceCard({
    super.key,
    required this.balance,
    required this.totalEarnings,
    required this.currency,
    required this.isLoading,
    this.onRecharge,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.gapLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(context.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade900.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Balance',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: context.bodyLarge,
            ),
          ),
          SizedBox(height: context.gapSmall),

          if (isLoading)
            const SizedBox(
              height: 40,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            )
          else if (errorMessage != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Error Loading Balance',
                  style: TextStyle(
                    color: Colors.red.shade300,
                    fontSize: context.headlineMedium,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: context.gapSmall),
                Text(
                  errorMessage!,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: context.bodySmall,
                  ),
                ),
              ],
            )
          else
            Text(
              '${balance.toStringAsFixed(2)}',
              // '$currency ${balance.toStringAsFixed(2)}',
              style: TextStyle(
                color: Colors.white,
                fontSize: context.headlineLarge,
                fontWeight: FontWeight.bold,
              ),
            ),

          SizedBox(height: context.gapMedium),

          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.gapMedium,
                  vertical: context.gapSmall,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(context.borderRadiusSmall),
                ),
                child: Text(
                  'Total Earnings: ${totalEarnings.toStringAsFixed(2)}',
                  // 'Total Earnings: $currency ${totalEarnings.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.bodySmall,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: context.gapLarge),

          if (onRecharge != null && !isLoading)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onRecharge,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue.shade900,
                  padding: EdgeInsets.symmetric(vertical: context.gapMedium),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(context.borderRadiusMedium),
                  ),
                ),
                child: Text(
                  'Add Money',
                  style: TextStyle(
                    fontSize: context.bodyLarge,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}