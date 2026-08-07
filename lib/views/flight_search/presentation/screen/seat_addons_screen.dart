import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/currency_converter.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/utils/storage/shared_preference.dart';
import 'package:wander_nova/injection_container.dart';
import 'package:wander_nova/core/error/data_state.dart';

import 'package:wander_nova/views/AKSeatLayout/domain/entity/AKSeatLayout_entity.dart';
import 'package:wander_nova/views/AKSeatLayout/presentation/bloc/AKSeatLayout_bloc.dart';
import 'package:wander_nova/views/AKSeatLayout/presentation/bloc/AKSeatLayout_event.dart';
import 'package:wander_nova/views/AKSeatLayout/presentation/bloc/AKSeatLayout_state.dart';
import 'package:wander_nova/views/AKSelectSeats/domain/entity/AKSelectSeats_entity.dart';
import 'package:wander_nova/views/AKSelectSeats/domain/usecase/AKSelectSeats_usecase.dart';

import 'package:wander_nova/views/AKSsr/domain/entity/AKSsr_entity.dart';
import 'package:wander_nova/views/AKSsr/presentation/bloc/AKSsr_bloc.dart';
import 'package:wander_nova/views/AKSsr/presentation/bloc/AKSsr_event.dart';
import 'package:wander_nova/views/AKSsr/presentation/bloc/AKSsr_state.dart';
import 'package:wander_nova/views/AKSelectSsr/domain/entity/AKSelectSsr_entity.dart';
import 'package:wander_nova/views/AKSelectSsr/domain/usecase/AKSelectSsr_usecase.dart';

import 'booking_screen.dart';

const _blue = Color(0xFF1769F6);
const _navy = Color(0xFF071638);
const _pageBg = Color(0xFFF3F6FC);
const _border = Color(0xFFE2E7F0);
const _muted = Color(0xFF6B7280);
const _availableBorder = Color(0xFF2E9E5B);
const _availableFill = Color(0xFFE7F6EC);

class _PaxDescriptor {
  final int paxId;
  final String label;
  final bool isAdult;

  const _PaxDescriptor(this.paxId, this.label, this.isAdult);
}

class _SeatPick {
  final int ssid;
  final int fuid;
  final int paxId;
  final double fare;
  final double tax;
  final String seatNumber;

  const _SeatPick({
    required this.ssid,
    required this.fuid,
    required this.paxId,
    required this.fare,
    required this.tax,
    required this.seatNumber,
  });
}

/// Composite key for [_SeatAddonsScreenState._seatPicks] — a passenger picks
/// one seat per flight segment, not one seat total, so the key must include
/// the segment (fuid) alongside the passenger, or a later leg's pick
/// silently overwrites an earlier leg's for the same passenger.
String _seatPickKey(int fuid, int paxId) => '$fuid-$paxId';

class _SsrPick {
  final int id;
  final int fuid;
  final int paxId;
  final double charge;
  final String typeName;
  final String description;

  const _SsrPick({
    required this.id,
    required this.fuid,
    required this.paxId,
    required this.charge,
    required this.typeName,
    required this.description,
  });
}

/// Seat map (SeatLayout/SelectSeats) + baggage/meal add-ons (SSR/SelectSSR),
/// shown between "Book Now" (end of the flight-detail sheet, once GetSPricer
/// has produced a pricing TUI + session_id) and the passenger form. Follows
/// the same step-by-step PageView pattern as the existing TBO
/// `SSRMainScreen` (lib/views/flight_ssr/.../ssr/main_screen.dart), just
/// against Akbar's tui/session_id session model instead of TBO's
/// traceId/tokenId. Both steps are optional — Skip and Continue both reach
/// [FlightBookingScreen] with the same [route]; the only difference is
/// whether SelectSeats/SelectSSR were called first. Those calls store the
/// choice on the server-side session, so CreateItinerary's NetAmount picks
/// up the extra cost automatically with no further plumbing needed here.
class SeatAddonsScreen extends StatefulWidget {
  final FlightRouteSegment route;
  final String totalPrice;
  final String? traceId;
  final String? resultIndex;
  final String price;
  final int travellerCount;
  final int adultCount;
  final int childCount;
  final int infantCount;

