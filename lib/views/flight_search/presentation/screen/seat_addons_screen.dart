import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/currency_converter.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/common_widgets/airline_logo.dart';
import 'package:wander_nova/core/resources/app_colours.dart';
import 'package:wander_nova/core/utils/storage/shared_preference.dart';
import 'package:wander_nova/injection_container.dart';
import 'package:wander_nova/core/error/data_state.dart';
import 'package:wander_nova/newUIWidgets/fare_breakup_sheet.dart';

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
  final String code;

  const _SsrPick({
    required this.id,
    required this.fuid,
    required this.paxId,
    required this.charge,
    required this.typeName,
    required this.description,
    this.code = '',
  });
}

/// One meal row on the Meals tab: the SSR item plus the segment it belongs
/// to and its journey's multi-select rule. Pure view-model — selection is
/// still stored in [_SeatAddonsScreenState._ssrPicks].
class _MealEntry {
  final AkSsrItemEntity item;
  final int fuid;
  final List<AkSsrItemEntity> group;
  final bool multiSelectAllowed;

  const _MealEntry({
    required this.item,
    required this.fuid,
    required this.group,
    required this.multiSelectAllowed,
  });
}


/// What the traveller actually picked on this screen, in a form the review
/// and payment screens can render without knowing anything about the SSR
/// wire format. [total] is the same INR figure that used to be handed to
/// `onProceed` on its own.
class AddOnsSummary {
  final double total;
  final List<String> seatNumbers;
  final List<String> meals;
  final List<String> others;

  const AddOnsSummary({
    this.total = 0,
    this.seatNumbers = const [],
    this.meals = const [],
    this.others = const [],
  });

  /// "8B", "8B, 12C", or "--" when nothing was picked — matches the review
  /// screen's Add-ons rows.
  static String display(List<String> values) =>
      values.isEmpty ? '--' : values.join(', ');
}

/// Seat map (SeatLayout/SelectSeats) + baggage/meal add-ons (SSR/SelectSSR).
///
/// Sits between [FlightBookingScreen] (traveller details) and the payment
/// screen: the booking screen pushes this, and finishing here calls
/// [onProceed] with the chosen add-on total so CreateItinerary is priced
/// *after* SelectSeats/SelectSSR have written the picks onto the
/// server-side session, and the flow lands directly on the payment screen —
/// this screen never pops back to [FlightBookingScreen] as part of
/// Skip/Continue.
///
/// Both steps are optional — Skip and Continue both call [onProceed]; the
/// only difference is whether SelectSeats/SelectSSR were called first.
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

  /// Invoked (with this screen's own [BuildContext]) once Skip or Continue
  /// is tapped, passing what was chosen. The caller runs CreateItinerary and
  /// pushes the review + payment screens directly from that context — this
  /// screen's own navigation never returns to [FlightBookingScreen] as part
  /// of that hand-off.
  final Future<void> Function(BuildContext context, AddOnsSummary addOns) onProceed;

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
    required this.onProceed,
  });

  @override
  State<SeatAddonsScreen> createState() => _SeatAddonsScreenState();
}

class _SeatAddonsScreenState extends State<SeatAddonsScreen> {
  final PageController _pageController = PageController();
  late final AkSeatLayoutBloc _seatLayoutBloc;
  late final AkSsrBloc _ssrBloc;
  late final List<_PaxDescriptor> _pax;

  /// Scroll position of the seat map.
  final ScrollController _seatScrollController = ScrollController();

  /// 0..1 progress of [_seatScrollController], published as a
  /// [ValueNotifier] rather than via `setState` so the red exit-row highlight
  /// can track the scroll frame-for-frame while only *that* box repaints.
  final ValueNotifier<double> _seatScrollProgress = ValueNotifier<double>(0);

  /// Live fractional PageView offset (0.0 → 2.0), again notifier-driven so the
  /// tab underline slides with the swipe without rebuilding the pages.
  final ValueNotifier<double> _pageOffset = ValueNotifier<double>(0);

  /// Bumped when a Meals-tab filter / menu toggles. Scoping those to their own
  /// [ValueListenableBuilder] keeps a filter tap from rebuilding the (much
  /// heavier) seat grid on the neighbouring page.
  final ValueNotifier<int> _mealUiRevision = ValueNotifier<int>(0);

  // Figma tab order: SEATS, MEALS, BAGGAGE.
  static const _tabLabels = ['SEATS', 'MEALS', 'BAGGAGE'];

  /// Everything that isn't a meal (BAGGAGE, SPORTS, SEAT extras, …) is shown
  /// on the last tab — Figma only names "Baggage", but any other add-on type
  /// the API returns still needs a home or it becomes unreachable.
  static const _baggageTabTypes = {'BAGGAGE', 'SPORTS', 'SEAT', 'OTHER'};
  static const _mealTabTypes = {'MEALS'};

  int _currentIndex = 0;

  int _activePaxId = 1;
  final Map<String, _SeatPick> _seatPicks = {};
  final List<_SsrPick> _ssrPicks = [];
  bool _submitting = false;

  // Meals tab (Figma 467:6784) — veg/non-veg quick filter (empty = show all)
  // and the collapsible "Menu" overview panel.
  final Set<bool> _mealVegFilter = <bool>{};
  bool _mealMenuOpen = false;

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

    _seatScrollController.addListener(_onSeatScroll);
    _pageController.addListener(_onPageScroll);

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

  /// Maps the seat list's scroll offset onto 0..1. No `setState` — only the
  /// highlight's [ValueListenableBuilder] reacts, so this stays smooth even
  /// during a fast fling.
  void _onSeatScroll() {
    if (!_seatScrollController.hasClients) return;
    final position = _seatScrollController.position;
    if (!position.hasContentDimensions) return;
    final max = position.maxScrollExtent;
    _seatScrollProgress.value = max <= 0 ? 0 : (position.pixels / max).clamp(0.0, 1.0);
  }

