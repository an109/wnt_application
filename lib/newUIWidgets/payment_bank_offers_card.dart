import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/services/bank_offer_service.dart';

/// "Bank offers" card for the flight payment page: a code box plus every
/// card/bank offer with Apply / Remove, so the traveller can pick or change
/// the offer right before paying.
///
/// It only records the choice ([BankOfferSelection]). The discount itself is
/// given by Razorpay when the traveller pays by CARD with a card that matches
/// the offer. Renders nothing when there are no offers (switched off on the
/// server, none active, or the request failed) so it can never block a payment.
///
/// [amountInr] is the amount being paid, used to grey out offers whose
/// minimum it does not reach.
class PaymentBankOffersCard extends StatefulWidget {
  final double amountInr;

  /// The booking type the offers are for ('flight', 'hotel', ...).
  final String type;
  const PaymentBankOffersCard({super.key, required this.amountInr, this.type = 'flight'});

  @override
  State<PaymentBankOffersCard> createState() => _PaymentBankOffersCardState();
}

class _PaymentBankOffersCardState extends State<PaymentBankOffersCard> {
  static const _stroke = Color(0xFFE6E8EC);
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF6B7280);
  static const _green = Color(0xFF16A34A);
  static const _blue = Color(0xFF2563EB);

  final _codeCtrl = TextEditingController();
  List<BankOffer> _offers = const [];
  int? _openTermsId;
  String _codeError = '';
  String _codeNote = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final list = await BankOfferService().fetchOffers(type: widget.type);
      if (!mounted) return;
      // An applied offer that is no longer offered (ended, switched off) is
      // dropped so it can never get in the way of a payment.
      final applied = BankOfferSelection.currentFor(widget.type);
      if (applied != null && !list.any((o) => o.id == applied.id)) {
        BankOfferSelection.clear();
      }
      setState(() => _offers = list);
    } catch (_) {
      // Offers are a nice-to-have: any problem just means no card is shown.
    }
  }

  bool _below(BankOffer o) => o.isBelowMinimum(widget.amountInr);

  void _applyCode() {
    final typed = _codeCtrl.text.trim();
    setState(() {
      _codeNote = '';
      if (typed.isEmpty) {
        _codeError = 'Enter a coupon code';
        return;
      }
      final match = _offers
          .where((o) => o.hasCode && o.code.toLowerCase() == typed.toLowerCase())
          .firstOrNull;
      if (match == null) {
        _codeError =
            'This code is not a bank offer code. Other promo codes are applied on the booking page.';
        return;
      }
      if (_below(match)) {
        _codeError =
            'Applicable on bookings of ₹${match.minAmount.toStringAsFixed(0)} or more';
        return;
      }
      _codeError = '';
      BankOfferSelection.select(match, type: widget.type);
      _codeCtrl.clear();
      _codeNote =
          '${match.code} applied — pay by card${match.bankName.isNotEmpty ? ' with a ${match.bankName} card' : ''} to get ${match.displayText.isNotEmpty ? match.displayText : 'this offer'}.';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_offers.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: context.h(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: _stroke),
      ),
      padding: EdgeInsets.all(context.w(14)),
      child: ValueListenableBuilder<BankOffer?>(
        valueListenable: BankOfferSelection.selected,
        builder: (context, _, __) {
          final selected = BankOfferSelection.currentFor(widget.type);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.local_offer_rounded,
                      size: context.w(18), color: _green),
                  SizedBox(width: context.w(8)),
                  Text(
                    'Bank offers',
                    style: TextStyle(
                      fontSize: context.fs(15),
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.h(10)),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _codeCtrl,
                      textCapitalization: TextCapitalization.characters,
                      onChanged: (_) {
                        if (_codeError.isNotEmpty) {
                          setState(() => _codeError = '');
                        }
                      },
                      onSubmitted: (_) => _applyCode(),
                      style: TextStyle(fontSize: context.fs(14)),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Enter coupon code',
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: context.w(12),
                            vertical: context.h(11)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(context.r(8)),
                          borderSide: const BorderSide(color: _stroke),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: context.w(8)),
                  TextButton(
                    onPressed: _applyCode,
                    style: TextButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                          horizontal: context.w(18), vertical: context.h(11)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(context.r(8)),
                      ),
                    ),
                    child: Text('Apply',
                        style: TextStyle(
                            fontSize: context.fs(14),
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              if (_codeError.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: context.h(6)),
                  child: Text(_codeError,
                      style: TextStyle(
                          fontSize: context.fs(12),
                          color: const Color(0xFFDC2626))),
                ),
              if (_codeNote.isNotEmpty && _codeError.isEmpty)
                Padding(
                  padding: EdgeInsets.only(top: context.h(6)),
                  child: Text(_codeNote,
                      style: TextStyle(
                          fontSize: context.fs(12),
                          fontWeight: FontWeight.w600,
                          color: _green)),
                ),
              SizedBox(height: context.h(12)),
              for (final o in _offers) ...[
                _offerRow(context, o, selected),
                SizedBox(height: context.h(10)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _offerRow(BuildContext context, BankOffer o, BankOffer? selected) {
    final below = _below(o);
    final applied = !below && selected?.id == o.id;
    final bank = o.bankName.isNotEmpty ? 'a ${o.bankName}' : 'a matching';

    return Container(
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: applied ? const Color(0xFFECFDF5) : Colors.white,
        borderRadius: BorderRadius.circular(context.r(10)),
        border: Border.all(
          color: applied ? const Color(0xFF10B981) : _stroke,
          width: applied ? 1.5 : 1,
        ),
      ),
      child: Opacity(
        opacity: below ? 0.6 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              o.hasCode
                  ? o.code
                  : (o.bankName.isNotEmpty ? '${o.bankName} card offer' : o.title),
              style: TextStyle(
                  fontSize: context.fs(14),
                  fontWeight: FontWeight.w700,
                  color: _ink),
            ),
            SizedBox(height: context.h(2)),
            Text(o.displayText,
                style: TextStyle(
                    fontSize: context.fs(13), color: const Color(0xFF374151))),
            SizedBox(height: context.h(2)),
            Text(
              below
                  ? 'Applicable on bookings of ₹${o.minAmount.toStringAsFixed(0)} or more'
                  : applied
                      ? 'Applied — pay by card with $bank card to get this discount'
                      : 'Apply, then pay by card with $bank card',
              style: TextStyle(
                fontSize: context.fs(12),
                fontWeight: below ? FontWeight.w600 : FontWeight.w400,
                color: below ? const Color(0xFFB45309) : _muted,
              ),
            ),
            SizedBox(height: context.h(6)),
            Row(
              children: [
                if (!below)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() {
                        _codeNote = '';
                        _codeError = '';
                      });
                      applied
                          ? BankOfferSelection.clear()
                          : BankOfferSelection.select(o, type: widget.type);
                    },
                    child: Text(
                      applied ? 'Remove' : 'Apply',
                      style: TextStyle(
                        fontSize: context.fs(13),
                        fontWeight: FontWeight.w700,
                        color: applied ? const Color(0xFFDC2626) : _blue,
                      ),
                    ),
                  ),
                if (!below && o.terms.isNotEmpty) SizedBox(width: context.w(16)),
                if (o.terms.isNotEmpty)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(
                        () => _openTermsId = _openTermsId == o.id ? null : o.id),
                    child: Text(
                      _openTermsId == o.id ? 'Hide T&C' : 'T&C',
                      style: TextStyle(
                          fontSize: context.fs(13),
                          fontWeight: FontWeight.w700,
                          color: _blue),
                    ),
                  ),
              ],
            ),
            if (_openTermsId == o.id && o.terms.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: context.h(6)),
                child: Text(o.terms,
                    style: TextStyle(
                        fontSize: context.fs(12),
                        height: 1.5,
                        color: const Color(0xFF4B5563))),
              ),
          ],
        ),
      ),
    );
  }
}
