import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../UI_helper/responsive_layout.dart';
import '../../data/model/trisha_models.dart';
import 'trisha_style.dart';

/// What a card can ask the chat screen to do.
class TrishaCardHandler {
  /// Send an action to Trisha; [label] is shown as the user's bubble.
  final void Function(String type, {Map<String, dynamic>? data, String? label}) action;
  final VoidCallback addTraveller;

  /// Opens the profile (travellers / contact details). When [thenAction] is
  /// given it is sent once the user comes back.
  final void Function({String? thenAction}) openProfile;
  final void Function(Map<String, dynamic> checkout) pay;
  final VoidCallback openFlights;

  const TrishaCardHandler({
    required this.action,
    required this.addTraveller,
    required this.openProfile,
    required this.pay,
    required this.openFlights,
  });
}

final _inr = NumberFormat.decimalPattern('en_IN');
final _day = DateFormat('EEE, d MMM');

String _date(dynamic iso) {
  final d = DateTime.tryParse('$iso');
  return d == null ? '' : _day.format(d);
}

String _nights(dynamic n) {
  final v = (n as num?)?.toInt() ?? 0;
  return '$v night${v == 1 ? '' : 's'}';
}
String _money(dynamic v) => '₹${_inr.format(num.tryParse('$v') ?? 0)}';

const _paxNames = {'ADT': 'Adult', 'CHD': 'Child', 'INF': 'Infant'};

class TrishaCardView extends StatelessWidget {
  final TrishaCard card;

  /// Only the latest reply's cards are tappable; older ones are history.
  final bool active;
  final TrishaCardHandler handler;

  const TrishaCardView({super.key, required this.card, required this.active, required this.handler});

  @override
  Widget build(BuildContext context) {
    final d = card.data;
    switch (card.type) {
      case 'flight_option':
        return _FlightOptionCard(data: d, onTap: active ? () => _selectOption(d) : null);
      case 'traveller_picker':
        return _TravellerPickerCard(data: d, active: active, handler: handler);
      case 'add_traveller':
        return _ActionCard(
          icon: Icons.person_add_alt_1_rounded,
          text: 'Add a new traveller to your profile.',
          button: '+ Add traveller',
          onTap: active ? handler.addTraveller : null,
        );
      case 'edit_traveller':
        return _ActionCard(
          icon: Icons.edit_note_rounded,
          text: 'Missing: ${(d['missing'] as List? ?? []).join(', ')}',
          button: 'Update traveller details',
          onTap: active ? () => handler.openProfile(thenAction: 'travellers_updated') : null,
        );
      case 'update_profile':
        return _ActionCard(
          icon: Icons.account_circle_outlined,
          text: 'Missing on your profile: ${(d['missing'] as List? ?? []).join(', ')}',
          button: 'Open profile',
          onTap: active ? () => handler.openProfile() : null,
        );
      case 'booking_review':
        return _BookingReviewCard(data: d, active: active, handler: handler);
      case 'razorpay_checkout':
        return _PaymentCard(data: d, onPay: active ? () => handler.pay(d) : null);
      case 'booking_confirmed':
        return _ConfirmedCard(data: d);
      case 'hotel_option':
        return _HotelOptionCard(
          data: d,
          onTap: active
              ? () => handler.action('select_option',
                  data: {'option_number': d['option_number']}, label: 'Hotel ${d['option_number']} · ${d['name']}')
              : null,
        );
      case 'room_option':
        return _RoomOptionCard(
          data: d,
          onTap: active
              ? () => handler.action('select_option',
                  data: {'option_number': d['option_number']}, label: 'Room ${d['option_number']} · ${d['room_name']}')
              : null,
        );
      case 'hotel_review':
        return _HotelReviewCard(data: d, active: active, handler: handler);
      case 'hotel_booking_confirmed':
        return _HotelConfirmedCard(data: d);
      case 'holiday_option':
        return _HolidayOptionCard(
          data: d,
          onTap: active
              ? () => handler.action('select_option',
                  data: {'option_number': d['option_number']}, label: 'Package ${d['option_number']} · ${d['title']}')
              : null,
        );
      case 'holiday_quote':
        return _HolidayQuoteCard(data: d);
      case 'package_choice':
        return _PackageChoiceCard(
          data: d,
          onTap: active
              ? () => handler.action('select_option',
                  data: {'option_number': d['option_number']}, label: 'Option ${d['option_number']} · ${d['title']}')
              : null,
        );
      case 'holiday_review':
        return _HolidayReviewCard(data: d, active: active, handler: handler);
      case 'holiday_payment_options':
        return _HolidayPayOptionsCard(data: d, active: active, handler: handler);
      case 'holiday_booking_confirmed':
        return _HolidayConfirmedCard(data: d);
      case 'web_sources':
        return _WebSourcesCard(data: d);
      case 'open_flight_booking':
        return _ActionCard(
          icon: Icons.flight_rounded,
          text: 'This booking needs passport details. Please complete it from the Flights section.',
          button: 'Go to Flights',
          onTap: handler.openFlights,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _selectOption(Map<String, dynamic> d) {
    final n = d['option_number'];
    handler.action('select_option', data: {'option_number': n}, label: 'Option $n · ${d['airline']} ${d['flight_no']}');
  }
}

// ---- building blocks ----------------------------------------------------------

class _CardBox extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _CardBox({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.fx(14)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(context.fx(14)),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(context.fx(14)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(context.fx(14)),
              border: Border.all(color: TrishaStyle.cardBorder),
            ),
            child: child,
          ),
        ),
      );
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool outlined;

  const _PrimaryButton({required this.label, this.onTap, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.fx(24)));
    final padding = EdgeInsets.symmetric(vertical: context.fx(12));
    final style = TrishaStyle.body(context, 13, weight: FontWeight.w600, height: 1.2);
    return SizedBox(
      width: double.infinity,
      child: outlined
          ? OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                shape: shape,
                padding: padding,
                side: const BorderSide(color: TrishaStyle.brandBlue),
                foregroundColor: TrishaStyle.brandBlue,
              ),
              child: Text(label, style: style.copyWith(color: TrishaStyle.brandBlue)),
            )
          : ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                shape: shape,
                padding: padding,
                elevation: 0,
                backgroundColor: TrishaStyle.accent,
                disabledBackgroundColor: const Color(0xFFE5E7EB),
              ),
              child: Text(label, style: style.copyWith(color: onTap == null ? TrishaStyle.hint : Colors.white)),
            ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String text;
  final String button;
  final VoidCallback? onTap;

  const _ActionCard({required this.icon, required this.text, required this.button, this.onTap});

  @override
  Widget build(BuildContext context) => _CardBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: context.fx(20), color: TrishaStyle.brandBlue),
                SizedBox(width: context.fx(8)),
                Expanded(child: Text(text, style: TrishaStyle.body(context, 12))),
              ],
            ),
            SizedBox(height: context.fx(12)),
            _PrimaryButton(label: button, onTap: onTap, outlined: true),
          ],
        ),
      );
}

