import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../injection_container.dart';
import '../../data/diy_holiday_api.dart';
import '../../data/models/diy_models.dart';
import '../widgets/diy_common.dart';
import '../widgets/diy_trip_day_card.dart';

/// "Transfer" — one transfer of the trip in full, and the car it runs in.
///
/// Opened by both View Details and Modify; Modify lands on Transfer Options.
/// The car classes come from **GET /trips/{trip_id}/cab/**, each priced as
/// the whole trip in that car. Picking one and pressing UPDATE sends **POST
/// /cab/** and pops the repriced trip. There is no per-transfer car: every
/// transfer and sightseeing drive of the package runs in the one class, so
/// changing it here changes them all — the screen says so.
///
/// Everything written on this screen comes from the trip itself. The design's
/// languages, waiting-time and cancellation lines are policy the backend does
/// not hold yet, so they are not shown rather than made up.
class DiyTransferScreen extends StatefulWidget {
  final DiyTrip trip;
  final DiyDay day;
  final DiyRow transfer;
  final bool openOnOptions;

  const DiyTransferScreen({
    super.key,
    required this.trip,
    required this.day,
    required this.transfer,
    this.openOnOptions = false,
  });

  @override
  State<DiyTransferScreen> createState() => _DiyTransferScreenState();
}

class _DiyTransferScreenState extends State<DiyTransferScreen> {
  final DiyHolidayApi _api = sl<DiyHolidayApi>();
  final GlobalKey _optionsKey = GlobalKey();

  DiyCabOptions _cabs = DiyCabOptions.empty;
  bool _loading = true;
  String? _error;
  String? _chosen;
  bool _updating = false;

