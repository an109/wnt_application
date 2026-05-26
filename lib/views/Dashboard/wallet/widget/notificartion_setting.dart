import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../model/wallet_model.dart';

class NotificationSettingsWidget extends StatelessWidget {
  final NotificationSettings settings;
  final Function(NotificationSettings) onChanged;

  const NotificationSettingsWidget({
    super.key,
    required this.settings,
    required this.onChanged,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notifications',
            style: TextStyle(
              fontSize: context.bodyLarge,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: context.gapLarge),

          _NotificationSwitch(
            title: 'Notify me when balance is low',
            value: settings.lowBalanceAlert,
            onChanged: (value) {
              settings.lowBalanceAlert = value;
              onChanged(settings);
            },
          ),

          Divider(height: context.hp(2), color: Colors.grey.shade200),

          _NotificationSwitch(
            title: 'Transaction alerts',
            value: settings.transactionAlerts,
            onChanged: (value) {
              settings.transactionAlerts = value;
              onChanged(settings);
            },
          ),
        ],
      ),
    );
  }
}

class _NotificationSwitch extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotificationSwitch({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: context.bodyMedium,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.red.shade600,
        ),
      ],
    );
  }
}