  /// Extra legs beyond [route] — the return leg for RT/RS, or legs 2..N for
  /// Multi City. Empty for a plain one-way booking.
  final List<FlightRouteSegment> additionalLegs;

  const SeatAddonsScreen({
    super.key,
    required this.route,
    required this.totalPrice,
    this.traceId,
    this.resultIndex,
    required this.price,
    required this.travellerCount,
    this.adultCount = 0,
    this.childCount = 0,
    this.infantCount = 0,
    this.additionalLegs = const [],
  });

  @override
  State<SeatAddonsScreen> createState() => _SeatAddonsScreenState();
}

class _SeatAddonsScreenState extends State<SeatAddonsScreen> {
  final PageController _pageController = PageController();
  late final AkSeatLayoutBloc _seatLayoutBloc;
  late final AkSsrBloc _ssrBloc;
  late final List<_PaxDescriptor> _pax;

  static const _titles = ['Choose Your Seat', 'Baggage & Meals'];
  int _currentIndex = 0;

  int _activePaxId = 1;
  final Map<String, _SeatPick> _seatPicks = {};
  final List<_SsrPick> _ssrPicks = [];
  bool _submitting = false;

  bool get _hasPricing => (widget.route.pricingTui ?? '').isNotEmpty;
  bool get _hasChildOrInfant => _pax.any((p) => !p.isAdult);

