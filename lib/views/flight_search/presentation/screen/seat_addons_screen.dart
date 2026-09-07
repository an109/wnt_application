import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/currency_converter.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/common_widgets/airline_logo.dart';
import 'package:wander_nova/core/resources/app_colours.dart';
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
const _border = Color(0xFFE2E7F0);
const _muted = Color(0xFF6B7280);

const _title900 = Color(0xFF111527);
const _stroke = Color(0xFFCCCCCC);

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

class _SeatAddonsScreenState extends State<SeatAddonsScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late final AkSeatLayoutBloc _seatLayoutBloc;
  late final AkSsrBloc _ssrBloc;
  late final List<_PaxDescriptor> _pax;
  final ScrollController _seatScrollController = ScrollController();

  // Animation for smooth sliding
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  double _scrollProgress = 0.0;
  double _targetProgress = 0.0;

  // Figma tab order: SEATS, MEALS, BAGGAGE (was one combined "Baggage &
  // Meals" page) — `_ssrSectionsByType` below splits the same already-loaded
  // AkSsr data by typeName so this is purely a display change.
  static const _tabLabels = ['SEATS', 'MEALS', 'BAGGAGE'];
  int _currentIndex = 0;

  int _activePaxId = 1;
  final Map<String, _SeatPick> _seatPicks = {};
  final List<_SsrPick> _ssrPicks = [];
  bool _submitting = false;

  // Populated on each seat-map build; used only to derive the Figma legend's
  // "standard"/"premium" fare bands per segment (see `_seatIsPremium`).
  final Map<int, List<AkSeatEntity>> _seatsByFuid = {};
  final Map<int, double> _medianPaidFareByFuid = {};

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

    // Initialize animation controller with smooth curve
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );

    // Listen to scroll and update target progress
    _seatScrollController.addListener(() {
      final maxScroll = _seatScrollController.position.maxScrollExtent;
      if (maxScroll > 0) {
        final progress = _seatScrollController.offset / maxScroll;
        _targetProgress = progress.clamp(0.0, 1.0);

        // Animate to the new position
        _animationController.animateTo(
          _targetProgress,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
        );
      }
    });

    // Listen to animation updates
    _animationController.addListener(() {
      setState(() {
        _scrollProgress = _slideAnimation.value;
      });
    });

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
    _seatScrollController.dispose();
    _animationController.dispose();
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

  void _goToTab(int index) {
    if (index == _currentIndex) return;
    _pageController.animateToPage(index, duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
  }

  void _nextPage() {
    if (_currentIndex < _tabLabels.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _continue();
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            _tabBar(context),

            if (_currentIndex == 0 && widget.route.from.isNotEmpty) ...[
              _routeCardLarge(context),
              _exitRowBanner(context),
            ],
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (v) => setState(() => _currentIndex = v),
                children: [_seatsPage(context), _mealsPage(context), _baggagePage(context)],
              ),
            ),
            _bottomBar(context),
          ],
        ),
      ),
    );
  }

  // ==================== HEADER (Figma: "← Add-ons" [+ route badge / Skip]) ====================
  Widget _header(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.w(16), vertical: context.h(12)),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).maybePop(),
            child: Image.asset('assets/NewIcons/arrowBack.png', width: context.w(24), height: context.h(24), color: _title900),
          ),
          SizedBox(width: context.w(12)),
          Expanded(
            child: Text(
              'Add-ons',
              style: TextStyle(color: _title900, fontSize: context.fs(20), fontWeight: FontWeight.w600),
            ),
          ),
          // Not in Figma, but skipping seats/add-ons entirely is real,
          // existing functionality (straight to the booking form) — kept
          // as a small text action instead of dropping it.
          if (_currentIndex == 0)
            GestureDetector(
              onTap: _submitting ? null : _skip,
              child: Text('Skip', style: TextStyle(color: AppColors.subhead, fontSize: context.fs(13), fontWeight: FontWeight.w600)),
            )
          else if (widget.route.from.isNotEmpty)
            _routeBadgeCompact(context),
        ],
      ),
    );
  }

  /// `route.flightNo` is built upstream as "`<IATA code>` • `<number>`"
  /// (see detail_popup.dart's `_bookNow`) — this pulls the code back out so
  /// the real airline logo can be shown instead of a generic route icon.
  String _routeAirlineCode() {
    final flightNo = widget.route.flightNo;
    final sep = flightNo.indexOf('•');
    return (sep > 0 ? flightNo.substring(0, sep) : flightNo).trim();
  }

  Widget _routeBadgeCompact(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AirlineLogo(code: _routeAirlineCode(), name: widget.route.airline, size: context.w(24), borderRadius: BorderRadius.circular(context.r(8))),
        SizedBox(width: context.w(8)),
        Text(
          '${widget.route.from} - ${widget.route.to}',
          style: TextStyle(color: _title900, fontSize: context.fs(16), fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  // ==================== LARGE ROUTE CARD (Figma: Seats tab) ====================
  Widget _routeCardLarge(BuildContext context) {
    final route = widget.route;
    final paleBlue = Color.lerp(AppColors.AppBlue, Colors.white, 0.72)!;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: context.w(16), vertical: context.h(20)),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.centerRight, end: Alignment.centerLeft, colors: [paleBlue, Colors.white]),
      ),
      child: Row(
        children: [
          AirlineLogo(code: _routeAirlineCode(), name: route.airline, size: context.w(38), borderRadius: BorderRadius.circular(context.r(8))),
          SizedBox(width: context.w(16)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${route.from} - ${route.to}', style: TextStyle(color: _title900, fontSize: context.fs(18), fontWeight: FontWeight.w700)),
              Text('${route.from} to ${route.to}', style: TextStyle(color: _title900, fontSize: context.fs(12))),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== EXIT ROW BANNER (Figma: "Flighjt seat2", node 458:5319) ====================
  /// A real aircraft cross-section image with a red-outlined highlight over
  /// the exit-row area. Figma places the highlight at a fixed spot on a
  /// fixed illustration — it isn't computed from this flight's actual
  /// exit-row seats, so this stays a static visual aid rather than a claim
  /// about where the real exit row is.
  Widget _exitRowBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      height: context.h(116),
      // `clipBehavior` other than Clip.none requires a real `decoration`
      // (Container's own assertion: `decoration != null || clipBehavior ==
      // Clip.none`) — a bare `color:` doesn't satisfy it, which is exactly
      // what crashed this screen on launch.
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.64)),
      clipBehavior: Clip.hardEdge,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Start from the far left and scan to the right
          final startLeft = constraints.maxWidth * 0.12;  // Start from leftmost
          final endLeft = constraints.maxWidth * 0.65;    // End at rightmost

          // Use the animated progress value for smooth sliding
          final currentLeft = startLeft + (_scrollProgress * (endLeft - startLeft));

          return Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.w(20)),
                  child: Image.asset('assets/NewIcons/flightSeat.png', fit: BoxFit.cover),
                ),
              ),
              Positioned(
                left: currentLeft,
                top: constraints.maxHeight * 0.20,
                child: Container(
                  width: constraints.maxWidth * 0.107,
                  height: constraints.maxHeight * 0.52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF383C).withValues(alpha: 0.34),
                    border: Border.all(color: const Color(0xFFFF383C)),
                    borderRadius: BorderRadius.circular(context.r(4)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==================== TAB BAR (Figma: SEATS / MEALS / BAGGAGE) ====================
  Widget _tabBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
      child: Row(
        children: [
          for (var i = 0; i < _tabLabels.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _goToTab(i),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: context.h(12.5)),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: _currentIndex == i ? AppColors.AppBlue : Colors.transparent, width: 2)),
                  ),
                  child: Text(
                    _tabLabels[i],
                    style: TextStyle(
                      color: _currentIndex == i ? AppColors.AppBlue : AppColors.subhead,
                      fontSize: context.fs(14),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
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
        _seatsByFuid.clear();
        _medianPaidFareByFuid.clear();
        for (int t = 0; t < data.trips.length; t++) {
          for (final journey in data.trips[t].journey) {
            for (final segment in journey.segments) {
              if (segment.seats.isNotEmpty) {
                legGroups.putIfAbsent(t, () => []).add(segment);
                _seatsByFuid[segment.fuid] = segment.seats;
              }
            }
          }
        }
        final showLegLabels = legGroups.length > 1;

        return Column(
          children: [
            _paxSelector(context),
            Expanded(
              child: ListView(
                controller: _seatScrollController,
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

    // Figma flat-square scheme: free = pale orange, paid = blue (a fuller
    // blue once fare crosses this seat map's own median paid fare, so the
    // "premium" tier is derived from the real fares, not hardcoded),
    // selected = solid AppBlue + check, blocked = grey + ×.
    Color fill;
    Widget? mark;
    if (blocked || pickedByOtherPax) {
      fill = Colors.grey.shade300;
      mark = Icon(Icons.close, size: context.w(12), color: AppColors.subhead.withValues(alpha: 0.6));
    } else if (isPickedByMe) {
      fill = AppColors.AppBlue;
      mark = const Icon(Icons.check, color: Colors.white, size: 16);
    } else if (seat.fare <= 0) {
      fill = AppColors.OrangeColor.withValues(alpha: 0.15);
    } else {
      fill = _seatIsPremium(fuid, seat) ? AppColors.AppBlue : AppColors.AppBlue.withValues(alpha: 0.24);
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
                borderRadius: BorderRadius.circular(context.r(10)),
                border: (blocked || pickedByOtherPax || isPickedByMe) ? null : Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: mark,
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

  /// A paid seat counts as "premium" once its fare reaches the median paid
  /// fare among this segment's seats — splits the real fare data into two
  /// visual bands instead of hardcoding a price cutoff.
  bool _seatIsPremium(int fuid, AkSeatEntity seat) {
    final median = _medianPaidFareByFuid.putIfAbsent(fuid, () {
      final fares = _seatsByFuid[fuid]?.where((s) => s.fare > 0).map((s) => s.fare).toList() ?? [];
      if (fares.isEmpty) return 0.0;
      fares.sort();
      return fares[fares.length ~/ 2];
    });
    return median > 0 && seat.fare >= median;
  }

  Widget _seatLegend(BuildContext context) {
    Widget swatch(Color color, String label, {Border? border}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: context.w(12),
          height: context.w(12),
          decoration: BoxDecoration(color: color, border: border, borderRadius: BorderRadius.circular(2)),
        ),
        SizedBox(width: context.w(5)),
        Text(label, style: TextStyle(fontSize: context.fs(10.5), color: AppColors.subhead)),
      ],
    );
    return Wrap(
      spacing: context.w(14),
      runSpacing: context.h(6),
      alignment: WrapAlignment.center,
      children: [
        swatch(AppColors.OrangeColor.withValues(alpha: 0.15), 'Free'),
        swatch(AppColors.AppBlue.withValues(alpha: 0.24), 'Standard fare'),
        swatch(AppColors.AppBlue, 'Premium fare'),
        swatch(AppColors.AppBlue, 'Selected'),
        swatch(Colors.grey.shade300, 'Unavailable', border: Border.all(color: _stroke)),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Add-ons page
  // ---------------------------------------------------------------------------

  /// Figma splits the old combined "Baggage & Meals" page into two tabs —
  /// this builds the widget list for whichever `typeName`s [wantedTypes]
  /// asks for, from the exact same already-loaded AkSsr data the old single
  /// page iterated. `_ssrGroupCard`/`_ssrItemTile`/the selection maps below
  /// are untouched, so nothing about *how* an item gets selected changed.
  List<Widget> _typedSections(BuildContext context, AkSsrEntity data, Set<String> wantedTypes) {
    final showLegLabels = data.trips.where((t) => t.journey.any(
          (j) => j.segments.any((s) => s.items.any((i) => wantedTypes.contains(_typeKey(i.typeName)))),
    )).length >
        1;

    final sections = <Widget>[];
    for (int t = 0; t < data.trips.length; t++) {
      final trip = data.trips[t];
      for (final journey in trip.journey) {
        for (final segment in journey.segments) {
          final wanted = segment.items.where((i) => wantedTypes.contains(_typeKey(i.typeName))).toList();
          if (wanted.isEmpty) continue;
          final grouped = <String, List<AkSsrItemEntity>>{};
          for (final item in wanted) {
            grouped.putIfAbsent(_typeKey(item.typeName), () => []).add(item);
          }
          for (final entry in grouped.entries) {
            if (showLegLabels) {
              sections.add(_legLabel(context, t));
              sections.add(SizedBox(height: context.h(8)));
            }
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
    return sections;
  }

  String _typeKey(String typeName) => typeName.isEmpty ? 'OTHER' : typeName.toUpperCase();

  Widget _addonsTabScaffold(BuildContext context, {required IconData emptyIcon, required String emptyMessage, required Set<String> wantedTypes}) {
    if (!_hasPricing) return _emptyState(context, emptyIcon, emptyMessage);

    return BlocBuilder<AkSsrBloc, AkSsrState>(
      bloc: _ssrBloc,
      builder: (context, state) {
        if (state is AkSsrLoading || state is AkSsrInitial) {
          return _addonsSkeleton(context);
        }
        if (state is AkSsrFailed) {
          return _emptyState(context, emptyIcon, emptyMessage);
        }
        final data = (state as AkSsrLoaded).data;
        final sections = data.hasOptions ? _typedSections(context, data, wantedTypes) : <Widget>[];
        if (sections.isEmpty) {
          return _emptyState(context, emptyIcon, emptyMessage);
        }

        return Column(
          children: [
            _paxSelector(context),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(context.w(18), context.h(12), context.w(18), context.h(10)),
                children: sections,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _mealsPage(BuildContext context) =>
      _addonsTabScaffold(context, emptyIcon: Icons.restaurant_outlined, emptyMessage: 'No meal options available for this fare.', wantedTypes: const {'MEALS'});

  /// Everything that isn't a meal (BAGGAGE, SPORTS, SEAT extras, …) lives on
  /// the last tab — Figma only names "Baggage", but any other add-on type
  /// the API returns still needs a home or it becomes unreachable.
  Widget _baggagePage(BuildContext context) => _addonsTabScaffold(
    context,
    emptyIcon: Icons.luggage_outlined,
    emptyMessage: 'No baggage options available for this fare.',
    wantedTypes: const {'BAGGAGE', 'SPORTS', 'SEAT', 'OTHER'},
  );

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

  /// Best-effort veg/non-veg dot for a MEALS item — this API only gives a
  /// free-text description/code (no dedicated veg flag like the TBO meal
  /// codes elsewhere in the app), so this is a keyword guess and shows no
  /// dot at all when it can't tell either way, instead of asserting one.
  bool? _mealIsVeg(AkSsrItemEntity item) {
    final text = '${item.code} ${item.description}'.toLowerCase();
    if (text.contains('non veg') || text.contains('non-veg') || text.contains('nonveg')) return false;
    if (text.contains('veg')) return true;
    return null;
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
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: _stroke, width: 0.5),
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
                decoration: BoxDecoration(color: AppColors.AppBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(context.r(8))),
                child: Icon(_typeIcon(typeName), size: context.w(15), color: AppColors.AppBlue),
              ),
              SizedBox(width: context.w(8)),
              Text(typeName, style: TextStyle(fontSize: context.fs(14), fontWeight: FontWeight.w600, color: _title900)),
            ],
          ),
          SizedBox(height: context.h(6)),
          Divider(color: _stroke, height: context.h(14)),
          for (final item in items)
            _ssrItemTile(context, fuid: fuid, item: item, groupItems: items, multiSelectAllowed: multiSelectAllowed, isMeal: typeName == 'MEALS'),
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
        required bool isMeal,
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

    final veg = isMeal ? _mealIsVeg(item) : null;

    return InkWell(
      onTap: toggle,
      borderRadius: BorderRadius.circular(context.r(10)),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.h(8)),
        child: Row(
          children: [
            if (veg != null) ...[
              Container(
                width: context.w(10),
                height: context.w(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: veg ? const Color(0xFF16A34A) : const Color(0xFFFF383C),
                ),
              ),
              SizedBox(width: context.w(10)),
            ] else
              Icon(
                multiSelectAllowed
                    ? (selected ? Icons.check_box : Icons.check_box_outline_blank)
                    : (selected ? Icons.check_circle : Icons.radio_button_off),
                size: context.w(18),
                color: selected ? AppColors.AppBlue : _stroke,
              ),
            SizedBox(width: context.w(10)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.description.isEmpty ? item.code : item.description,
                    style: TextStyle(fontSize: context.fs(12.5), fontWeight: FontWeight.w600, color: _title900),
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
            if (veg != null)
              Padding(
                padding: EdgeInsets.only(right: context.w(10)),
                child: Icon(
                  selected ? Icons.check_circle : Icons.radio_button_off,
                  size: context.w(18),
                  color: selected ? AppColors.AppBlue : _stroke,
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

  // ==================== BOTTOM BAR (Figma: total + Continue) ====================
  Widget _bottomBar(BuildContext context) {
    final total = _baseFare + _addOnsTotal;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.w(19), vertical: context.h(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _displayAmount(total),
                  style: TextStyle(color: _title900, fontSize: context.fs(24), fontWeight: FontWeight.w800, letterSpacing: -0.6),
                ),
                Text(
                  'FOR ${widget.travellerCount} ADULT${widget.travellerCount > 1 ? 'S' : ''}',
                  style: TextStyle(color: AppColors.subhead, fontSize: context.fs(8), fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          SizedBox(
            height: context.h(44),
            child: ElevatedButton(
              onPressed: _submitting ? null : _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.OrangeColor,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: context.w(24)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(12))),
              ),
              child: _submitting
                  ? SizedBox(
                width: context.w(18),
                height: context.w(18),
                child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : Text(
                'CONTINUE',
                style: TextStyle(color: Colors.white, fontSize: context.fs(14), fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}