// ---- flight option -------------------------------------------------------------

class _FlightOptionCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onTap;

  const _FlightOptionCard({required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    final stops = (data['stops'] as num?)?.toInt() ?? 0;
    final highlights = (data['highlights'] as List? ?? []).map((e) => '$e').toList();
    final travellers = (data['travellers'] as num?)?.toInt() ?? 1;
    return _CardBox(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${data['airline']} · ${data['flight_no']}',
                  style: TrishaStyle.body(context, 13, weight: FontWeight.w600),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: context.fx(8), vertical: context.fx(3)),
                decoration: BoxDecoration(
                  color: TrishaStyle.listBg,
                  borderRadius: BorderRadius.circular(context.fx(10)),
                ),
                child: Text(
                  '${data['leg'] == 'return' ? 'Return' : 'Option'} ${data['option_number']}',
                  style: TrishaStyle.body(context, 10, color: TrishaStyle.brandBlue, weight: FontWeight.w600),
                ),
              ),
            ],
          ),
          SizedBox(height: context.fx(12)),
          Row(
            children: [
              _TimeColumn(time: '${data['departure_time']}', code: '${data['from']}'),
              Expanded(
                child: Column(
                  children: [
                    Text('${data['duration']}', style: TrishaStyle.body(context, 10, color: TrishaStyle.hint)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: context.fx(8), vertical: context.fx(2)),
                      child: const Divider(height: 1, thickness: 1, color: TrishaStyle.cardBorder),
                    ),
                    Text(
                      stops == 0 ? 'Non-stop' : '$stops stop${stops > 1 ? 's' : ''}',
                      style: TrishaStyle.body(context, 10, color: stops == 0 ? Colors.green.shade700 : TrishaStyle.hint),
                    ),
                  ],
                ),
              ),
              _TimeColumn(time: '${data['arrival_time']}', code: '${data['to']}', end: true),
            ],
          ),
          if (highlights.isNotEmpty) ...[
            SizedBox(height: context.fx(10)),
            Wrap(
              spacing: context.fx(6),
              runSpacing: context.fx(6),
              children: [
                for (final h in highlights)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: context.fx(8), vertical: context.fx(3)),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(context.fx(10)),
                    ),
                    child: Text(h, style: TrishaStyle.body(context, 10, color: TrishaStyle.brandBlue, height: 1.2)),
                  ),
              ],
            ),
          ],
          SizedBox(height: context.fx(12)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_money(data['fare_total']), style: TrishaStyle.body(context, 16, weight: FontWeight.w700, height: 1)),
              SizedBox(width: context.fx(6)),
              Expanded(
                child: Text(
                  'for $travellers traveller${travellers > 1 ? 's' : ''}${data['refundable'] == true ? ' · Refundable' : ''}',
                  style: TrishaStyle.body(context, 10, color: TrishaStyle.hint, height: 1.2),
                ),
              ),
              Text(
                onTap != null ? 'Select ›' : '',
                style: TrishaStyle.body(context, 12, color: TrishaStyle.accent, weight: FontWeight.w600, height: 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeColumn extends StatelessWidget {
  final String time;
  final String code;
  final bool end;

  const _TimeColumn({required this.time, required this.code, this.end = false});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: end ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(time, style: TrishaStyle.body(context, 16, weight: FontWeight.w700, height: 1.1)),
          Text(code, style: TrishaStyle.body(context, 11, color: TrishaStyle.hint, height: 1.3)),
        ],
      );
}

// ---- travellers ----------------------------------------------------------------

class _TravellerPickerCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool active;
  final TrishaCardHandler handler;

  const _TravellerPickerCard({required this.data, required this.active, required this.handler});

  @override
  State<_TravellerPickerCard> createState() => _TravellerPickerCardState();
}

class _TravellerPickerCardState extends State<_TravellerPickerCard> {
  final _picked = <int>{};

  List<Map<String, dynamic>> get _travellers => (widget.data['travellers'] as List? ?? [])
      .whereType<Map>()
      .map((t) => t.cast<String, dynamic>())
      .toList();

  int get _needed => (widget.data['required'] as Map? ?? {})
      .values
      .fold<int>(0, (sum, v) => sum + ((v as num?)?.toInt() ?? 0));

  static const _singular = {'adults': 'adult', 'children': 'child', 'infants': 'infant'};

  String get _requiredText => (widget.data['required'] as Map? ?? {})
      .entries
      .map((e) => '${e.value} ${e.value == 1 ? (_singular[e.key] ?? e.key) : e.key}')
      .join(', ');

