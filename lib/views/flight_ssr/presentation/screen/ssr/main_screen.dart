import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../UI_helper/responsive_layout.dart';
import '../../../../../common_widgets/airline_logo.dart';
import '../../../../../core/resources/app_colours.dart';
import '../../../../../injection_container.dart';
import '../../../domain/entities/baggage_option_entity.dart';
import '../../../domain/entities/meal_option_entity.dart';
import '../../../domain/entities/seat_option_entity.dart';
import '../../../domain/entities/service_selection_entity.dart';
import '../../bloc/ssr_bloc.dart';
import '../../bloc/ssr_event.dart';
import '../../../../flight_payment/presentation/screen/payment_screen.dart';
import '../../../../flight_search/presentation/screen/booking_screen.dart';
import 'baggage_screen.dart';
import 'meal_screen.dart';
import 'seats_screen.dart';

/// Add-ons screen — Figma "Flighjt seat 1" / "Flighjt meals" / "Flighjt
/// BAGGAGE" (node-id 458:5077 / 467:6784 / 487:1672): a SEATS / MEALS /
/// BAGGAGE tab bar instead of the old wizard (progress bar + Back/Next),
/// with a shared route badge in the header and a sticky bottom bar showing
/// the running total + the primary action. Same 3 sub-screens, same
/// selection callbacks, same `_navigateToPayment` payload as before — only
/// the shell around them changed.
class SSRMainScreen extends StatefulWidget {
  final String traceId;
  final String tokenId;
  final String resultIndex;
  final String endUserIp;
  final Map<String, dynamic> passengerData;
  final FareQuoteData? fareQuoteData;
  final FlightRouteSegment? route;

  /// Number of travellers — caps how many seats can be chosen.
  final int travellerCount;

  final double promoDiscount;
  final String promoCode;

  const SSRMainScreen({
    super.key,
    required this.traceId,
    required this.tokenId,
    required this.resultIndex,
    required this.endUserIp,
    this.passengerData = const {},
    this.fareQuoteData,
    this.route,
    this.travellerCount = 1,
    this.promoDiscount = 0.0,
    this.promoCode = '',
  });

  @override
  State<SSRMainScreen> createState() => _SSRMainScreenState();
}

class _SSRMainScreenState extends State<SSRMainScreen> {
  static const _title900 = Color(0xFF111527);

  final PageController _pageController = PageController();
  late final SsrBloc _ssrBloc;
  MealOptionEntity? _selectedMeal;
  List<SeatOptionEntity> _selectedSeats = [];
  List<SpecialServiceEntity> _selectedServices = [];

  int currentIndex = 0;
  BaggageOptionEntity? _selectedBaggage;

  // Figma tab order: SEATS, MEALS, BAGGAGE (was Baggage/Meals/Seats).
  static const _tabLabels = ["SEATS", "MEALS", "BAGGAGE"];

