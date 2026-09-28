import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import 'card_form.dart';
import 'checkout_ui.dart';

/// Shared loader: payment methods come from Razorpay (only what's enabled on
/// the account), so every section renders from the same future.
class _MethodsBuilder extends StatelessWidget {
  final Future<Map<String, dynamic>> methods;
  final Widget Function(BuildContext, Map<String, dynamic>) builder;

  const _MethodsBuilder({required this.methods, required this.builder});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: methods,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: context.h(20)),
            child: const Center(
              child: CircularProgressIndicator(color: CheckoutColors.primary),
            ),
          );
        }
        if (snap.hasError) {
          return const InlineNote(
            'Could not load options. Close and reopen this section to retry.',
            icon: Icons.error_outline_rounded,
            color: CheckoutColors.error,
          );
        }
        return builder(context, snap.data ?? const {});
      },
    );
  }
}

// ============================ NET BANKING ============================

class NetbankingSection extends StatefulWidget {
  final double amount;
  final bool busy;
  final Future<Map<String, dynamic>> methods;
  final ValueChanged<String> onPay; // bank code

  const NetbankingSection({
    super.key,
    required this.amount,
    required this.busy,
    required this.methods,
    required this.onPay,
  });

  @override
  State<NetbankingSection> createState() => _NetbankingSectionState();
}

class _NetbankingSectionState extends State<NetbankingSection> {
  static const _popular = {
    'SBIN': 'SBI',
    'HDFC': 'HDFC',
    'ICIC': 'ICICI',
    'UTIB': 'Axis',
    'KKBK': 'Kotak',
    'YESB': 'Yes Bank',
  };

