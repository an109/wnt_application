import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../injection_container.dart';
import '../../data/diy_holiday_api.dart';
import '../../data/diy_search_query.dart';
import '../../data/models/diy_models.dart';
import '../widgets/diy_common.dart';
import '../widgets/diy_itinerary.dart';
import 'diy_addons_screen.dart';
import 'diy_enquiry_screen.dart';
import 'diy_trip_screen.dart';

/// The saved package — **API 4: GET /packages/{share_id}/?flight=with|without**.
///
/// A land package opens here at its fixed price. One sold with flights opens
/// here only for a moment: [priceLiveOnOpen] sends it straight on to the live
/// price for the customer's city and date.
///
/// From here the customer can:
///  * pick add-ons and see a live quote — **API 14: POST /customise/** —
///    without a trip being created;
///  * reprice against their own dates, which creates the trip —
///    **API 5: POST /price/** — and opens the customise screen;
///  * or send an enquiry straight away — **API 15: POST /enquiry/**.
class DiyPackageDetailScreen extends StatefulWidget {
  final String shareId;
  final DiySearchQuery query;
  final bool withFlight;
  final String previewImage;

  /// Go straight to the live price once the package has loaded — how a
  /// package sold with flights opens: the fares are searched from the
  /// customer's city on their date, and the trip screen shows the real cost.
  final bool priceLiveOnOpen;

  const DiyPackageDetailScreen({
    super.key,
    required this.shareId,
    required this.query,
    this.withFlight = true,
    this.previewImage = '',
    this.priceLiveOnOpen = false,
  });

  @override
  State<DiyPackageDetailScreen> createState() => _DiyPackageDetailScreenState();
}

class _DiyPackageDetailScreenState extends State<DiyPackageDetailScreen> {
  final DiyHolidayApi _api = sl<DiyHolidayApi>();

  late bool _withFlight;
  DiyPackageDetail? _package;
  bool _loading = true;
  String? _error;

  List<DiyAddon> _addons = const [];
  final Set<String> _selectedAddons = {};
  DiyCustomiseQuote? _quote;
  bool _quoting = false;
  Timer? _quoteDebounce;

  bool _creatingTrip = false;
  bool _pricedOnOpen = false;

  @override
  void initState() {
    super.initState();
    _withFlight = widget.withFlight;
    _load();
  }

