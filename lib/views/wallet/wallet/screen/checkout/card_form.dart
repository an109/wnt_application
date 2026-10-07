import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../Dashboard/profile/widgets/account_kit.dart'
    show accountInputDecoration;
import 'checkout_ui.dart';

/// Inline card entry used by the Card and EMI sections. Calls [onSubmit] with
/// the Razorpay `card` object once every field validates.
class CardForm extends StatefulWidget {
  final String payLabel;
  final bool busy;
  final ValueChanged<Map<String, dynamic>> onSubmit;

  /// When given, the form drops its own pay button and is submitted by the
  /// screen's call to action instead. Left null everywhere else, so those
  /// checkouts keep the inline button.
  final CheckoutSubmitController? submitController;

  /// Figma "Add Top Up" look: outlined fields with the label on the border
  /// (CARD NUMBER, VALID THRU, CVV/CVC, NAME ON CARD) and a leading icon.
  /// Off by default so the other checkouts keep their current fields.
  final bool outlinedLabels;

  const CardForm({
    super.key,
    required this.payLabel,
    required this.busy,
    required this.onSubmit,
    this.submitController,
    this.outlinedLabels = false,
  });

  @override
  State<CardForm> createState() => _CardFormState();
}

class _CardFormState extends State<CardForm> {
  final _formKey = GlobalKey<FormState>();
  final _number = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();
  final _name = TextEditingController();
  CardNetwork _network = CardNetwork.unknown;
  bool _showCvv = false;

  @override
  void dispose() {
    widget.submitController?.unbind();
    _number.dispose();
    _expiry.dispose();
    _cvv.dispose();
    _name.dispose();
    super.dispose();
  }

  String? _validateExpiry(String? v) {
    final parts = (v ?? '').split('/');
    if (parts.length != 2 || parts[1].length != 2) return 'MM/YY';
    final month = int.tryParse(parts[0]) ?? 0;
    final year = 2000 + (int.tryParse(parts[1]) ?? 0);
    if (month < 1 || month > 12) return 'Invalid month';
    final now = DateTime.now();
    if (year < now.year || (year == now.year && month < now.month))
      return 'Card expired';
    return null;
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final parts = _expiry.text.split('/');
    widget.onSubmit({
      'number': _number.text.replaceAll(' ', ''),
      'name': _name.text.trim(),
      'expiry_month': int.parse(parts[0]),
      'expiry_year': int.parse(parts[1]),
      'cvv': _cvv.text.trim(),
    });
  }

  Widget _networkBadge(BuildContext context) {
    if (_network == CardNetwork.unknown) {
      return Icon(
        Icons.credit_card_rounded,
        color: CheckoutColors.muted,
        size: context.w(20),
      );
    }
    if (_network == CardNetwork.visa) {
      // Visa wordmark: bold italic navy on white (assets have no card logo).
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: context.w(10)),
        child: Center(
          widthFactor: 1,
          child: Text(
            'VISA',
            style: TextStyle(
              fontSize: context.fs(16),
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.5,
              color: const Color(0xFF1A1F71),
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: context.h(12),
        horizontal: context.w(8),
      ),
      child: CheckoutBadge(_network.label, color: CheckoutColors.primary),
    );
  }

  InputDecoration _decoration(
    String label, {
    required String outlinedLabel,
    required IconData icon,
    String? hint,
    Widget? suffix,
  }) {
    if (!widget.outlinedLabels) {
      return checkoutInput(context, label, hint: hint, suffix: suffix);
    }
    return accountInputDecoration(
      context,
      label: outlinedLabel,
      icon: icon,
      hint: hint,
      suffix: suffix,
    ).copyWith(counterText: ''); // no "0/3" under CVV in this design
  }

  @override
  Widget build(BuildContext context) {
    final gap = SizedBox(height: context.h(widget.outlinedLabels ? 16 : 12));
    // The fields validate on submit, so the card is always "ready to try" —
    // a half-filled form reports its own errors rather than greying the
    // screen's button out.
    widget.submitController?.bind(
      onSubmit: _submit,
      canSubmit: !widget.busy,
    );
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _number,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.creditCardNumber],
            inputFormatters: [CardNumberFormatter()],
            onChanged: (v) {
              final n = detectCardNetwork(v);
              if (n != _network) setState(() => _network = n);
            },
            decoration: _decoration(
              'Card number',
              outlinedLabel: 'CARD NUMBER',
              icon: Icons.credit_card_rounded,
              hint: 'XXXX XXXX XXXX XXXX',
              suffix: widget.outlinedLabels && _network == CardNetwork.unknown
                  ? null
                  : _networkBadge(context),
            ),
            validator: (v) =>
                isValidCardNumber(v ?? '') ? null : 'Enter a valid card number',
          ),
          gap,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _expiry,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.creditCardExpirationDate],
                  inputFormatters: [ExpiryFormatter()],
                  decoration: _decoration(
                    'Expiry',
                    outlinedLabel: 'VALID THRU (MM/YY)',
                    icon: Icons.calendar_month_rounded,
                    hint: 'MM/YY',
                  ),
                  validator: _validateExpiry,
                ),
              ),
              SizedBox(width: context.w(12)),
              Expanded(
                child: TextFormField(
                  controller: _cvv,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  obscureText: !_showCvv,
                  maxLength: _network.cvvLength,
                  autofillHints: const [AutofillHints.creditCardSecurityCode],
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _decoration(
                    'CVV',
                    outlinedLabel: 'CVV/CVC',
                    icon: Icons.lock_rounded,
                    hint: _network.cvvLength == 4 ? '••••' : '•••',
                    suffix: IconButton(
                      splashRadius: 18,
                      icon: Icon(
                        _showCvv
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        size: context.w(18),
                        color: CheckoutColors.muted,
                      ),
                      onPressed: () => setState(() => _showCvv = !_showCvv),
                    ),
                  ),
                  validator: (v) =>
                      (v ?? '').length == _network.cvvLength ||
                          ((v ?? '').length >= 3 &&
                              _network == CardNetwork.unknown)
                      ? null
                      : 'Invalid CVV',
                ),
              ),
            ],
          ),
          gap,
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.creditCardName],
            onFieldSubmitted: (_) => _submit(),
            decoration: _decoration(
              'Name on card',
              outlinedLabel: 'NAME ON CARD',
              icon: Icons.person_rounded,
            ),
            validator: (v) =>
                (v ?? '').trim().length >= 2 ? null : 'Enter the name on card',
          ),
          SizedBox(height: context.h(10)),
          const InlineNote(
            'Your card details are sent securely to Razorpay and never stored by us.',
            icon: Icons.lock_outline_rounded,
          ),
          if (widget.submitController == null) ...[
            SizedBox(height: context.h(14)),
            CheckoutPayButton(
              label: widget.payLabel,
              loading: widget.busy,
              onPressed: _submit,
            ),
          ],
        ],
      ),
    );
  }
}
