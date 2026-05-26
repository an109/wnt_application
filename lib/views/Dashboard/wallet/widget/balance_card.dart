import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

class BalanceCard extends StatelessWidget {
  final double balance;
  final double totalEarnings;
  final VoidCallback? onRecharge;

  const BalanceCard({
    super.key,
    required this.balance,
    required this.totalEarnings,
    this.onRecharge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: context.responsivePadding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: context.shadowOffsetSmall,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _BalanceItem(
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: Colors.green,
                  iconBgColor: Colors.green.shade50,
                  title: 'WALLET BALANCE',
                  amount: '₹${balance.toStringAsFixed(2)}',
                  subtitle: 'Available to use',
                ),
              ),

              if (!context.isMobile)
                Container(
                  width: 1,
                  height: context.hp(10),
                  color: Colors.grey.shade200,
                ),

              if (!context.isMobile)
                Expanded(
                  child: _BalanceItem(
                    icon: Icons.trending_up_outlined,
                    iconColor: Colors.blue,
                    iconBgColor: Colors.blue.shade50,
                    title: 'WALLET TOTAL EARNINGS',
                    amount: '₹${totalEarnings.toStringAsFixed(2)}',
                    subtitle: 'Lifetime cashback & rewards',
                  ),
                ),
            ],
          ),

          SizedBox(height: context.gapLarge),

          if (onRecharge != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onRecharge,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add money / Recharge'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: context.gapMedium),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(context.borderRadiusMedium),
                  ),
                  elevation: 0,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BalanceItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String amount;
  final String subtitle;

  const _BalanceItem({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.amount,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(context.gapMedium),
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(context.borderRadiusMedium),
          ),
          child: Icon(icon, color: iconColor, size: context.iconLarge),
        ),
        SizedBox(height: context.gapMedium),
        Text(
          title,
          style: TextStyle(
            fontSize: context.bodySmall,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: context.gapXSmall),
        Text(
          amount,
          style: TextStyle(
            fontSize: context.headlineSmall,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: context.gapXSmall),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: context.bodySmall,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}