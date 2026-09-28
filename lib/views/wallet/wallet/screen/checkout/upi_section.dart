import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/views/flight_payment/data/razorpay_custom_checkout_service.dart';

import 'checkout_ui.dart';

/// UPI body with two tabs: UPI ID (collect) and Scan QR.
/// UPI apps (intent) are accessible via the Google Pay quick-tile at the top
/// of the checkout screen; they are not shown here.
class UpiSection extends StatefulWidget {
  final double amount;
  final bool busy;
  final Future<List<UpiApp>> apps; // kept for parent's GPay tile
  final ValueChanged<UpiApp> onPayWithApp; // kept for parent's GPay tile
  final ValueChanged<String> onPayWithVpa;
  final Widget qrPanel;

  const UpiSection({
    super.key,
    required this.amount,
    required this.busy,
    required this.apps,
    required this.onPayWithApp,
    required this.onPayWithVpa,
    required this.qrPanel,
  });

  @override
  State<UpiSection> createState() => _UpiSectionState();
}

class _UpiSectionState extends State<UpiSection> {
  int _tab = 0; // 0 = UPI ID, 1 = Scan QR
  final _vpaKey = GlobalKey<FormState>();
  final _vpa = TextEditingController();

  static const _tabs = ['UPI ID', 'Scan QR'];

  @override
  void dispose() {
    _vpa.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = _tabs[_tab];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CheckoutTabs(
          tabs: _tabs,
          index: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        SizedBox(height: context.h(16)),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: KeyedSubtree(
            key: ValueKey(current),
            child: current == 'Scan QR' ? widget.qrPanel : _upiIdTab(context),
          ),
        ),
      ],
    );
  }

  Widget _upiIdTab(BuildContext context) {
    return Form(
      key: _vpaKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _vpa,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            textInputAction: TextInputAction.done,
            decoration: checkoutInput(
              context,
              'UPI ID',
              hint: 'yourname@okhdfcbank',
              prefixIcon: Icon(
                Icons.alternate_email_rounded,
                size: context.w(18),
              ),
            ),
            validator: (v) =>
                RegExp(
                  r'^[\w.\-]{2,256}@[a-zA-Z][a-zA-Z0-9.]{1,64}$',
                ).hasMatch((v ?? '').trim())
                ? null
                : 'Enter a valid UPI ID',
          ),
          SizedBox(height: context.h(10)),
          const InlineNote(
            'A payment request will be sent to your UPI app. Approve it within 5 minutes.',
          ),
          SizedBox(height: context.h(14)),
          CheckoutPayButton(
            label: 'Verify & Pay ${formatInr(widget.amount)}',
            loading: widget.busy,
            onPressed: () {
              FocusScope.of(context).unfocus();
              if (_vpaKey.currentState!.validate())
                widget.onPayWithVpa(_vpa.text.trim());
            },
          ),
        ],
      ),
    );
  }
}