  double get _baseFare {
    final amount = widget.route.amount;
    if (amount != null && amount > 0) return amount;
    return double.tryParse(widget.price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
  }

  double get _addOnsTotal {
    final seatTotal = _seatPicks.values.fold<double>(0, (s, p) => s + p.fare + p.tax);
    final ssrTotal = _ssrPicks.fold<double>(0, (s, p) => s + p.charge);
    return seatTotal + ssrTotal;
  }

  /// Akbar fare/seat/add-on amounts are always in INR — this converts to
  /// whatever currency the user has picked in Settings, instead of always
  /// showing a hardcoded ₹.
  String _displayAmount(double amountInInr) {
    final prefs = sl<PreferencesManager>();
    final target = prefs.getPreferredCurrency() ?? 'INR';
    final converted = target.toUpperCase() == 'INR'
        ? amountInInr
        : CurrencyConverter.convert(amount: amountInInr, fromCurrency: 'INR', toCurrency: target);
    return CurrencyConverter.format(converted, target);
  }

  @override
  void initState() {
    super.initState();
    _pax = _buildPax();
    _activePaxId = _pax.isNotEmpty ? _pax.first.paxId : 1;

    _seatLayoutBloc = sl<AkSeatLayoutBloc>();
    _ssrBloc = sl<AkSsrBloc>();

    final pricingTui = widget.route.pricingTui;
    if (pricingTui != null && pricingTui.isNotEmpty) {
      // One order_id per leg — [1] for one-way, [1, 2] for round trip/multi
      // city — so the backend returns a seat map / add-ons for every leg
      // instead of defaulting to just the first one.
      final orderIds = List<int>.generate(1 + widget.additionalLegs.length, (i) => i + 1);
      _seatLayoutBloc.add(
        LoadAkSeatLayoutEvent(AkSeatLayoutRequestEntity(tui: pricingTui, orderIds: orderIds)),
      );
      _ssrBloc.add(LoadAkSsrEvent(AkSsrRequestEntity(tui: pricingTui, orderIds: orderIds)));
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _seatLayoutBloc.close();
    _ssrBloc.close();
    super.dispose();
  }

  List<_PaxDescriptor> _buildPax() {
    final list = <_PaxDescriptor>[];
    int id = 1;
    for (int i = 1; i <= widget.adultCount; i++) {
      list.add(_PaxDescriptor(id++, 'Adult $i', true));
    }
    for (int i = 1; i <= widget.childCount; i++) {
      list.add(_PaxDescriptor(id++, 'Child $i', false));
    }
    for (int i = 1; i <= widget.infantCount; i++) {
      list.add(_PaxDescriptor(id++, 'Infant $i', false));
    }
    if (list.isEmpty) {
      final count = widget.travellerCount < 1 ? 1 : widget.travellerCount;
      for (int i = 1; i <= count; i++) {
        list.add(_PaxDescriptor(i, 'Traveller $i', true));
      }
    }
    return list;
  }

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  void _goToBooking() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => FlightBookingScreen(
          routes: [widget.route, ...widget.additionalLegs],
          totalPrice: widget.totalPrice,
          traceId: widget.traceId,
          resultIndex: widget.resultIndex,
          price: widget.price,
          travellerCount: widget.travellerCount,
          isLoggedIn: false,
          addOnsTotal: _addOnsTotal,
        ),
      ),
    );
  }

  void _skip() => _goToBooking();

  void _nextPage() {
    if (_currentIndex < _titles.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _continue();
    }
  }

  void _previousPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  Future<void> _continue() async {
    final sessionId = widget.route.sessionId;
    if (sessionId == null || sessionId.isEmpty) {
      _goToBooking();
      return;
    }

    setState(() => _submitting = true);
    String? warning;

    if (_seatPicks.isNotEmpty) {
      try {
        final result = await sl<AkSelectSeatsUseCase>().call(
          AkSelectSeatsRequestEntity(
            sessionId: sessionId,
            selectedSeats: _seatPicks.values
                .map((p) => AkSelectedSeatItemEntity(
                      ssid: p.ssid,
                      fuid: p.fuid,
                      paxId: p.paxId,
                      fare: p.fare,
                      tax: p.tax,
                    ))
                .toList(),
          ),
        );
        if (result is DataFailed) warning = 'Your seat selection could not be saved.';
      } catch (_) {
        warning = 'Your seat selection could not be saved.';
      }
    }

    if (_ssrPicks.isNotEmpty) {
      try {
        final result = await sl<AkSelectSsrUseCase>().call(
          AkSelectSsrRequestEntity(
            sessionId: sessionId,
            selectedSsr: _ssrPicks
                .map((p) => AkSelectedSsrItemEntity(
                      id: p.id,
                      fuid: p.fuid,
                      paxId: p.paxId,
                      charge: p.charge,
                      vat: 0,
                    ))
                .toList(),
          ),
        );
        if (result is DataFailed) {
          warning = warning == null
              ? 'Your add-on selection could not be saved.'
              : 'Your seat and add-on selections could not be saved.';
        }
      } catch (_) {
        warning = warning == null
            ? 'Your add-on selection could not be saved.'
            : 'Your seat and add-on selections could not be saved.';
      }
    }

    if (!mounted) return;
    setState(() => _submitting = false);

    if (warning != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$warning You can still continue.')),
      );
    }
    _goToBooking();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            _fareSummaryCard(context),
            SizedBox(height: context.h(10)),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (v) => setState(() => _currentIndex = v),
                children: [_seatsPage(context), _addonsPage(context)],
              ),
            ),
            _bottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(context.w(18), context.h(10), context.w(18), 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                borderRadius: BorderRadius.circular(context.r(20)),
                child: Padding(
                  padding: EdgeInsets.all(context.w(4)),
                  child: Icon(Icons.arrow_back_ios_new_rounded, size: context.w(16), color: _navy),
                ),
              ),
              SizedBox(width: context.w(6)),
              Expanded(
                child: Text(
                  'Customize Your Journey',
                  style: TextStyle(fontSize: context.titleLarge, fontWeight: FontWeight.bold, color: _navy),
                ),
              ),
            ],
          ),
          SizedBox(height: context.gapXSmall),
          Text(
            _titles[_currentIndex],
            style: TextStyle(fontSize: context.bodyLarge, color: _muted, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: context.gapMedium),
          Row(
            children: List.generate(
              _titles.length,
              (i) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i == _titles.length - 1 ? 0 : context.w(8)),
                  height: context.h(4),
                  decoration: BoxDecoration(
                    color: i <= _currentIndex ? _blue : const Color(0xFFE1E6F0),
                    borderRadius: BorderRadius.circular(context.r(50)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// A persistent MMT/Paytm-style fare card — always populated (base fare +
  /// running extras total), so this screen never reads as empty even while
  /// the seat/SSR calls are still loading.
  Widget _fareSummaryCard(BuildContext context) {
    final total = _baseFare + _addOnsTotal;
    return Padding(
      padding: EdgeInsets.fromLTRB(context.w(18), context.h(14), context.w(18), 0),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: context.w(16), vertical: context.h(12)),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1769F6), Color(0xFF3F8CFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(context.borderRadiusLarge),
          boxShadow: [
            BoxShadow(color: _blue.withValues(alpha: 0.28), blurRadius: 18, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fare + Extras',
                      style: TextStyle(color: Colors.white70, fontSize: context.fs(11), fontWeight: FontWeight.w600)),
                  SizedBox(height: context.h(2)),
                  Text(
                    _displayAmount(total),
                    style: TextStyle(color: Colors.white, fontSize: context.fs(20), fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            if (_addOnsTotal > 0)
              Container(
                padding: EdgeInsets.symmetric(horizontal: context.w(10), vertical: context.h(6)),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(context.r(20)),
                ),
                child: Text(
                  '+${_displayAmount(_addOnsTotal)} extras',
                  style: TextStyle(color: Colors.white, fontSize: context.fs(11), fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _paxSelector(BuildContext context) {
    if (_pax.length <= 1) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.fromLTRB(context.w(18), 0, context.w(18), context.h(10)),
      child: SizedBox(
        height: context.h(34),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _pax.length,
          separatorBuilder: (_, __) => SizedBox(width: context.w(8)),
          itemBuilder: (_, i) {
            final p = _pax[i];
            final active = p.paxId == _activePaxId;
            return InkWell(
              borderRadius: BorderRadius.circular(context.r(18)),
              onTap: () => setState(() => _activePaxId = p.paxId),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: context.w(14)),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? _blue : Colors.white,
                  borderRadius: BorderRadius.circular(context.r(18)),
                  border: Border.all(color: active ? _blue : _border),
                ),
                child: Text(
                  p.label,
                  style: TextStyle(fontSize: context.fs(12), fontWeight: FontWeight.w700, color: active ? Colors.white : _navy),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Seats page
  // ---------------------------------------------------------------------------

  Widget _seatsPage(BuildContext context) {
    if (!_hasPricing) return _emptyState(context, Icons.event_seat_outlined, "Seat selection isn't available for this flight.");

    return BlocBuilder<AkSeatLayoutBloc, AkSeatLayoutState>(
      bloc: _seatLayoutBloc,
      builder: (context, state) {
        if (state is AkSeatLayoutLoading || state is AkSeatLayoutInitial) {
          return _seatSkeleton(context);
        }
        if (state is AkSeatLayoutFailed) {
          return _emptyState(context, Icons.event_seat_outlined, "Seat selection isn't available for this flight.");
        }
        final data = (state as AkSeatLayoutLoaded).data;
        if (!data.supported || !data.hasSeats) {
          return _emptyState(context, Icons.event_seat_outlined, "Seat selection isn't available for this flight.");
        }

        // Group by trip (leg) so a round trip's onward/return seat maps are
        // clearly labelled, instead of just listing every flight number
        // back-to-back with no indication of which leg they belong to.
        final legGroups = <int, List<AkSeatLayoutSegmentEntity>>{};
        for (int t = 0; t < data.trips.length; t++) {
          for (final journey in data.trips[t].journey) {
            for (final segment in journey.segments) {
              if (segment.seats.isNotEmpty) {
                legGroups.putIfAbsent(t, () => []).add(segment);
              }
            }
          }
        }
        final showLegLabels = legGroups.length > 1;

        return Column(
          children: [
            _paxSelector(context),
            Padding(
              padding: EdgeInsets.fromLTRB(context.w(18), 0, context.w(18), context.h(8)),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: context.w(14), color: _blue),
                  SizedBox(width: context.w(6)),
                  Expanded(
                    child: Text(
                      _hasChildOrInfant
                          ? 'Emergency exit seats are blocked for this booking.'
                          : 'Tap a seat to assign it to the selected passenger.',
                      style: TextStyle(fontSize: context.fs(11), color: _muted, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(context.w(14), 0, context.w(14), context.h(10)),
                children: [
                  for (final tripIndex in legGroups.keys.toList()..sort()) ...[
                    if (showLegLabels) ...[
                      _legLabel(context, tripIndex),
                      SizedBox(height: context.h(8)),
                    ],
                    for (final segment in legGroups[tripIndex]!) ...[
                      _airplaneBody(context, segment),
                      SizedBox(height: context.h(14)),
                    ],
                  ],
                  _seatLegend(context),
                  SizedBox(height: context.h(8)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _seatSkeleton(BuildContext context) {
    Widget bar(double w) => Container(
          width: w,
          height: context.h(10),
          margin: EdgeInsets.only(bottom: context.h(10)),
          decoration: BoxDecoration(color: const Color(0xFFE7EAF2), borderRadius: BorderRadius.circular(context.r(6))),
        );
    return Padding(
      padding: EdgeInsets.all(context.w(18)),
      child: Column(
        children: [
          bar(double.infinity),
          bar(220),
          SizedBox(height: context.h(16)),
          Container(
            height: context.h(280),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(context.r(24))),
            alignment: Alignment.center,
            child: const CircularProgressIndicator(strokeWidth: 2.4, color: _blue),
          ),
        ],
      ),
    );
  }

  Widget _legLabel(BuildContext context, int tripIndex) {
    final text = tripIndex == 0
        ? 'Onward Flight'
        : tripIndex == 1
            ? 'Return Flight'
            : 'Flight ${tripIndex + 1}';
    return Padding(
      padding: EdgeInsets.only(left: context.w(4)),
      child: Text(
        text,
        style: TextStyle(fontSize: context.fs(13), fontWeight: FontWeight.w900, color: _navy),
      ),
    );
  }

  Widget _airplaneBody(BuildContext context, AkSeatLayoutSegmentEntity segment) {
    final byRow = <int, List<AkSeatEntity>>{};
    for (final seat in segment.seats) {
      final y = int.tryParse(seat.yValue) ?? 0;
      byRow.putIfAbsent(y, () => []).add(seat);
    }
    final rows = byRow.keys.toList()..sort();
    for (final r in rows) {
      byRow[r]!.sort((a, b) => (int.tryParse(a.xValue) ?? 0).compareTo(int.tryParse(b.xValue) ?? 0));
    }

    // Detect the aisle: the widest gap between consecutive column positions.
    final columns = segment.seats.map((s) => int.tryParse(s.xValue) ?? 0).toSet().toList()..sort();
    int aisleAfterIndex = -1;
    if (columns.length > 2) {
      int widestGap = 0;
      for (int i = 0; i < columns.length - 1; i++) {
        final gap = columns[i + 1] - columns[i];
        if (gap > widestGap) {
          widestGap = gap;
          aisleAfterIndex = i;
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(24)),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(color: _navy.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      padding: EdgeInsets.symmetric(vertical: context.h(16)),
      child: Column(
        children: [
          Text(
            'Flight ${segment.flightNo}',
            style: TextStyle(fontSize: context.fs(12.5), fontWeight: FontWeight.w800, color: _navy),
          ),
          SizedBox(height: context.h(12)),
          for (final y in rows)
            Padding(
              padding: EdgeInsets.symmetric(vertical: context.h(3)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < byRow[y]!.length; i++) ...[
                    _seatTile(context, segment.fuid, byRow[y]![i]),
                    SizedBox(width: i == aisleAfterIndex ? context.w(22) : context.w(4)),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _seatTile(BuildContext context, int fuid, AkSeatEntity seat) {
    final blockedByExit = seat.isEmergencyExit && _hasChildOrInfant;
    final blocked = !seat.selectable || blockedByExit;
    final myPick = _seatPicks[_seatPickKey(fuid, _activePaxId)];
    final isPickedByMe = myPick?.ssid == seat.ssid;
    // Scoped to this segment (fuid) — seat IDs are only unique within a
    // single flight's seat map, so comparing across segments would flag
    // unrelated seats on a different leg as "taken".
    final pickedByOtherPax =
        !isPickedByMe && _seatPicks.values.any((p) => p.fuid == fuid && p.ssid == seat.ssid);

    Color fill = _availableFill;
    Color border = _availableBorder;
    Color iconColor = _availableBorder;

    if (blocked || pickedByOtherPax) {
      fill = const Color(0xFFEDEFF3);
      border = const Color(0xFFD7DBE3);
      iconColor = const Color(0xFFAEB4C0);
    } else if (isPickedByMe) {
      fill = _blue;
      border = _blue;
      iconColor = Colors.white;
    } else if (seat.fare > 0) {
      border = const Color(0xFFF59E0B);
    }

    return Tooltip(
      message: blocked
          ? (blockedByExit ? 'Emergency exit — unavailable' : 'Not available')
          : pickedByOtherPax
              ? 'Taken by another passenger'
              : seat.seatNumber,
      child: GestureDetector(
        onTap: (blocked || pickedByOtherPax)
            ? null
            : () {
                setState(() {
                  final key = _seatPickKey(fuid, _activePaxId);
                  if (isPickedByMe) {
                    _seatPicks.remove(key);
                  } else {
                    _seatPicks[key] = _SeatPick(
                      ssid: seat.ssid,
                      fuid: fuid,
                      paxId: _activePaxId,
                      fare: seat.fare,
                      tax: seat.tax,
                      seatNumber: seat.seatNumber,
                    );
                  }
                });
              },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: context.w(30),
              height: context.w(30),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(context.r(8)),
                border: Border.all(color: border),
              ),
              child: Icon(Icons.event_seat, size: context.w(16), color: iconColor),
            ),
            SizedBox(height: context.h(2)),
            Text(
              seat.seatNumber,
              maxLines: 1,
              style: TextStyle(fontSize: context.fs(8), fontWeight: FontWeight.w600, color: _navy),
            ),
          ],
        ),
      ),
    );
  }

  Widget _seatLegend(BuildContext context) {
    Widget dot(Color fill, Color border, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: context.w(14),
              height: context.w(14),
              decoration: BoxDecoration(color: fill, border: Border.all(color: border), borderRadius: BorderRadius.circular(context.r(4))),
            ),
            SizedBox(width: context.w(5)),
            Text(label, style: TextStyle(fontSize: context.fs(10.5), color: _muted)),
          ],
        );
    return Wrap(
      spacing: context.w(14),
      runSpacing: context.h(6),
      alignment: WrapAlignment.center,
      children: [
        dot(_availableFill, _availableBorder, 'Available'),
        dot(_blue, _blue, 'Selected'),
        dot(const Color(0xFFEDEFF3), const Color(0xFFD7DBE3), 'Unavailable'),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Add-ons page
  // ---------------------------------------------------------------------------

  Widget _addonsPage(BuildContext context) {
    if (!_hasPricing) return _emptyState(context, Icons.card_travel_outlined, 'No add-ons available for this fare.');

    return BlocBuilder<AkSsrBloc, AkSsrState>(
      bloc: _ssrBloc,
      builder: (context, state) {
        if (state is AkSsrLoading || state is AkSsrInitial) {
          return _addonsSkeleton(context);
        }
        if (state is AkSsrFailed) {
          return _emptyState(context, Icons.card_travel_outlined, 'No add-ons available for this fare.');
        }
        final data = (state as AkSsrLoaded).data;
        if (!data.hasOptions) {
          return _emptyState(context, Icons.card_travel_outlined, 'No add-ons available for this fare.');
        }

        final showLegLabels = data.trips.where((t) => t.journey.any(
              (j) => j.segments.any((s) => s.items.isNotEmpty),
            )).length >
            1;

        final sections = <Widget>[];
        for (int t = 0; t < data.trips.length; t++) {
          final trip = data.trips[t];
          final tripHasItems = trip.journey.any((j) => j.segments.any((s) => s.items.isNotEmpty));
          if (!tripHasItems) continue;
          if (showLegLabels) {
            sections.add(_legLabel(context, t));
            sections.add(SizedBox(height: context.h(8)));
          }
          for (final journey in trip.journey) {
            for (final segment in journey.segments) {
              if (segment.items.isEmpty) continue;
              final grouped = <String, List<AkSsrItemEntity>>{};
              for (final item in segment.items) {
                final key = item.typeName.isEmpty ? 'OTHER' : item.typeName;
                grouped.putIfAbsent(key, () => []).add(item);
              }
              for (final entry in grouped.entries) {
                sections.add(_ssrGroupCard(
                  context,
                  fuid: segment.fuid,
                  typeName: entry.key,
                  items: entry.value,
                  multiSelectAllowed: journey.multiSelectAllowed,
                ));
                sections.add(SizedBox(height: context.h(12)));
              }
            }
          }
        }

        return Column(
          children: [
            _paxSelector(context),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(context.w(18), 0, context.w(18), context.h(10)),
                children: sections,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _addonsSkeleton(BuildContext context) {
    Widget card() => Container(
          margin: EdgeInsets.only(bottom: context.h(12)),
          height: context.h(70),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(context.borderRadius)),
        );
    return Padding(
      padding: EdgeInsets.all(context.w(18)),
      child: Column(children: [card(), card(), card()]),
    );
  }

  IconData _typeIcon(String typeName) {
    switch (typeName.toUpperCase()) {
      case 'MEALS':
        return Icons.restaurant_outlined;
      case 'BAGGAGE':
        return Icons.luggage_outlined;
      case 'SEAT':
        return Icons.event_seat_outlined;
      case 'SPORTS':
        return Icons.sports_outlined;
      default:
        return Icons.add_circle_outline;
    }
  }

  Widget _ssrGroupCard(
    BuildContext context, {
    required int fuid,
    required String typeName,
    required List<AkSsrItemEntity> items,
    required bool multiSelectAllowed,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadius),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(color: _navy.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: context.w(28),
                height: context.w(28),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: _blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(context.r(8))),
                child: Icon(_typeIcon(typeName), size: context.w(15), color: _blue),
              ),
              SizedBox(width: context.w(8)),
              Text(typeName, style: TextStyle(fontSize: context.fs(13.5), fontWeight: FontWeight.w800, color: _navy)),
            ],
          ),
          SizedBox(height: context.h(6)),
          Divider(color: _border, height: context.h(14)),
          for (final item in items)
            _ssrItemTile(context, fuid: fuid, item: item, groupItems: items, multiSelectAllowed: multiSelectAllowed),
        ],
      ),
    );
  }

  Widget _ssrItemTile(
    BuildContext context, {
    required int fuid,
    required AkSsrItemEntity item,
    required List<AkSsrItemEntity> groupItems,
    required bool multiSelectAllowed,
  }) {
    final selected = _ssrPicks.any((p) => p.id == item.id && p.fuid == fuid && p.paxId == _activePaxId);

    void toggle() {
      setState(() {
        if (selected) {
          _ssrPicks.removeWhere((p) => p.id == item.id && p.fuid == fuid && p.paxId == _activePaxId);
          return;
        }
        if (!multiSelectAllowed) {
          final groupIds = groupItems.map((g) => g.id).toSet();
          _ssrPicks.removeWhere((p) => p.fuid == fuid && p.paxId == _activePaxId && groupIds.contains(p.id));
        }
        _ssrPicks.add(_SsrPick(
          id: item.id,
          fuid: fuid,
          paxId: _activePaxId,
          charge: item.charge,
          typeName: item.typeName,
          description: item.description,
        ));
      });
    }

    return InkWell(
      onTap: toggle,
      borderRadius: BorderRadius.circular(context.r(10)),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.h(8)),
        child: Row(
          children: [
            Icon(
              multiSelectAllowed
                  ? (selected ? Icons.check_box : Icons.check_box_outline_blank)
                  : (selected ? Icons.radio_button_checked : Icons.radio_button_off),
              size: context.w(18),
              color: selected ? _blue : const Color(0xFFB0B4BD),
            ),
            SizedBox(width: context.w(10)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.description.isEmpty ? item.code : item.description,
                    style: TextStyle(fontSize: context.fs(12.5), fontWeight: FontWeight.w600, color: _navy),
                  ),
                  if (item.isFree)
                    Padding(
                      padding: EdgeInsets.only(top: context.h(2)),
                      child: Text(
                        'Free',
                        style: TextStyle(fontSize: context.fs(10.5), fontWeight: FontWeight.w700, color: const Color(0xFF16A34A)),
                      ),
                    ),
                ],
              ),
            ),
            Text(
              item.isFree ? _displayAmount(0) : _displayAmount(item.charge),
              style: TextStyle(fontSize: context.fs(12.5), fontWeight: FontWeight.w800, color: _navy),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shared UI
  // ---------------------------------------------------------------------------

  Widget _emptyState(BuildContext context, IconData icon, String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.w(28)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: context.w(64),
              height: context.w(64),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: _border)),
              child: Icon(icon, size: context.w(28), color: _muted),
            ),
            SizedBox(height: context.h(14)),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: context.fs(13), color: _muted, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: context.h(6)),
            Text(
              'You can still continue with your booking.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: context.fs(11.5), color: _muted.withValues(alpha: 0.8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(context.w(18), context.h(10), context.w(18), context.h(14)),
      child: Row(
        children: [
          if (_currentIndex != 0) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: _submitting ? null : _previousPage,
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(double.infinity, context.buttonHeight),
                  side: const BorderSide(color: _border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(10))),
                ),
                child: Text('Back', style: TextStyle(color: _navy, fontWeight: FontWeight.w700, fontSize: context.fs(13))),
              ),
            ),
            SizedBox(width: context.gapMedium),
          ] else ...[
            Expanded(
              child: OutlinedButton(
                onPressed: _submitting ? null : _skip,
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(double.infinity, context.buttonHeight),
                  side: const BorderSide(color: _border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(10))),
                ),
                child: Text('Skip', style: TextStyle(color: _muted, fontWeight: FontWeight.w700, fontSize: context.fs(13))),
              ),
            ),
            SizedBox(width: context.gapMedium),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _submitting ? null : _nextPage,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, context.buttonHeight),
                backgroundColor: _blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(10))),
              ),
              child: _submitting
                  ? SizedBox(
                      width: context.w(18),
                      height: context.w(18),
                      child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _currentIndex == _titles.length - 1 ? 'Continue' : 'Next',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: context.fs(13.5)),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