  @override
  Widget build(BuildContext context) {
    final travellers = _travellers;
    return _CardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select $_requiredText', style: TrishaStyle.body(context, 12, weight: FontWeight.w600)),
          SizedBox(height: context.fx(6)),
          if (travellers.isEmpty)
            Text('No saved travellers yet.', style: TrishaStyle.body(context, 12, color: TrishaStyle.hint)),
          for (final t in travellers)
            CheckboxListTile(
              value: _picked.contains(t['id']),
              onChanged: widget.active
                  ? (on) => setState(() => on == true ? _picked.add(t['id'] as int) : _picked.remove(t['id']))
                  : null,
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: TrishaStyle.brandBlue,
              title: Text('${t['name']}', style: TrishaStyle.body(context, 13, weight: FontWeight.w500, height: 1.2)),
              subtitle: Text(
                [
                  _paxNames[t['pax_type']] ?? '${t['pax_type']}',
                  if ((t['missing'] as List? ?? []).isNotEmpty) 'Needs ${(t['missing'] as List).join(', ')}',
                ].join(' · '),
                style: TrishaStyle.body(
                  context,
                  11,
                  color: (t['missing'] as List? ?? []).isNotEmpty ? Colors.red.shade400 : TrishaStyle.hint,
                  height: 1.2,
                ),
              ),
            ),
          SizedBox(height: context.fx(8)),
          _PrimaryButton(
            label: 'Continue',
            onTap: widget.active && _picked.length == _needed && _needed > 0
                ? () {
                    final names = travellers.where((t) => _picked.contains(t['id'])).map((t) => '${t['name']}');
                    widget.handler.action(
                      'select_travellers',
                      data: {'traveller_ids': _picked.toList()},
                      label: names.join(', '),
                    );
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

// ---- review, payment, ticket ------------------------------------------------------

class _FlightLines extends StatelessWidget {
  final List flights;

  const _FlightLines({required this.flights});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final f in flights.whereType<Map>())
            Padding(
              padding: EdgeInsets.only(bottom: context.fx(8)),
              child: Row(
                children: [
                  Icon(
                    f['leg'] == 'return' ? Icons.flight_land_rounded : Icons.flight_takeoff_rounded,
                    size: context.fx(16),
                    color: TrishaStyle.brandBlue,
                  ),
                  SizedBox(width: context.fx(8)),
                  Expanded(
                    child: Text(
                      '${f['from']} → ${f['to']}  ·  ${f['departure_time']} – ${f['arrival_time']}\n'
                      '${f['airline']} ${f['flight_no']} · ${f['duration']}',
                      style: TrishaStyle.body(context, 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
}

class _BookingReviewCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool active;
  final TrishaCardHandler handler;

  const _BookingReviewCard({required this.data, required this.active, required this.handler});

  @override
  Widget build(BuildContext context) {
    final travellers = (data['travellers'] as List? ?? []).whereType<Map>();
    final baggage = (data['baggage'] as Map? ?? {});
    return _CardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FlightLines(flights: data['flights'] as List? ?? []),
          const Divider(color: TrishaStyle.cardBorder),
          Text(
            travellers.map((t) => '${t['name']} (${_paxNames[t['pax_type']] ?? t['pax_type']})').join('\n'),
            style: TrishaStyle.body(context, 12),
          ),
          if (baggage.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: context.fx(6)),
              child: Text(
                'Baggage: ${baggage.entries.map((e) => '${e.value} ${e.key}').join(', ')}',
                style: TrishaStyle.body(context, 11, color: TrishaStyle.hint),
              ),
            ),
          const Divider(color: TrishaStyle.cardBorder),
          Row(
            children: [
              Text('Total', style: TrishaStyle.body(context, 13, weight: FontWeight.w600)),
              const Spacer(),
              if (data['previous_fare'] != null) ...[
                Text(
                  _money(data['previous_fare']),
                  style: TrishaStyle.body(context, 12, color: TrishaStyle.hint)
                      .copyWith(decoration: TextDecoration.lineThrough),
                ),
                SizedBox(width: context.fx(6)),
              ],
              Text(_money(data['fare_total']), style: TrishaStyle.body(context, 18, weight: FontWeight.w700, height: 1)),
            ],
          ),
          if (data['refundable'] == true)
            Text('Refundable fare', style: TrishaStyle.body(context, 11, color: Colors.green.shade700)),
          SizedBox(height: context.fx(12)),
          _PrimaryButton(
            label: 'Confirm & pay',
            onTap: active ? () => handler.action('confirm_booking', label: 'Confirm & pay') : null,
          ),
          SizedBox(height: context.fx(8)),
          _PrimaryButton(
            label: 'Change travellers',
            outlined: true,
            onTap: active ? () => handler.action('change_travellers', label: 'Change travellers') : null,
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onPay;

  const _PaymentCard({required this.data, this.onPay});

  @override
  Widget build(BuildContext context) => _CardBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount to pay', style: TrishaStyle.body(context, 11, color: TrishaStyle.hint)),
            Text(_money(data['display_amount']), style: TrishaStyle.body(context, 22, weight: FontWeight.w700, height: 1.3)),
            Text('${data['description'] ?? ''}', style: TrishaStyle.body(context, 11, color: TrishaStyle.hint)),
            SizedBox(height: context.fx(12)),
            _PrimaryButton(label: 'Pay ${_money(data['display_amount'])} securely', onTap: onPay),
          ],
        ),
      );
}

class _ConfirmedCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ConfirmedCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final travellers = (data['travellers'] as List? ?? []).whereType<Map>();
    return _CardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: context.fx(22)),
              SizedBox(width: context.fx(8)),
              Text('Booking confirmed', style: TrishaStyle.body(context, 14, weight: FontWeight.w700)),
            ],
          ),
          if (data['pnr'] != null) ...[
            SizedBox(height: context.fx(10)),
            Text('PNR', style: TrishaStyle.body(context, 11, color: TrishaStyle.hint)),
            SelectableText(
              '${data['pnr']}',
              style: TrishaStyle.body(context, 22, weight: FontWeight.w700, height: 1.2).copyWith(letterSpacing: 2),
            ),
          ],
          SizedBox(height: context.fx(10)),
          _FlightLines(flights: data['flights'] as List? ?? []),
          Text(
            travellers.map((t) => '${t['name']}').join(', '),
            style: TrishaStyle.body(context, 12),
          ),
          SizedBox(height: context.fx(6)),
          Text(
            'Paid ${_money(data['amount_paid'])} · Ref ${data['booking_reference'] ?? '-'}',
            style: TrishaStyle.body(context, 11, color: TrishaStyle.hint),
          ),
        ],
      ),
    );
  }
}


