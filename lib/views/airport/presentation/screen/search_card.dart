import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/common_widgets/compact_date_picker_dialog.dart';
import 'package:wander_nova/core/resources/app_colours.dart';
import '../../../../core/error/data_state.dart';
import '../../../../core/utils/storage/shared_preference.dart';
import '../../../../injection_container.dart';
import '../../../MainApi/presentation/bloc/general_setting_bloc.dart';
import '../../../MainApi/presentation/bloc/general_settings_event.dart';
import '../../../MainApi/presentation/bloc/general_settings_state.dart';
import '../../domain/entities/airport_entities.dart';
import '../bloc/airport_bloc.dart';
import '../bloc/airport_event.dart';
import '../../../AKFlight_tui/domain/entity/akflight_search_entity.dart';
import '../../../AKFlight_tui/domain/usecase/akflight_search_usecase.dart';
import '../../../flight_search/domain/entities/fare_trip_type.dart';
import '../../../flight_search/presentation/screen/flight_search_screen.dart';
import '../../../home/flight/flight_calendar_screen.dart';
import 'destination_search_screen.dart';

const String _homeCountryCode = 'IN';

const String _icOneWay = 'assets/NewIcons/oneWay.png';
const String _icRoundTrip = 'assets/NewIcons/roundTrip.png';
const String _icMultiCity = 'assets/NewIcons/multicity.png';
const String _icFrom = 'assets/NewIcons/from.png';
const String _icTo = 'assets/NewIcons/to.png';
const String _icDepartureCalendar = 'assets/NewIcons/departureCalendar.png';
const String _icTravellerAdult = 'assets/NewIcons/TravellerAdult.png';
const String _icTravellerChild = 'assets/NewIcons/TravellerChild.png';
const String _icTravellerBaby = 'assets/NewIcons/TravellerBaby.png';

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