  DiyTrip get _trip => widget.trip;
  DiyCab get _cab => _trip.cab;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cabs = await _api.getCabOptions(_trip.tripId);
      if (!mounted) return;
      setState(() {
        _cabs = cabs;
        _chosen = cabs.options.where((o) => o.isSelected).firstOrNull?.code ??
            cabs.selected;
        _loading = false;
      });
      if (widget.openOnOptions) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final target = _optionsKey.currentContext;
          if (target != null) {
            Scrollable.ensureVisible(
              target,
              duration: const Duration(milliseconds: 350),
              alignment: 0.05,
            );
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  DiyCabOption? get _current =>
      _cabs.options.where((o) => o.isSelected).firstOrNull;
  DiyCabOption? get _picked =>
      _cabs.options.where((o) => o.code == _chosen).firstOrNull;
  bool get _changed => _picked != null && _picked != _current;

  Future<void> _update() async {
    final picked = _picked;
    if (!_changed || picked == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _updating = true);
    try {
      final trip = await _api.changeCab(
        tripId: _trip.tripId,
        code: picked.code,
        previous: _trip,
      );
      if (mounted) Navigator.of(context).pop(trip);
    } on DiyApiException catch (e) {
      if (mounted) diySnack(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  // ------------------------------------------------------------- wording

  String get _title {
    final t = widget.transfer;
    return switch (t.transferKind) {
      'AIRPORT' => 'One-Way Private Transfer\n${t.title}',
      'LOCAL_SIGHTSEEING' => 'Private Cab\n${t.title}',
      'INTERCITY' => 'Private Intercity Transfer\n${t.title}',
      _ => 'Private Transfer\n${t.title}',
    };
  }

  String get _dateLine {
    final d = diyParseDate(widget.day.date);
    return 'Day ${widget.day.day}'
        '${d == null ? '' : ' • ${DateFormat('MMM d, yyyy').format(d)}'}';
  }

  String get _travellers => [
        '${_trip.adults} Adult${_trip.adults == 1 ? '' : 's'}',
        if (_trip.children > 0)
          '${_trip.children} Child${_trip.children == 1 ? '' : 'ren'}',
      ].join(', ');

  String get _carName =>
      [_cab.selected, if (_cab.label.isNotEmpty) _cab.label].join(' · ');

  // ----------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.15),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black, size: context.w(24)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Text(
          'Transfer',
          style: TextStyle(
            fontSize: context.fs(18),
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          context.w(16),
          context.h(16),
          context.w(16),
          context.h(24),
        ),
        children: [
          _carImage(),
          SizedBox(height: context.h(20)),
          Text(
            _title,
            style: TextStyle(
              fontSize: context.fs(17),
              fontWeight: FontWeight.w700,
              color: Colors.black,
              height: 1.3,
            ),
          ),
          SizedBox(height: context.h(16)),
          Row(
            children: [
              Expanded(
                child: _factBox(
                  icon: Icons.calendar_month_rounded,
                  tint: DiyTokens.blue,
                  label: 'DATE & DAY',
                  value: _dateLine,
                ),
              ),
              SizedBox(width: context.w(10)),
              Expanded(
                child: _factBox(
                  icon: Icons.groups_rounded,
                  tint: DiyTripStyle.green,
                  label: 'TRAVELLERS',
                  value: _travellers,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(16)),
          _aboutCard(),
          SizedBox(height: context.h(16)),
          _highlightsCard(),
          SizedBox(height: context.h(16)),
          KeyedSubtree(key: _optionsKey, child: _optionsCard()),
          SizedBox(height: context.h(16)),
          _additionalInfo(),
        ],
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  Widget _carImage() {
    final image = _picked?.image.isNotEmpty == true ? _picked!.image : _cab.image;
    return SizedBox(
      height: context.h(150),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            bottom: 0,
            child: Container(
              width: context.w(260),
              height: context.h(40),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(200),
                gradient: RadialGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          image.isNotEmpty
              ? DiyImage(
                  url: image,
                  width: context.w(250),
                  height: context.h(130),
                  fit: BoxFit.contain,
                )
              : Image.asset(
                  DiyTripStyle.carPhoto,
                  width: context.w(250),
                  height: context.h(130),
                  fit: BoxFit.contain,
                ),
        ],
      ),
    );
  }

  Widget _factBox({
    required IconData icon,
    required Color tint,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(context.w(10)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.r(8)),
        border: Border.all(color: DiyTripStyle.divider),
      ),
      child: Row(
        children: [
          Container(
            width: context.w(28),
            height: context.w(28),
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(context.r(6)),
            ),
            child: Icon(icon, size: context.w(16), color: tint),
          ),
          SizedBox(width: context.w(8)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: context.fs(8),
                    fontWeight: FontWeight.w600,
                    color: DiyTripStyle.grey,
                  ),
                ),
                Text(
                  value,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: context.fs(11),
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({
    required IconData icon,
    required Color iconColor,
    required String title,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.r(10)),
        border: Border.all(color: DiyTripStyle.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: context.w(18), color: iconColor),
              SizedBox(width: context.w(8)),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: context.fs(14),
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          SizedBox(height: context.h(10)),
          const Divider(height: 1, color: DiyTripStyle.divider),
          SizedBox(height: context.h(10)),
          child,
        ],
      ),
    );
  }

  Widget _aboutCard() {
    final seats = _cab.seats > 0 ? ' (${_cab.seats} seats)' : '';
    return _card(
      icon: Icons.info_rounded,
      iconColor: DiyTokens.blue,
      title: 'About Transfer',
      child: Text(
        '${widget.transfer.title}, in a private '
        '${_carName.isEmpty ? 'car' : _carName}$seats. The car is yours alone — '
        'it is not shared with other travellers — and the same car runs every '
        'transfer and sightseeing drive in your package.',
        style: TextStyle(
          fontSize: context.fs(12),
          color: DiyTripStyle.grey,
          height: 1.45,
        ),
      ),
    );
  }

  Widget _highlightsCard() {
    final transfers = _trip.counts.transfers;
    final points = [
      'Private, door-to-door — no ride sharing.',
      if (_cab.seats > 0 || _cab.luggage > 0)
        [
          if (_cab.seats > 0) '${_cab.seats} seats',
          if (_cab.luggage > 0) '${_cab.luggage} bags',
        ].join(' · '),
      if (transfers > 0)
        'Covers all $transfers transfer${transfers == 1 ? '' : 's'} in your package.',
      if (widget.transfer.durationMinutes > 0)
        'About ${diyDuration(widget.transfer.durationMinutes)} on the road.',
    ];
    return _card(
      icon: Icons.stars_rounded,
      iconColor: DiyTripStyle.orange,
      title: 'Highlights',
      child: Column(
        children: [
          for (final point in points)
            Padding(
              padding: EdgeInsets.only(bottom: context.h(10)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: context.w(18),
                    height: context.w(18),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: DiyTokens.blue.withValues(alpha: 0.12),
                    ),
                    child: Icon(Icons.check_rounded,
                        size: context.w(12), color: DiyTokens.blue),
                  ),
                  SizedBox(width: context.w(10)),
                  Expanded(
                    child: Text(
                      point,
                      style: TextStyle(
                        fontSize: context.fs(12),
                        color: DiyTripStyle.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _optionsCard() {
    final options = _cabs.options;
    final Widget body;
    if (_loading) {
      body = Padding(
        padding: EdgeInsets.symmetric(vertical: context.h(20)),
        child: const Center(child: CircularProgressIndicator()),
      );
    } else if (_error != null) {
      body = Column(
        children: [
          Text(_error!,
              style: TextStyle(fontSize: context.fs(12), color: DiyTripStyle.red)),
          TextButton(onPressed: _load, child: const Text('Retry')),
        ],
      );
    } else {
      // The cheapest car that can be priced is the design's BEST VALUE.
      final priced = options.where((o) => o.total != null).toList()
        ..sort((a, b) => a.total!.compareTo(b.total!));
      final bestValue = priced.isNotEmpty ? priced.first.code : null;
      body = Column(
        children: [
          for (final o in options)
            Padding(
              padding: EdgeInsets.only(bottom: context.h(12)),
              child: _optionTile(o, best: o.code == bestValue),
            ),
        ],
      );
    }

    return _card(
      icon: Icons.directions_car_filled_rounded,
      iconColor: DiyTokens.blue,
      title: 'Transfer Options',
      trailing: _loading
          ? null
          : Text(
              '${options.length} Available',
              style: TextStyle(fontSize: context.fs(11), color: DiyTripStyle.grey),
            ),
      child: body,
    );
  }

  Widget _optionTile(DiyCabOption o, {required bool best}) {
    final selected = o.code == _chosen;
    final name = [
      if (o.name.isNotEmpty) o.name else o.code,
      if (o.label.isNotEmpty) '(${o.label})',
    ].join(' ');

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: EdgeInsets.all(context.w(12)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.r(10)),
            border: Border.all(
              color: selected ? DiyTokens.blue : DiyTripStyle.divider,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: context.fs(13),
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: context.h(4)),
              Row(
                children: [
                  Icon(Icons.event_seat_rounded,
                      size: context.w(12), color: DiyTripStyle.grey),
                  SizedBox(width: context.w(4)),
                  Text(
                    '${o.seats} seats • ${o.luggage} bags',
                    style: TextStyle(
                        fontSize: context.fs(11), color: DiyTripStyle.grey),
                  ),
                  SizedBox(width: context.w(8)),
                  Text(
                    '• Private',
                    style: TextStyle(
                        fontSize: context.fs(11), color: DiyTripStyle.green),
                  ),
                ],
              ),
              SizedBox(height: context.h(8)),
              const Divider(height: 1, color: DiyTripStyle.divider),
              SizedBox(height: context.h(8)),
              Row(
                children: [
                  Icon(Icons.local_taxi_rounded,
                      size: context.w(14), color: DiyTripStyle.orange),
                  SizedBox(width: context.w(6)),
                  Expanded(
                    child: Text(
                      'Dedicated door-to-door private cab (No ride sharing)',
                      style: TextStyle(
                          fontSize: context.fs(11), color: DiyTripStyle.grey),
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.h(8)),
              const Divider(height: 1, color: DiyTripStyle.divider),
              SizedBox(height: context.h(10)),
              Row(
                children: [
                  Expanded(child: _optionPrice(o)),
                  SizedBox(
                    width: context.w(110),
                    height: context.h(38),
                    child: selected
                        ? ElevatedButton(
                            onPressed: null,
                            style: ElevatedButton.styleFrom(
                              disabledBackgroundColor: DiyTripStyle.orange,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(context.r(8)),
                              ),
                            ),
                            child: Text(
                              'SELECTED',
                              style: TextStyle(
                                fontSize: context.fs(13),
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : OutlinedButton(
                            onPressed: o.total == null
                                ? null
                                : () => setState(() => _chosen = o.code),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: DiyTripStyle.orange),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(context.r(8)),
                              ),
                            ),
                            child: Text(
                              'SELECT',
                              style: TextStyle(
                                fontSize: context.fs(13),
                                fontWeight: FontWeight.w600,
                                color: DiyTripStyle.orange,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (best)
          Positioned(
            right: context.w(12),
            top: -context.h(9),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.w(8),
                vertical: context.h(2),
              ),
              decoration: BoxDecoration(
                color: DiyTokens.blue,
                borderRadius: BorderRadius.circular(context.r(10)),
              ),
              child: Text(
                'BEST VALUE',
                style: TextStyle(
                  fontSize: context.fs(8),
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _optionPrice(DiyCabOption o) {
    if (o.total == null) {
      return Text(
        'On request',
        style: TextStyle(
          fontSize: context.fs(13),
          fontWeight: FontWeight.w700,
          color: DiyTripStyle.grey,
        ),
      );
    }
    final delta = o.delta ?? 0;
    final adults = _trip.adults > 0 ? _trip.adults : 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          o.isSelected ? 'Included' : '${diyDelta(delta / adults, currency: _trip.currency)}/person',
          style: TextStyle(
            fontSize: context.fs(17),
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        Text(
          'Trip total ${diyMoney(o.total!, currency: _trip.currency)}',
          style: TextStyle(fontSize: context.fs(10), color: DiyTripStyle.grey),
        ),
      ],
    );
  }

  Widget _additionalInfo() {
    final rows = <(String, String)>[
      if (_carName.isNotEmpty) ('Vehicle', _carName),
      if (_cab.seats > 0) ('Seats', '${_cab.seats}'),
      if (_cab.luggage > 0)
        ('Luggage Allowance', '${_cab.luggage} Bag${_cab.luggage == 1 ? '' : 's'}'),
      ('Shared with others', 'No — private'),
    ];
    return Container(
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.r(10)),
        border: Border.all(color: DiyTripStyle.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ADDITIONAL INFO',
            style: TextStyle(
              fontSize: context.fs(12),
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          SizedBox(height: context.h(10)),
          for (final (label, value) in rows) ...[
            const Divider(height: 1, color: DiyTripStyle.divider),
            Padding(
              padding: EdgeInsets.symmetric(vertical: context.h(10)),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                          fontSize: context.fs(12), color: DiyTripStyle.grey),
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: context.fs(12),
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// "-₹534/person · Total Price ₹7,168" and UPDATE, once a different car is
  /// picked. Before that it shows the trip as it stands.
  Widget? _bottomBar() {
    final picked = _picked;
    final adults = _trip.adults > 0 ? _trip.adults : 1;
    final changed = _changed && picked?.total != null;
    final total = changed ? picked!.total! : _trip.grandTotal;
    final perPersonDelta = changed ? (picked!.delta ?? 0) / adults : 0.0;

    return Container(
      padding: EdgeInsets.fromLTRB(
        context.w(19),
        context.h(14),
        context.w(19),
        context.h(14) + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: context.w(12),
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: changed
                            ? diyDelta(perPersonDelta, currency: _trip.currency)
                            : diyMoney(total / adults, currency: _trip.currency),
                        style: TextStyle(
                          fontSize: context.fs(22),
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                      TextSpan(
                        text: '/person',
                        style: TextStyle(
                          fontSize: context.fs(12),
                          color: DiyTripStyle.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Total Price ${diyMoney(total, currency: _trip.currency)}',
                  style: TextStyle(
                    fontSize: context.fs(10),
                    color: DiyTripStyle.grey,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: context.w(140),
            height: context.h(44),
            child: ElevatedButton(
              onPressed: _updating || !_changed ? null : _update,
              style: ElevatedButton.styleFrom(
                backgroundColor: DiyTripStyle.orange,
                disabledBackgroundColor: const Color(0xFFFFC299),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.r(8)),
                ),
              ),
              child: _updating
                  ? SizedBox(
                      width: context.w(18),
                      height: context.w(18),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'UPDATE',
                      style: TextStyle(
                        fontSize: context.fs(15),
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