  void _onPageScroll() {
    if (!_pageController.hasClients || _pageController.positions.isEmpty) return;
    final page = _pageController.page;
    if (page == null) return;
    // Only the underline / label colours react (via `_pageOffset`). No
    // `setState` here — the pages are all built already and nothing in the
    // shell branches on the index, so a swipe never triggers a rebuild.
    _pageOffset.value = page;
    _currentIndex = page.round();
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    _seatScrollController.removeListener(_onSeatScroll);
    _seatScrollController.dispose();
    _seatScrollProgress.dispose();
    _pageOffset.dispose();
    _mealUiRevision.dispose();
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

  /// This screen sits *after* [FlightBookingScreen] in the flow
  /// (Search → Booking → Add-ons → Payment), so finishing here hands the
  /// chosen seat/meal/baggage total to [widget.onProceed], which runs
  /// CreateItinerary and pushes straight to payment — never back through
  /// [FlightBookingScreen]. SelectSeats/SelectSSR have already been sent by
  /// [_continue], so the server-side session — and therefore
  /// CreateItinerary's netAmount — reflects these picks.
  Future<void> _proceedToPayment(AddOnsSummary addOns) async {
    if (!mounted) return;
    setState(() => _submitting = true);
    await widget.onProceed(context, addOns);
    if (mounted) setState(() => _submitting = false);
  }

  /// Snapshot of the current picks for the review screen. Seat numbers come
  /// straight off `_seatPicks`; SSR items are split into meals vs everything
  /// else by the same `typeName` buckets the tabs use.
  AddOnsSummary get _addOnsSummary {
    final seats = _seatPicks.values.map((p) => p.seatNumber).where((s) => s.isNotEmpty).toList()
      ..sort();
    final meals = <String>[];
    final others = <String>[];
    for (final pick in _ssrPicks) {
      final name = pick.description.isNotEmpty ? pick.description : pick.code;
      if (name.isEmpty) continue;
      if (_mealTabTypes.contains(_typeKey(pick.typeName))) {
        meals.add(name);
      } else {
        others.add(name);
      }
    }
    return AddOnsSummary(
      total: _addOnsTotal,
      seatNumbers: seats,
      meals: meals,
      others: others,
    );
  }

  void _skip() => _proceedToPayment(const AddOnsSummary());

  void _goToTab(int index) {
    if (index == _currentIndex || !_pageController.hasClients) return;
    // `_onPageScroll` keeps `_currentIndex` and the underline in step as the
    // page animates — this call just kicks off the glide.
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _nextPage() {
    if (_currentIndex < _tabLabels.length - 1) {
      _goToTab(_currentIndex + 1);
    } else {
      _continue();
    }
  }

  Future<void> _continue() async {
    final sessionId = widget.route.sessionId;
    if (sessionId == null || sessionId.isEmpty) {
      await _proceedToPayment(_addOnsSummary);
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

    if (warning != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$warning You can still continue.')),
      );
    }
    // `_submitting` stays true across this hand-off — `_proceedToPayment`
    // clears it only if CreateItinerary fails and the user is left here.
    await _proceedToPayment(_addOnsSummary);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  /// The outer shell is deliberately fixed: header, tab bar, pages, bottom
  /// bar. Every tab-specific chrome (route card, aircraft banner, legend,
  /// summary strips) lives *inside* its own page, so switching tabs can never
  /// resize the shell — that's what used to make the swipe jump.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            _tabBar(context),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const ClampingScrollPhysics(),
                children: [
                  // Opaque so a page never shows another tab's content behind
                  // it while the PageView is mid-transition.
                  ColoredBox(color: Colors.white, child: _seatsPage(context)),
                  ColoredBox(color: Colors.white, child: _mealsPage(context)),
                  ColoredBox(color: Colors.white, child: _baggagePage(context)),
                ],
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
            child: Image.asset(
              'assets/NewIcons/arrowBack.png',
              width: context.w(24),
              height: context.h(24),
              color: _title900,
            ),
          ),
          SizedBox(width: context.w(12)),
          Expanded(
            child: Text(
              'Add-ons',
              style: TextStyle(color: _title900, fontSize: context.fs(20), fontWeight: FontWeight.w600),
            ),
          ),
          if (widget.route.from.isNotEmpty) ...[
            _routeBadgeCompact(context),
            SizedBox(width: context.w(12)),
          ],
          // Not in Figma, but skipping seats/add-ons entirely is real,
          // existing functionality (straight on to payment) — kept as a
          // small text action instead of dropping it. Shown on every tab
          // so the header never changes shape when switching.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _submitting ? null : _skip,
            child: Text(
              'Skip',
              style: TextStyle(
                color: AppColors.subhead,
                fontSize: context.fs(13),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
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
        AirlineLogo(
          code: _routeAirlineCode(),
          name: widget.route.airline,
          size: context.w(24),
          borderRadius: BorderRadius.circular(context.r(8)),
        ),
        SizedBox(width: context.w(8)),
        Text(
          '${widget.route.from} - ${widget.route.to}',
          style: TextStyle(color: _title900, fontSize: context.fs(14), fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  // ==================== LARGE ROUTE CARD (Figma node 458:5338) ====================
  Widget _routeCardLarge(BuildContext context) {
    final route = widget.route;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: context.w(16), vertical: context.h(20)),
      decoration: const BoxDecoration(
        // Figma: linear-gradient(-75deg, #FFFFFF 44%, rgba(128,218,255,.894) 176%)
        gradient: LinearGradient(
          begin: Alignment(0.9, -1),
          end: Alignment(-0.5, 1),
          colors: [Color(0xE480DAFF), Colors.white],
          stops: [0.0, 0.62],
        ),
      ),
      child: Row(
        children: [
          // The real carrier mark for this booking, resolved from the flight
          // number's IATA code — never a static placeholder.
          AirlineLogo(
            code: _routeAirlineCode(),
            name: route.airline,
            size: context.w(38),
            borderRadius: BorderRadius.circular(context.r(8)),
          ),
          SizedBox(width: context.w(16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${route.from} - ${route.to}',
                  style: TextStyle(
                    color: _title900,
                    fontSize: context.fs(18),
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
                Text(
                  route.airline.isNotEmpty ? route.airline : '${route.from} to ${route.to}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: _title900, fontSize: context.fs(12), height: 1.33),
                ),
              ],
            ),
          ),
          SizedBox(width: context.w(8)),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _submitting ? null : () => Navigator.of(context).maybePop(),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: context.w(12), vertical: context.h(8)),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.34),
                borderRadius: BorderRadius.circular(context.r(8)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Change Flight',
                    style: TextStyle(
                      color: AppColors.AppBlue,
                      fontSize: context.fs(12),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: context.w(6)),
                  Icon(Icons.keyboard_arrow_down_rounded, size: context.w(14), color: AppColors.AppBlue),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== AIRCRAFT BANNER (Figma "Flighjt seat2", node 458:5570) ====================
  /// Dark cabin strip under the route card, with the translucent red
  /// highlight (node 458:5573) gliding across the cabin **in lockstep with
  /// the seat list's scroll position** — scroll down and it travels aft,
  /// scroll back and it returns. Only the highlight rebuilds per frame
  /// (`ValueListenableBuilder` on `_seatScrollProgress`), so it tracks the
  /// finger without dropping frames.
  Widget _exitRowBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      height: context.h(116),
      // `clipBehavior` needs a real decoration (Container asserts
      // `decoration != null || clipBehavior == Clip.none`).
      decoration: const BoxDecoration(color: Color(0xA3000000)), // black @ 64%
      clipBehavior: Clip.hardEdge,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          // Figma node 458:5573 geometry, as fractions of the 412×116 frame.
          final boxW = w * 0.096;
          final boxH = h * 0.571;
          final boxTop = h * 0.169;
          // Travel range: nose-ward start through to the tail-ward end,
          // keeping the box fully inside the illustration's 20px insets.
          final startLeft = w * 0.12;
          final endLeft = w * 0.78 - boxW;

          return Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  // Figma: image inset 20px each side, slight vertical bleed.
                  padding: EdgeInsets.symmetric(horizontal: context.w(20)),
                  child: Image.asset('assets/NewIcons/flightSeat.png', fit: BoxFit.cover),
                ),
              ),
              ValueListenableBuilder<double>(
                valueListenable: _seatScrollProgress,
                builder: (context, progress, child) => Positioned(
                  left: startLeft + progress * (endLeft - startLeft),
                  top: boxTop,
                  child: child!,
                ),
                child: Container(
                  width: boxW,
                  height: boxH,
                  decoration: BoxDecoration(
                    color: const Color(0x57FF383C), // rgba(255,56,60,0.34)
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
  /// Labels and underline both interpolate off the live page offset, so the
  /// indicator slides continuously with a swipe instead of snapping after the
  /// page settles. Nothing here calls `setState` while scrolling.
  Widget _tabBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: ValueListenableBuilder<double>(
        valueListenable: _pageOffset,
        builder: (context, page, _) {
          return LayoutBuilder(
            builder: (context, c) {
              final tabWidth = c.maxWidth / _tabLabels.length;
              return Stack(
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < _tabLabels.length; i++)
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _goToTab(i),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: context.h(12.5)),
                              alignment: Alignment.center,
                              child: Text(
                                _tabLabels[i],
                                style: TextStyle(
                                  color: Color.lerp(
                                    AppColors.subhead,
                                    AppColors.AppBlue,
                                    (1 - (page - i).abs()).clamp(0.0, 1.0),
                                  ),
                                  fontSize: context.fs(14),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  Positioned(
                    left: page.clamp(0.0, (_tabLabels.length - 1).toDouble()) * tabWidth,
                    bottom: 0,
                    child: Container(
                      width: tabWidth,
                      height: 2,
                      color: AppColors.AppBlue,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _paxSelector(BuildContext context) {
    if (_pax.length <= 1) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.fromLTRB(context.w(18), context.h(10), context.w(18), context.h(10)),
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
                  style: TextStyle(
                    fontSize: context.fs(12),
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : _navy,
                  ),
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

  /// Owns all of its own chrome (route card, aircraft banner, legend strip) so
  /// the shell around the PageView never changes height between tabs.
  Widget _seatsPage(BuildContext context) {
    return Column(
      children: [
        if (widget.route.from.isNotEmpty) ...[
          _routeCardLarge(context),
          _exitRowBanner(context),
        ],
        Expanded(child: _seatsBody(context)),
        _seatLegendStrip(context),
      ],
    );
  }

  Widget _seatsBody(BuildContext context) {
    if (!_hasPricing) {
      return _emptyState(
          context, Icons.event_seat_outlined, "Seat selection isn't available for this flight.");
    }

    return BlocBuilder<AkSeatLayoutBloc, AkSeatLayoutState>(
      bloc: _seatLayoutBloc,
      builder: (context, state) {
        if (state is AkSeatLayoutLoading || state is AkSeatLayoutInitial) {
          return _seatSkeleton(context);
        }
        if (state is AkSeatLayoutFailed) {
          return _emptyState(
              context, Icons.event_seat_outlined, "Seat selection isn't available for this flight.");
        }
        final data = (state as AkSeatLayoutLoaded).data;
        if (!data.supported || !data.hasSeats) {
          return _emptyState(
              context, Icons.event_seat_outlined, "Seat selection isn't available for this flight.");
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
        final sortedTrips = legGroups.keys.toList()..sort();

        return Column(
          children: [
            _paxSelector(context),
            Expanded(
              child: ListView(
                controller: _seatScrollController,
                // Momentum-based physics so the seat map glides to a stop
                // instead of halting abruptly.
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                // Extra top padding leaves room for a selected seat's price
                // callout, which floats above its row.
                padding: EdgeInsets.fromLTRB(context.w(16), context.h(30), context.w(16), context.h(18)),
                children: [
                  for (final tripIndex in sortedTrips) ...[
                    if (showLegLabels) ...[
                      _legLabel(context, tripIndex),
                      SizedBox(height: context.h(10)),
                    ],
                    for (final segment in legGroups[tripIndex]!) ...[
                      _airplaneBody(context, segment, showCaption: showLegLabels),
                      SizedBox(height: context.h(18)),
                    ],
                  ],
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
          decoration: BoxDecoration(
            color: const Color(0xFFE7EAF2),
            borderRadius: BorderRadius.circular(context.r(6)),
          ),
        );
    return Padding(
      padding: EdgeInsets.all(context.w(18)),
      child: Column(
        children: [
          bar(double.infinity),
          bar(220),
          SizedBox(height: context.h(16)),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(context.r(24)),
              ),
              alignment: Alignment.center,
              child: const CircularProgressIndicator(strokeWidth: 2.4, color: _blue),
            ),
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

  /// The aligned seat grid for one flight segment (Figma node 456:4575) —
  /// column-letter header, then one [Row] per seat-row with the row number
  /// sitting in the aisle gap. Columns are aligned into a true grid (an
  /// absent seat leaves a blank slot) so headers line up with their column.
  Widget _airplaneBody(BuildContext context, AkSeatLayoutSegmentEntity segment,
      {required bool showCaption}) {
    final colXs = segment.seats.map((s) => int.tryParse(s.xValue) ?? 0).toSet().toList()..sort();
    final rowYs = segment.seats.map((s) => int.tryParse(s.yValue) ?? 0).toSet().toList()..sort();

    final seatAt = <String, AkSeatEntity>{
      for (final s in segment.seats)
        '${int.tryParse(s.xValue) ?? 0}|${int.tryParse(s.yValue) ?? 0}': s,
    };

    // Column letter / row number pulled straight from the API seat numbers
    // ("12A" -> row "12", column "A"), with A/B/C… and 1/2/3… fallbacks.
    final colLetterByX = <int, String>{};
    final rowLabelByY = <int, String>{};
    for (final s in segment.seats) {
      final x = int.tryParse(s.xValue) ?? 0;
      final y = int.tryParse(s.yValue) ?? 0;
      final cm = RegExp(r'([A-Za-z]+)').firstMatch(s.seatNumber);
      if (cm != null) colLetterByX.putIfAbsent(x, () => cm.group(1)!.toUpperCase());
      final rm = RegExp(r'(\d+)').firstMatch(s.seatNumber);
      if (rm != null) rowLabelByY.putIfAbsent(y, () => rm.group(1)!);
    }

    // Aisle = the widest gap between consecutive column positions.
    int aisleAfterIndex = -1;
    if (colXs.length > 2) {
      int widest = 0;
      for (int i = 0; i < colXs.length - 1; i++) {
        final gap = colXs[i + 1] - colXs[i];
        if (gap > widest) {
          widest = gap;
          aisleAfterIndex = i;
        }
      }
    }

    final n = colXs.length;
    final gap = context.w(10);
    final aisleW = context.w(24);

    List<Widget> rowChildren(Widget Function(int idx, int x) buildCell, Widget aisleSlot) {
      final cells = <Widget>[];
      for (int i = 0; i < n; i++) {
        cells.add(buildCell(i, colXs[i]));
        if (i == aisleAfterIndex) cells.add(aisleSlot);
      }
      final joined = <Widget>[];
      for (int i = 0; i < cells.length; i++) {
        if (i > 0) joined.add(SizedBox(width: gap));
        joined.add(cells[i]);
      }
      return joined;
    }

    return LayoutBuilder(
      builder: (context, c) {
        double size = context.w(40);
        final slots = aisleAfterIndex >= 0 ? n + 1 : n;
        double needed() => n * size + (aisleAfterIndex >= 0 ? aisleW : 0) + (slots - 1) * gap;
        if (needed() > c.maxWidth) {
          size = ((c.maxWidth - (aisleAfterIndex >= 0 ? aisleW : 0) - (slots - 1) * gap) / n)
              .clamp(context.w(26), context.w(40));
        }
        final gridWidth = needed();

        final grid = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showCaption) ...[
              Text(
                'Flight ${segment.flightNo}',
                style: TextStyle(
                  fontSize: context.fs(12),
                  fontWeight: FontWeight.w700,
                  color: AppColors.subhead,
                ),
              ),
              SizedBox(height: context.h(12)),
            ],
            Row(
              mainAxisSize: MainAxisSize.min,
              children: rowChildren(
                (idx, x) => SizedBox(
                  width: size,
                  child: Text(
                    colLetterByX[x] ?? String.fromCharCode(65 + idx),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: context.fs(12),
                      fontWeight: FontWeight.w700,
                      color: AppColors.subhead,
                    ),
                  ),
                ),
                SizedBox(width: aisleW),
              ),
            ),
            SizedBox(height: context.h(10)),
            for (int ri = 0; ri < rowYs.length; ri++)
              Padding(
                padding: EdgeInsets.symmetric(vertical: context.h(4)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: rowChildren(
                    (idx, x) {
                      final seat = seatAt['$x|${rowYs[ri]}'];
                      return seat == null
                          ? SizedBox(width: size, height: size)
                          : _seatCell(context, segment.fuid, seat, size);
                    },
                    SizedBox(
                      width: aisleW,
                      child: Center(
                        child: Text(
                          rowLabelByY[rowYs[ri]] ?? '${ri + 1}',
                          style: TextStyle(
                            fontSize: context.fs(10),
                            fontWeight: FontWeight.w700,
                            color: AppColors.subhead,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );

        final fits = gridWidth <= c.maxWidth + 0.5;
        final sized = SizedBox(width: gridWidth, child: grid);
        return fits
            ? Center(child: sized)
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                child: sized,
              );
      },
    );
  }

  /// One seat in the grid (Figma nodes 456:4592 / 456:4606 / 456:4650 …).
  Widget _seatCell(BuildContext context, int fuid, AkSeatEntity seat, double size) {
    final blockedByExit = seat.isEmergencyExit && _hasChildOrInfant;
    final unavailable = !seat.selectable || blockedByExit;
    final myPick = _seatPicks[_seatPickKey(fuid, _activePaxId)];
    final isMine = myPick?.ssid == seat.ssid;
    // Scoped to this segment (fuid) — seat IDs are only unique within a
    // single flight's seat map.
    final takenByOther =
        !isMine && _seatPicks.values.any((p) => p.fuid == fuid && p.ssid == seat.ssid);
    final inactive = unavailable || takenByOther;

    final isFree = !inactive && seat.selectable && seat.fare <= 0;
    final isPremium = !inactive && !isFree && seat.fare > 0 && _seatIsPremium(fuid, seat);

    final typeText = seat.seatTypeName.toLowerCase();
    final nonReclining =
        typeText.contains('recl') && (typeText.contains('non') || typeText.contains('not'));
    final extraLegroom = typeText.contains('legroom') ||
        typeText.contains('extra') ||
        RegExp(r'\bxl\b').hasMatch(typeText);

    // Figma palette: unavailable #F8FAFC, standard rgba(0,161,228,.24),
    // premium #00A1E4, free #FF6600, selected #34C759.
    Color bg;
    Color fg = Colors.white;
    if (inactive) {
      bg = const Color(0xFFF8FAFC);
    } else if (isMine) {
      bg = const Color(0xFF34C759);
    } else if (isFree) {
      bg = AppColors.OrangeColor;
    } else if (isPremium) {
      bg = AppColors.AppBlue;
    } else {
      bg = AppColors.AppBlue.withValues(alpha: 0.24);
      fg = AppColors.AppBlue;
    }

    Border? border;
    if (inactive) {
      border = Border.all(color: const Color(0xFFF1F5F9));
    } else if (nonReclining) {
      border = const Border(bottom: BorderSide(color: Colors.black, width: 2));
    }

    List<BoxShadow>? shadow;
    if (isMine) {
      shadow = [
        BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 6, offset: const Offset(0, 6))
      ];
    } else if (isPremium) {
      shadow = [
        BoxShadow(
            color: const Color(0xFF1D61FF).withValues(alpha: 0.3),
            blurRadius: 1,
            offset: const Offset(0, 1))
      ];
    }

    final label = inactive ? '' : (extraLegroom ? 'XL' : '');

    void toggle() {
      setState(() {
        final key = _seatPickKey(fuid, _activePaxId);
        if (isMine) {
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
    }

    final box = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(context.r(12)),
        border: border,
        boxShadow: shadow,
      ),
      child: inactive
          ? Icon(Icons.close_rounded, size: size * 0.3, color: const Color(0xFFCBD5E1))
          : label.isEmpty
              ? null
              : Text(label,
                  style: TextStyle(
                      fontSize: context.fs(10), fontWeight: FontWeight.w700, color: fg)),
    );

    return Tooltip(
      message: unavailable
          ? (blockedByExit ? 'Emergency exit — unavailable' : 'Not available')
          : takenByOther
              ? 'Taken by another passenger'
              : seat.fare > 0
                  ? '${seat.seatNumber} · ${_displayAmount(seat.fare)}'
                  : '${seat.seatNumber} · Free',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: inactive ? null : toggle,
        child: SizedBox(
          width: size,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              AnimatedScale(
                scale: isMine ? 1.06 : 1.0,
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutBack,
                child: box,
              ),
              if (seat.isEmergencyExit && !isMine)
                Positioned(
                  right: -context.w(3),
                  top: -context.h(2),
                  child: Container(
                    width: context.w(13),
                    height: context.w(13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF383C),
                      borderRadius: BorderRadius.circular(context.r(4)),
                    ),
                  ),
                ),
              if (isMine)
                Positioned(
                  right: -context.w(5),
                  top: -context.h(5),
                  child: Container(
                    padding: EdgeInsets.all(context.w(1)),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Icon(Icons.check_circle, size: context.w(15), color: const Color(0xFF34C759)),
                  ),
                ),
              if (isMine)
                Positioned(
                  bottom: size + context.h(5),
                  left: size / 2,
                  child: FractionalTranslation(
                    translation: const Offset(-0.5, 0),
                    child: _seatCallout(context, seat),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// The floating "4A | ₹725" price bubble above a selected seat
  /// (Figma nodes 458:6419 / 458:6420). Pops in with a small spring.
  Widget _seatCallout(BuildContext context, AkSeatEntity seat) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      builder: (context, v, child) => Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.8 + 0.2 * v, alignment: Alignment.bottomCenter, child: child),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: context.w(8), vertical: context.h(4)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(context.r(6)),
              border: Border.all(color: AppColors.AppBlue.withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3)),
              ],
            ),
            child: Text(
              seat.fare > 0
                  ? '${seat.seatNumber} | ${_displayAmount(seat.fare)}'
                  : '${seat.seatNumber} | Free',
              style: TextStyle(
                  fontSize: context.fs(11),
                  fontWeight: FontWeight.w600,
                  color: AppColors.AppBlue),
            ),
          ),
          Transform.translate(
            offset: Offset(0, -context.h(3)),
            child: Transform.rotate(
              angle: 0.785398,
              child: Container(width: context.w(7), height: context.w(7), color: Colors.white),
            ),
          ),
        ],
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

  /// Legend strip at the foot of the Seats page (Figma node 458:5518) —
  /// `#F1F5F9` band, horizontally scrollable. The two paid-fare chips show
  /// the real min–max range from this flight's seat fares (split on the
  /// median, same as `_seatIsPremium`), so they aren't hardcoded. Hidden
  /// entirely until a seat map actually loads.
  Widget _seatLegendStrip(BuildContext context) {
    return BlocBuilder<AkSeatLayoutBloc, AkSeatLayoutState>(
      bloc: _seatLayoutBloc,
      builder: (context, state) {
        if (state is! AkSeatLayoutLoaded || !state.data.hasSeats) {
          return const SizedBox.shrink();
        }

        final paid = <double>[];
        for (final t in state.data.trips) {
          for (final j in t.journey) {
            for (final s in j.segments) {
              for (final seat in s.seats) {
                if (seat.selectable && seat.fare > 0) paid.add(seat.fare);
              }
            }
          }
        }
        paid.sort();
        final double? median = paid.isEmpty ? null : paid[paid.length ~/ 2];
        final standard = median == null ? const <double>[] : paid.where((f) => f < median).toList();
        final premium = median == null ? const <double>[] : paid.where((f) => f >= median).toList();
        String range(List<double> xs) =>
            xs.isEmpty ? '' : '${_displayAmount(xs.first)} - ${_displayAmount(xs.last)}';

        final chips = <Widget>[
          _legendChip(context, color: AppColors.OrangeColor, label: 'Free'),
          if (standard.isNotEmpty)
            _legendChip(context,
                color: AppColors.AppBlue.withValues(alpha: 0.24),
                border: Border.all(color: _stroke),
                label: range(standard)),
          if (premium.isNotEmpty)
            _legendChip(context, color: AppColors.AppBlue, label: range(premium)),
          _legendChip(context,
              color: Colors.white,
              border: Border.all(color: _stroke),
              label: 'Exit Row Seats',
              cornerMark: true),
          _legendChip(context,
              color: Colors.white,
              border: Border.all(color: _stroke),
              label: 'Extra Legroom',
              xl: true),
          _legendChip(context,
              color: Colors.white,
              border: const Border(bottom: BorderSide(color: Colors.black, width: 2)),
              label: 'Non Reclining'),
        ];

        return Container(
          width: double.infinity,
          color: const Color(0xFFF1F5F9),
          padding: EdgeInsets.symmetric(horizontal: context.w(16), vertical: context.h(6)),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < chips.length; i++) ...[
                  if (i > 0) SizedBox(width: context.w(12)),
                  chips[i],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _legendChip(
    BuildContext context, {
    required Color color,
    required String label,
    Border? border,
    bool cornerMark = false,
    bool xl = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: context.w(12),
          height: context.w(12),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color,
                  border: border,
                  borderRadius: BorderRadius.circular(context.r(2)),
                ),
                child: xl
                    ? Text('XL',
                        style: TextStyle(
                            fontSize: context.fs(4),
                            fontWeight: FontWeight.w900,
                            color: _title900))
                    : null,
              ),
              if (cornerMark)
                Positioned(
                  right: -context.w(3),
                  top: -context.w(3),
                  child: Transform.rotate(
                    angle: 0.785398,
                    child: Container(
                        width: context.w(7),
                        height: context.w(7),
                        color: const Color(0xFFFF383C)),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(width: context.w(4)),
        Text(label, style: TextStyle(fontSize: context.fs(8), color: AppColors.subhead)),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Meals page — Figma "Flighjt meals" (node 467:6784)
  // ---------------------------------------------------------------------------

  String _typeKey(String typeName) => typeName.isEmpty ? 'OTHER' : typeName.toUpperCase();

  /// Filter bar + grouped meal cards + the summary strip, all owned by this
  /// page. The filter/menu state is republished through [_mealUiRevision] so a
  /// chip tap rebuilds only this subtree, never the seat grid next door.
  Widget _mealsPage(BuildContext context) {
    const emptyMessage = 'No meal options available for this fare.';
    if (!_hasPricing) return _emptyState(context, Icons.restaurant_outlined, emptyMessage);

    return BlocBuilder<AkSsrBloc, AkSsrState>(
      bloc: _ssrBloc,
      builder: (context, state) {
        if (state is AkSsrLoading || state is AkSsrInitial) {
          return _addonsSkeleton(context);
        }
        if (state is AkSsrFailed) {
          return _emptyState(context, Icons.restaurant_outlined, emptyMessage);
        }
        final data = (state as AkSsrLoaded).data;
        final groups = data.hasOptions ? _mealGroups(data) : <String, List<_MealEntry>>{};
        if (groups.isEmpty) {
          return _emptyState(context, Icons.restaurant_outlined, emptyMessage);
        }

        return ValueListenableBuilder<int>(
          valueListenable: _mealUiRevision,
          builder: (context, _, __) {
            final sections = <Widget>[];
            groups.forEach((label, entries) {
              final visible = entries.where((e) {
                if (_mealVegFilter.isEmpty) return true;
                final v = _mealIsVeg(e.item);
                return v != null && _mealVegFilter.contains(v);
              }).toList();
              if (visible.isEmpty) return;
              sections.add(Text(
                label,
                style: TextStyle(
                    fontSize: context.fs(14),
                    fontWeight: FontWeight.w500,
                    color: AppColors.subhead),
              ));
              sections.add(SizedBox(height: context.h(16)));
              for (int i = 0; i < visible.length; i++) {
                sections.add(_mealCard(context, entry: visible[i]));
                if (i != visible.length - 1) sections.add(SizedBox(height: context.h(12)));
              }
              sections.add(SizedBox(height: context.h(34)));
            });
            if (sections.isNotEmpty && sections.last is SizedBox) sections.removeLast();

            return Stack(
              children: [
                Column(
                  children: [
                    _mealFilterBar(context),
                    Expanded(
                      child: sections.isEmpty
                          ? _emptyState(
                              context, Icons.restaurant_outlined, 'No meals match this filter.')
                          : ListView(
                              padding: EdgeInsets.fromLTRB(
                                  context.w(16), context.h(20), context.w(16), context.h(16)),
                              children: sections,
                            ),
                    ),
                    _mealSummaryCard(context),
                  ],
                ),
                if (_mealMenuOpen) ..._mealMenuOverlay(context, groups),
              ],
            );
          },
        );
      },
    );
  }

  /// Groups the MEALS SSR items for display (Figma node 481:1297). No
  /// category field exists on the API item, so a single "Meals" section is
  /// used for one leg and per-leg sections for a round trip — always a real
  /// signal, never an invented category.
  Map<String, List<_MealEntry>> _mealGroups(AkSsrEntity data) {
    final legsWithMeals = <int>{};
    for (int t = 0; t < data.trips.length; t++) {
      for (final j in data.trips[t].journey) {
        for (final s in j.segments) {
          if (s.items.any((i) => _mealTabTypes.contains(_typeKey(i.typeName)))) {
            legsWithMeals.add(t);
          }
        }
      }
    }
    final multiLeg = legsWithMeals.length > 1;

    final out = <String, List<_MealEntry>>{};
    for (int t = 0; t < data.trips.length; t++) {
      for (final j in data.trips[t].journey) {
        for (final s in j.segments) {
          final meals =
              s.items.where((i) => _mealTabTypes.contains(_typeKey(i.typeName))).toList();
          if (meals.isEmpty) continue;
          for (final m in meals) {
            final label = multiLeg
                ? (t == 0
                    ? 'Onward Flight'
                    : t == 1
                        ? 'Return Flight'
                        : 'Flight ${t + 1}')
                : _mealCategoryLabel(m);
            out.putIfAbsent(label, () => []).add(_MealEntry(
                  item: m,
                  fuid: s.fuid,
                  group: meals,
                  multiSelectAllowed: j.multiSelectAllowed,
                ));
          }
        }
      }
    }
    return out;
  }

  String _mealCategoryLabel(AkSsrItemEntity item) {
    final tn = item.typeName.trim();
    if (tn.isEmpty || tn.toUpperCase() == 'MEALS') return 'Meals';
    return tn[0].toUpperCase() + tn.substring(1).toLowerCase();
  }

  /// Current quantity of one meal on one segment = the number of `_ssrPicks`
  /// carrying it (one per passenger), so the model stays exactly what
  /// `_continue()`'s AkSelectSsr call already sends.
  int _mealQty(int itemId, int fuid) =>
      _ssrPicks.where((p) => p.id == itemId && p.fuid == fuid).length;

  void _setMealQty(_MealEntry e, int target) {
    setState(() {
      final maxQ = _pax.length;
      target = target.clamp(0, maxQ);
      final current = _ssrPicks.where((p) => p.id == e.item.id && p.fuid == e.fuid).toList()
        ..sort((a, b) => a.paxId.compareTo(b.paxId));
      if (target < current.length) {
        for (final p in current.reversed.take(current.length - target).toList()) {
          _ssrPicks.remove(p);
        }
      } else if (target > current.length) {
        final used = current.map((p) => p.paxId).toSet();
        final groupIds = e.group.map((g) => g.id).toSet();
        for (final pax in _pax) {
          if (_mealQty(e.item.id, e.fuid) >= target) break;
          if (used.contains(pax.paxId)) continue;
          if (!e.multiSelectAllowed) {
            _ssrPicks.removeWhere(
                (p) => p.fuid == e.fuid && p.paxId == pax.paxId && groupIds.contains(p.id));
          }
          _ssrPicks.add(_SsrPick(
            id: e.item.id,
            fuid: e.fuid,
            paxId: pax.paxId,
            charge: e.item.charge,
            typeName: e.item.typeName,
            description: e.item.description,
            code: e.item.code,
          ));
        }
      }
    });
    // Refresh the meals subtree too (quantity badges live inside it).
    _mealUiRevision.value++;
  }

  Widget _vegBadge(BuildContext context, bool veg, {double size = 14}) {
    final c = veg ? const Color(0xFF16A34A) : const Color(0xFFFF383C);
    return Container(
      width: context.w(size),
      height: context.w(size),
      padding: EdgeInsets.all(context.w(size * 0.21)),
      decoration: BoxDecoration(
        border: Border.all(color: c),
        borderRadius: BorderRadius.circular(context.r(2)),
      ),
      child: Container(decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
    );
  }

  // ==================== MEALS FILTER BAR (Figma nodes 481:1199 / 481:1363) ====================
  Widget _mealFilterBar(BuildContext context) {
    Widget chip(bool veg) {
      final active = _mealVegFilter.contains(veg);
      final c = veg ? const Color(0xFF34C759) : const Color(0xFFFF383C);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!_mealVegFilter.add(veg)) _mealVegFilter.remove(veg);
          _mealUiRevision.value++;
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: EdgeInsets.symmetric(horizontal: context.w(6), vertical: context.h(4)),
          decoration: BoxDecoration(
            color: active ? c.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(context.r(4)),
            border: Border.all(color: active ? c : _stroke, width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _vegBadge(context, veg),
              SizedBox(width: context.w(4)),
              Text(
                veg ? 'Veg' : 'Non Veg',
                style: TextStyle(
                    fontSize: context.fs(12),
                    fontWeight: FontWeight.w500,
                    color: AppColors.subhead),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(context.w(16), context.h(12), context.w(16), context.h(4)),
      child: Row(
        children: [
          chip(true),
          SizedBox(width: context.w(12)),
          chip(false),
          const Spacer(),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              _mealMenuOpen = !_mealMenuOpen;
              _mealUiRevision.value++;
            },
            child: Container(
              padding: EdgeInsets.all(context.w(6)),
              decoration: BoxDecoration(
                  color: Colors.black, borderRadius: BorderRadius.circular(context.r(4))),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.restaurant_menu, size: context.w(10), color: Colors.white),
                  SizedBox(width: context.w(8)),
                  Text('Menu',
                      style: TextStyle(
                          fontSize: context.fs(12),
                          fontWeight: FontWeight.w500,
                          color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _mealMenuOverlay(BuildContext context, Map<String, List<_MealEntry>> groups) {
    final labels = groups.keys.toList();
    return [
      Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            _mealMenuOpen = false;
            _mealUiRevision.value++;
          },
          child: const SizedBox.expand(),
        ),
      ),
      Positioned(
        right: context.w(16),
        top: context.h(8),
        width: context.w(200),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(context.w(12)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(context.r(8)),
              border: Border.all(color: _stroke, width: 0.5),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < labels.length; i++) ...[
                  if (i > 0) SizedBox(height: context.h(12)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          labels[i],
                          style: TextStyle(
                            fontSize: context.fs(12),
                            fontWeight: i == 0 ? FontWeight.w600 : FontWeight.w400,
                            color: i == 0 ? AppColors.AppBlue : Colors.black,
                          ),
                        ),
                      ),
                      Text(
                        '${groups[labels[i]]!.length}',
                        style: TextStyle(
                          fontSize: context.fs(12),
                          fontWeight: i == 0 ? FontWeight.w600 : FontWeight.w400,
                          color: i == 0 ? AppColors.AppBlue : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ];
  }

  // ==================== MEAL CARD (Figma node 478:1142) ====================
  Widget _mealCard(BuildContext context, {required _MealEntry entry}) {
    final item = entry.item;
    final qty = _mealQty(item.id, entry.fuid);
    final selected = qty > 0;
    final veg = _mealIsVeg(item);
    final maxQ = _pax.length;
    final imgSize = context.w(101);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: double.infinity,
      padding: EdgeInsets.all(context.w(12.5)),
      decoration: BoxDecoration(
        color: selected ? AppColors.AppBlue.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: selected ? AppColors.AppBlue : _stroke, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(context.r(12)),
            child: Image.asset(
              'assets/Newimage/mealPlaceholder.png',
              width: context.w(102),
              height: imgSize,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: context.w(12)),
          Expanded(
            child: SizedBox(
              height: imgSize,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (veg != null) ...[
                        _vegBadge(context, veg),
                        SizedBox(width: context.w(8)),
                      ],
                      Expanded(
                        child: Text(
                          item.description.isEmpty ? item.code : item.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: context.fs(12),
                            fontWeight: FontWeight.w400,
                            color: AppColors.subhead,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: item.isFree
                            ? Text(
                                'Free',
                                style: TextStyle(
                                  fontSize: context.fs(14),
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF16A34A),
                                ),
                              )
                            : Text.rich(
                                TextSpan(children: [
                                  TextSpan(
                                    text: _displayAmount(item.charge),
                                    style: TextStyle(
                                      fontSize: context.fs(14),
                                      fontWeight: FontWeight.w700,
                                      color: _title900,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '/person',
                                    style: TextStyle(
                                      fontSize: context.fs(10),
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.subhead,
                                    ),
                                  ),
                                ]),
                              ),
                      ),
                      _mealStepper(context, entry, qty, maxQ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mealStepper(BuildContext context, _MealEntry e, int qty, int maxQ) {
    Widget btn(IconData icon, VoidCallback? onTap) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.w(8), vertical: context.h(8)),
            child: Icon(icon, size: context.w(12), color: onTap == null ? _stroke : _title900),
          ),
        );
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.r(8)),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(Icons.remove, qty > 0 ? () => _setMealQty(e, qty - 1) : null),
          Container(
            constraints: BoxConstraints(minWidth: context.w(20)),
            alignment: Alignment.center,
            child: Text(
              '$qty',
              style: TextStyle(
                  fontSize: context.fs(14), fontWeight: FontWeight.w600, color: _title900),
            ),
          ),
          btn(Icons.add, qty < maxQ ? () => _setMealQty(e, qty + 1) : null),
        ],
      ),
    );
  }

  /// Slim strip at the foot of the Meals page (Figma node 481:1227), driven
  /// off `_ssrPicks`.
  Widget _mealSummaryCard(BuildContext context) {
    final picks = _ssrPicks.where((p) => _mealTabTypes.contains(_typeKey(p.typeName))).toList();
    if (picks.isEmpty) return const SizedBox.shrink();

    final total = picks.fold<double>(0, (s, p) => s + p.charge);
    final paxWithMeal = picks.map((p) => p.paxId).toSet().length;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: context.w(16), vertical: context.h(6)),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _stroke, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${picks.length} meal(s) Selected',
                style: TextStyle(
                    fontSize: context.fs(12), fontWeight: FontWeight.w500, color: Colors.black),
              ),
              Text(
                '$paxWithMeal of ${_pax.length} Meal(s) Selected',
                style: TextStyle(fontSize: context.fs(8), color: const Color(0xFF0B9D9D)),
              ),
            ],
          ),
          SizedBox(width: context.w(12)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _displayAmount(total),
                style: TextStyle(
                    fontSize: context.fs(12), fontWeight: FontWeight.w700, color: Colors.black),
              ),
              Text(
                'Added to fare',
                style: TextStyle(
                    fontSize: context.fs(8),
                    fontWeight: FontWeight.w400,
                    color: AppColors.subhead),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Baggage page — Figma "Flighjt BAGGAGE" (node 487:1672)
  // ---------------------------------------------------------------------------

  /// A flat vertical list of baggage cards plus the summary strip. Options,
  /// the AkSsr BLoC, the `_ssrPicks` selection model and `_addOnsTotal` are
  /// the same ones the Meals tab and `_continue()`'s AkSelectSsr call use.
  Widget _baggagePage(BuildContext context) {
    const emptyMessage = 'No baggage options available for this fare.';
    if (!_hasPricing) return _emptyState(context, Icons.luggage_outlined, emptyMessage);

    return BlocBuilder<AkSsrBloc, AkSsrState>(
      bloc: _ssrBloc,
      builder: (context, state) {
        if (state is AkSsrLoading || state is AkSsrInitial) {
          return _addonsSkeleton(context);
        }
        if (state is AkSsrFailed) {
          return _emptyState(context, Icons.luggage_outlined, emptyMessage);
        }
        final data = (state as AkSsrLoaded).data;
        final sections = data.hasOptions ? _baggageSections(context, data) : <Widget>[];
        if (sections.isEmpty) {
          return _emptyState(context, Icons.luggage_outlined, emptyMessage);
        }

        return Column(
          children: [
            _paxSelector(context),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                    context.w(16), context.h(16), context.w(16), context.h(12)),
                children: sections,
              ),
            ),
            _baggageSummaryCard(context),
          ],
        );
      },
    );
  }

  List<Widget> _baggageSections(BuildContext context, AkSsrEntity data) {
    bool hasBaggage(AkSsrJourneyEntity j) => j.segments
        .any((s) => s.items.any((i) => _baggageTabTypes.contains(_typeKey(i.typeName))));
    final showLegLabels = data.trips.where((t) => t.journey.any(hasBaggage)).length > 1;

    final sections = <Widget>[];
    for (int t = 0; t < data.trips.length; t++) {
      final trip = data.trips[t];
      for (final journey in trip.journey) {
        for (final segment in journey.segments) {
          final wanted = segment.items
              .where((i) => _baggageTabTypes.contains(_typeKey(i.typeName)))
              .toList();
          if (wanted.isEmpty) continue;
          if (showLegLabels) {
            sections.add(_legLabel(context, t));
            sections.add(SizedBox(height: context.h(12)));
          }
          for (final item in wanted) {
            sections.add(_baggageCard(
              context,
              fuid: segment.fuid,
              item: item,
              groupItems: wanted,
              multiSelectAllowed: journey.multiSelectAllowed,
            ));
            sections.add(SizedBox(height: context.h(20)));
          }
        }
      }
    }
    // Drop the trailing spacer so the list doesn't end with dead space.
    if (sections.isNotEmpty && sections.last is SizedBox) sections.removeLast();
    return sections;
  }

  // ==================== BAGGAGE CARD (Figma node 487:1945 / 487:1954) ====================
  Widget _baggageCard(
    BuildContext context, {
    required int fuid,
    required AkSsrItemEntity item,
    required List<AkSsrItemEntity> groupItems,
    required bool multiSelectAllowed,
  }) {
    final selected =
        _ssrPicks.any((p) => p.id == item.id && p.fuid == fuid && p.paxId == _activePaxId);

    void toggle() {
      setState(() {
        if (selected) {
          _ssrPicks
              .removeWhere((p) => p.id == item.id && p.fuid == fuid && p.paxId == _activePaxId);
          return;
        }
        if (!multiSelectAllowed) {
          final groupIds = groupItems.map((g) => g.id).toSet();
          _ssrPicks.removeWhere(
              (p) => p.fuid == fuid && p.paxId == _activePaxId && groupIds.contains(p.id));
        }
        _ssrPicks.add(_SsrPick(
          id: item.id,
          fuid: fuid,
          paxId: _activePaxId,
          charge: item.charge,
          typeName: item.typeName,
          description: item.description,
          code: item.code,
        ));
      });
    }

    // Both lines come from the SSR response — the allowance description and
    // its fare code — never a hardcoded caption.
    final title = item.description.isEmpty ? item.code : item.description;
    final subtitle = (item.description.isEmpty || item.code.isEmpty || item.code == item.description)
        ? ''
        : item.code;
    const pri = AppColors.AppBlue;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: toggle,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: double.infinity,
            padding: EdgeInsets.all(context.w(12)),
            decoration: BoxDecoration(
              color: selected ? pri.withValues(alpha: 0.04) : Colors.white,
              borderRadius: BorderRadius.circular(context.r(8)),
              border: Border.all(color: selected ? pri : _stroke, width: 0.5),
            ),
            child: Row(
              children: [
                Image.asset(
                  'assets/Newimage/bag.png',
                  width: context.w(16.5),
                  height: context.h(23.5),
                  fit: BoxFit.contain,
                  color: pri,
                ),
                SizedBox(width: context.w(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: context.fs(14),
                          fontWeight: FontWeight.w600,
                          color: _title900,
                          letterSpacing: 0.14,
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: context.h(2)),
                          child: Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: context.fs(8),
                              fontWeight: FontWeight.w500,
                              color: AppColors.subhead,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(width: context.w(8)),
                item.isFree
                    ? Text(
                        'Free',
                        style: TextStyle(
                          fontSize: context.fs(14),
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF16A34A),
                        ),
                      )
                    : Text.rich(
                        TextSpan(children: [
                          TextSpan(
                            text: _displayAmount(item.charge),
                            style: TextStyle(
                              fontSize: context.fs(14),
                              fontWeight: FontWeight.w600,
                              color: _title900,
                              letterSpacing: 0.14,
                            ),
                          ),
                          TextSpan(
                            text: '/person',
                            style: TextStyle(
                              fontSize: context.fs(8),
                              fontWeight: FontWeight.w600,
                              color: AppColors.subhead,
                            ),
                          ),
                        ]),
                      ),
              ],
            ),
          ),
          if (selected)
            Positioned(
              right: context.w(6),
              top: -context.h(10),
              child: Container(
                width: context.w(22),
                height: context.w(22),
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: pri, shape: BoxShape.circle),
                child: Icon(Icons.check, size: context.w(13), color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  /// Figma node 487:1804 — the slim strip at the foot of the Baggage page.
  /// Driven entirely off `_ssrPicks`, so it appears the moment a card is
  /// selected and updates as picks change.
  Widget _baggageSummaryCard(BuildContext context) {
    final picks = _ssrPicks.where((p) => _baggageTabTypes.contains(_typeKey(p.typeName))).toList();
    if (picks.isEmpty) return const SizedBox.shrink();

    final last = picks.last;
    final total = picks.fold<double>(0, (s, p) => s + p.charge);
    final title = last.description.isEmpty ? last.code : last.description;
    final detail =
        picks.length > 1 ? '${picks.length} items' : (last.description.isEmpty ? '' : last.code);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: context.w(16), vertical: context.h(6)),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _stroke, width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: title),
                    const TextSpan(text: ' Selected'),
                  ]),
                  style: TextStyle(
                    fontSize: context.fs(12),
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                if (detail.isNotEmpty)
                  Text(
                    detail,
                    style: TextStyle(fontSize: context.fs(8), color: const Color(0xFF0B9D9D)),
                  ),
              ],
            ),
          ),
          SizedBox(width: context.w(12)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _displayAmount(total),
                style: TextStyle(
                  fontSize: context.fs(12),
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              Text(
                'Added to fare',
                style: TextStyle(
                  fontSize: context.fs(8),
                  fontWeight: FontWeight.w400,
                  color: AppColors.subhead,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _addonsSkeleton(BuildContext context) {
    Widget card() => Container(
          margin: EdgeInsets.only(bottom: context.h(12)),
          height: context.h(70),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F5F9),
            borderRadius: BorderRadius.circular(context.r(12)),
          ),
        );
    return Padding(
      padding: EdgeInsets.all(context.w(18)),
      child: Column(children: [card(), card(), card()]),
    );
  }

  /// Best-effort veg/non-veg dot for a MEALS item — this API only gives a
  /// free-text description/code (no dedicated veg flag like the TBO meal
  /// codes elsewhere in the app), so this is a keyword guess and shows no
  /// dot at all when it can't tell either way, instead of asserting one.
  bool? _mealIsVeg(AkSsrItemEntity item) {
    final text = '${item.code} ${item.description}'.toLowerCase();
    if (text.contains('non veg') || text.contains('non-veg') || text.contains('nonveg')) {
      return false;
    }
    if (text.contains('veg')) return true;
    return null;
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
              decoration: BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle, border: Border.all(color: _border)),
              child: Icon(icon, size: context.w(28), color: _muted),
            ),
            SizedBox(height: context.h(14)),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: context.fs(13), color: _muted, fontWeight: FontWeight.w600),
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

  /// Opens the shared Fare Breakup drawer from the bottom bar's total/info
  /// tap. Splits the same `_seatPicks` / `_ssrPicks` this screen already
  /// sums for the bottom bar — no new pricing logic.
  void _openFareBreakup(BuildContext context) {
    final seatTotal =
        _seatPicks.values.fold<double>(0, (s, p) => s + p.fare + p.tax);
    final mealTotal = _ssrPicks
        .where((p) => _mealTabTypes.contains(_typeKey(p.typeName)))
        .fold<double>(0, (s, p) => s + p.charge);
    final extrasTotal = _ssrPicks
        .where((p) => !_mealTabTypes.contains(_typeKey(p.typeName)))
        .fold<double>(0, (s, p) => s + p.charge);

    final pax = widget.travellerCount < 1 ? 1 : widget.travellerCount;
    final lines = <FareBreakupLine>[
      FareBreakupLine(
        label: 'Base Fare',
        amount: _displayAmount(_baseFare),
        subLabel: 'Traveller(s) ($pax X ${_displayAmount(_baseFare / pax)})',
        subAmount: _displayAmount(_baseFare),
      ),
      if (seatTotal > 0)
        FareBreakupLine(label: 'Seats', amount: _displayAmount(seatTotal)),
      if (mealTotal > 0)
        FareBreakupLine(label: 'Meals', amount: _displayAmount(mealTotal)),
      if (extrasTotal > 0)
        FareBreakupLine(
            label: 'Baggage & Extras', amount: _displayAmount(extrasTotal)),
    ];

    FareBreakupSheet.show(
      context,
      lines: lines,
      totalAmount: _displayAmount(_baseFare + _addOnsTotal),
    );
  }

  // ==================== BOTTOM BAR (Figma: total + Continue) ====================
  Widget _bottomBar(BuildContext context) {
    final total = _baseFare + _addOnsTotal;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.w(19), vertical: context.h(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, -4))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _openFareBreakup(context),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        _displayAmount(total),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _title900,
                          fontSize: context.fs(24),
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ),
                    SizedBox(width: context.w(4)),
                    Icon(Icons.info_outline, size: context.w(12), color: AppColors.subhead),
                  ],
                ),
                Text(
                  'FOR ${widget.travellerCount} ADULT${widget.travellerCount > 1 ? 'S' : ''}',
                  style: TextStyle(
                      color: AppColors.subhead,
                      fontSize: context.fs(8),
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
            ),
          ),
          SizedBox(width: context.w(12)),
          SizedBox(
            height: context.h(44),
            child: ElevatedButton(
              onPressed: _submitting ? null : _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.OrangeColor,
                disabledBackgroundColor: AppColors.OrangeColor.withValues(alpha: 0.6),
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
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: context.fs(14),
                          fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