  @override
  void initState() {
    super.initState();
    _ssrBloc = sl<SsrBloc>();

    // Pre-load SSR data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ssrBloc.add(
        LoadSsrData(
          endUserIp: widget.endUserIp,
          traceId: widget.traceId,
          tokenId: widget.tokenId,
          resultIndex: widget.resultIndex,
        ),
      );
    });
  }

  @override
  void dispose() {
    _ssrBloc.close();
    _pageController.dispose();
    super.dispose();
  }

  void _goToTab(int index) {
    if (index == currentIndex) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void nextPage() {
    if (currentIndex < _tabLabels.length - 1) {
      _goToTab(currentIndex + 1);
    }
  }

  void _handleBaggageSelected(
    List<BaggageOptionEntity>? options,
    int? selectedIndex,
  ) {
    if (options != null &&
        selectedIndex != null &&
        selectedIndex < options.length) {
      setState(() {
        _selectedBaggage = options[selectedIndex];
      });
    }
  }

  /// Base fare (chosen result's amount) + everything selected so far — a
  /// display-only running total for the bottom bar (Figma shows it growing
  /// tab to tab). Doesn't change what's actually sent to payment — that's
  /// still the untouched `ssrSelections` payload below.
  double get _runningTotal {
    final base = widget.route?.amount ??
        double.tryParse((widget.route?.price ?? '').replaceAll(RegExp(r'[^0-9.]'), '')) ??
        0;
    final seats = _selectedSeats.fold<double>(0, (sum, s) => sum + s.price);
    final meal = _selectedMeal?.price ?? 0;
    final baggage = _selectedBaggage?.price ?? 0;
    return base + seats + meal + baggage;
  }

  void _navigateToPayment() {
    if (widget.route == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Missing flight details. Please go back and try again.',
          ),
        ),
      );
      return;
    }

    // Pass the COMPLETE TBO SSR objects, not just the codes. TBO's Book/Ticket
    // validates every field (AirlineCode, WayType, Price, Origin/Destination,
    // Weight, …); a code-only stub makes it throw "unhandled exception".
    final ssrSelections = <String, dynamic>{
      'baggage': _selectedBaggage?.toTboJson(),
      'meal': _selectedMeal?.toTboJson(),
      'seat': _selectedSeats.map((s) => s.toTboJson()).toList(),
      'services': _selectedServices.map((s) => s.toTboJson()).toList(),
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FlightPaymentScreen(
          route: widget.route!,
          traceId: widget.traceId,
          resultIndex: widget.resultIndex,
          passengerData: widget.passengerData,
          ssrSelections: ssrSelections,
          promoDiscount: widget.promoDiscount,
          promoCode: widget.promoCode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SsrBloc>(
      create: (_) => _ssrBloc,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _header(context),
              // Figma: a bigger route card on the Seats tab, a compact
              // header badge on Meals/Baggage.
              if (currentIndex == 0) _routeCardLarge(context),
              _tabBar(context),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (value) => setState(() => currentIndex = value),
                  children: [
                    SeatScreen(
                      traceId: widget.traceId,
                      tokenId: widget.tokenId,
                      resultIndex: widget.resultIndex,
                      travellerCount: widget.travellerCount,
                      onSeatsSelected: (seats) {
                        setState(() => _selectedSeats = seats);
                      },
                    ),
                    MealScreen(
                      traceId: widget.traceId,
                      tokenId: widget.tokenId,
                      resultIndex: widget.resultIndex,
                      onMealSelected: (meals, index) {
                        if (meals != null &&
                            index != null &&
                            index < meals.length) {
                          setState(() {
                            _selectedMeal = meals[index];
                          });
                        } else {
                          setState(() => _selectedMeal = null);
                        }
                      },
                    ),
                    BaggageScreen(
                      traceId: widget.traceId,
                      tokenId: widget.tokenId,
                      resultIndex: widget.resultIndex,
                      endUserIp: widget.endUserIp,
                      selectedSegmentIndex: 0,
                      onBaggageSelected: _handleBaggageSelected,
                    ),
                  ],
                ),
              ),
              _bottomBar(context),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== HEADER (Figma: "← Add-ons" [+ route badge]) ====================
  Widget _header(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.w(16), vertical: context.h(12)),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.maybePop(context),
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
          // Compact route badge — shown on Meals/Baggage tabs (Figma); the
          // Seats tab shows the bigger _routeCardLarge instead.
          if (currentIndex != 0 && widget.route != null) _routeBadgeCompact(context),
        ],
      ),
    );
  }

  /// `route.flightNo` is built upstream as "`<IATA code>` • `<number>`"
  /// (see detail_popup.dart's `_bookNow`) — pulls the code back out so the
  /// real airline logo shows instead of a generic route icon.
  String _routeAirlineCode(FlightRouteSegment route) {
    final sep = route.flightNo.indexOf('•');
    return (sep > 0 ? route.flightNo.substring(0, sep) : route.flightNo).trim();
  }

  Widget _routeBadgeCompact(BuildContext context) {
    final route = widget.route!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AirlineLogo(code: _routeAirlineCode(route), name: route.airline, size: context.w(24), borderRadius: BorderRadius.circular(context.r(8))),
        SizedBox(width: context.w(8)),
        Text(
          '${route.from} - ${route.to}',
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
        gradient: LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [paleBlue, Colors.white],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              route != null
                  ? AirlineLogo(code: _routeAirlineCode(route), name: route.airline, size: context.w(38), borderRadius: BorderRadius.circular(context.r(8)))
                  : Container(
                      width: context.w(38),
                      height: context.w(38),
                      padding: EdgeInsets.all(context.w(10)),
                      decoration: BoxDecoration(color: const Color(0xFF000080), borderRadius: BorderRadius.circular(context.r(8))),
                      child: Image.asset('assets/NewIcons/oneWay.png', color: Colors.white, fit: BoxFit.contain),
                    ),
              SizedBox(width: context.w(16)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    route != null ? '${route.from} - ${route.to}' : 'Select flight',
                    style: TextStyle(color: _title900, fontSize: context.fs(18), fontWeight: FontWeight.w700),
                  ),
                  if (route != null)
                    Text(
                      '${route.from} to ${route.to}',
                      style: TextStyle(color: _title900, fontSize: context.fs(12)),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== TAB BAR (Figma: SEATS / MEALS / BAGGAGE) ====================
  Widget _tabBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
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
                    border: Border(
                      bottom: BorderSide(
                        color: currentIndex == i ? AppColors.AppBlue : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    _tabLabels[i],
                    style: TextStyle(
                      color: currentIndex == i ? AppColors.AppBlue : AppColors.subhead,
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

  // ==================== BOTTOM BAR (Figma: total + Continue/Proceed to Payment) ====================
  Widget _bottomBar(BuildContext context) {
    final isLastTab = currentIndex == _tabLabels.length - 1;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.w(19), vertical: context.h(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, -4)),
        ],
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
                  '₹ ${_runningTotal.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: _title900,
                    fontSize: context.fs(24),
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
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
              onPressed: isLastTab ? _navigateToPayment : nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.OrangeColor,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: context.w(20)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(12))),
              ),
              child: Text(
                isLastTab ? 'PROCEED TO PAYMENT' : 'CONTINUE',
                style: TextStyle(color: Colors.white, fontSize: context.fs(14), fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
