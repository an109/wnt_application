import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/common_widgets/airline_logo.dart';
import 'package:wander_nova/core/resources/app_colours.dart';

import '../../../../core/services/pdf_generator.dart';
import '../../../home/flight/flight_screen.dart';
import '../../Screen/trip_card.dart';
import '../data/data_source/flight_refund_service.dart';
import '../domain/entities/FlightBookEntity.dart';
import '../domain/flight_trip_info.dart';
import 'flight_pdf_builder.dart';
import 'flight_ticket_screen.dart';

// Figma "trip upcoming / Past trip / Cancelled details" (412px wide).

const Color _kInk = Color(0xFF111527);
const Color _kMuted = Color(0xFF6B7280);
const Color _kLine = Color(0xFFE5E7EB);
const Color _kOrange = Color(0xFFEE7330);
const Color _kRed = Color(0xFFE53935);
const Color _kGreen = Color(0xFF34A853);

const Map<String, String> _kCurrencySymbols = {'INR': '₹', 'USD': '\$', 'EUR': '€', 'GBP': '£', 'AED': 'AED '};

String _money(num amount, String currency) {
  final symbol = _kCurrencySymbols[currency.toUpperCase()] ?? '${currency.toUpperCase()} ';
  final whole = amount.round().abs().toString();
  // Indian grouping: 12,34,567
  String grouped;
  if (whole.length <= 3) {
    grouped = whole;
  } else {
    final last3 = whole.substring(whole.length - 3);
    var rest = whole.substring(0, whole.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    grouped = '${parts.join(',')},$last3';
  }
  return '${amount < 0 ? '- ' : ''}$symbol$grouped';
}

String _paidVia(String? raw) => switch ((raw ?? '').toLowerCase()) {
  '' => '',
  'ccavenue' => 'CCAvenue',
  'razorpay' => 'Razorpay',
  'nomod' => 'Card (Nomod)',
  'wallet' => 'WanderNova Wallet',
  final other => titleCase(other),
};

/// Saves [pdf] and offers Share / Print, with a snackbar while it builds.
Future<void> saveAndOfferPdf(
  BuildContext context, {
  required Future<pw.Document> Function(pw.ImageProvider? logo) build,
  required String filename,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(const SnackBar(content: Text('Preparing PDF…'), behavior: SnackBarBehavior.floating));
  try {
    pw.ImageProvider? logo;
    try {
      final data = await rootBundle.load('assets/images/wander_logo.png');
      logo = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {}
    final file = await PDFService.savePDF(await build(logo), filename);
    messenger.hideCurrentSnackBar();
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(sheet.fx(20), sheet.fx(16), sheet.fx(20), sheet.fx(12)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: _kGreen),
                  SizedBox(width: sheet.fx(8)),
                  Expanded(
                    child: Text(
                      'PDF ready',
                      style: TextStyle(fontSize: sheet.ffs(16), fontWeight: FontWeight.w600, color: _kInk),
                    ),
                  ),
                ],
              ),
              SizedBox(height: sheet.fx(4)),
              Text(filename, style: TextStyle(fontSize: sheet.ffs(12), color: _kMuted)),
              SizedBox(height: sheet.fx(12)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.share_rounded, color: AppColors.AppBlue),
                title: const Text('Share / Save to Files'),
                onTap: () {
                  Navigator.pop(sheet);
                  Share.shareXFiles([XFile(file.path)]);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.print_rounded, color: AppColors.AppBlue),
                title: const Text('Open / Print'),
                onTap: () {
                  Navigator.pop(sheet);
                  PDFService.printPDF(file);
                },
              ),
            ],
          ),
        ),
      ),
    );
  } catch (e) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text("Couldn't create the PDF: $e"), backgroundColor: _kRed, behavior: SnackBarBehavior.floating),
      );
  }
}

class FlightTripDetailsScreen extends StatefulWidget {
  final FlightBookEntity booking;
  final FlightRefundService? refundService;

  const FlightTripDetailsScreen({super.key, required this.booking, this.refundService});

  @override
  State<FlightTripDetailsScreen> createState() => _FlightTripDetailsScreenState();
}