const Color _kLabelGrey = Color(0xFF9AA3B2);
const Color _kSubGrey = Color(0xFF7A8494);
const Color _kPageBg = Color(0xFFF8F9FA);

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
  String? _flightHeroImage;

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
      context.read<GeneralSettingsBloc>().add(
        const LoadSectionHeroes(domain: 'thewandernova.com'),
      );
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<GeneralSettingsBloc, GeneralSettingsState>(
      listener: (context, state) {
        if (state is SectionHeroesLoaded) {
          setState(() => _flightHeroImage = state.sectionHeroes.flights);
        }
      },
      child: Stack(
        children: [
          // Full-bleed hero image - no padding, no radius, edge to edge.
          Positioned.fill(child: _buildHeroBackdrop(context)),

          // ====== BOTTOM MELTING GRADIENT ======
// This creates smooth transition so the next section merges with white
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: context.h(100),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.white,
                    Colors.white.withOpacity(0.90),
                    Colors.white.withOpacity(0.60),
                    Colors.white.withOpacity(0.35),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.25, 0.50, 0.75, 1.0],
                ),
              ),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: context.h(170), // Keep as is or increase to 180
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _kPageBg.withOpacity(0.0),
                    _kPageBg.withOpacity(0.45),
                    _kPageBg,
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
              child: const SizedBox.expand(),
            ),
          ),
          // Foreground content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: context.statusBarHeight + context.h(10)),
              _buildTopBar(),
              SizedBox(height: context.h(18)),
              _buildTripTypeSelector(),
              if (isRoundTrip && !isMultiCityMode) ...[
                SizedBox(height: context.h(10)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.w(14)),
                  child: _specialFareCheckbox(),
                ),
              ],
              SizedBox(height: context.h(14)),
              if (isMultiCityMode) ...[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.w(14)),
                  child: _buildMultiCityLegs(),
                ),
              ] else ...[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.w(14)),
                  child: _buildFromToCard(),
                ),
                SizedBox(height: context.h(10)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.w(14)),
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
                        SizedBox(width: context.w(10)),
                        Expanded(
                          child: _buildDateCard(
                            label: "RETURN",
                            iconAsset: _icDepartureCalendar,
                            iconColor: AppColors.AppBlue,
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
              SizedBox(height: context.h(10)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.w(14)),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _buildTravellersCard()),
                      SizedBox(width: context.w(10)),
                      Expanded(child: _buildCabinClassCard()),
                    ],
                  ),
                ),
              ),
              SizedBox(height: context.h(26)),
              _buildSearchButton(),
              SizedBox(height: context.h(26)),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ HERO IMAGE

  Widget _buildHeroBackdrop(BuildContext context) {
    const fallbackGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF4A90E2), Color(0xFF87CEEB)],
    );

    const fallback = DecoratedBox(
      decoration: BoxDecoration(gradient: fallbackGradient),
    );

    final hero = _flightHeroImage;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (hero != null && hero.isNotEmpty)
          Image.network(
            hero,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (_, __, ___) => fallback,
            loadingBuilder: (ctx, child, progress) =>
            progress == null ? child : fallback,
          )
        else
          fallback,

        // ====== LAYER GRADIENT EFFECT (NO BLUR) - Same as HomeScreen ======
        // Layer 1: Soft white gradient that creates the "cloudy" look
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: context.h(154),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.white,
                  Colors.white.withOpacity(0.92),
                  Colors.white.withOpacity(0.72),
                  Colors.white.withOpacity(0.38),
                  Colors.white.withOpacity(0.10),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.20, 0.40, 0.60, 0.80, 1.0],
              ),
            ),
          ),
        ),

        // Layer 2: Additional subtle gradient overlay for depth
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: context.h(100),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.white.withOpacity(0.3),
                  Colors.white.withOpacity(0.10),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),

        // Soft scrim so the white "Flight" title stays readable on any hero.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.22),
                Colors.black.withOpacity(0.0),
              ],
              stops: const [0.0, 0.3],
            ),
          ),
        ),
      ],
    );
  }
  // --------------------------------------------------------------- TOP BAR

  Widget _buildTopBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.w(14)),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            },
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              // width: context.w(40),
              // height: context.w(40),
              child: Image.asset(
                'assets/NewIcons/arrowBack.png',
                width: context.w(17),
                height: context.w(17),
                color: Color(0xFFFFFFFF),
              ),
            ),
          ),
          SizedBox(width: context.w(14)),
          Text(
            'Flight',
            style: TextStyle(
              fontSize: context.fs(20),
              fontWeight: FontWeight.w600,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------- TRIP TYPE PILLS

  Widget _buildTripTypeSelector() {
    final radius = BorderRadius.circular(context.r(30));

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.w(14)),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          // Unselected area shows the hero image through a frosted blur.
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: EdgeInsets.all(context.w(4)),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.28),
              borderRadius: radius,
              // border: Border.all(color: Colors.white.withOpacity(0.35)),
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
          ),
        ),
      ),
    );
  }

  Widget _tripTypeButton({
    required String iconAsset,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
        decoration: BoxDecoration(
          // Selected = solid white pill. Unselected = fully transparent so
          // the frosted/blurred hero shows through.
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(context.r(24)),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: context.w(10),
              offset: Offset(0, context.h(2)),
            ),
          ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: isSelected ? 1 : 0.8,
              child: Image.asset(
                iconAsset,
                width: context.w(17),
                height: context.w(17),
                fit: BoxFit.contain,
                color: isSelected ? AppColors.AppBlue : Colors.white,
              ),
            ),
            SizedBox(width: context.w(6)),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.visible,
                softWrap: false,
                style: TextStyle(
                  fontSize: context.fs(14),
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? AppColors.AppBlue
                      : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------ FROM / TO

  BoxDecoration get _cardDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(context.r(12)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.06),
        blurRadius: context.w(14),
        offset: Offset(0, context.h(4)),
      ),
    ],
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
            fontSize: context.fs(8),
            fontWeight: FontWeight.bold,
            color: _kLabelGrey,
            letterSpacing: 0.5,
          ),
        ),
        if (showChevron) ...[
          SizedBox(width: context.w(3)),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            size: context.w(12),
            color: _kLabelGrey,
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
    return GestureDetector(
      onTap: onTap ?? _swapAirports,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: context.w(12),
        height: context.w(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: context.w(10),
              offset: Offset(0, context.h(4)),
            ),
          ],
        ),
        child: Center(
          child: Image.asset(
            'assets/NewIcons/flip.png',
            // width: context.w(8),
            // height: context.w(8),
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
      borderRadius: BorderRadius.circular(context.r(18)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          context.w(14),
          context.h(12),
          context.w(6),
          context.h(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1 - heading
            _cardLabel(title),
            SizedBox(height: context.h(6)),
            // Row 2 - icon + value
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  iconAsset,
                  width: context.w(22),
                  height: context.w(22),
                  fit: BoxFit.contain,
                  color: AppColors.AppBlue,
                ),
                SizedBox(width: context.w(8)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RichText(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: airport?.cityName ?? "Select",
                              style: TextStyle(
                                fontSize: context.fs(12),
                                fontWeight: FontWeight.w600,
                                color: airport != null
                                    ? AppColors.textPrimary
                                    : Colors.grey.shade400,
                              ),
                            ),
                            if (airport != null)
                              TextSpan(
                                text: " (${airport.airportCode})",
                                style: TextStyle(
                                  fontSize: context.fs(10.5),
                                  fontWeight: FontWeight.w600,
                                  color: _kSubGrey,
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: context.h(2)),
                      Text(
                        airport?.airportName ?? "Search airports",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: context.fs(11),
                          color: airport != null
                              ? _kSubGrey
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
          horizontal: context.w(12),
          vertical: context.h(8),
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(context.r(10)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: context.w(18),
              height: context.w(18),
              child: Checkbox(
                value: isSpecialFare,
                activeColor: AppColors.blue,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                onChanged: (val) => setState(() => isSpecialFare = val ?? false),
              ),
            ),
            SizedBox(width: context.w(8)),
            Expanded(
              child: Text(
                "Special Fare (student / senior citizen / armed forces)",
                style: TextStyle(
                  fontSize: context.fs(11),
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy,
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
          SizedBox(height: context.h(10)),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _multiCityDateCard(i),
                ),
                SizedBox(width: context.w(10)),
                Expanded(
                  child: i == multiCityLegs.length - 1
                      ? _multiCityAddCityButton()
                      : _multiCityRemoveButton(i),
                ),
              ],
            ),
          ),
          if (i != multiCityLegs.length - 1) SizedBox(height: context.h(10)),
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
    final radius = BorderRadius.circular(context.r(12));

    return GestureDetector(
      onTap: canAdd
          ? () => setState(() => multiCityLegs.add(_MultiCityLeg()))
          : null,
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: context.h(12),
              horizontal: context.w(12),
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.28),
              borderRadius: radius,
              border: Border.all(color: AppColors.white),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add,
                  size: context.w(15),
                  color: canAdd ? Color(0xFFFFFFFF) : Colors.grey.shade400,
                ),
                SizedBox(width: context.w(4)),
                Text(
                  "ADD CITY",
                  style: TextStyle(
                    fontSize: context.fs(12),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: canAdd ? Color(0xFFFFFFFF) : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
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
          borderRadius: BorderRadius.circular(context.r(12)),
          border: Border.all(color: Colors.red.shade200, width: 1.2),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.close, size: context.w(16), color: Colors.red.shade400),
            SizedBox(width: context.w(4)),
            Text(
              "REMOVE",
              style: TextStyle(
                fontSize: context.fs(12),
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
        padding: EdgeInsets.symmetric(
          horizontal: context.w(14),
          vertical: context.h(12),
        ),
        decoration: _cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1 - heading
            _cardLabel(label),
            SizedBox(height: context.h(6)),
            // Row 2 - icon + value
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  iconAsset,
                  width: context.w(24),
                  height: context.w(24),
                  fit: BoxFit.contain,
                  color: iconColor,
                ),
                SizedBox(width: context.w(8)),
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
                          fontSize: context.fs(15),
                          fontWeight: FontWeight.w700,
                          color: date != null
                              ? AppColors.navy
                              : Colors.grey.shade400,
                        ),
                      ),
                      SizedBox(height: context.h(2)),
                      Text(
                        date != null
                            ? DateFormat('EEEE').format(date)
                            : subPlaceholder,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: context.fs(11),
                          color: _kSubGrey,
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
      height: context.w(20),
      margin: EdgeInsets.symmetric(horizontal: context.w(9)),
      color: Colors.grey.shade300,
    );
  }

  // ------------------------------------------------- TRAVELLERS / CABIN

  Widget _buildTravellersCard() {
    return GestureDetector(
      onTap: _openTravellerSheet,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(14),
          vertical: context.h(12),
        ),
        decoration: _cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1 - heading
            _cardLabel("TRAVELLERS", showChevron: false),
            SizedBox(height: context.h(8)),
            // Row 2 - icons + counts, separated by a vertical divider
            Row(
              children: [
                _travellerIcon(asset: _icTravellerAdult, count: adults),
                _travellerDivider(),

                _travellerIcon(asset: _icTravellerChild, count: children),
                _travellerDivider(),
                _travellerIcon(asset: _icTravellerBaby, count: infants),
              ],
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
          width: context.w(15),
          height: context.w(15),
          fit: BoxFit.contain,
          color: AppColors.AppBlue,
        ),
        SizedBox(width: context.w(4)),
        Text(
          "$count",
          style: TextStyle(
            fontSize: context.fs(12),
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildCabinClassCard() {
    return GestureDetector(
      onTap: _openTravellerSheet,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(14),
          vertical: context.h(12),
        ),
        decoration: _cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _cardLabel("CABIN CLASS", showChevron: false),
            SizedBox(height: context.h(8)),
            SizedBox(
              height: context.w(20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  travelClass,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.fs(14),
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
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
    return Center(
      child: SizedBox(
        width: context.w(150),
        height: context.h(42),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.orange,
            foregroundColor: Colors.white,
            elevation: 6,
            shadowColor: AppColors.orange.withOpacity(0.45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(context.r(30)),
            ),
          ),
          onPressed: _isSearching ? null : _performSearch,
          child: _isSearching
              ? SizedBox(
            width: context.w(22),
            height: context.w(22),
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Colors.white),
            ),
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Search Flight",
                style: TextStyle(
                  fontSize: context.fs(14),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: context.w(10)),
              Image.asset(
                'assets/NewIcons/arrowForward.png',
                width: context.w(9.54),
                height: context.w(13),
                color: Color(0xFFFFFFFF),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------ TRAVELLER SHEET

  void _openTravellerSheet() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              insetPadding: EdgeInsets.symmetric(
                horizontal: context.w(20),
                vertical: context.h(8),
              ),
              contentPadding: EdgeInsets.all(context.dialogContentPadding),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.dialogBorderRadius),
              ),
              content: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: context.screenHeight * 0.6,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _travellerSection(
                        title: "Adults (Above 12 Years)",
                        selectedValue: adults,
                        onSelected: (val) {
                          setDialogState(() => adults = val);
                        },
                      ),
                      SizedBox(height: context.gapMedium),
                      _travellerSection(
                        title: "Children (2–12 Years)",
                        selectedValue: children,
                        onSelected: (val) {
                          setDialogState(() => children = val);
                        },
                      ),
                      SizedBox(height: context.gapMedium),
                      _travellerSection(
                        title: "Infants (0–23 Months)",
                        selectedValue: infants,
                        onSelected: (val) {
                          setDialogState(() => infants = val);
                        },
                      ),
                      SizedBox(height: context.gapLarge),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Travel Class",
                          style: TextStyle(
                            fontSize: context.titleMedium,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(height: context.gapSmall),
                      Row(
                        children: [
                          Expanded(
                            child: _classRadio(
                              title: "Economy",
                              value: "Economy",
                              groupValue: travelClass,
                              onChanged: (val) {
                                setDialogState(() => travelClass = val!);
                              },
                            ),
                          ),
                          Expanded(
                            child: _classRadio(
                              title: "Premium Economy",
                              value: "Premium Economy",
                              groupValue: travelClass,
                              onChanged: (val) {
                                setDialogState(() => travelClass = val!);
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: context.gapXSmall),
                      Row(
                        children: [
                          Expanded(
                            child: _classRadio(
                              title: "Business",
                              value: "Business",
                              groupValue: travelClass,
                              onChanged: (val) {
                                setDialogState(() => travelClass = val!);
                              },
                            ),
                          ),
                          Expanded(
                            child: _classRadio(
                              title: "First",
                              value: "First",
                              groupValue: travelClass,
                              onChanged: (val) {
                                setDialogState(() => travelClass = val!);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: Text(
                    "CANCEL",
                    style: TextStyle(
                      fontSize: context.labelMedium,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                SizedBox(width: context.gapXSmall),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                    Navigator.pop(dialogContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        context.borderRadiusMedium,
                      ),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: context.w(24),
                      vertical: context.h(12),
                    ),
                  ),
                  child: Text(
                    "APPLY",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.labelMedium,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              actionsPadding: EdgeInsets.symmetric(
                horizontal: context.dialogContentPadding,
                vertical: context.gapMedium,
              ),
              actionsAlignment: MainAxisAlignment.end,
            );
          },
        );
      },
    );
  }

  Widget _travellerSection({
    required String title,
    required int selectedValue,
    required Function(int) onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: context.bodyMedium,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              selectedValue.toString(),
              style: TextStyle(
                fontSize: context.titleMedium,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: context.gapSmall),
        Wrap(
          spacing: context.gapXSmall,
          runSpacing: context.gapXSmall,
          children: List.generate(
            10,
                (index) => GestureDetector(
              onTap: () => onSelected(index),
              child: Container(
                width: context.w(30),
                height: context.h(30),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selectedValue == index
                      ? AppColors.blue
                      : Colors.white,
                  border: Border.all(
                    color: selectedValue == index
                        ? AppColors.blue
                        : Colors.grey.shade300,
                    width: context.dividerThin,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  index.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: context.bodySmall,
                    color: selectedValue == index
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _classRadio({
    required String title,
    required String value,
    required String groupValue,
    required Function(String?) onChanged,
  }) {
    return Row(
      children: [
        Transform.scale(
          scale: context.radioSize / 20,
          child: Radio<String>(
            value: value,
            groupValue: groupValue,
            activeColor: AppColors.blue,
            onChanged: onChanged,
          ),
        ),
        SizedBox(width: context.gapXXSmall),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: context.bodySmall,
            ),
          ),
        ),
      ],
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
