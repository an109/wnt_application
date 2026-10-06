import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/common_widgets/compact_date_picker_dialog.dart';
import 'package:wander_nova/common_widgets/currency_chip.dart';
import 'package:wander_nova/core/resources/app_colours.dart';
import '../../../../core/error/data_state.dart';
import '../../../../core/utils/storage/shared_preference.dart';
import '../../../../injection_container.dart';
import '../../../../newUIWidgets/shine.dart';
import '../../domain/entities/airport_entities.dart';
import '../bloc/airport_bloc.dart';
import '../bloc/airport_event.dart';
import '../../../AKFlight_tui/domain/entity/akflight_search_entity.dart';
import '../../../AKFlight_tui/domain/usecase/akflight_search_usecase.dart';
import '../../../flight_search/domain/entities/fare_trip_type.dart';
import '../../../flight_search/presentation/screen/flight_search_screen.dart';
import '../../../home/flight/flight_calendar_screen.dart';
import 'destination_search_screen.dart';
import 'package:wander_nova/common_widgets/app_surface.dart';

const String _homeCountryCode = 'IN';

const String _icOneWay = 'assets/NewIcons/oneWay.png';
const String _icRoundTrip = 'assets/NewIcons/roundTrip.png';
const String _icMultiCity = 'assets/NewIcons/multicity.png';
const String _icFrom = 'assets/NewIcons/from.png';
const String _icTo = 'assets/NewIcons/to.png';
const String _icDepartureCalendar = 'assets/NewIcons/departureCalendar.png';
const String _icReturnCalendar = 'assets/Newimage/CA.png';
const String _icTravellerAdult = 'assets/NewIcons/TravellerAdult.png';
const String _icTravellerChild = 'assets/NewIcons/TravellerChild.png';
const String _icTravellerBaby = 'assets/NewIcons/TravellerBaby.png';
const String _icSeat = 'assets/NewIcons/seat.png';

const int _maxMultiCityLegs = 6;

/// Route the search card opens on when the user has no previous search to
/// restore — the busiest domestic pair, so a first-time user can hit Search
/// straight away instead of being sent to the picker before anything works.
/// Both are overwritten the moment a saved search exists, and the user can
/// change either field as normal.
///
/// Hardcoded rather than looked up from the airports API: the whole point is
/// to have a usable route on the very first frame, including when that call
/// is slow or offline. The values match what `flights/airports` returns for
/// these two codes.
const AirportEntity _kDefaultFromAirport = AirportEntity(
  airportCode: 'DEL',
  airportName: 'Indira Gandhi International Airport',
  cityCode: 'DEL',
  cityName: 'New Delhi',
  countryCode: 'IN',
);

const AirportEntity _kDefaultToAirport = AirportEntity(
  airportCode: 'BOM',
  airportName: 'Chhatrapati Shivaji International Airport',
  cityCode: 'BOM',
  cityName: 'Mumbai',
  countryCode: 'IN',
);

const Color _kSubGrey = Color(0xFF7A8494);
const Color _kPageBg = Color(0xFFF8F9FA);
const Color _kMutedText = Color(0xFF757575);
const Color _kTripBarBg = Color(0xFFEEF3FA);

class _MultiCityLeg {
  AirportEntity? from;
  AirportEntity? to;
  DateTime? date;
}

class SearchCard extends StatefulWidget {
  const SearchCard({super.key});

  @override
  State<SearchCard> createState() => _SearchCardState();
}

class _SearchCardState extends State<SearchCard> {
  bool isRoundTrip = false;
  bool isSpecialFare = false;
  bool isMultiCityMode = false;
  List<_MultiCityLeg> multiCityLegs = [];

  AirportEntity? fromAirport;
  AirportEntity? toAirport;
  DateTime? departureDate;
  DateTime? returnDate;