class _FlightTripDetailsScreenState extends State<FlightTripDetailsScreen> {
  late FlightTripInfo _info = FlightTripInfo(widget.booking);
  bool _passengersOpen = true;

  // Cancelled trips only.
  bool _refundLoading = false;
  FlightRefund? _refund;
  int? _refundDays;

  FlightBookEntity get _b => widget.booking;

  @override
  void initState() {
    super.initState();
    if (_info.state == FlightTripState.cancelled) _loadRefund();
  }

  @override
  void didUpdateWidget(FlightTripDetailsScreen old) {
    super.didUpdateWidget(old);
    if (old.booking != widget.booking) {
      _info = FlightTripInfo(widget.booking);
      _refund = null;
      if (_info.state == FlightTripState.cancelled) _loadRefund();
    }
  }

  Future<void> _loadRefund() async {
    setState(() => _refundLoading = true);
    final service = widget.refundService ?? FlightRefundService();
    FlightRefund? refund;
    int? days;
    try {
      refund = await service.forBooking(bookingId: _b.id, pnr: _b.pnr);
    } catch (_) {}
    try {
      days = await service.processingDays();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _refund = refund;
      _refundDays = days;
      _refundLoading = false;
    });
  }

  String get _bookingId => _b.tboBookingId.isNotEmpty ? _b.tboBookingId : '${_b.id}';

  void _share() {
    final dep = _info.departure;
    Share.share([
      '${_info.airline} ${_info.flightNumber}'.trim(),
      '${_info.fromCity} (${_info.fromCode}) → ${_info.toCity} (${_info.toCode})',
      if (dep != null) '${tripDate(dep)}${_info.hasSegments ? ', ${tripTime(dep)}' : ''}',
      if (_info.isConfirmed) 'PNR: ${_b.pnr}',
      'Booked with WanderNova',
    ].join('\n'));
  }

  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final cancelled = _info.state == FlightTripState.cancelled;
    final gap = SizedBox(height: context.fx(16));
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        bottomNavigationBar: _bottomBar(),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _topBar(),
              Expanded(
                child: ListView(
                  physics: context.scrollPhysics,
                  padding: EdgeInsets.only(bottom: context.fx(24)),
                  children: [
                    _Hero(info: _info),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: context.fx(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          gap,
                          _flightCard(),
                          if (cancelled) ...[gap, _flightStatus()],
                          gap,
                          _passengers(),
                          gap,
                          _fare(),
                          gap,
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: _baggageCard()),
                                SizedBox(width: context.fx(12)),
                                Expanded(child: _infoCard()),
                              ],
                            ),
                          ),
                        ],
                      ),
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

  Widget _topBar() {
    final (label, color) = switch (_info.state) {
      FlightTripState.upcoming => ('Upcoming', AppColors.AppBlue),
      FlightTripState.past => ('Past Trip', const Color(0xFF7CC7EE)),
      FlightTripState.cancelled => ('Cancelled', const Color(0xFF7CC7EE)),
    };
    return Padding(
      padding: EdgeInsets.fromLTRB(context.fx(8), context.fx(6), context.fx(4), context.fx(10)),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(Icons.arrow_back, size: context.fx(24), color: _kInk),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Trip Details',
                      style: TextStyle(fontSize: context.ffs(18), fontWeight: FontWeight.w600, color: _kInk),
                    ),
                    SizedBox(width: context.fx(8)),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: context.fx(8), vertical: context.fx(2)),
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(context.fx(20))),
                      child: Text(
                        label,
                        style: TextStyle(fontSize: context.ffs(10.5), fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Booking ID: $_bookingId',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: context.ffs(11), color: _kMuted),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Share',
            onPressed: _share,
            icon: Icon(Icons.share_rounded, size: context.fx(20), color: _kInk),
          ),
        ],
      ),
    );
  }

  Widget _flightCard() {
    final dep = _info.departure, arr = _info.arrival;
    final corner = switch (_info.state) {
      FlightTripState.past => ('Completed', const Color(0xFF7CC7EE)),
      FlightTripState.cancelled => ('Cancelled', _kRed),
      FlightTripState.upcoming => null,
    };
    return _Section(
      padding: EdgeInsets.fromLTRB(context.fx(14), context.fx(14), context.fx(14), context.fx(12)),
      cornerTag: corner,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AirlineLogo(
                code: _info.airlineCode,
                name: _info.airline,
                size: context.fx(32),
                borderRadius: BorderRadius.circular(context.fx(6)),
              ),
              SizedBox(width: context.fx(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        text: _info.airline,
                        children: [
                          if (_info.flightNumber.isNotEmpty)
                            TextSpan(
                              text: '  ${_info.flightNumber}',
                              style: const TextStyle(fontWeight: FontWeight.w400, color: _kMuted),
                            ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: context.ffs(15), fontWeight: FontWeight.w600, color: _kInk),
                    ),
                    Text(
                      [
                        if (_info.isConfirmed) 'PNR ${_b.pnr}',
                        if (_info.cabinClass.isNotEmpty) _info.cabinClass,
                        if (_info.isRoundTrip) 'Round trip',
                      ].join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: context.ffs(11), color: _kMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.fx(14)),
          TripRouteRow(
            from: TripEndpoint(
              code: _info.fromCode,
              place: _info.fromCity,
              time: _info.hasSegments ? tripTime(dep) : '',
              date: tripDate(dep),
            ),
            to: TripEndpoint(code: _info.toCode, place: _info.toCity, time: tripTime(arr), date: tripDate(arr)),
            middleTop: _info.routeSummary,
            middleIcon: Icons.flight_rounded,
            middleBottom: _info.checkInOpen ? 'Check-in Open' : null,
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: context.fx(12)),
            child: const Divider(height: 1, color: Color(0xFFF0F1F4)),
          ),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(child: _Stat(icon: Icons.person_rounded, label: 'Passengers', value: _info.paxLabel)),
                const VerticalDivider(width: 12, color: _kLine),
                Expanded(
                  child: _Stat(
                    icon: Icons.airline_seat_recline_normal_rounded,
                    label: 'Cabin Class',
                    value: _info.cabinClass.isEmpty ? '—' : _info.cabinClass,
                  ),
                ),
                const VerticalDivider(width: 12, color: _kLine),
                Expanded(
                  child: _Stat(
                    icon: Icons.work_rounded,
                    label: 'Baggage',
                    value: _info.checkInBaggage.isEmpty ? '—' : _info.checkInBaggage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _flightStatus() {
    final cancelledAt = parseTripDate(_b.cancelledAt)?.toLocal();
    final dep = _info.departure, arr = _info.arrival;
    Widget row(DateTime? when, String kind, String where) => Padding(
      padding: EdgeInsets.only(top: context.fx(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cancel, size: context.fx(18), color: _kRed),
          SizedBox(width: context.fx(8)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    text: _info.hasSegments && when != null ? '${tripTime(when)} ' : '',
                    children: [
                      TextSpan(
                        text: '(Scheduled $kind)',
                        style: TextStyle(fontWeight: FontWeight.w400, color: AppColors.AppBlue, fontSize: context.ffs(11.5)),
                      ),
                    ],
                  ),
                  style: TextStyle(fontSize: context.ffs(13), fontWeight: FontWeight.w600, color: _kInk),
                ),
                Text(
                  [if (when != null) tripDate(when), where].join(', '),
                  style: TextStyle(fontSize: context.ffs(11), color: _kMuted),
                ),
              ],
            ),
          ),
          Text('Cancelled', style: TextStyle(fontSize: context.ffs(12), fontWeight: FontWeight.w500, color: _kRed)),
        ],
      ),
    );

    return _Section(
      title: 'Flight Status',
      icon: Icons.flight_rounded,
      iconColor: _kRed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.all(context.fx(12)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(context.fx(12)),
              gradient: const LinearGradient(colors: [Color(0xFFF7C9C9), Color(0xFFFDEDED)]),
            ),
            child: Row(
              children: [
                Container(
                  width: context.fx(36),
                  height: context.fx(36),
                  decoration: const BoxDecoration(color: _kRed, shape: BoxShape.circle),
                  child: Icon(Icons.close_rounded, color: Colors.white, size: context.fx(22)),
                ),
                SizedBox(width: context.fx(10)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cancelled',
                        style: TextStyle(fontSize: context.ffs(15), fontWeight: FontWeight.w600, color: _kRed),
                      ),
                      Text(
                        'This booking has been cancelled.',
                        style: TextStyle(fontSize: context.ffs(11.5), color: const Color(0xFF7A3B3B)),
                      ),
                    ],
                  ),
                ),
                if (cancelledAt != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: context.fx(8), vertical: context.fx(6)),
                    decoration: BoxDecoration(color: _kRed, borderRadius: BorderRadius.circular(context.fx(8))),
                    child: Column(
                      children: [
                        Text('Cancelled on', style: TextStyle(fontSize: context.ffs(9.5), color: Colors.white)),
                        Text(
                          tripDate(cancelledAt),
                          style: TextStyle(fontSize: context.ffs(11.5), fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                        Text(tripTime(cancelledAt), style: TextStyle(fontSize: context.ffs(10), color: Colors.white)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          row(dep, 'Departure', '${_info.fromCity} (${_info.fromCode})'),
          row(arr, 'Arrival', '${_info.toCity} (${_info.toCode})'),
        ],
      ),
    );
  }

  Widget _passengers() {
    final pax = _b.passengersData;
    final ssr = _b.ssrSelections;
    List<dynamic> ssrList(String key) => ssr[key] is List ? ssr[key] as List : const [];
    String ssrField(String key, int i, String field) {
      final list = ssrList(key);
      if (i >= list.length || list[i] is! Map) return '';
      return ((list[i] as Map)[field] ?? '').toString().trim();
    }

    return _Section(
      title: 'Passenger Details',
      icon: Icons.groups_rounded,
      iconColor: AppColors.AppBlue,
      trailing: IconButton(
        tooltip: _passengersOpen ? 'Collapse' : 'Expand',
        visualDensity: VisualDensity.compact,
        onPressed: () => setState(() => _passengersOpen = !_passengersOpen),
        icon: Icon(
          _passengersOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
          color: AppColors.AppBlue,
        ),
      ),
      child: !_passengersOpen
          ? const SizedBox.shrink()
          : pax.isEmpty
          ? Text(
              _info.paxCount.isEmpty ? 'Passenger details unavailable.' : _info.paxCount,
              style: TextStyle(fontSize: context.ffs(12.5), color: _kMuted),
            )
          : Column(
              children: [
                for (var i = 0; i < pax.length; i++)
                  Padding(
                    padding: EdgeInsets.only(bottom: i == pax.length - 1 ? 0 : context.fx(10)),
                    child: _PassengerTile(
                      pax: pax[i],
                      baggage: ssrField('baggage', i, 'weight').isNotEmpty
                          ? '${_info.checkInBaggage.isEmpty ? '' : '${_info.checkInBaggage} + '}${ssrField('baggage', i, 'weight')}'
                          : _info.checkInBaggage,
                      seat: ssrField('seat', i, 'code').isNotEmpty ? ssrField('seat', i, 'code') : '${pax[i].tboSeat ?? ''}'.trim(),
                      meal: ssrField('meal', i, 'description').isNotEmpty
                          ? ssrField('meal', i, 'description')
                          : '${pax[i].tboMeal ?? ''}'.trim(),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _fare() {
    final cur = _b.currency.isEmpty ? 'INR' : _b.currency;
    final pb = _b.priceBreakdown;
    double n(String key) => double.tryParse('${pb?[key] ?? ''}') ?? 0;
    final total = double.tryParse(_b.totalAmount) ?? (pb != null ? n('total_paid') : 0);
    final rows = <(String, double)>[
      if (pb != null) ...[
        ('Flight Fare (${_info.paxLabel})', n('flight_fare')),
        if (n('ssr_amount') + n('seat_amount') > 0) ('Add-ons (seats, meals, baggage)', n('ssr_amount') + n('seat_amount')),
        if (n('convenience_fee') > 0) ('Convenience Fee', n('convenience_fee')),
        if (n('platform_fee') > 0) ('Platform Fee', n('platform_fee')),
        if (n('booking_mgmt_fee') > 0) ('Booking Fee', n('booking_mgmt_fee')),
        if (n('coupon_discount') > 0)
          ('Coupon${(pb['coupon_code'] ?? '').toString().isNotEmpty ? ' (${pb['coupon_code']})' : ''}', -n('coupon_discount')),
      ],
    ];
    final cancelled = _info.state == FlightTripState.cancelled;

    return _Section(
      title: 'Fare Details',
      icon: Icons.description_rounded,
      iconColor: _kOrange,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Inset(
            child: Column(
              children: [
                for (final (label, amount) in rows) _kv(label, _money(amount, cur), muted: true),
                if (rows.isNotEmpty) Divider(height: context.fx(20), color: _kLine),
                Row(
                  children: [
                    Expanded(
                      child: Text('Total Paid', style: TextStyle(fontSize: context.ffs(15), fontWeight: FontWeight.w500, color: _kInk)),
                    ),
                    Text(
                      _money(total, cur),
                      style: TextStyle(fontSize: context.ffs(17), fontWeight: FontWeight.w600, color: AppColors.AppBlue),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: context.fx(12)),
          cancelled ? _refundBox(cur) : _paymentBox(total),
        ],
      ),
    );
  }

  Widget _paymentBox(double total) {
    final paid = total > 0;
    final txn = (_b.ccavenueOrderId ?? _b.checkoutId ?? '').toString();
    final paidOn = parseTripDate(_b.created)?.toLocal();
    return _Inset(
      tinted: true,
      title: 'Payment Details',
      titleIcon: Icons.credit_card_rounded,
      child: Column(
        children: [
          _kv('Payment Status', '', chip: paid ? ('Success', _kGreen) : ('Pending', const Color(0xFFE59400))),
          if (_paidVia(_b.paidVia).isNotEmpty) _kv('Payment Method', _paidVia(_b.paidVia)),
          if (txn.isNotEmpty && txn != 'null') _kv('Transaction ID', txn),
          if (paidOn != null) _kv('Payment Date', tripDateTime(paidOn)),
        ],
      ),
    );
  }

  Widget _refundBox(String cur) {
    final r = _refund;
    Widget body;
    if (_refundLoading) {
      body = Padding(
        padding: EdgeInsets.symmetric(vertical: context.fx(8)),
        child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    } else if (r == null) {
      body = Text(
        "No refund request found for this booking yet. If you expected one, please contact support.",
        style: TextStyle(fontSize: context.ffs(12), height: 1.4, color: _kMuted),
      );
    } else {
      final (label, color) = switch (r.status) {
        'completed' => ('Completed', _kGreen),
        'rejected' => ('Rejected', _kRed),
        'processing' => ('Processing', const Color(0xFFE59400)),
        _ => ('Pending', const Color(0xFFE59400)),
      };
      final method = r.refundType == 'wallet'
          ? 'WanderNova Wallet'
          : 'Original Payment Method${_paidVia(_b.paidVia).isNotEmpty ? ' (${_paidVia(_b.paidVia)})' : ''}';
      final open = r.status == 'pending' || r.status == 'processing';
      body = Column(
        children: [
          _kv('Refund Status', '', chip: (label, color)),
          _kv('Refund Amount', _money(r.refundAmount, r.currency.isEmpty ? cur : r.currency)),
          if (r.providerPenalty > 0) _kv('Airline Penalty', _money(r.providerPenalty, r.currency)),
          if (r.platformFee > 0) _kv('Processing Fee', _money(r.platformFee, r.currency)),
          _kv('Refund Method', method),
          if (open && _refundDays != null) _kv('Expected Refund', 'Within $_refundDays business days'),
        ],
      );
    }
    return _Inset(tinted: true, title: 'Refund Information', titleIcon: Icons.credit_card_rounded, child: body);
  }

  Widget _kv(String label, String value, {bool muted = false, (String, Color)? chip}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.fx(5)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: TextStyle(fontSize: context.ffs(12.5), color: muted ? _kMuted : const Color(0xFF4B5563)),
            ),
          ),
          SizedBox(width: context.fx(8)),
          Flexible(
            flex: 6,
            child: Align(
              alignment: Alignment.centerRight,
              child: chip != null
                  ? Container(
                      padding: EdgeInsets.symmetric(horizontal: context.fx(10), vertical: context.fx(3)),
                      decoration: BoxDecoration(
                        color: chip.$2.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(context.fx(20)),
                      ),
                      child: Text(chip.$1, style: TextStyle(fontSize: context.ffs(11.5), color: chip.$2)),
                    )
                  : Text(
                      value,
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: context.ffs(12.5), fontWeight: FontWeight.w500, color: _kInk),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _baggageCard() {
    final rows = [
      ('Check-in Baggage', _info.checkInBaggage),
      ('Cabin Baggage', _info.cabinBaggage),
    ].where((r) => r.$2.isNotEmpty);
    return _Section(
      title: 'Baggage Allowance',
      icon: Icons.luggage_rounded,
      iconColor: AppColors.AppBlue,
      compact: true,
      child: rows.isEmpty
          ? Text('As per airline policy.', style: TextStyle(fontSize: context.ffs(11.5), color: _kMuted))
          : Column(
              children: [
                for (final (label, value) in rows)
                  Padding(
                    padding: EdgeInsets.only(bottom: context.fx(8)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Text(label, style: TextStyle(fontSize: context.ffs(11.5), color: const Color(0xFF4B5563)))),
                        Text(
                          '$value\n(Each)',
                          textAlign: TextAlign.right,
                          style: TextStyle(fontSize: context.ffs(11.5), fontWeight: FontWeight.w600, color: _kInk),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _infoCard() {
    return _Section(
      title: 'Important Info',
      icon: Icons.info_rounded,
      iconColor: const Color(0xFF6B6B6B),
      compact: true,
      child: Text(
        'Carry a valid photo ID (passport and visa for international travel).\n'
        'Reach the airport 2–3 hours before departure.\n'
        'Check airline guidelines for latest updates.',
        style: TextStyle(fontSize: context.ffs(11), height: 1.45, color: const Color(0xFF4B5563)),
      ),
    );
  }

  // ---------------------------------------------------------------------------

  Widget _bottomBar() {
    final buttons = switch (_info.state) {
      FlightTripState.upcoming => [
        _ActionButton(
          label: _info.isConfirmed ? 'VIEW TICKETS' : 'TICKET BEING ISSUED',
          icon: Icons.confirmation_number_rounded,
          onPressed: _info.isConfirmed
              ? () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => FlightTicketScreen(booking: _b)),
                )
              : null,
        ),
      ],
      FlightTripState.past => [
        _ActionButton(
          label: 'DOWNLOAD INVOICE',
          icon: Icons.download_rounded,
          outlined: true,
          onPressed: () => saveAndOfferPdf(
            context,
            filename: 'invoice_${_b.pnr.isEmpty ? _b.id : _b.pnr}.pdf',
            build: (logo) async => FlightPdfBuilder.buildInvoice(booking: _b, logo: logo),
          ),
        ),
        _ActionButton(
          label: 'REBOOK',
          icon: Icons.replay_rounded,
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FlightScreen())),
        ),
      ],
      FlightTripState.cancelled => [
        _ActionButton(
          label: 'DOWNLOAD CANCELLATION RECEIPT',
          icon: Icons.download_rounded,
          onPressed: _refundLoading ? null : _downloadReceipt,
        ),
      ],
    };
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -3))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(context.fx(16), context.fx(12), context.fx(16), context.fx(12)),
          child: Row(
            children: [
              for (var i = 0; i < buttons.length; i++) ...[
                if (i > 0) SizedBox(width: context.fx(12)),
                Expanded(child: buttons[i]),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _downloadReceipt() {
    final r = _refund;
    final cur = _b.currency.isEmpty ? 'INR' : _b.currency;
    saveAndOfferPdf(
      context,
      filename: 'cancellation_${_b.pnr.isEmpty ? _b.id : _b.pnr}.pdf',
      build: (logo) async => FlightPdfBuilder.buildCancellationReceipt(
        booking: _b,
        route: '${_info.fromCity} (${_info.fromCode}) - ${_info.toCity} (${_info.toCode})',
        cancelledOn: tripDateTime(parseTripDate(_b.cancelledAt)?.toLocal()),
        refund: r == null
            ? const []
            : [
                ('Status', titleCase(r.status)),
                ('Refund amount', _money(r.refundAmount, r.currency.isEmpty ? cur : r.currency).replaceAll('₹', 'INR ')),
                if (r.providerPenalty > 0) ('Airline penalty', _money(r.providerPenalty, r.currency).replaceAll('₹', 'INR ')),
                if (r.platformFee > 0) ('Processing fee', _money(r.platformFee, r.currency).replaceAll('₹', 'INR ')),
                ('Refund to', r.refundType == 'wallet' ? 'WanderNova Wallet' : 'Original payment method'),
                if (r.reference.isNotEmpty) ('Reference', r.reference),
              ],
        logo: logo,
      ),
    );
  }
}

// -----------------------------------------------------------------------------

class _Hero extends StatelessWidget {
  final FlightTripInfo info;

  const _Hero({required this.info});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: context.fx(116),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF8CC8F2), Color(0xFFD8EEFC), Colors.white],
              ),
            ),
          ),
          Positioned(
            left: -context.fx(40),
            right: -context.fx(40),
            bottom: -context.fx(36),
            child: Image.asset('assets/home/footer_clouds.png', height: context.fx(110), fit: BoxFit.cover),
          ),
          Positioned(
            right: context.fx(8),
            top: context.fx(2),
            child: Image.asset('assets/home/plane.png', height: context.fx(108)),
          ),
          Positioned(
            left: context.fx(16),
            top: context.fx(24),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(context.fx(10)),
                boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 10, offset: Offset(0, 3))],
              ),
              child: AirlineLogo(
                code: info.airlineCode,
                name: info.airline,
                size: context.fx(56),
                borderRadius: BorderRadius.circular(context.fx(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String? title;
  final IconData? icon;
  final Color? iconColor;
  final Widget? trailing;
  final Widget child;
  final EdgeInsets? padding;
  final (String, Color)? cornerTag;
  final bool compact;

  const _Section({
    this.title,
    this.icon,
    this.iconColor,
    this.trailing,
    required this.child,
    this.padding,
    this.cornerTag,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding ?? EdgeInsets.all(context.fx(compact ? 12 : 14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.fx(14)),
        border: Border.all(color: _kLine),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Icon(icon, size: context.fx(compact ? 16 : 18), color: iconColor),
                SizedBox(width: context.fx(8)),
                Expanded(
                  child: Text(
                    title!,
                    style: TextStyle(
                      fontSize: context.ffs(compact ? 13 : 14.5),
                      fontWeight: FontWeight.w600,
                      color: _kInk,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            SizedBox(height: context.fx(trailing != null ? 4 : 12)),
          ],
          child,
        ],
      ),
    );
    if (cornerTag == null) return card;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        Positioned(
          top: -1,
          right: context.fx(10),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: context.fx(10), vertical: context.fx(3)),
            decoration: BoxDecoration(
              color: cornerTag!.$2,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(context.fx(8))),
            ),
            child: Text(
              cornerTag!.$1,
              style: TextStyle(fontSize: context.ffs(10.5), fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

/// Bordered inner box (fare rows, payment / refund details).
class _Inset extends StatelessWidget {
  final Widget child;
  final bool tinted;
  final String? title;
  final IconData? titleIcon;

  const _Inset({required this.child, this.tinted = false, this.title, this.titleIcon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.fx(12)),
      decoration: BoxDecoration(
        color: tinted ? const Color(0xFFF3FAFE) : Colors.white,
        borderRadius: BorderRadius.circular(context.fx(12)),
        border: Border.all(color: tinted ? const Color(0xFFD6ECF8) : _kLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Icon(titleIcon, size: context.fx(16), color: _kGreen),
                SizedBox(width: context.fx(8)),
                Text(title!, style: TextStyle(fontSize: context.ffs(12.5), fontWeight: FontWeight.w600, color: _kInk)),
              ],
            ),
            SizedBox(height: context.fx(6)),
          ],
          child,
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Stat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: context.fx(30),
          height: context.fx(30),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(context.fx(6)),
          ),
          child: Icon(icon, size: context.fx(17), color: const Color(0xFF3B9BE0)),
        ),
        SizedBox(width: context.fx(6)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: context.ffs(10.5), color: _kMuted)),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: context.ffs(13), fontWeight: FontWeight.w600, color: _kInk),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PassengerTile extends StatelessWidget {
  final PassengerDataEntity pax;
  final String baggage;
  final String seat;
  final String meal;

  const _PassengerTile({required this.pax, required this.baggage, required this.seat, required this.meal});

  String get _type => switch (pax.paxType) {
    2 => 'Child',
    3 => 'Infant',
    _ => 'Adult',
  };

  String get _details {
    final dob = parseTripDate(pax.dateOfBirth);
    final now = DateTime.now();
    int? age;
    if (dob != null) {
      age = now.year - dob.year - ((now.month < dob.month || (now.month == dob.month && now.day < dob.day)) ? 1 : 0);
    }
    final title = pax.title.toLowerCase().replaceAll('.', '');
    final gender = switch (title) {
      'mr' || 'mstr' || 'master' => 'Male',
      'ms' || 'mrs' || 'miss' => 'Female',
      _ => '',
    };
    final parts = [if (age != null) '$age yrs', if (gender.isNotEmpty) gender];
    return parts.isEmpty ? '' : ' (${parts.join(', ')})';
  }

  @override
  Widget build(BuildContext context) {
    final name = '${pax.firstName} ${pax.lastName}'.trim();
    Widget fact(IconData icon, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: context.fx(12), color: _kMuted),
        SizedBox(width: context.fx(3)),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: context.ffs(10.5), color: const Color(0xFF4B5563)),
          ),
        ),
      ],
    );
    return Container(
      padding: EdgeInsets.all(context.fx(12)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.fx(12)),
        border: Border.all(color: _kLine),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    text: name.isEmpty ? 'Passenger' : name,
                    children: [
                      TextSpan(
                        text: _details,
                        style: TextStyle(fontSize: context.ffs(10), fontWeight: FontWeight.w400, color: _kMuted),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: context.ffs(13.5), fontWeight: FontWeight.w600, color: _kInk),
                ),
                SizedBox(height: context.fx(5)),
                Wrap(
                  spacing: context.fx(10),
                  runSpacing: context.fx(4),
                  children: [
                    fact(Icons.person_rounded, _type),
                    if (baggage.isNotEmpty) fact(Icons.work_rounded, baggage),
                    fact(Icons.airline_seat_recline_normal_rounded, seat.isEmpty ? '—' : seat),
                    fact(Icons.restaurant_rounded, meal.isEmpty ? '—' : meal),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: context.fx(8)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Ticket No.', style: TextStyle(fontSize: context.ffs(11), color: AppColors.AppBlue)),
              SizedBox(height: context.fx(2)),
              Text(
                pax.ticketNumber.isEmpty ? 'Pending' : pax.ticketNumber,
                style: TextStyle(
                  fontSize: context.ffs(pax.ticketNumber.isEmpty ? 12 : 13.5),
                  fontWeight: FontWeight.w600,
                  color: pax.ticketNumber.isEmpty ? _kMuted : _kOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool outlined;

  const _ActionButton({required this.label, required this.icon, required this.onPressed, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: context.fx(18)),
        SizedBox(width: context.fx(8)),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: context.ffs(13.5), fontWeight: FontWeight.w600, letterSpacing: 0.2),
          ),
        ),
      ],
    );
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.fx(10)));
    final size = Size.fromHeight(context.fx(50));
    return outlined
        ? OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: _kOrange,
              side: const BorderSide(color: _kOrange),
              shape: shape,
              minimumSize: size,
              padding: EdgeInsets.symmetric(horizontal: context.fx(8)),
            ),
            child: content,
          )
        : FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: _kOrange,
              disabledBackgroundColor: const Color(0xFFF5C3A6),
              disabledForegroundColor: Colors.white,
              shape: shape,
              minimumSize: size,
              padding: EdgeInsets.symmetric(horizontal: context.fx(8)),
            ),
            child: content,
          );
  }
}