  String? _selected;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return _MethodsBuilder(
      methods: widget.methods,
      builder: (context, methods) {
        final raw = methods['netbanking'];
        final banks = <String, String>{};
        if (raw is Map) {
          raw.forEach((k, v) {
            if (k is String && v is String && v.isNotEmpty) banks[k] = v;
          });
        }
        if (banks.isEmpty) {
          return const InlineNote('Net banking is not available right now.');
        }
        final popular = _popular.keys.where(banks.containsKey).toList();
        final q = _query.toLowerCase();
        final all =
            banks.entries
                .where(
                  (e) =>
                      q.isEmpty ||
                      e.value.toLowerCase().contains(q) ||
                      e.key.toLowerCase().contains(q),
                )
                .toList()
              ..sort((a, b) => a.value.compareTo(b.value));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (popular.isNotEmpty) ...[
              _label(context, 'Popular banks'),
              SizedBox(height: context.h(10)),
              LayoutBuilder(
                builder: (context, c) {
                  final perRow = c.maxWidth < 300 ? 2 : 3;
                  final tile =
                      (c.maxWidth - (perRow - 1) * context.w(10)) / perRow;
                  return Wrap(
                    spacing: context.w(10),
                    runSpacing: context.h(10),
                    children: [
                      for (final code in popular)
                        SizedBox(
                          width: tile,
                          child: _bankTile(context, code, _popular[code]!),
                        ),
                    ],
                  );
                },
              ),
              SizedBox(height: context.h(16)),
            ],
            _label(context, 'All banks'),
            SizedBox(height: context.h(8)),
            TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: checkoutInput(
                context,
                'Search bank',
                prefixIcon: Icon(Icons.search_rounded, size: context.w(18)),
              ),
            ),
            SizedBox(height: context.h(6)),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: context.h(260)),
              child: all.isEmpty
                  ? Padding(
                      padding: EdgeInsets.all(context.w(12)),
                      child: const InlineNote('No bank matches your search.'),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: all.length,
                      itemBuilder: (_, i) =>
                          _bankRow(context, all[i].key, all[i].value),
                    ),
            ),
            SizedBox(height: context.h(12)),
            CheckoutPayButton(
              label: _selected == null
                  ? 'Select a bank'
                  : 'Pay ${formatInr(widget.amount)} via ${banks[_selected] ?? _selected}',
              loading: widget.busy,
              onPressed: _selected == null
                  ? null
                  : () => widget.onPay(_selected!),
            ),
          ],
        );
      },
    );
  }

  Widget _bankTile(BuildContext context, String code, String name) {
    final selected = _selected == code;
    return InkWell(
      borderRadius: BorderRadius.circular(context.r(12)),
      onTap: () => setState(() => _selected = code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(
          vertical: context.h(10),
          horizontal: context.w(6),
        ),
        decoration: BoxDecoration(
          color: selected
              ? CheckoutColors.primary.withValues(alpha: 0.06)
              : Colors.white,
          border: Border.all(
            color: selected ? CheckoutColors.primary : CheckoutColors.stroke,
            width: selected ? 1.4 : 1,
          ),
          borderRadius: BorderRadius.circular(context.r(12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LogoAvatar(url: bankLogoUrl(code), label: name, size: 28),
            SizedBox(height: context.h(6)),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: context.fs(11.5),
                fontWeight: FontWeight.w600,
                color: CheckoutColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bankRow(BuildContext context, String code, String name) {
    final selected = _selected == code;
    return InkWell(
      onTap: () => setState(() => _selected = code),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: context.h(10),
          horizontal: context.w(2),
        ),
        child: Row(
          children: [
            LogoAvatar(url: bankLogoUrl(code), label: name, size: 26),
            SizedBox(width: context.w(12)),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: context.fs(13),
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: CheckoutColors.ink,
                ),
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: context.w(20),
              color: selected ? CheckoutColors.primary : CheckoutColors.stroke,
            ),
          ],
        ),
      ),
    );
  }
}

// ================================ EMI ================================

/// Card EMI: pick the issuing bank → tenure (with monthly EMI) → card.
/// Plans come from Razorpay's `emi_plans` (bank → min_amount + months→rate).
class EmiSection extends StatefulWidget {
  final double amount;
  final bool busy;
  final Future<Map<String, dynamic>> methods;
  final void Function(int months, Map<String, dynamic> card) onPay;

  const EmiSection({
    super.key,
    required this.amount,
    required this.busy,
    required this.methods,
    required this.onPay,
  });

  @override
  State<EmiSection> createState() => _EmiSectionState();
}

class _EmiPlan {
  final int months;
  final double rate; // annual %
  const _EmiPlan(this.months, this.rate);
}

class _EmiBank {
  final String code;
  final String name;
  final double minAmount; // INR
  final List<_EmiPlan> plans;
  const _EmiBank(this.code, this.name, this.minAmount, this.plans);
}

class _EmiSectionState extends State<EmiSection> {
  String? _bank;
  int? _months;

  static double monthlyEmi(double principal, _EmiPlan p) {
    if (p.rate <= 0) return principal / p.months;
    final r = p.rate / 1200;
    final f = math.pow(1 + r, p.months);
    return principal * r * f / (f - 1);
  }

  List<_EmiBank> _parse(Map<String, dynamic> methods) {
    // Razorpay methods API returns the key as 'emi', not 'emi_plans'.
    final raw = methods['emi'] ?? methods['emi_plans'];
    final names = methods['netbanking'] is Map
        ? methods['netbanking'] as Map
        : const {};
    final banks = <_EmiBank>[];
    if (raw is Map) {
      raw.forEach((code, v) {
        if (code is! String || v is! Map) return;
        final plans = <_EmiPlan>[];
        final p = v['plans'];
        if (p is Map) {
          p.forEach((m, rate) {
            final months = int.tryParse(m.toString());
            final r = rate is num
                ? rate.toDouble()
                : double.tryParse(rate.toString());
            if (months != null && r != null) plans.add(_EmiPlan(months, r));
          });
        }
        plans.sort((a, b) => a.months.compareTo(b.months));
        final min = v['min_amount'] is num
            ? (v['min_amount'] as num) / 100
            : 0.0;
        if (plans.isNotEmpty) {
          banks.add(
            _EmiBank(
              code,
              (names[code] ?? code).toString(),
              min.toDouble(),
              plans,
            ),
          );
        }
      });
    }
    banks.sort((a, b) => a.name.compareTo(b.name));
    return banks;
  }

  @override
  Widget build(BuildContext context) {
    return _MethodsBuilder(
      methods: widget.methods,
      builder: (context, methods) {
        final banks = _parse(methods);
        if (banks.isEmpty) {
          return const InlineNote('EMI is not available for this payment.');
        }
        final bank = banks.where((b) => b.code == _bank).firstOrNull;
        final eligible = bank == null || widget.amount >= bank.minAmount;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _label(context, 'Choose your card\'s bank'),
            SizedBox(height: context.h(8)),
            SizedBox(
              height: context.h(44).clamp(40.0, 52.0),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: banks.length,
                separatorBuilder: (_, __) => SizedBox(width: context.w(8)),
                itemBuilder: (_, i) {
                  final b = banks[i];
                  final selected = b.code == _bank;
                  return ChoiceChip(
                    selected: selected,
                    showCheckmark: false,
                    avatar: LogoAvatar(
                      url: bankLogoUrl(b.code),
                      label: b.name,
                      size: 18,
                    ),
                    label: Text(
                      b.name,
                      style: TextStyle(fontSize: context.fs(12)),
                    ),
                    selectedColor: CheckoutColors.primary.withValues(
                      alpha: 0.12,
                    ),
                    side: BorderSide(
                      color: selected
                          ? CheckoutColors.primary
                          : CheckoutColors.stroke,
                    ),
                    onSelected: (_) => setState(() {
                      _bank = b.code;
                      _months = null;
                    }),
                  );
                },
              ),
            ),
            if (bank != null) ...[
              SizedBox(height: context.h(16)),
              if (!eligible)
                InlineNote(
                  '${bank.name} EMI needs a minimum of ${formatInr(bank.minAmount)}.',
                  icon: Icons.error_outline_rounded,
                  color: CheckoutColors.error,
                )
              else ...[
                _label(context, 'Choose a plan'),
                SizedBox(height: context.h(8)),
                for (final plan in bank.plans) _planRow(context, plan),
              ],
            ],
            if (bank != null && eligible && _months != null) ...[
              SizedBox(height: context.h(16)),
              _label(context, 'Enter your ${bank.name} card'),
              SizedBox(height: context.h(10)),
              CardForm(
                payLabel: 'Pay ${formatInr(widget.amount)} in $_months EMIs',
                busy: widget.busy,
                onSubmit: (card) => widget.onPay(_months!, card),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _planRow(BuildContext context, _EmiPlan plan) {
    final selected = _months == plan.months;
    final emi = monthlyEmi(widget.amount, plan);
    final total = emi * plan.months;
    return InkWell(
      onTap: () => setState(() => _months = plan.months),
      borderRadius: BorderRadius.circular(context.r(10)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: EdgeInsets.only(bottom: context.h(8)),
        padding: EdgeInsets.symmetric(
          horizontal: context.w(12),
          vertical: context.h(10),
        ),
        decoration: BoxDecoration(
          color: selected
              ? CheckoutColors.primary.withValues(alpha: 0.06)
              : Colors.white,
          border: Border.all(
            color: selected ? CheckoutColors.primary : CheckoutColors.stroke,
          ),
          borderRadius: BorderRadius.circular(context.r(10)),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: context.w(20),
              color: selected ? CheckoutColors.primary : CheckoutColors.muted,
            ),
            SizedBox(width: context.w(10)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${formatInr(emi.roundToDouble())} × ${plan.months} months',
                    style: TextStyle(
                      fontSize: context.fs(13.5),
                      fontWeight: FontWeight.w700,
                      color: CheckoutColors.ink,
                    ),
                  ),
                  SizedBox(height: context.h(2)),
                  Text(
                    'Total ${formatInr(total.roundToDouble())}',
                    style: TextStyle(
                      fontSize: context.fs(11.5),
                      color: CheckoutColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            CheckoutBadge(
              plan.rate <= 0
                  ? 'NO COST'
                  : '${plan.rate.toStringAsFixed(plan.rate % 1 == 0 ? 0 : 1)}% p.a.',
              color: plan.rate <= 0
                  ? CheckoutColors.offer
                  : CheckoutColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================== WALLETS ==============================

class WalletsSection extends StatefulWidget {
  final double amount;
  final bool busy;
  final Future<Map<String, dynamic>> methods;
  final ValueChanged<String> onPay; // wallet code

  const WalletsSection({
    super.key,
    required this.amount,
    required this.busy,
    required this.methods,
    required this.onPay,
  });

  @override
  State<WalletsSection> createState() => _WalletsSectionState();
}

class _WalletsSectionState extends State<WalletsSection> {
  static const _names = {
    'paytm': 'Paytm',
    'phonepe': 'PhonePe',
    'amazonpay': 'Amazon Pay',
    'mobikwik': 'MobiKwik',
    'freecharge': 'Freecharge',
    'airtelmoney': 'Airtel Money',
    'jiomoney': 'JioMoney',
    'olamoney': 'Ola Money',
    'payzapp': 'PayZapp',
    'phonepeswitch': 'PhonePe Switch',
    'paypal': 'PayPal',
  };

  String? _selected;

  @override
  Widget build(BuildContext context) {
    return _MethodsBuilder(
      methods: widget.methods,
      builder: (context, methods) {
        final raw = methods['wallet'];
        final wallets = <String>[];
        if (raw is Map) {
          raw.forEach((k, v) {
            if (k is String && v == true) wallets.add(k);
          });
        }
        wallets.sort((a, b) => (_names[a] ?? a).compareTo(_names[b] ?? b));
        if (wallets.isEmpty)
          return const InlineNote('No wallets are available right now.');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final code in wallets)
              InkWell(
                onTap: () => setState(() => _selected = code),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: context.h(10)),
                  child: Row(
                    children: [
                      LogoAvatar(
                        url: walletLogoUrl(code),
                        label: _names[code] ?? code,
                        size: 28,
                      ),
                      SizedBox(width: context.w(12)),
                      Expanded(
                        child: Text(
                          _names[code] ?? code,
                          style: TextStyle(
                            fontSize: context.fs(13.5),
                            fontWeight: _selected == code
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: CheckoutColors.ink,
                          ),
                        ),
                      ),
                      Icon(
                        _selected == code
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        size: context.w(20),
                        color: _selected == code
                            ? CheckoutColors.primary
                            : CheckoutColors.stroke,
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(height: context.h(10)),
            CheckoutPayButton(
              label: _selected == null
                  ? 'Select a wallet'
                  : 'Pay ${formatInr(widget.amount)} with ${_names[_selected] ?? _selected}',
              loading: widget.busy,
              onPressed: _selected == null
                  ? null
                  : () => widget.onPay(_selected!),
            ),
          ],
        );
      },
    );
  }
}

// ============================= PAY LATER =============================

class PayLaterSection extends StatefulWidget {
  final double amount;
  final bool busy;
  final Future<Map<String, dynamic>> methods;
  final ValueChanged<String> onPay; // provider code

  const PayLaterSection({
    super.key,
    required this.amount,
    required this.busy,
    required this.methods,
    required this.onPay,
  });

  @override
  State<PayLaterSection> createState() => _PayLaterSectionState();
}

class _PayLaterSectionState extends State<PayLaterSection> {
  static const _names = {
    'lazypay': 'LazyPay',
    'getsimpl': 'Simpl',
    'icic': 'ICICI PayLater',
    'hdfc': 'HDFC PayLater',
    'kkbk': 'Kotak PayLater',
    'fdrl': 'Federal Bank PayLater',
    'idfb': 'IDFC FIRST Bank',
    'cshe': 'CASHe',
    'krbe': 'KreditBee',
    'tvsc': 'TVS Credit',
  };

  String? _selected;

  @override
  Widget build(BuildContext context) {
    return _MethodsBuilder(
      methods: widget.methods,
      builder: (context, methods) {
        final raw = methods['paylater'];
        final providers = <String>[];
        if (raw is Map) {
          raw.forEach((k, v) {
            if (k is! String) return;
            // Razorpay may return `true` (bool) or `{"enabled": true}` (map).
            final enabled = v == true ||
                (v is Map && (v['enabled'] == true || v['enabled'] == 1));
            if (enabled) providers.add(k);
          });
        }
        providers.sort(
          (a, b) => (_names[a] ?? a).compareTo(_names[b] ?? b),
        );
        if (providers.isEmpty) {
          return const InlineNote(
            'Pay Later is not available for this payment. Try another method.',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final code in providers)
              InkWell(
                onTap: () => setState(() => _selected = code),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: context.h(10)),
                  child: Row(
                    children: [
                      LogoAvatar(
                        url: walletLogoUrl(code),
                        label: _names[code] ?? code,
                        size: 28,
                      ),
                      SizedBox(width: context.w(12)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _names[code] ?? code,
                              style: TextStyle(
                                fontSize: context.fs(13.5),
                                fontWeight: _selected == code
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: CheckoutColors.ink,
                              ),
                            ),
                            Text(
                              'Buy now, pay later',
                              style: TextStyle(
                                fontSize: context.fs(11.5),
                                color: CheckoutColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _selected == code
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        size: context.w(20),
                        color: _selected == code
                            ? CheckoutColors.primary
                            : CheckoutColors.stroke,
                      ),
                    ],
                  ),
                ),
              ),
            const Divider(height: 1, color: CheckoutColors.stroke),
            SizedBox(height: context.h(12)),
            const InlineNote(
              'You will be redirected to complete a quick OTP verification. '
              'Repayment is due as per your Pay Later plan.',
              icon: Icons.info_outline_rounded,
            ),
            SizedBox(height: context.h(10)),
            CheckoutPayButton(
              label: _selected == null
                  ? 'Select a provider'
                  : 'Pay ${formatInr(widget.amount)} with ${_names[_selected] ?? _selected}',
              loading: widget.busy,
              onPressed: _selected == null
                  ? null
                  : () => widget.onPay(_selected!),
            ),
          ],
        );
      },
    );
  }
}

Widget _label(BuildContext context, String text) => Text(
  text,
  style: TextStyle(
    fontSize: context.fs(12.5),
    fontWeight: FontWeight.w700,
    color: CheckoutColors.ink,
  ),
);