// ---- hotels ----------------------------------------------------------------------

class _HotelImage extends StatelessWidget {
  final String? url;
  final double height;

  const _HotelImage({required this.url, required this.height});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      height: height,
      color: TrishaStyle.listBg,
      alignment: Alignment.center,
      child: Icon(Icons.hotel_rounded, size: context.fx(28), color: TrishaStyle.hint),
    );
    if (url == null || url!.isEmpty) return placeholder;
    return CachedNetworkImage(
      imageUrl: url!,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (_, __) => placeholder,
      errorWidget: (_, __, ___) => placeholder,
    );
  }
}

class _Stars extends StatelessWidget {
  final num stars;

  const _Stars({required this.stars});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < stars.round().clamp(0, 5); i++)
            Icon(Icons.star_rounded, size: context.fx(13), color: const Color(0xFFF5A623)),
        ],
      );
}

class _Chip extends StatelessWidget {
  final String text;
  final Color color;
  final Color bg;

  const _Chip(this.text, {this.color = TrishaStyle.brandBlue, this.bg = const Color(0xFFEFF6FF)});

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: context.fx(8), vertical: context.fx(3)),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(context.fx(10))),
        child: Text(text, style: TrishaStyle.body(context, 10, color: color, height: 1.2)),
      );
}

const _green = Color(0xFF15803D);
const _greenBg = Color(0xFFECFDF3);