  int adults = 1;
  int children = 0;
  int infants = 0;
  String travelClass = "Economy";
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Departure always opens on today regardless of trip type; the saved
    // search below deliberately no longer overrides it.
    departureDate = DateUtils.dateOnly(DateTime.now());
    // Applied before the (async) saved search loads so the first frame shows
    // a real route instead of "Select" flashing into place a moment later.
    _applyDefaultRoute();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AirportBloc>().add(LoadAirports());
    });
    _loadLastSearch();
  }

  Future<void> _saveSearchToPreferences() async {
    final prefsManager = await PreferencesManager.create(
      await SharedPreferences.getInstance(),
    );

    final searchData = {
      'fromAirport': {
        'code': fromAirport?.airportCode,
        'city': fromAirport?.cityName,
        'name': fromAirport?.airportName,
        'cityCode': fromAirport?.cityCode,
        'countryCode': fromAirport?.countryCode,
      },
      'toAirport': {
        'code': toAirport?.airportCode,
        'city': toAirport?.cityName,
        'name': toAirport?.airportName,
        'cityCode': toAirport?.cityCode,
        'countryCode': toAirport?.countryCode,
      },
      'departureDate': departureDate?.toIso8601String(),
      'returnDate': returnDate?.toIso8601String(),
      'isRoundTrip': isRoundTrip,
      'isSpecialFare': isSpecialFare,
      'adults': adults,
      'children': children,
      'infants': infants,
      'travelClass': travelClass,
      'totalTravellers': adults + children + infants,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await prefsManager.saveLastSearch(searchData);
    await prefsManager.addToSearchHistory(searchData);
  }

  Future<void> _loadLastSearch() async {
    try {
      final prefsManager = await PreferencesManager.create(
        await SharedPreferences.getInstance(),
      );
      final lastSearch = prefsManager.getLastSearch();

      if (lastSearch == null || !mounted) return;

      final savedFromAirport = _airportFromJson(lastSearch['fromAirport']);
      var savedToAirport = _airportFromJson(lastSearch['toAirport']);

      if (savedFromAirport != null &&
          savedToAirport != null &&
          savedFromAirport.airportCode == savedToAirport.airportCode) {
        savedToAirport = null;
      }

      setState(() {
        // Assigned unconditionally, nulls included, so _applyDefaultRoute can
        // tell "the saved search had no origin" from "initState already put
        // the default there" — otherwise a saved airport on one side could
        // collide with a pre-seeded default on the other and get dropped.
        fromAirport = savedFromAirport;
        toAirport = savedToAirport;
        _applyDefaultRoute();

        isRoundTrip = lastSearch['isRoundTrip'] ?? false;
        isSpecialFare = lastSearch['isSpecialFare'] ?? false;

        // Dates are deliberately NOT restored: departure always opens on
        // today, and a return date carried over from an older search could
        // easily precede it. The user picks the return leg themselves.

        adults = lastSearch['adults'] ?? 1;
        children = lastSearch['children'] ?? 0;
        infants = lastSearch['infants'] ?? 0;
        travelClass = lastSearch['travelClass'] ?? 'Economy';
      });
    } catch (e) {
      debugPrint('Error loading last search: $e');
    }
  }

  /// Fills whichever of origin/destination is still unknown with the default
  /// route, so the card is never left showing "Select".
  ///
  /// Each gap is filled with the default that doesn't collide with the side
  /// that is already known — a saved search can legitimately restore just one
  /// half (the loader drops a destination matching the origin), and blindly
  /// pairing that with a fixed default could leave both fields on the same
  /// airport, which the search validator rejects. Whatever was already set is
  /// never overwritten.
  void _applyDefaultRoute() {
    fromAirport ??= toAirport?.airportCode == _kDefaultFromAirport.airportCode
        ? _kDefaultToAirport
        : _kDefaultFromAirport;
    toAirport ??= fromAirport!.airportCode == _kDefaultToAirport.airportCode
        ? _kDefaultFromAirport
        : _kDefaultToAirport;
  }

  AirportEntity? _airportFromJson(dynamic json) {
    if (json == null || json['code'] == null) return null;
    return AirportEntity(
      airportCode: json['code'] ?? '',
      airportName: json['name'] ?? '',
      cityName: json['city'] ?? '',
      cityCode: json['cityCode'] ?? '',
      countryCode: json['countryCode'] ?? '',
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontSize: context.bodyMedium)),
        backgroundColor: Colors.red,
      ),
    );
  }

  FareTripType _resolveFareType() {
    if (isMultiCityMode) {
      final allDomestic = multiCityLegs.every(
        (leg) =>
            (leg.from?.countryCode.toUpperCase() ?? '') == _homeCountryCode &&
            (leg.to?.countryCode.toUpperCase() ?? '') == _homeCountryCode,
      );
      return allDomestic
          ? FareTripType.domesticMulticity
          : FareTripType.internationalMulticity;
    }
    if (isRoundTrip) {
      return isSpecialFare
          ? FareTripType.specialReturn
          : FareTripType.roundTrip;
    }
    return FareTripType.oneWay;
  }

  List<TripEntity> _buildTrips() {
    if (isMultiCityMode) {
      return multiCityLegs
          .map(
            (leg) => TripEntity(
              from: leg.from!.airportCode,
              to: leg.to!.airportCode,
              onwardDate: DateFormat('yyyy-MM-dd').format(leg.date!),
            ),
          )
          .toList();
    }
    return [
      TripEntity(
        from: fromAirport!.airportCode,
        to: toAirport!.airportCode,
        onwardDate: DateFormat('yyyy-MM-dd').format(departureDate!),
        returnDate: isRoundTrip && returnDate != null
            ? DateFormat('yyyy-MM-dd').format(returnDate!)
            : null,
      ),
    ];
  }

  bool _validateBeforeSearch() {
    if (isMultiCityMode) {
      for (var i = 0; i < multiCityLegs.length; i++) {
        final leg = multiCityLegs[i];
        if (leg.from == null || leg.to == null || leg.date == null) {
          _showError('Please complete all details for Flight ${i + 1}');
          return false;
        }
        if (leg.from!.airportCode == leg.to!.airportCode) {
          _showError(
            'Origin and destination cannot be the same airport for Flight ${i + 1}',
          );
          return false;
        }
      }
      return true;
    }

    if (fromAirport == null || toAirport == null || departureDate == null) {
      _showError('Please fill in all required fields');
      return false;
    }
    if (isRoundTrip && returnDate == null) {
      _showError('Please select return date for round trip');
      return false;
    }
    return true;
  }

  void _performSearch() async {
    /// REMOVE THIS WHEN MULTI-CITY WILL WORK
    if (isMultiCityMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Multi-city search coming soon!'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (!_validateBeforeSearch()) return;

    setState(() => _isSearching = true);

    try {
      await _saveSearchToPreferences();

      final fareType = _resolveFareType();

      final tuiRequest = FlightSearchRequestEntity(
        adults: adults,
        children: children,
        infants: infants,
        cabin: _cabinCode(travelClass),
        fareType: fareType.wireValue,
        trips: _buildTrips(),
      );

      final result = await sl<AkFlightSearchUseCase>().call(tuiRequest);

      if (!mounted) return;

      if (result is DataSuccess<AkFlightSearchEntity> && result.data != null) {
        final firstLeg = isMultiCityMode ? multiCityLegs.first : null;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FlightSearchScreen(
              tui: result.data!.tui,
              from: isMultiCityMode
                  ? firstLeg!.from!.cityName
                  : fromAirport!.cityName,
              to: isMultiCityMode
                  ? firstLeg!.to!.cityName
                  : toAirport!.cityName,
              fromCode: isMultiCityMode
                  ? firstLeg!.from!.airportCode
                  : fromAirport!.airportCode,
              toCode: isMultiCityMode
                  ? firstLeg!.to!.airportCode
                  : toAirport!.airportCode,
              fromAirport: isMultiCityMode
                  ? firstLeg!.from!.airportName
                  : fromAirport!.airportName,
              toAirport: isMultiCityMode
                  ? firstLeg!.to!.airportName
                  : toAirport!.airportName,
              date: isMultiCityMode ? firstLeg!.date : departureDate,
              travellers: adults + children + infants,
              adults: adults,
              children: children,
              infants: infants,
              travelClass: travelClass,
              isRoundTrip: isRoundTrip && !isMultiCityMode,
              returnDate: returnDate,
              fareType: fareType.wireValue,
              multiCityLegs: isMultiCityMode
                  ? multiCityLegs
                        .map(
                          (leg) => MultiCityLegSummary(
                            from: leg.from!.cityName,
                            to: leg.to!.cityName,
                            fromCode: leg.from!.airportCode,
                            toCode: leg.to!.airportCode,
                            date: leg.date!,
                          ),
                        )
                        .toList()
                  : null,
            ),
          ),
        );
      } else {
        _showError(result.error?.message ?? 'Failed to search flights');
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  String _cabinCode(String travelClass) {
    switch (travelClass) {
      case 'Premium Economy':
        return 'PE';
      case 'Business':
        return 'B';
      case 'First':
        return 'F';
      default:
        return 'E';
    }
  }

  void _swapAirports() {
    setState(() {
      final temp = fromAirport;
      fromAirport = toAirport;
      toAirport = temp;
    });
  }

  /// Flight 1 of a multi-city trip opens on the same route and departure
  /// date the one-way/round-trip form was showing, so switching tabs carries
  /// the work over instead of dropping the user onto an empty leg. Legs the
  /// user adds afterwards stay blank — those routes are genuinely unknown.
  _MultiCityLeg _buildSeededFirstLeg() {
    return _MultiCityLeg()
      ..from = fromAirport
      ..to = toAirport
      ..date = departureDate ?? DateUtils.dateOnly(DateTime.now());
  }

  void _swapMultiCityLeg(int index) {
    setState(() {
      final leg = multiCityLegs[index];
      final temp = leg.from;
      leg.from = leg.to;
      leg.to = temp;
    });
  }

  Future<void> _openDestinationSearch({required bool startWithFrom}) async {
    final result = await Navigator.of(context)
        .push<Map<String, AirportEntity?>>(
          MaterialPageRoute(
            builder: (_) => DestinationSearchScreen(
              initialFrom: fromAirport,
              initialTo: toAirport,
              startWithFrom: startWithFrom,
            ),
          ),
        );
    if (result == null || !mounted) return;
    setState(() {
      fromAirport = result['from'];
      toAirport = result['to'];
    });
  }

  Future<void> _openMultiCityDestinationSearch(
    int index, {
    required bool startWithFrom,
  }) async {
    final leg = multiCityLegs[index];
    final result = await Navigator.of(context)
        .push<Map<String, AirportEntity?>>(
          MaterialPageRoute(
            builder: (_) => DestinationSearchScreen(
              initialFrom: leg.from,
              initialTo: leg.to,
              startWithFrom: startWithFrom,
            ),
          ),
        );
    if (result == null || !mounted) return;
    setState(() {
      leg.from = result['from'];
      leg.to = result['to'];
    });
  }

  void _pickMultiCityDate(int index) async {
    final leg = multiCityLegs[index];
    final minDate = index == 0
        ? DateUtils.dateOnly(DateTime.now())
        : (multiCityLegs[index - 1].date ?? DateUtils.dateOnly(DateTime.now()));
    final initial = leg.date != null && !leg.date!.isBefore(minDate)
        ? leg.date!
        : minDate;

    final picked = await showDialog<DateTime>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => CompactDatePickerDialog(
        initialDate: initial,
        firstDate: minDate,
        lastDate: DateTime(2030, 12, 31),
      ),
    );

    if (picked == null || !mounted) return;

    setState(() {
      leg.date = picked;
      // A later leg's date can't precede this one anymore — clear it so
      // the user re-confirms it rather than silently booking it out of order.
      for (var i = index + 1; i < multiCityLegs.length; i++) {
        final laterLeg = multiCityLegs[i];
        final previousDate = multiCityLegs[i - 1].date;
        if (laterLeg.date != null &&
            previousDate != null &&
            laterLeg.date!.isBefore(previousDate)) {
          laterLeg.date = null;
        }
      }
    });
  }

  // ---------------------------------------------------------------- BUILD
  // Layout and sizes follow the "main Flight one way" Figma frame (412px
  // wide, hence `context.fx`): white page, light trip-type bar, white cards.

  @override
  Widget build(BuildContext context) {
    final gutter = EdgeInsets.symmetric(horizontal: context.fx(16));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: context.statusBarHeight + context.fx(16)),
        Padding(padding: gutter, child: _buildTopBar()),
        SizedBox(height: context.fx(8)),
        // Search form on the plain white page; the cards carry the
        // #E2F6FF shadow (kRaisedCardShadow).
        Padding(
          padding: EdgeInsets.symmetric(vertical: context.fx(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(padding: gutter, child: _buildTripTypeSelector()),
              if (isRoundTrip && !isMultiCityMode) ...[
                SizedBox(height: context.fx(12)),
                Padding(padding: gutter, child: _specialFareCheckbox()),
              ],
              SizedBox(height: context.fx(24)),
              if (isMultiCityMode)
                Padding(padding: gutter, child: _buildMultiCityLegs())
              else ...[
                Padding(padding: gutter, child: _buildFromToCard()),
                SizedBox(height: context.fx(12)),
                Padding(
                  padding: gutter,
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _buildDateCard(
                            label: "DEPARTURE",
                            iconAsset: _icDepartureCalendar,
                            date: departureDate,
                            placeholder: "Select date",
                            subPlaceholder: "-",
                            iconColor: AppColors.AppBlue,
                            onTap: () => _pickDate(isReturn: false),
                          ),
                        ),
                        SizedBox(width: context.fx(12)),
                        Expanded(
                          child: _buildDateCard(
                            label: "RETURN",
                            iconAsset: _icReturnCalendar,
                            date: isRoundTrip ? returnDate : null,
                            placeholder: "Own Way",
                            subPlaceholder: "-",
                            onTap: () {
                              if (!isRoundTrip) {
                                setState(() => isRoundTrip = true);
                              }
                              _pickDate(isReturn: true);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              SizedBox(height: context.fx(12)),
              Padding(
                padding: gutter,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _buildTravellersCard()),
                      SizedBox(width: context.fx(12)),
                      Expanded(child: _buildCabinClassCard()),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: context.fx(20)),
        _buildSearchButton(),
        SizedBox(height: context.fx(8)),
      ],
    );
  }

  // --------------------------------------------------------------- TOP BAR

  Widget _buildTopBar() {
    return SizedBox(
      height: context.fx(36),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Back',
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: context.fx(6)),
                child: Icon(
                  Icons.arrow_back,
                  size: context.fx(24),
                  color: Colors.black,
                ),
              ),
            ),
          ),
          SizedBox(width: context.fx(16)),
          Text(
            'Flight',
            style: TextStyle(
              fontSize: context.ffs(20),
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          const CurrencyChip(),
          SizedBox(width: context.fx(16)),
          SvgPicture.asset(
            'assets/home/notification.svg',
            width: context.fx(24),
            height: context.fx(24),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------- TRIP TYPE PILLS

  Widget _buildTripTypeSelector() {
    return Container(
      padding: EdgeInsets.all(context.fx(8)),
      decoration: BoxDecoration(
        color: _kTripBarBg,
        borderRadius: BorderRadius.circular(context.fx(26)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _tripTypeButton(
              iconAsset: _icOneWay,
              label: "One Way",
              isSelected: !isRoundTrip && !isMultiCityMode,
              onTap: () => setState(() {
                isRoundTrip = false;
                isMultiCityMode = false;
                returnDate = null;
              }),
            ),
          ),
          Expanded(
            child: _tripTypeButton(
              iconAsset: _icRoundTrip,
              label: "Round Trip",
              isSelected: isRoundTrip && !isMultiCityMode,
              onTap: () => setState(() {
                isRoundTrip = true;
                isMultiCityMode = false;
              }),
            ),
          ),
          Expanded(
            child: _tripTypeButton(
              iconAsset: _icMultiCity,
              label: "Multi-city",
              isSelected: isMultiCityMode,
              onTap: () => setState(() {
                isMultiCityMode = true;
                if (multiCityLegs.isEmpty) {
                  multiCityLegs = [_buildSeededFirstLeg()];
                }
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tripTypeButton({
    required String iconAsset,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final color = isSelected ? AppColors.AppBlue : _kMutedText;
    return Semantics(
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: context.fx(34),
          padding: EdgeInsets.symmetric(horizontal: context.fx(6)),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(context.fx(17)),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  iconAsset,
                  width: context.fx(16),
                  height: context.fx(16),
                  fit: BoxFit.contain,
                  color: color,
                ),
                SizedBox(width: context.fx(6)),
                Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: context.ffs(14),
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------ FROM / TO

  // Figma drop shadow (see kRaisedCardShadow) — the cards' raised look.
  BoxDecoration get _cardDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(context.fx(12)),
    boxShadow: kRaisedCardShadow,
  );

  /// Small grey caps heading, with an optional chevron (dropdown-style
  /// fields like FROM/TO/dates show it; plain display fields like
  /// TRAVELLERS/CABIN CLASS don't).
  Widget _cardLabel(String text, {bool showChevron = true}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: context.ffs(9),
            fontWeight: FontWeight.w600,
            color: _kMutedText,
            letterSpacing: 0.6,
          ),
        ),
        if (showChevron) ...[
          SizedBox(width: context.fx(4)),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            size: context.fx(14),
            color: _kMutedText,
          ),
        ],
      ],
    );
  }

  /// FROM and TO live in ONE card, side by side, with the swap button between.
  Widget _buildFromToCard() {
    return Container(
      decoration: _cardDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: _airportField(
              title: "FROM",
              iconAsset: _icFrom,
              airport: fromAirport,
              onTap: () => _openDestinationSearch(startWithFrom: true),
            ),
          ),
          _swapButton(),
          Expanded(
            child: _airportField(
              title: "TO",
              iconAsset: _icTo,
              airport: toAirport,
              onTap: () => _openDestinationSearch(startWithFrom: false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _swapButton({VoidCallback? onTap}) {
    return Semantics(
      button: true,
      label: 'Swap origin and destination',
      child: GestureDetector(
        onTap: onTap ?? _swapAirports,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: context.fx(32),
          height: context.fx(32),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.all(context.fx(8)),
          child: Image.asset(
            'assets/NewIcons/flip.png',
            fit: BoxFit.contain,
            color: AppColors.AppBlue,
          ),
        ),
      ),
    );
  }

  Widget _airportField({
    required String title,
    required String iconAsset,
    required AirportEntity? airport,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(context.fx(12)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          context.fx(12),
          context.fx(12),
          context.fx(6),
          context.fx(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _cardLabel(title),
            SizedBox(height: context.fx(6)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  iconAsset,
                  width: context.fx(26),
                  height: context.fx(26),
                  fit: BoxFit.contain,
                  color: AppColors.AppBlue,
                ),
                SizedBox(width: context.fx(8)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: airport?.cityName ?? "Select",
                              style: TextStyle(
                                fontSize: context.ffs(12),
                                fontWeight: FontWeight.w600,
                                color: airport != null
                                    ? Colors.black
                                    : Colors.grey.shade400,
                              ),
                            ),
                            if (airport != null)
                              TextSpan(
                                text: " (${airport.airportCode})",
                                style: TextStyle(
                                  fontSize: context.ffs(8),
                                  fontWeight: FontWeight.w500,
                                  color: _kMutedText,
                                ),
                              ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: context.fx(2)),
                      Text(
                        airport?.airportName ?? "Search airports",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: context.ffs(10),
                          color: airport != null
                              ? _kMutedText
                              : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------- SPECIAL FARE

  Widget _specialFareCheckbox() {
    return GestureDetector(
      onTap: () => setState(() => isSpecialFare = !isSpecialFare),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.fx(12),
          vertical: context.fx(8),
        ),
        decoration: BoxDecoration(
          color: _kTripBarBg,
          borderRadius: BorderRadius.circular(context.fx(10)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: context.fx(18),
              height: context.fx(18),
              child: Checkbox(
                value: isSpecialFare,
                activeColor: AppColors.AppBlue,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                onChanged: (val) =>
                    setState(() => isSpecialFare = val ?? false),
              ),
            ),
            SizedBox(width: context.fx(8)),
            Expanded(
              child: Text(
                "Special Fare (student / senior citizen / armed forces)",
                style: TextStyle(
                  fontSize: context.ffs(11),
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------- MULTI-CITY

  Widget _buildMultiCityLegs() {
    return Column(
      children: [
        for (var i = 0; i < multiCityLegs.length; i++) ...[
          _multiCityLegFromToCard(i),
          SizedBox(height: context.fx(12)),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _multiCityDateCard(i)),
                SizedBox(width: context.fx(12)),
                Expanded(
                  child: i == multiCityLegs.length - 1
                      ? _multiCityAddCityButton()
                      : _multiCityRemoveButton(i),
                ),
              ],
            ),
          ),
          if (i != multiCityLegs.length - 1) SizedBox(height: context.fx(12)),
        ],
      ],
    );
  }

  Widget _multiCityLegFromToCard(int index) {
    final leg = multiCityLegs[index];
    return Container(
      decoration: _cardDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: _airportField(
              title: "FROM",
              iconAsset: _icFrom,
              airport: leg.from,
              onTap: () =>
                  _openMultiCityDestinationSearch(index, startWithFrom: true),
            ),
          ),
          _swapButton(onTap: () => _swapMultiCityLeg(index)),
          Expanded(
            child: _airportField(
              title: "TO",
              iconAsset: _icTo,
              airport: leg.to,
              onTap: () =>
                  _openMultiCityDestinationSearch(index, startWithFrom: false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _multiCityDateCard(int index) {
    final leg = multiCityLegs[index];
    return _buildDateCard(
      label: "FLIGHT ${index + 1} DATE",
      iconAsset: _icDepartureCalendar,
      iconColor: AppColors.AppBlue,
      date: leg.date,
      placeholder: "Select date",
      subPlaceholder: "-",
      onTap: () => _pickMultiCityDate(index),
    );
  }

  Widget _multiCityAddCityButton() {
    final canAdd = multiCityLegs.length < _maxMultiCityLegs;
    final color = canAdd ? AppColors.AppBlue : Colors.grey.shade400;

    return GestureDetector(
      onTap: canAdd
          ? () => setState(() => multiCityLegs.add(_MultiCityLeg()))
          : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: context.fx(12),
          horizontal: context.fx(12),
        ),
        decoration: BoxDecoration(
          color: canAdd ? const Color(0xFFEFF8FD) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(context.fx(12)),
          border: Border.all(color: color),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: context.fx(16), color: color),
            SizedBox(width: context.fx(4)),
            Text(
              "ADD CITY",
              style: TextStyle(
                fontSize: context.ffs(12),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _multiCityRemoveButton(int index) {
    return GestureDetector(
      onTap: () => setState(() => multiCityLegs.removeAt(index)),
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.fx(12)),
          border: Border.all(color: Colors.red.shade200, width: 1.2),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.close, size: context.fx(16), color: Colors.red.shade400),
            SizedBox(width: context.fx(4)),
            Text(
              "REMOVE",
              style: TextStyle(
                fontSize: context.ffs(12),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: Colors.red.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------- DATE CARDS

  Widget _buildDateCard({
    required String label,
    required String iconAsset,
    required DateTime? date,
    required String placeholder,
    required String subPlaceholder,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.all(context.fx(12)),
        decoration: _cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _cardLabel(label),
            SizedBox(height: context.fx(6)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  iconAsset,
                  width: context.fx(26),
                  height: context.fx(26),
                  fit: BoxFit.contain,
                  color: iconColor,
                ),
                SizedBox(width: context.fx(8)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        date != null
                            ? DateFormat('dd MMM, yy').format(date)
                            : placeholder,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: context.ffs(12),
                          fontWeight: FontWeight.w600,
                          color: date != null || placeholder == "Own Way"
                              ? Colors.black
                              : Colors.grey.shade400,
                        ),
                      ),
                      SizedBox(height: context.fx(2)),
                      Text(
                        date != null
                            ? DateFormat('EEEE').format(date)
                            : subPlaceholder,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: context.ffs(10),
                          color: _kMutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _travellerDivider() {
    return Container(
      width: 0.5,
      height: context.fx(20),
      margin: EdgeInsets.symmetric(horizontal: context.fx(9)),
      color: const Color(0xFFCCCCCC),
    );
  }

  // ------------------------------------------------- TRAVELLERS / CABIN

  Widget _buildTravellersCard() {
    return GestureDetector(
      onTap: _openTravellersDrawer,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.all(context.fx(12)),
        decoration: _cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _cardLabel("TRAVELLERS", showChevron: false),
            SizedBox(height: context.fx(12)),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _travellerIcon(asset: _icTravellerAdult, count: adults),
                  _travellerDivider(),
                  _travellerIcon(asset: _icTravellerChild, count: children),
                  _travellerDivider(),
                  _travellerIcon(asset: _icTravellerBaby, count: infants),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _travellerIcon({required String asset, required int count}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          asset,
          width: context.fx(16),
          height: context.fx(16),
          fit: BoxFit.contain,
          color: AppColors.AppBlue,
        ),
        SizedBox(width: context.fx(8)),
        Text(
          "$count",
          style: TextStyle(
            fontSize: context.ffs(12),
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildCabinClassCard() {
    return GestureDetector(
      onTap: _openCabinClassDrawer,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.all(context.fx(12)),
        decoration: _cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _cardLabel("CABIN CLASS", showChevron: false),
            SizedBox(height: context.fx(12)),
            SizedBox(
              height: context.fx(20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  travelClass,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.ffs(12),
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------- SEARCH BUTTON

  Widget _buildSearchButton() {
    // Inner content shrinks by the shine's thickness so the whole pill
    // (shine + button) measures exactly the Figma 210×42.
    const double shineWidth = 2;

    return Center(
      child: ShineBorderButton(
        enabled: !_isSearching,
        borderRadius: context.fx(21),
        borderWidth: shineWidth,
        shineColor: const Color(0xFFFFE0B2), // warm highlight
        duration: const Duration(seconds: 2, milliseconds: 500),
        child: SizedBox(
          width: context.fx(210) - (shineWidth * 2),
          height: context.fx(42) - (shineWidth * 2),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.orange.withValues(alpha: 0.85),
              elevation: 6,
              shadowColor: AppColors.orange.withValues(alpha: 0.45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.fx(21)),
              ),
              padding: EdgeInsets.symmetric(horizontal: context.fx(8)),
            ),
            onPressed: _isSearching ? null : _performSearch,
            child: _isSearching
                ? SizedBox(
                    width: context.fx(20),
                    height: context.fx(20),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Search Flight",
                          style: TextStyle(
                            fontSize: context.ffs(14),
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: context.fx(10)),
                        Icon(
                          Icons.arrow_forward,
                          size: context.fx(18),
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------- TRAVELLERS DRAWER

  void _openTravellersDrawer() {
    int localAdults = adults;
    int localChildren = children;
    int localInfants = infants;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Close — floating just above the sheet, top right.
                Padding(
                  padding: EdgeInsets.only(
                    right: context.w(20),
                    bottom: context.h(10),
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _sheetCloseButton(sheetContext),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(context.r(24)),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.w(20),
                      context.h(10),
                      context.w(20),
                      context.h(20) +
                          MediaQuery.of(sheetContext).viewInsets.bottom,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(child: _sheetHandle()),
                        SizedBox(height: context.h(20)),
                        Text(
                          "Select Travellers",
                          style: TextStyle(
                            fontSize: context.fs(12),
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                        SizedBox(height: context.h(14)),
                        Text(
                          "ADD NUMBER OF TRAVELLERS",
                          style: TextStyle(
                            fontSize: context.fs(10),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.6,
                            color: AppColors.subhead,
                          ),
                        ),
                        SizedBox(height: context.h(14)),
                        _travellerCounterRow(
                          title: "Adults",
                          badge: "12y+",
                          value: localAdults,
                          minValue: 1,
                          onChanged: (v) =>
                              setSheetState(() => localAdults = v),
                        ),
                        SizedBox(height: context.h(9)),

                        _travellerCounterRow(
                          title: "Children",
                          badge: "2-12y",
                          value: localChildren,
                          minValue: 0,
                          onChanged: (v) =>
                              setSheetState(() => localChildren = v),
                        ),
                        SizedBox(height: context.h(9)),

                        _travellerCounterRow(
                          title: "Infants",
                          badge: "Under 2y",
                          value: localInfants,
                          minValue: 0,
                          onChanged: (v) =>
                              setSheetState(() => localInfants = v),
                        ),
                        SizedBox(height: context.h(18)),
                        _sheetDoneButton(
                          onTap: () {
                            setState(() {
                              adults = localAdults;
                              children = localChildren;
                              infants = localInfants;
                            });
                            Navigator.pop(sheetContext);
                          },
                        ),
                        SizedBox(height: context.h(20)),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _sheetCloseButton(BuildContext ctx) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(ctx).maybePop(),
      child: Container(
        width: context.w(34),
        height: context.w(34),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.close_rounded,
          size: context.w(19),
          color: AppColors.black,
        ),
      ),
    );
  }

  Widget _sheetHandle() {
    return Container(
      width: context.w(103),
      height: context.h(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(context.r(24)),
      ),
    );
  }

  Widget _sheetDoneButton({required VoidCallback onTap}) {
    return SizedBox(
      width: context.w(380),
      height: context.h(44),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.OrangeColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.r(12)),
          ),
        ),
        child: Text(
          "DONE",
          style: TextStyle(
            fontSize: context.fs(14),
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }

  Widget _travellerCounterRow({
    required String title,
    required String badge,
    required int value,
    required int minValue,
    required ValueChanged<int> onChanged,
  }) {
    const int maxValue = 9;
    return Container(
      width: context.w(380),
      height: context.h(80),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFF1F59), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: context.fs(18),
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                    SizedBox(width: context.w(8)),
                    Container(
                      padding: EdgeInsets.fromLTRB(8, 2, 8, 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Color(0xFFF1F5F9),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: context.fs(10),
                          fontWeight: FontWeight.w600,
                          color: AppColors.subhead,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.h(2)),
                Text(
                  "On the day of travel",
                  style: TextStyle(
                    fontSize: context.fs(10),
                    color: AppColors.subhead,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Color(0xFFF8FAFC),
            ),
            child: Row(
              children: [
                _stepperButton(
                  icon: Icons.remove,
                  enabled: value > minValue,
                  onTap: () => onChanged(value - 1),
                ),
                SizedBox(
                  width: context.w(34),
                  child: Text(
                    "$value",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: context.fs(20),
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                _stepperButton(
                  icon: Icons.add,
                  enabled: value < maxValue,
                  onTap: () => onChanged(value + 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepperButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: context.w(40),
        height: context.w(40),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: context.w(14),
          color: enabled ? AppColors.AppBlue : Colors.grey.shade300,
        ),
      ),
    );
  }

  // ------------------------------------------------- CABIN CLASS DRAWER

  void _openCabinClassDrawer() {
    String localClass = travelClass;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.r(24)),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                context.w(20),
                context.h(10),
                context.w(20),
                context.h(20),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: context.screenHeight * 0.8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: _sheetHandle()),
                    SizedBox(height: context.h(14)),
                    Text(
                      "Select Cabin Class",
                      style: TextStyle(
                        fontSize: context.fs(12),
                        fontWeight: FontWeight.w600,
                        color: AppColors.subhead,
                      ),
                    ),
                    SizedBox(height: context.h(20)),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // Added iconAsset for each
                            _cabinOption(
                              title: "Economy/Premium\nEconomy",
                              iconAsset: 'assets/NewIcons/seat.png',
                              // Features is now a list of maps with 'text' and 'icon'
                              features: const [],
                              selected: localClass == "Economy",
                              onTap: () {
                                setSheetState(() => localClass = "Economy");
                                setState(() => travelClass = "Economy");
                                Navigator.pop(sheetContext);
                              },
                            ),
                            _cabinOption(
                              title: "Premium Economy",
                              iconAsset: 'assets/NewIcons/seat1.png',
                              features: const [
                                {
                                  'text': "Extra Legroom",
                                  'icon': 'assets/Newimage/extraLegroom.png',
                                },
                                {
                                  'text': "Extra Baggage",
                                  'icon': 'assets/Newimage/extraLegroom.png',
                                },
                                {
                                  'text': "Premium Meals",
                                  'icon': 'assets/Newimage/premiumMeals.png',
                                },
                              ],
                              selected: localClass == "Premium Economy",
                              onTap: () {
                                setSheetState(
                                  () => localClass = "Premium Economy",
                                );
                                setState(() => travelClass = "Premium Economy");
                                Navigator.pop(sheetContext);
                              },
                            ),
                            _cabinOption(
                              title: "Business Class",
                              iconAsset: 'assets/NewIcons/seat2.png',
                              features: const [
                                {
                                  'text': "Luxury Lounges",
                                  'icon': 'assets/Newimage/Lounges1.png',
                                },
                                {
                                  'text': "Cabin Comfort",
                                  'icon': 'assets/Newimage/sofa.png',
                                },
                                {
                                  'text': "Premium Dining",
                                  'icon': 'assets/Newimage/Dining.png',
                                },
                              ],
                              selected: localClass == "Business",
                              onTap: () {
                                setSheetState(() => localClass = "Business");
                                setState(() => travelClass = "Business");
                                Navigator.pop(sheetContext);
                              },
                            ),
                            _cabinOption(
                              title: "First Class",
                              iconAsset: 'assets/NewIcons/seat3.png',
                              features: const [
                                {
                                  'text': "Luxury Lounges",
                                  'icon': 'assets/Newimage/Lounges2.png',
                                },
                                {
                                  'text': "Cabin Comfort",
                                  'icon': 'assets/Newimage/cabinComfort.png',
                                },
                                {
                                  'text': "Highly Personalized",
                                  'icon':
                                      'assets/Newimage/highlyPersonalized.png',
                                },
                              ],
                              selected: localClass == "First",
                              onTap: () {
                                setSheetState(() => localClass = "First");
                                setState(() => travelClass = "First");
                                Navigator.pop(sheetContext);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _cabinOption({
    required String title,
    required String iconAsset,
    required List<Map<String, dynamic>> features, // Change to List<Map>
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: EdgeInsets.only(bottom: context.h(12)),
        padding: EdgeInsets.symmetric(
          horizontal: context.w(20),
          vertical: context.h(20),
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.AppBlue.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(context.r(20)),
          border: Border.all(
            color: selected ? AppColors.AppBlue : Colors.grey.shade200,
            width: selected ? 1.2 : 1,
          ),
        ),
        child: Row(
          children: [
            _radioDot(selected),
            SizedBox(width: context.w(10)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: context.fs(18),
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                  if (features.isNotEmpty) ...[
                    SizedBox(height: context.h(8)),
                    // Wrap allows items to flow to the next line if needed
                    Wrap(
                      spacing: context.w(10),
                      runSpacing: context.h(6),
                      children: features
                          .map(
                            (feature) => Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  feature['icon'],
                                  width: context.w(12),
                                  height: context.w(12),
                                  fit: BoxFit.contain,
                                ),
                                SizedBox(width: context.w(4)),
                                Text(
                                  feature['text'], // Access the text
                                  style: TextStyle(
                                    fontSize: context.fs(10.5),
                                    color: _kSubGrey,
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: context.w(10)),
            Image.asset(
              iconAsset,
              width: context.w(32),
              height: context.w(49),
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }

  Widget _radioDot(bool selected) {
    return Container(
      width: context.w(20),
      height: context.w(20),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.AppBlue : Colors.grey.shade400,
          width: 2,
        ),
      ),
      child: selected
          ? Container(
              width: context.w(10),
              height: context.w(10),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.AppBlue,
              ),
            )
          : null,
    );
  }

  void _pickDate({required bool isReturn}) async {
    final now = DateUtils.dateOnly(DateTime.now());

    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => FlightCalendarScreen(
          initialDeparture: departureDate,
          initialReturn: returnDate,
          isRoundTrip: isRoundTrip,
          startWithReturn: isReturn,
          firstDate: now,
          lastDate: DateTime(2030, 12, 31),
        ),
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      departureDate = result['departure'] as DateTime? ?? departureDate;
      returnDate = result['return'] as DateTime?;
      isRoundTrip = result['isRoundTrip'] as bool? ?? isRoundTrip;
    });
  }
}