  @override
  void dispose() {
    _quoteDebounce?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.getPackage(widget.shareId, withFlight: _withFlight),
        // The add-ons list is per package, not per flight mode — fetch once.
        if (_addons.isEmpty)
          _api.getAddons(widget.shareId)
        else
          Future.value(_addons),
      ]);
      if (!mounted) return;
      final package = results[0] as DiyPackageDetail;
      setState(() {
        _package = package;
        _addons = results[1] as List<DiyAddon>;
        // Flights only on a package saved with them, and only when the
        // customer chose them — a land package has none to price.
        _withFlight = package.includesFlight && widget.withFlight;
        _loading = false;
      });
      if (widget.priceLiveOnOpen && !_pricedOnOpen) {
        _pricedOnOpen = true;
        _customiseForMyDates(replace: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ------------------------------------------------- API 14: customise

  void _requestQuote() {
    _quoteDebounce?.cancel();
    if (_selectedAddons.isEmpty) {
      setState(() => _quote = null);
      return;
    }
    _quoteDebounce = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      setState(() => _quoting = true);
      try {
        final quote = await _api.customise(
          shareId: widget.shareId,
          addOnIds: _selectedAddons.toList(),
          withFlight: _withFlight,
        );
        if (mounted) setState(() => _quote = quote);
      } catch (e) {
        if (mounted) diySnack(context, e.toString(), isError: true);
      } finally {
        if (mounted) setState(() => _quoting = false);
      }
    });
  }

  Future<void> _openAddons() async {
    final result = await Navigator.of(context).push<Set<String>>(
      MaterialPageRoute(
        builder: (_) => DiyAddonsPickerScreen(
          addons: _addons,
          initiallySelected: _selectedAddons,
          currency: _package?.currency ?? 'INR',
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _selectedAddons
        ..clear()
        ..addAll(result);
    });
    _requestQuote();
  }

  // -------------------------------------- API 5: real price → creates trip

  /// [replace] swaps this screen for the trip, so back from the live price
  /// returns to the results rather than to a package page nobody asked for.
  Future<void> _customiseForMyDates({bool replace = false}) async {
    final date = widget.query.departureDate;
    if (date == null) {
      diySnack(context, 'Pick a starting date first', isError: true);
      return;
    }

    setState(() => _creatingTrip = true);
    try {
      final trip = await _api.priceForDates(
        shareId: widget.shareId,
        departureDate: date,
        adults: widget.query.adults,
        children: widget.query.children,
        rooms: widget.query.roomsPayload,
        // The customer's own city: the flights are searched from here, not
        // from wherever the package happened to be saved.
        origin: widget.query.origin.slug,
        withFlight: _withFlight,
      );
      if (!mounted) return;
      final route = MaterialPageRoute<void>(
        builder: (_) => DiyTripScreen(
          trip: trip,
          query: widget.query,
          shareId: widget.shareId,
          addons: _addons,
          preselectedAddonIds: _selectedAddons.toList(),
          canAddFlights: _package?.includesFlight ?? false,
        ),
      );
      if (replace) {
        Navigator.of(context).pushReplacement(route);
      } else {
        Navigator.of(context).push(route);
      }
    } catch (e) {
      if (mounted) diySnack(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _creatingTrip = false);
    }
  }

  void _sendEnquiry() {
    final package = _package;
    if (package == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DiyEnquiryScreen(
          shareId: widget.shareId,
          query: widget.query,
          withFlight: _withFlight,
          addOnIds: _selectedAddons.toList(),
          quotedTotal: _currentTotal,
          currency: package.currency,
          packageTitle: package.title,
        ),
      ),
    );
  }

  double get _currentTotal {
    final quote = _quote;
    if (quote != null && quote.total > 0) return quote.total;
    final package = _package;
    if (package == null) return 0;
    return _withFlight ? package.priceWithFlight : package.priceWithoutFlight;
  }

  // ------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    if (_creatingTrip) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: diyAppBar(context, title: 'Pricing your trip'),
        body: DiyLoading(
          message: _withFlight
              ? 'Searching live flights from ${widget.query.origin.name}…'
              : 'Preparing your package…',
          hint: _withFlight
              ? 'Flight pricing takes a few seconds.'
              : null,
        ),
      );
    }

    return Scaffold(
      backgroundColor: DiyTokens.pageBg,
      body: _loading
          ? const DiyLoading(message: 'Loading package…')
          : _error != null
              ? DiyErrorView(message: _error!, onRetry: _load)
              : _content(),
      bottomNavigationBar: _loading || _error != null ? null : _bottomBar(),
    );
  }

  Widget _content() {
    final package = _package!;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: context.h(210),
          pinned: true,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                DiyImage(url: widget.previewImage),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.55),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: context.w(16),
                  right: context.w(16),
                  bottom: context.h(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        package.title,
                        style: TextStyle(
                          fontSize: context.fs(19),
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: context.h(3)),
                      Text(
                        '${package.origin} → ${package.destination} · '
                        '${package.nights} night'
                        '${package.nights == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: context.fs(12),
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              context.w(14),
              context.h(14),
              context.w(14),
              context.h(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _packageTypeNote(package),
                SizedBox(height: context.h(12)),
                _summaryStrip(package),
                if (package.cab.isIncluded) ...[
                  SizedBox(height: context.h(12)),
                  _cabStrip(package.cab),
                ],
                SizedBox(height: context.h(12)),
                _addonsStrip(package),
                SizedBox(height: context.h(4)),
                Text(
                  'Itinerary',
                  style: TextStyle(
                    fontSize: context.fs(16),
                    fontWeight: FontWeight.w800,
                    color: DiyTokens.navy,
                  ),
                ),
                DiyItinerary(days: package.days),
                if (package.validUntil.isNotEmpty) ...[
                  SizedBox(height: context.h(6)),
                  Text(
                    'Published price valid until ${package.validUntil}. '
                    'Your own dates are priced live in the next step.',
                    style: TextStyle(
                      fontSize: context.fs(11),
                      color: DiyTokens.subGrey,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// What kind of package this is, in one line: a land package is sold as
  /// shown, one with flights has its air priced live in the next step.
  Widget _packageTypeNote(DiyPackageDetail package) {
    final live = _withFlight;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: context.w(12),
        vertical: context.h(10),
      ),
      decoration: BoxDecoration(
        color: live ? const Color(0xFFE8F4FC) : const Color(0xFFF1F8EE),
        borderRadius: BorderRadius.circular(context.r(10)),
      ),
      child: Row(
        children: [
          Icon(
            live ? Icons.flight_takeoff : Icons.landscape_rounded,
            size: context.w(18),
            color: live ? DiyTokens.blue : const Color(0xFF3B8B3A),
          ),
          SizedBox(width: context.w(10)),
          Expanded(
            child: Text(
              live
                  ? 'Flights from ${widget.query.origin.name} are priced live '
                      'for your date in the next step.'
                  : package.includesFlight
                      ? 'Without flights — hotels, transfers, sightseeing and '
                          'activities at a fixed price.'
                      : 'Land package — hotels, transfers, sightseeing and '
                          'activities at a fixed price.',
              style: TextStyle(fontSize: context.fs(12), color: DiyTokens.navy),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryStrip(DiyPackageDetail package) {
    final counts = package.counts;
    final items = <List<dynamic>>[
      [Icons.calendar_month_rounded, '${counts.days}', 'Days'],
      [Icons.flight_rounded, '${counts.flights}', 'Flights'],
      [Icons.hotel_rounded, '${counts.hotels}', 'Hotels'],
      [Icons.directions_car_filled_rounded, '${counts.transfers}', 'Transfers'],
      [Icons.local_activity_rounded, '${counts.activities}', 'Activities'],
      [Icons.restaurant_rounded, '${counts.meals}', 'Meals'],
    ];

    return Container(
      padding: EdgeInsets.symmetric(vertical: context.h(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: DiyTokens.line),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        runSpacing: context.h(10),
        children: [
          for (final item in items)
            SizedBox(
              width: context.w(100),
              child: Column(
                children: [
                  Icon(
                    item[0] as IconData,
                    size: context.w(18),
                    color: DiyTokens.blue,
                  ),
                  SizedBox(height: context.h(4)),
                  Text(
                    item[1] as String,
                    style: TextStyle(
                      fontSize: context.fs(14),
                      fontWeight: FontWeight.w700,
                      color: DiyTokens.navy,
                    ),
                  ),
                  Text(
                    item[2] as String,
                    style: TextStyle(
                      fontSize: context.fs(10),
                      color: DiyTokens.subGrey,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _cabStrip(DiyCab cab) {
    return Container(
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: DiyTokens.line),
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_taxi_rounded,
            size: context.w(20),
            color: DiyTokens.blue,
          ),
          SizedBox(width: context.w(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cab included · ${cab.selected}',
                  style: TextStyle(
                    fontSize: context.fs(13),
                    fontWeight: FontWeight.w700,
                    color: DiyTokens.navy,
                  ),
                ),
                Text(
                  '${cab.label} · ${cab.seats} seats · ${cab.luggage} bags',
                  style: TextStyle(
                    fontSize: context.fs(11),
                    color: DiyTokens.subGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _addonsStrip(DiyPackageDetail package) {
    return GestureDetector(
      onTap: _addons.isEmpty ? null : _openAddons,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.all(context.w(12)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.r(12)),
          border: Border.all(color: DiyTokens.line),
        ),
        child: Row(
          children: [
            Icon(
              Icons.add_circle_outline_rounded,
              size: context.w(20),
              color: DiyTokens.orange,
            ),
            SizedBox(width: context.w(10)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add-on experiences',
                    style: TextStyle(
                      fontSize: context.fs(13),
                      fontWeight: FontWeight.w700,
                      color: DiyTokens.navy,
                    ),
                  ),
                  Text(
                    _selectedAddons.isEmpty
                        ? '${_addons.length} available for ${package.destination}'
                        : '${_selectedAddons.length} selected',
                    style: TextStyle(
                      fontSize: context.fs(11),
                      color: DiyTokens.subGrey,
                    ),
                  ),
                ],
              ),
            ),
            if (_quoting)
              SizedBox(
                width: context.w(16),
                height: context.w(16),
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                color: DiyTokens.labelGrey,
                size: context.w(20),
              ),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar() {
    final package = _package!;
    return Container(
      padding: EdgeInsets.fromLTRB(
        context.w(14),
        context.h(10),
        context.w(14),
        context.h(10) + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: DiyTokens.line)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _quote != null
                          ? 'With your add-ons'
                          : _withFlight
                              ? 'Starting from'
                              : 'Fixed price',
                      style: TextStyle(
                        fontSize: context.fs(10),
                        color: DiyTokens.labelGrey,
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: diyMoney(
                              package.adults > 0
                                  ? _currentTotal / package.adults
                                  : _currentTotal,
                              currency: package.currency,
                            ),
                            style: TextStyle(
                              fontSize: context.fs(20),
                              fontWeight: FontWeight.w800,
                              color: DiyTokens.navy,
                            ),
                          ),
                          TextSpan(
                            text: '/person',
                            style: TextStyle(
                              fontSize: context.fs(10),
                              fontWeight: FontWeight.w600,
                              color: DiyTokens.subGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Total ${diyMoney(_currentTotal, currency: package.currency)}',
                      style: TextStyle(
                        fontSize: context.fs(10),
                        color: DiyTokens.subGrey,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: context.w(190),
                child: DiyPrimaryButton(
                  label: _withFlight ? 'GET LIVE PRICE' : 'CONTINUE',
                  onPressed: _customiseForMyDates,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(6)),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _sendEnquiry,
              child: Text(
                'Talk to a consultant instead',
                style: TextStyle(
                  fontSize: context.fs(12.5),
                  fontWeight: FontWeight.w600,
                  color: DiyTokens.blue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