class _HotelOptionCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onTap;

  const _HotelOptionCard({required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    final rating = data['rating'] as num?;
    final highlights = (data['highlights'] as List? ?? []).map((e) => '$e').toList();
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(context.fx(14)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.fx(14)),
            border: Border.all(color: TrishaStyle.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  _HotelImage(url: data['image'] as String?, height: context.fx(130)),
                  Positioned(
                    top: context.fx(8),
                    left: context.fx(8),
                    child: _Chip('Hotel ${data['option_number']}', color: Colors.white, bg: const Color(0x99000000)),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.all(context.fx(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${data['name']}', maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: TrishaStyle.body(context, 14, weight: FontWeight.w700, height: 1.25)),
                    SizedBox(height: context.fx(4)),
                    Row(
                      children: [
                        _Stars(stars: (data['stars'] as num?) ?? 0),
                        if (rating != null) ...[
                          SizedBox(width: context.fx(8)),
                          _Chip('${rating.toStringAsFixed(1)} ★', color: Colors.white, bg: _green),
                          SizedBox(width: context.fx(4)),
                          Flexible(
                            child: Text('(${data['reviews'] ?? 0} reviews)', maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: TrishaStyle.body(context, 10, color: TrishaStyle.hint, height: 1.2)),
                          ),
                        ],
                      ],
                    ),
                    if ('${data['address'] ?? ''}'.isNotEmpty) ...[
                      SizedBox(height: context.fx(4)),
                      Text('${data['address']}', maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TrishaStyle.body(context, 11, color: TrishaStyle.hint, height: 1.3)),
                    ],
                    if (highlights.isNotEmpty) ...[
                      SizedBox(height: context.fx(8)),
                      Wrap(
                        spacing: context.fx(6),
                        runSpacing: context.fx(6),
                        children: [
                          for (final h in highlights)
                            h == 'Free cancellation' || h == 'Breakfast included'
                                ? _Chip(h, color: _green, bg: _greenBg)
                                : _Chip(h),
                        ],
                      ),
                    ],
                    SizedBox(height: context.fx(10)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text.rich(
                            TextSpan(children: [
                              TextSpan(text: _money(data['price_per_night']),
                                  style: TrishaStyle.body(context, 16, weight: FontWeight.w700, height: 1)),
                              TextSpan(text: ' /night',
                                  style: TrishaStyle.body(context, 11, color: TrishaStyle.hint, height: 1.2)),
                            ]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(onTap != null ? 'View rooms ›' : '',
                            style: TrishaStyle.body(context, 12, color: TrishaStyle.accent, weight: FontWeight.w600, height: 1)),
                      ],
                    ),
                    Text('${_money(data['price_total'])} total for ${_nights(data['nights'])}',
                        style: TrishaStyle.body(context, 10, color: TrishaStyle.hint, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomOptionCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onTap;

  const _RoomOptionCard({required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    final meal = '${data['meal'] ?? ''}';
    final withMeal = meal.isNotEmpty && !meal.toLowerCase().contains('room only');
    final refundable = data['refundable'] == true;
    final cancellation = '${data['cancellation'] ?? ''}';
    return _CardBox(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('${data['room_name']}',
                    style: TrishaStyle.body(context, 13, weight: FontWeight.w700, height: 1.25)),
              ),
              _Chip('Room ${data['option_number']}'),
            ],
          ),
          SizedBox(height: context.fx(8)),
          Row(
            children: [
              Icon(withMeal ? Icons.free_breakfast_rounded : Icons.no_meals_rounded,
                  size: context.fx(15), color: withMeal ? _green : TrishaStyle.hint),
              SizedBox(width: context.fx(6)),
              Expanded(
                child: Text(meal.isEmpty ? 'Room only' : meal, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TrishaStyle.body(context, 12, color: withMeal ? _green : TrishaStyle.text, height: 1.2)),
              ),
            ],
          ),
          SizedBox(height: context.fx(4)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(refundable ? Icons.verified_rounded : Icons.info_outline_rounded,
                  size: context.fx(15), color: refundable ? _green : TrishaStyle.hint),
              SizedBox(width: context.fx(6)),
              Expanded(
                child: Text(
                  refundable ? (cancellation.isNotEmpty ? cancellation : 'Free cancellation') : 'Non-refundable',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TrishaStyle.body(context, 12, color: refundable ? _green : TrishaStyle.hint, height: 1.3),
                ),
              ),
            ],
          ),
          SizedBox(height: context.fx(10)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_money(data['price_total']), style: TrishaStyle.body(context, 16, weight: FontWeight.w700, height: 1)),
              SizedBox(width: context.fx(6)),
              Expanded(
                child: Text('${_money(data['price_per_night'])}/night · ${_nights(data['nights'])}',
                    style: TrishaStyle.body(context, 10, color: TrishaStyle.hint, height: 1.2)),
              ),
              Text(onTap != null ? 'Select ›' : '',
                  style: TrishaStyle.body(context, 12, color: TrishaStyle.accent, weight: FontWeight.w600, height: 1)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StayLines extends StatelessWidget {
  final Map<String, dynamic> data;

  const _StayLines({required this.data});

  @override
  Widget build(BuildContext context) {
    final guests = (data['guests'] as List? ?? []).whereType<Map>();
    Widget line(IconData icon, String text) => Padding(
          padding: EdgeInsets.only(bottom: context.fx(6)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: context.fx(15), color: TrishaStyle.brandBlue),
              SizedBox(width: context.fx(8)),
              Expanded(child: Text(text, style: TrishaStyle.body(context, 12, height: 1.35))),
            ],
          ),
        );
    return Column(
      children: [
        line(Icons.calendar_month_rounded,
            '${_date(data['check_in'])} → ${_date(data['check_out'])} · ${_nights(data['nights'])}'),
        if ('${data['room_name'] ?? ''}'.isNotEmpty)
          line(Icons.bed_rounded, [
            if (((data['rooms'] as num?) ?? 1) > 1) '${data['rooms']} × ',
            '${data['room_name']}',
            if ('${data['meal'] ?? ''}'.isNotEmpty) ' · ${data['meal']}',
          ].join()),
        if (guests.isNotEmpty)
          line(Icons.people_alt_rounded,
              guests.map((g) => '${g['name']}${g['pax_type'] == 'ADT' ? '' : ' (child)'}').join(', ')),
      ],
    );
  }
}

class _HotelReviewCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool active;
  final TrishaCardHandler handler;

  const _HotelReviewCard({required this.data, required this.active, required this.handler});

  @override
  Widget build(BuildContext context) {
    final refundable = data['refundable'] == true;
    final cancellation = '${data['cancellation'] ?? ''}';
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.fx(14)),
        border: Border.all(color: TrishaStyle.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HotelImage(url: data['image'] as String?, height: context.fx(110)),
          Padding(
            padding: EdgeInsets.all(context.fx(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${data['hotel']}', style: TrishaStyle.body(context, 14, weight: FontWeight.w700, height: 1.25)),
                _Stars(stars: (data['stars'] as num?) ?? 0),
                if ('${data['address'] ?? ''}'.isNotEmpty)
                  Text('${data['address']}', maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: TrishaStyle.body(context, 11, color: TrishaStyle.hint, height: 1.3)),
                const Divider(color: TrishaStyle.cardBorder),
                _StayLines(data: data),
                Text(
                  refundable ? (cancellation.isNotEmpty ? cancellation : 'Free cancellation') : 'Non-refundable',
                  style: TrishaStyle.body(context, 11, color: refundable ? _green : TrishaStyle.hint),
                ),
                const Divider(color: TrishaStyle.cardBorder),
                Row(
                  children: [
                    Text('Total', style: TrishaStyle.body(context, 13, weight: FontWeight.w600)),
                    const Spacer(),
                    if (data['previous_price'] != null) ...[
                      Text(_money(data['previous_price']),
                          style: TrishaStyle.body(context, 12, color: TrishaStyle.hint)
                              .copyWith(decoration: TextDecoration.lineThrough)),
                      SizedBox(width: context.fx(6)),
                    ],
                    Text(_money(data['price_total']),
                        style: TrishaStyle.body(context, 18, weight: FontWeight.w700, height: 1)),
                  ],
                ),
                SizedBox(height: context.fx(12)),
                _PrimaryButton(
                  label: 'Confirm & pay',
                  onTap: active ? () => handler.action('confirm_booking', label: 'Confirm & pay') : null,
                ),
                SizedBox(height: context.fx(8)),
                _PrimaryButton(
                  label: 'Change guests',
                  outlined: true,
                  onTap: active ? () => handler.action('change_travellers', label: 'Change guests') : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HotelConfirmedCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _HotelConfirmedCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final confirmation = data['confirmation_number'] ?? data['booking_reference'];
    return _CardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: context.fx(22)),
              SizedBox(width: context.fx(8)),
              Text('Stay confirmed', style: TrishaStyle.body(context, 14, weight: FontWeight.w700)),
            ],
          ),
          if (confirmation != null) ...[
            SizedBox(height: context.fx(10)),
            Text(data['confirmation_number'] != null ? 'Confirmation number' : 'Booking reference',
                style: TrishaStyle.body(context, 11, color: TrishaStyle.hint)),
            SelectableText('$confirmation',
                style: TrishaStyle.body(context, 20, weight: FontWeight.w700, height: 1.2).copyWith(letterSpacing: 1.5)),
          ],
          SizedBox(height: context.fx(10)),
          Text('${data['hotel']}', style: TrishaStyle.body(context, 13, weight: FontWeight.w600)),
          if ('${data['address'] ?? ''}'.isNotEmpty)
            Text('${data['address']}', style: TrishaStyle.body(context, 11, color: TrishaStyle.hint, height: 1.3)),
          SizedBox(height: context.fx(8)),
          _StayLines(data: data),
          Text('Paid ${_money(data['amount_paid'])} · Ref ${data['booking_reference'] ?? '-'}',
              style: TrishaStyle.body(context, 11, color: TrishaStyle.hint)),
        ],
      ),
    );
  }
}


// ---- answers from the web -------------------------------------------------------

Future<void> _openExternal(String url) async {
  final uri = Uri.tryParse(url);
  if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Sources behind a live answer, plus Google's search-suggestion chip, which
/// Google's terms require to be shown with answers grounded in Google Search.
class _WebSourcesCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _WebSourcesCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final sources = (data['sources'] as List? ?? []).whereType<Map>().toList();
    final html = data['search_html'] as String?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sources.isNotEmpty) ...[
          Text('Sources', style: TrishaStyle.body(context, 11, color: TrishaStyle.hint, weight: FontWeight.w600)),
          SizedBox(height: context.fx(6)),
          Wrap(
            spacing: context.fx(6),
            runSpacing: context.fx(6),
            children: [
              for (final (i, src) in sources.indexed)
                InkWell(
                  borderRadius: BorderRadius.circular(context.fx(12)),
                  onTap: () => _openExternal('${src['url']}'),
                  child: Container(
                    constraints: BoxConstraints(maxWidth: context.fx(220)),
                    padding: EdgeInsets.symmetric(horizontal: context.fx(10), vertical: context.fx(5)),
                    decoration: BoxDecoration(
                      color: TrishaStyle.listBg,
                      borderRadius: BorderRadius.circular(context.fx(12)),
                      border: Border.all(color: TrishaStyle.cardBorder),
                    ),
                    child: Text('${i + 1}. ${src['title']}', maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TrishaStyle.body(context, 11, color: TrishaStyle.brandBlue, height: 1.2)),
                  ),
                ),
            ],
          ),
        ],
        if (html != null && html.isNotEmpty && WebViewPlatform.instance != null) ...[
          SizedBox(height: context.fx(8)),
          _SearchSuggestions(html: html),
        ],
      ],
    );
  }
}

class _SearchSuggestions extends StatefulWidget {
  final String html;

  const _SearchSuggestions({required this.html});

  @override
  State<_SearchSuggestions> createState() => _SearchSuggestionsState();
}

class _SearchSuggestionsState extends State<_SearchSuggestions> {
  late final WebViewController _controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setBackgroundColor(Colors.transparent)
    ..setNavigationDelegate(NavigationDelegate(
      // Taps on a suggestion open Google in the browser, not inside the chip.
      onNavigationRequest: (req) {
        if (req.url.startsWith('http')) {
          _openExternal(req.url);
          return NavigationDecision.prevent;
        }
        return NavigationDecision.navigate;
      },
    ))
    ..loadHtmlString(
      '<html><head><meta name="viewport" content="width=device-width, initial-scale=1"></head>'
      '<body style="margin:0">${widget.html}</body></html>',
    );

  @override
  Widget build(BuildContext context) => SizedBox(
        height: context.fx(56),
        child: WebViewWidget(controller: _controller),
      );
}


// ---- holidays ----------------------------------------------------------------------

String _party(Map<String, dynamic> d) {
  final adults = (d['adults'] as num?)?.toInt() ?? 0;
  final children = (d['children'] as num?)?.toInt() ?? 0;
  return [
    '$adults adult${adults == 1 ? '' : 's'}',
    if (children > 0) '$children child${children == 1 ? '' : 'ren'}',
  ].join(' + ');
}

String _travellerNames(Map<String, dynamic> d) => (d['travellers'] as List? ?? [])
    .whereType<Map>()
    .map((t) => '${t['name']}${t['pax_type'] == 'ADT' ? '' : ' (child)'}')
    .join(', ');

class _HolidayOptionCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onTap;

  const _HolidayOptionCard({required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    final themes = (data['themes'] as List? ?? []).map((e) => '$e').toList();
    final withFlight = data['price_with_flight'];
    final withoutFlight = data['price_without_flight'];
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(context.fx(14)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.fx(14)),
            border: Border.all(color: TrishaStyle.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(children: [
                _HotelImage(url: data['image'] as String?, height: context.fx(130)),
                Positioned(
                  top: context.fx(8),
                  left: context.fx(8),
                  child: _Chip('${data['nights']}N / ${data['days']}D', color: Colors.white, bg: const Color(0x99000000)),
                ),
              ]),
              Padding(
                padding: EdgeInsets.all(context.fx(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${data['title']}', maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: TrishaStyle.body(context, 14, weight: FontWeight.w700, height: 1.25)),
                    SizedBox(height: context.fx(4)),
                    Text('${data['destination']} · from ${data['origin']}',
                        style: TrishaStyle.body(context, 11, color: TrishaStyle.hint, height: 1.3)),
                    if (themes.isNotEmpty) ...[
                      SizedBox(height: context.fx(8)),
                      Wrap(spacing: context.fx(6), runSpacing: context.fx(6), children: [
                        for (final t in themes) _Chip(t[0].toUpperCase() + t.substring(1)),
                      ]),
                    ],
                    SizedBox(height: context.fx(10)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (withFlight != null)
                                Text.rich(TextSpan(children: [
                                  TextSpan(text: _money(withFlight),
                                      style: TrishaStyle.body(context, 16, weight: FontWeight.w700, height: 1.1)),
                                  TextSpan(text: ' with flights',
                                      style: TrishaStyle.body(context, 11, color: TrishaStyle.hint, height: 1.1)),
                                ]), maxLines: 1, overflow: TextOverflow.ellipsis),
                              if (withoutFlight != null)
                                Text('${_money(withoutFlight)} without flights',
                                    style: TrishaStyle.body(context, 11, color: TrishaStyle.hint, height: 1.4)),
                              Text('for ${data['adults'] ?? 2} adults',
                                  style: TrishaStyle.body(context, 10, color: TrishaStyle.hint, height: 1.3)),
                            ],
                          ),
                        ),
                        Text(onTap != null ? 'View ›' : '',
                            style: TrishaStyle.body(context, 12, color: TrishaStyle.accent, weight: FontWeight.w600, height: 1)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayPlan extends StatelessWidget {
  final List days;

  const _DayPlan({required this.days});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final d in days.whereType<Map>())
            Padding(
              padding: EdgeInsets.only(bottom: context.fx(8)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: context.fx(44),
                    padding: EdgeInsets.symmetric(vertical: context.fx(3)),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(context.fx(8)),
                    ),
                    child: Text('Day ${d['day']}',
                        style: TrishaStyle.body(context, 10, color: TrishaStyle.brandBlue, weight: FontWeight.w600, height: 1.2)),
                  ),
                  SizedBox(width: context.fx(10)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${d['label']}', style: TrishaStyle.body(context, 12, weight: FontWeight.w600, height: 1.3)),
                        for (final item in (d['items'] as List? ?? []))
                          Text('$item', style: TrishaStyle.body(context, 11, color: TrishaStyle.hint, height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
}

class _HolidayQuoteCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _HolidayQuoteCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final notes = (data['notes'] as List? ?? []).map((e) => '$e').toList();
    final changes = (data['changes'] as List? ?? []).map((e) => '$e').toList();
    final flights = data['flight_included'] == true ? 'Flights from ${data['origin']}' : 'Without flights';
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.fx(14)),
        border: Border.all(color: TrishaStyle.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HotelImage(url: data['image'] as String?, height: context.fx(110)),
          Padding(
            padding: EdgeInsets.all(context.fx(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${data['title']}', style: TrishaStyle.body(context, 14, weight: FontWeight.w700, height: 1.25)),
                SizedBox(height: context.fx(4)),
                Text('${_date(data['start_date'])} · ${data['nights']}N/${((data['nights'] as num?) ?? 0) + 1}D · '
                    '${_party(data)} · $flights',
                    style: TrishaStyle.body(context, 11, color: TrishaStyle.hint, height: 1.4)),
                const Divider(color: TrishaStyle.cardBorder),
                if (changes.isNotEmpty) ...[
                  Text('Your changes', style: TrishaStyle.body(context, 12, weight: FontWeight.w600, height: 1.3)),
                  for (final c in changes)
                    Padding(
                      padding: EdgeInsets.only(top: context.fx(3)),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Icon(Icons.check_circle_rounded, size: context.fx(13), color: _green),
                        SizedBox(width: context.fx(6)),
                        Expanded(child: Text(c, style: TrishaStyle.body(context, 11, color: TrishaStyle.hint, height: 1.35))),
                      ]),
                    ),
                  const Divider(color: TrishaStyle.cardBorder),
                ],
                _DayPlan(days: data['days'] as List? ?? []),
                if (notes.isNotEmpty)
                  Text(notes.join('\n'), style: TrishaStyle.body(context, 11, color: TrishaStyle.accent)),
                const Divider(color: TrishaStyle.cardBorder),
                if (data['total'] != null) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Total', style: TrishaStyle.body(context, 13, weight: FontWeight.w600)),
                      const Spacer(),
                      Text(_money(data['total']), style: TrishaStyle.body(context, 18, weight: FontWeight.w700, height: 1)),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${_money(data['per_person'])} per person${data['tax'] != null ? ' · incl. ${_money(data['tax'])} GST' : ''}',
                      style: TrishaStyle.body(context, 10, color: TrishaStyle.hint, height: 1.4),
                    ),
                  ),
                ] else
                  Text('Price on request', style: TrishaStyle.body(context, 13, weight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One alternative while customising a package: a hotel, flight, add-on or car.
/// `delta_text` is what picking it does to the package total ("+₹1,200").
class _PackageChoiceCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onTap;

  const _PackageChoiceCard({required this.data, this.onTap});

  static const _icons = {
    'hotel': Icons.hotel_rounded,
    'flight': Icons.flight_rounded,
    'addon': Icons.local_activity_rounded,
    'cab': Icons.directions_car_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final kind = '${data['kind']}';
    final image = data['image'] as String?;
    final details = (data['details'] as List? ?? []).map((e) => '$e').where((e) => e.isNotEmpty).toList();
    final delta = data['delta'] as num?;
    final deltaColor = delta == null
        ? TrishaStyle.hint
        : delta < 0
            ? _green
            : TrishaStyle.text;
    final size = context.fx(64);
    final thumb = ClipRRect(
      borderRadius: BorderRadius.circular(context.fx(10)),
      child: image != null && image.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: image,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _placeholder(context, kind, size),
              placeholder: (_, __) => _placeholder(context, kind, size),
            )
          : _placeholder(context, kind, size),
    );
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(context.fx(14)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(context.fx(10)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.fx(14)),
            border: Border.all(color: TrishaStyle.cardBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              thumb,
              SizedBox(width: context.fx(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(
                        child: Text('${data['option_number']}. ${data['title']}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TrishaStyle.body(context, 13, weight: FontWeight.w700, height: 1.25)),
                      ),
                      if (data['is_selected'] == true) ...[
                        SizedBox(width: context.fx(6)),
                        const _Chip('Current', color: _green, bg: _greenBg),
                      ],
                    ]),
                    if ('${data['subtitle'] ?? ''}'.isNotEmpty) ...[
                      SizedBox(height: context.fx(3)),
                      Text('${data['subtitle']}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TrishaStyle.body(context, 11, color: TrishaStyle.hint, height: 1.3)),
                    ],
                    if (details.isNotEmpty) ...[
                      SizedBox(height: context.fx(6)),
                      if (kind == 'addon')
                        Text(details.first,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TrishaStyle.body(context, 10, color: TrishaStyle.hint, height: 1.35))
                      else
                        Wrap(spacing: context.fx(5), runSpacing: context.fx(5), children: [
                          for (final t in details.take(3)) _Chip(t),
                        ]),
                    ],
                    SizedBox(height: context.fx(8)),
                    Row(children: [
                      Expanded(
                        child: Text('${data['delta_text'] ?? ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TrishaStyle.body(context, 13, weight: FontWeight.w700, color: deltaColor, height: 1.1)),
                      ),
                      Text(onTap != null ? 'Choose ›' : '',
                          style: TrishaStyle.body(context, 12, color: TrishaStyle.accent, weight: FontWeight.w600, height: 1)),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context, String kind, double size) => Container(
        width: size,
        height: size,
        color: TrishaStyle.listBg,
        alignment: Alignment.center,
        child: Icon(_icons[kind] ?? Icons.tune_rounded, size: context.fx(26), color: TrishaStyle.hint),
      );
}

class _HolidayReviewCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool active;
  final TrishaCardHandler handler;

  const _HolidayReviewCard({required this.data, required this.active, required this.handler});

  @override
  Widget build(BuildContext context) {
    final flights = data['flight_included'] == true ? 'Flights from ${data['origin']}' : 'Without flights';
    return _CardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${data['title']}', style: TrishaStyle.body(context, 14, weight: FontWeight.w700, height: 1.25)),
          SizedBox(height: context.fx(6)),
          _StayLines(data: {
            'check_in': data['start_date'],
            'check_out': DateTime.tryParse('${data['start_date']}')
                ?.add(Duration(days: (data['nights'] as num?)?.toInt() ?? 0))
                .toIso8601String(),
            'nights': data['nights'],
            'guests': data['travellers'],
          }),
          Row(children: [
            Icon(Icons.flight_rounded, size: context.fx(15), color: TrishaStyle.brandBlue),
            SizedBox(width: context.fx(8)),
            Text(flights, style: TrishaStyle.body(context, 12, height: 1.35)),
          ]),
          const Divider(color: TrishaStyle.cardBorder),
          Row(children: [
            Text('Total', style: TrishaStyle.body(context, 13, weight: FontWeight.w600)),
            const Spacer(),
            Text(_money(data['total']), style: TrishaStyle.body(context, 18, weight: FontWeight.w700, height: 1)),
          ]),
          SizedBox(height: context.fx(6)),
          Text('By confirming you accept the cancellation policy and terms.',
              style: TrishaStyle.body(context, 10, color: TrishaStyle.hint)),
          SizedBox(height: context.fx(10)),
          _PrimaryButton(
            label: 'Confirm & continue',
            onTap: active ? () => handler.action('confirm_booking', label: 'Confirm & continue') : null,
          ),
          SizedBox(height: context.fx(8)),
          _PrimaryButton(
            label: 'Change travellers',
            outlined: true,
            onTap: active ? () => handler.action('change_travellers', label: 'Change travellers') : null,
          ),
        ],
      ),
    );
  }
}

class _HolidayPayOptionsCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool active;
  final TrishaCardHandler handler;

  const _HolidayPayOptionsCard({required this.data, required this.active, required this.handler});

  @override
  Widget build(BuildContext context) {
    final instalments = (data['instalments'] as List? ?? []).whereType<Map>().toList();
    final policy = (data['cancellation_policy'] as List? ?? []).whereType<Map>().toList();
    return _CardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('Booking ${data['reference']}', style: TrishaStyle.body(context, 13, weight: FontWeight.w700)),
            const Spacer(),
            Text(_money(data['grand_total']), style: TrishaStyle.body(context, 14, weight: FontWeight.w700)),
          ]),
          SizedBox(height: context.fx(8)),
          for (final i in instalments)
            Padding(
              padding: EdgeInsets.only(bottom: context.fx(8)),
              child: Material(
                color: TrishaStyle.listBg,
                borderRadius: BorderRadius.circular(context.fx(10)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(context.fx(10)),
                  onTap: active
                      ? () => handler.action('select_instalment',
                          data: {'percent': i['percent']}, label: 'Pay ${i['percent']}% (${_money(i['pay_now'])})')
                      : null,
                  child: Padding(
                    padding: EdgeInsets.all(context.fx(10)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(i['percent'] == 100 ? 'Pay in full' : 'Pay ${i['percent']}% now',
                                  style: TrishaStyle.body(context, 12, weight: FontWeight.w600, height: 1.3)),
                              if (i['balance_due_on'] != null)
                                Text('${_money(i['balance'])} due by ${_date(i['balance_due_on'])}',
                                    style: TrishaStyle.body(context, 10, color: TrishaStyle.hint, height: 1.3)),
                            ],
                          ),
                        ),
                        Text(_money(i['pay_now']),
                            style: TrishaStyle.body(context, 14, color: TrishaStyle.accent, weight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (policy.isNotEmpty) ...[
            Text('Cancellation policy', style: TrishaStyle.body(context, 11, weight: FontWeight.w600)),
            for (final p in policy)
              Text(
                '• ${p['label']}: ${p['fee_percent'] == null ? 'fee to be confirmed by our team' : '${p['fee_percent']}% fee'}'
                '${'${p['note'] ?? ''}'.isNotEmpty ? ' (${p['note']})' : ''}',
                style: TrishaStyle.body(context, 11, color: TrishaStyle.hint, height: 1.4),
              ),
          ],
        ],
      ),
    );
  }
}

class _HolidayConfirmedCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _HolidayConfirmedCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final balance = (data['balance'] as num?) ?? 0;
    return _CardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: context.fx(22)),
            SizedBox(width: context.fx(8)),
            Text('Holiday booked', style: TrishaStyle.body(context, 14, weight: FontWeight.w700)),
          ]),
          SizedBox(height: context.fx(10)),
          Text('Booking reference', style: TrishaStyle.body(context, 11, color: TrishaStyle.hint)),
          SelectableText('${data['reference']}',
              style: TrishaStyle.body(context, 20, weight: FontWeight.w700, height: 1.2).copyWith(letterSpacing: 1.5)),
          SizedBox(height: context.fx(8)),
          Text('${data['title']}', style: TrishaStyle.body(context, 13, weight: FontWeight.w600)),
          Text('${_date(data['start_date'])} · ${data['nights']}N/${((data['nights'] as num?) ?? 0) + 1}D',
              style: TrishaStyle.body(context, 11, color: TrishaStyle.hint)),
          if (_travellerNames(data).isNotEmpty)
            Text(_travellerNames(data), style: TrishaStyle.body(context, 12)),
          const Divider(color: TrishaStyle.cardBorder),
          Text('Paid ${_money(data['amount_paid'])} of ${_money(data['grand_total'])}',
              style: TrishaStyle.body(context, 12, weight: FontWeight.w600)),
          if (balance > 0)
            Text('Balance ${_money(balance)}${data['balance_due_on'] != null ? ' due by ${_date(data['balance_due_on'])}' : ''}',
                style: TrishaStyle.body(context, 11, color: TrishaStyle.accent)),
        ],
      ),
    );
  }
}
