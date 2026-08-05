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
import '../../domain/entities/airport_entities.dart';
import '../bloc/airport_bloc.dart';
import '../bloc/airport_event.dart';
import '../../../AKFlight_tui/domain/entity/akflight_search_entity.dart';
import '../../../AKFlight_tui/domain/usecase/akflight_search_usecase.dart';
import '../../../flight_search/domain/entities/fare_trip_type.dart';
import '../../../flight_search/presentation/screen/flight_search_screen.dart';
import '../widgets/airport_dropdown.dart';

/// GDS country code for the home market — used to auto-derive Multi City's
/// Domestic (DM) vs International (IM) fare type from the legs' airports,
/// with no extra UI for the user to pick it themselves.
const String _homeCountryCode = 'IN';

/// One row of the Multi City leg editor. Plain mutable holder (not
/// Equatable/immutable) since it only ever lives as local widget state,
/// edited in place by the airport/date pickers.
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
  // RS (Return Special-Fare) vs RT (Normal Round-Trip) — only meaningful
  // while isRoundTrip is true; same request/response shape as RT, only the
  // wire fareType string differs.
  bool isSpecialFare = false;

  // Multi City (IM/DM) — a separate mode from the One Way/Round Trip pair
  // above, since it swaps the whole FROM/TO/date section for a leg editor.
  bool isMultiCityMode = false;
  List<_MultiCityLeg> multiCityLegs = [];

  // Store selected airports
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
    // Auto-select today's date for departure (user can still change it).
    departureDate = DateUtils.dateOnly(DateTime.now());
    // Load initial airports when widget first builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AirportBloc>().add(LoadAirports());
    });
    // Prefill fields from the user's last search (no bloc dependency needed —
    // the airport details are already stored in preferences).
    _loadLastSearch();
  }

  Future<void> _saveSearchToPreferences() async {
    final prefsManager = await PreferencesManager.create(await SharedPreferences.getInstance());

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
      final prefsManager =
          await PreferencesManager.create(await SharedPreferences.getInstance());
      final lastSearch = prefsManager.getLastSearch();

      if (lastSearch == null || !mounted) return;

      // Rebuild the airports directly from the saved data — no need to wait for
      // (or search through) the bloc's airport list.
      final savedFromAirport = _airportFromJson(lastSearch['fromAirport']);
      var savedToAirport = _airportFromJson(lastSearch['toAirport']);

      // Don't prefill the same airport for both origin and destination.
      if (savedFromAirport != null &&
          savedToAirport != null &&
          savedFromAirport.airportCode == savedToAirport.airportCode) {
        savedToAirport = null;
      }

      setState(() {
        if (savedFromAirport != null) fromAirport = savedFromAirport;
        if (savedToAirport != null) toAirport = savedToAirport;

        isRoundTrip = lastSearch['isRoundTrip'] ?? false;
        isSpecialFare = lastSearch['isSpecialFare'] ?? false;

        // Restore dates, but never prefill a date in the past.
        final today = DateUtils.dateOnly(DateTime.now());
        if (lastSearch['departureDate'] != null) {
          final depDate =
              DateUtils.dateOnly(DateTime.parse(lastSearch['departureDate']));
          departureDate = depDate.isBefore(today) ? today : depDate;
        }

        if (lastSearch['returnDate'] != null && isRoundTrip) {
          final retDate =
              DateUtils.dateOnly(DateTime.parse(lastSearch['returnDate']));
          returnDate =
              (departureDate != null && retDate.isBefore(departureDate!))
                  ? null
                  : retDate;
        } else {
          returnDate = null;
        }

        // Restore traveller details.
        adults = lastSearch['adults'] ?? 1;
        children = lastSearch['children'] ?? 0;
        infants = lastSearch['infants'] ?? 0;
        travelClass = lastSearch['travelClass'] ?? 'Economy';
      });
    } catch (e) {
      debugPrint('Error loading last search: $e');
    }
  }

  /// Reconstructs an [AirportEntity] from the map stored in preferences.
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

  /// Resolves which of the five fare types this search is for. RS is just
  /// RT with the "Special Fare" checkbox on; IM/DM is auto-derived from
  /// whether every Multi City leg stays inside the home country.
  FareTripType _resolveFareType() {
    if (isMultiCityMode) {
      final allDomestic = multiCityLegs.every((leg) =>
          (leg.from?.countryCode.toUpperCase() ?? '') == _homeCountryCode &&
          (leg.to?.countryCode.toUpperCase() ?? '') == _homeCountryCode);
      return allDomestic
          ? FareTripType.domesticMulticity
          : FareTripType.internationalMulticity;
    }
    if (isRoundTrip) {
      return isSpecialFare ? FareTripType.specialReturn : FareTripType.roundTrip;
    }
    return FareTripType.oneWay;
  }

  List<TripEntity> _buildTrips() {
    if (isMultiCityMode) {
      return multiCityLegs
          .map((leg) => TripEntity(
                from: leg.from!.airportCode,
                to: leg.to!.airportCode,
                onwardDate: DateFormat('yyyy-MM-dd').format(leg.date!),
              ))
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

  /// True once every field this mode needs is filled in — the shared
  /// gate before building the request, checked before `_performSearch`
  /// does its own mode-specific validation (with user-facing messages).
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
              'Origin and destination cannot be the same airport for Flight ${i + 1}');
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

      // Step 1: kick off the Akbar ExpressSearch to get a search `tui`.
      // GetExpSearch (polled inside FlightSearchScreen) uses this tui to
      // fetch the actual flight results.
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
              from: isMultiCityMode ? firstLeg!.from!.cityName : fromAirport!.cityName,
              to: isMultiCityMode ? firstLeg!.to!.cityName : toAirport!.cityName,
              fromCode: isMultiCityMode ? firstLeg!.from!.airportCode : fromAirport!.airportCode,
              toCode: isMultiCityMode ? firstLeg!.to!.airportCode : toAirport!.airportCode,
              fromAirport: isMultiCityMode ? firstLeg!.from!.airportName : fromAirport!.airportName,
              toAirport: isMultiCityMode ? firstLeg!.to!.airportName : toAirport!.airportName,
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
                      .map((leg) => MultiCityLegSummary(
                            from: leg.from!.cityName,
                            to: leg.to!.cityName,
                            fromCode: leg.from!.airportCode,
                            toCode: leg.to!.airportCode,
                            date: leg.date!,
                          ))
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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: context.w(4)),
      padding: EdgeInsets.fromLTRB(
        context.w(8),
        context.h(6),
        context.w(8),
        context.h(8),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: context.w(18),
            offset: Offset(0, context.h(6)),
          ),
        ],
      ),
      child: Column(
        children: [
          /// Trip Type Toggle — One Way / Round Trip / Multi City
          Container(
            // padding: EdgeInsets.all(context.w(1)),
            decoration: BoxDecoration(
              color: AppColors.fieldFill,
              borderRadius: BorderRadius.circular(context.r(4)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _tripButton(
                    title: "One Way",
                    selected: !isRoundTrip && !isMultiCityMode,
                    onTap: () => setState(() {
                      isRoundTrip = false;
                      isMultiCityMode = false;
                      returnDate = null;
                    }),
                  ),
                ),
                Expanded(
                  child: _tripButton(
                    title: "Round Trip",
                    selected: isRoundTrip && !isMultiCityMode,
                    onTap: () => setState(() {
                      isRoundTrip = true;
                      isMultiCityMode = false;
                    }),
                  ),
                ),
                Expanded(
                  child: _tripButton(
                    title: "Multi City",
                    selected: isMultiCityMode,
                    onTap: () => setState(() {
                      isMultiCityMode = true;
                      if (multiCityLegs.length < 2) {
                        multiCityLegs = [_MultiCityLeg(), _MultiCityLeg()];
                      }
                    }),
                  ),
                ),
              ],
            ),
          ),

          if (isRoundTrip && !isMultiCityMode) ...[
            SizedBox(height: context.h(8)),
            _specialFareCheckbox(),
          ],

          SizedBox(height: context.h(12)),

          if (isMultiCityMode) ...[
            _buildMultiCityLegs(),
          ] else ...[
          /// FROM - TO connected box with Swap Button on the boundary (MMT)
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.fieldFill,
                  borderRadius: BorderRadius.circular(context.r(6)),
                  border: Border.all(color: AppColors.fieldBorder, width: 1),
                ),
                child: Column(
                  children: [
                    AirportSearchDropdown(
                      title: "FROM",
                      hint: "Search airports",
                      initialSubtitle: "Select origin airport",
                      selectedAirport: fromAirport,
                      onAirportSelected: (airport) {
                        if (airport == null) {
                          setState(() {
                            fromAirport = null;
                          });
                          return;
                        }

                        if (toAirport != null &&
                            toAirport!.airportCode == airport.airportCode) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Origin and destination cannot be the same airport',
                                style: TextStyle(fontSize: context.bodyMedium),
                              ),
                              backgroundColor: Colors.red,
                              duration: Duration(
                                seconds: context.gapMedium.toInt(),
                              ),
                            ),
                          );
                          return;
                        }
                        setState(() {
                          fromAirport = airport;
                        });
                      },
                    ),

                    Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.fieldBorder,
                      indent: context.w(41),
                    ),

                    AirportSearchDropdown(
                      title: "TO",
                      hint: "Search airports",
                      initialSubtitle: "Select destination airport",
                      selectedAirport: toAirport,
                      onAirportSelected: (airport) {
                        if (airport == null) {
                          setState(() {
                            toAirport = null;
                          });
                          return;
                        }

                        if (fromAirport != null &&
                            fromAirport!.airportCode == airport.airportCode) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Origin and destination cannot be the same airport',
                                style: TextStyle(fontSize: context.bodyMedium),
                              ),
                              backgroundColor: Colors.red,
                              duration: Duration(
                                seconds: context.gapMedium.toInt(),
                              ),
                            ),
                          );
                          return;
                        }
                        setState(() {
                          toAirport = airport;
                        });
                      },
                    ),
                  ],
                ),
              ),

              /// Swap button straddling the FROM/TO boundary
              Positioned.fill(
                child: Align(
                  alignment: Alignment(0.93, 0),
                  child: GestureDetector(
                    onTap: _swapAirports,
                    child: Container(
                      width: context.w(34),
                      height: context.w(34),
                      decoration: BoxDecoration(
                        color: AppColors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.blue.withValues(alpha: 0.30),
                            blurRadius: context.w(8),
                            offset: Offset(0, context.h(2)),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.swap_vert,
                        color: Colors.white,
                        size: context.w(18),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: context.h(4)),

          /// Date Fields — connected box with a center divider (MMT style)
          Container(
            decoration: BoxDecoration(
              color: AppColors.fieldFill,
              border: Border.all(color: AppColors.fieldBorder, width: 1),
              borderRadius: BorderRadius.circular(context.r(6)),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _clickableDateTile(
                      context,
                      icon: Icons.flight_takeoff,
                      label: "DEPARTURE",
                      date: departureDate,
                      placeholder: "Select date",
                      onTap: () => _pickDate(isReturn: false),
                    ),
                  ),
                  Container(width: 1, color: AppColors.fieldBorder),
                  Expanded(
                    child: _clickableDateTile(
                      context,
                      icon: Icons.flight_land,
                      label: "RETURN",
                      date: returnDate,
                      placeholder: isRoundTrip ? "Select date" : "One Way",
                      muted: !isRoundTrip,
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

          SizedBox(height: context.h(4)),

          /// Travellers & Class Section
          _clickableInfoTile(
            context,
            icon: Icons.person_outline,
            title: "TRAVELLERS & CLASS",
            subtitle:
                "${adults + children + infants} Traveller${(adults + children + infants) > 1 ? 's' : ''}",
            additionalText: travelClass,
            onTap: _openTravellerSheet,
          ),

          SizedBox(height: context.h(10)),

          /// SEARCH Button
          SizedBox(
            width: double.infinity,
            height: context.h(45),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.r(14)),
                ),
              ),
              onPressed: _isSearching ? null : _performSearch,
              icon: _isSearching
                  ? SizedBox(
                      width: context.w(16),
                      height: context.w(16),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Icon(Icons.search, size: context.w(18)),
              label: Text(
                _isSearching ? "Searching..." : "Search Flights",
                style: TextStyle(
                  fontSize: context.fs(14),
                  fontWeight: FontWeight.w700,
                  letterSpacing: context.letterSpacingNormal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _specialFareCheckbox() {
    return InkWell(
      onTap: () => setState(() => isSpecialFare = !isSpecialFare),
      borderRadius: BorderRadius.circular(context.r(6)),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.h(2)),
        child: Row(
          children: [
            SizedBox(
              width: context.w(20),
              height: context.w(20),
              child: Checkbox(
                value: isSpecialFare,
                activeColor: AppColors.blue,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: (val) => setState(() => isSpecialFare = val ?? false),
              ),
            ),
            SizedBox(width: context.w(8)),
            Text(
              "Special Fare (student / senior citizen / armed forces)",
              style: TextStyle(
                fontSize: context.fs(12),
                fontWeight: FontWeight.w600,
                color: const Color(0xff4B5563),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const int _maxMultiCityLegs = 6;

  Widget _buildMultiCityLegs() {
    return Column(
      children: [
        for (var i = 0; i < multiCityLegs.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: context.h(8)),
            child: _multiCityLegCard(i),
          ),
        if (multiCityLegs.length < _maxMultiCityLegs)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => multiCityLegs.add(_MultiCityLeg())),
              icon: Icon(Icons.add, size: context.w(16), color: AppColors.blue),
              label: Text(
                "Add Flight",
                style: TextStyle(
                  fontSize: context.fs(13),
                  fontWeight: FontWeight.w700,
                  color: AppColors.blue,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _multiCityLegCard(int index) {
    final leg = multiCityLegs[index];
    final minDate = index == 0
        ? DateUtils.dateOnly(DateTime.now())
        : (multiCityLegs[index - 1].date ?? DateUtils.dateOnly(DateTime.now()));

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(context.r(6)),
        border: Border.all(color: AppColors.fieldBorder, width: 1),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(context.w(12), context.h(6), context.w(6), 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "FLIGHT ${index + 1}",
                    style: TextStyle(
                      fontSize: context.fs(10),
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                      letterSpacing: context.letterSpacingNormal,
                    ),
                  ),
                ),
                if (multiCityLegs.length > 2)
                  InkWell(
                    borderRadius: BorderRadius.circular(context.r(12)),
                    onTap: () => setState(() => multiCityLegs.removeAt(index)),
                    child: Padding(
                      padding: EdgeInsets.all(context.w(4)),
                      child: Icon(Icons.close, size: context.w(16), color: AppColors.muted),
                    ),
                  ),
              ],
            ),
          ),
          AirportSearchDropdown(
            title: "FROM",
            hint: "Search airports",
            initialSubtitle: "Select origin airport",
            selectedAirport: leg.from,
            onAirportSelected: (airport) => setState(() => leg.from = airport),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.fieldBorder,
            indent: context.w(41),
          ),
          AirportSearchDropdown(
            title: "TO",
            hint: "Search airports",
            initialSubtitle: "Select destination airport",
            selectedAirport: leg.to,
            onAirportSelected: (airport) => setState(() => leg.to = airport),
          ),
          Divider(height: 1, thickness: 1, color: AppColors.fieldBorder),
          InkWell(
            onTap: () => _pickMultiCityDate(index, minDate),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: context.w(12), vertical: context.h(10)),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: context.w(14), color: AppColors.navy),
                  SizedBox(width: context.w(8)),
                  Text(
                    leg.date != null
                        ? DateFormat('dd MMM yyyy').format(leg.date!)
                        : 'Select date',
                    style: TextStyle(
                      fontSize: context.fs(13),
                      fontWeight: FontWeight.w700,
                      color: leg.date != null
                          ? AppColors.navy
                          : const Color(0xff777777),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _pickMultiCityDate(int index, DateTime minDate) async {
    final leg = multiCityLegs[index];
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

    if (picked != null) {
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
  }

  Widget _tripButton({
    required String title,
    required bool selected,
    required VoidCallback onTap,
    bool comingSoon = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(vertical: context.h(9)),
        decoration: BoxDecoration(
          color: selected ? AppColors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(context.r(11)),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.blue.withValues(alpha: 0.28),
                    blurRadius: context.w(8),
                    offset: Offset(0, context.h(2)),
                  ),
                ]
              : null,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: context.fs(13),
                fontWeight: FontWeight.w700,
                color: selected
                    ? Colors.white
                    : (comingSoon ? AppColors.muted : const Color(0xff2C2F36)),
                letterSpacing: context.letterSpacingNormal,
              ),
            ),
            if (comingSoon)
              Positioned(
                top: -context.h(9),
                right: -context.w(2),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(4),
                    vertical: context.h(1),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: BorderRadius.circular(context.r(6)),
                  ),
                  child: Text(
                    'SOON',
                    style: TextStyle(
                      fontSize: context.fs(7),
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _clickableDateTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required DateTime? date,
    required String placeholder,
    bool muted = false,
    VoidCallback? onTap,
  }) {
    final hasDate = date != null;
    return InkWell(
      borderRadius: BorderRadius.circular(context.r(12)),
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: context.h(56)),
        padding: EdgeInsets.symmetric(
          horizontal: context.w(12),
          vertical: context.h(9),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, size: context.w(15), color: AppColors.navy),
                SizedBox(width: context.w(6)),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: context.fs(10),
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted,
                    letterSpacing: context.letterSpacingNormal,
                  ),
                ),
              ],
            ),
            SizedBox(height: context.h(5)),
            if (hasDate)
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    letterSpacing: context.letterSpacingNormal,
                  ),
                  children: [
                    TextSpan(
                      text: DateFormat('dd MMM').format(date),
                      style: TextStyle(fontSize: context.fs(15)),
                    ),
                    TextSpan(
                      text: "  '${DateFormat('yy').format(date)}",
                      style: TextStyle(
                        fontSize: context.fs(12),
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(
                placeholder,
                style: TextStyle(
                  fontSize: context.fs(14),
                  fontWeight: FontWeight.w700,
                  color: muted
                      ? const Color(0xffAAB0BC)
                      : const Color(0xff777777),
                  letterSpacing: context.letterSpacingNormal,
                ),
              ),
            SizedBox(height: context.h(2)),
            Text(
              hasDate ? DateFormat('EEEE').format(date) : ' ',
              style: TextStyle(
                fontSize: context.fs(11),
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
                letterSpacing: context.letterSpacingNormal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _clickableInfoTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String additionalText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(context.r(6)),
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: context.h(50)),
        padding: EdgeInsets.symmetric(
          horizontal: context.w(12),
          vertical: context.h(9),
        ),
        decoration: BoxDecoration(
          color: AppColors.fieldFill,
          border: Border.all(color: AppColors.fieldBorder, width: 1),
          borderRadius: BorderRadius.circular(context.r(6)),
        ),
        child: Row(
          children: [
            Icon(icon, size: context.w(18), color: const Color(0xff07163B)),
            SizedBox(width: context.w(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: context.fs(10),
                      fontWeight: FontWeight.w700,
                      color: const Color(0xff4B5563),
                      letterSpacing: context.letterSpacingNormal,
                    ),
                  ),
                  SizedBox(height: context.h(3)),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: context.fs(14),
                      fontWeight: FontWeight.w700,
                      color: const Color(0xff07163B),
                      letterSpacing: context.letterSpacingNormal,
                    ),
                  ),
                  Text(
                    additionalText,
                    style: TextStyle(
                      fontSize: context.fs(12),
                      color: const Color(0xff737780),
                      letterSpacing: context.letterSpacingNormal,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              size: context.w(18),
              color: Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }

  void _openTravellerSheet() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              insetPadding: EdgeInsets.symmetric(
                horizontal: context.w(20), // 20px on design
                vertical: context.h(8), // 8px on design
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
                            letterSpacing: context.letterSpacingNormal,
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
                      letterSpacing: context.letterSpacingWide,
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
                    backgroundColor: const Color(0xffF97316),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        context.borderRadiusMedium,
                      ),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: context.w(24), // 24px on design
                      vertical: context.h(12), // 12px on design
                    ),
                  ),
                  child: Text(
                    "APPLY",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.labelMedium,
                      fontWeight: FontWeight.bold,
                      letterSpacing: context.letterSpacingWide,
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
                letterSpacing: context.letterSpacingNormal,
              ),
            ),
            Text(
              selectedValue.toString(),
              style: TextStyle(
                fontSize: context.titleMedium,
                fontWeight: FontWeight.bold,
                letterSpacing: context.letterSpacingNormal,
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
                width: context.w(30), // 30px on design
                height: context.h(30), // 30px on design (square circle)
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selectedValue == index
                      ? const Color(0xff1663F7)
                      : Colors.white,
                  border: Border.all(
                    color: selectedValue == index
                        ? const Color(0xff1663F7)
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
                    letterSpacing: context.letterSpacingNormal,
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
          scale: context.radioSize / 20, // Scale radio relative to 20px base
          child: Radio<String>(
            value: value,
            groupValue: groupValue,
            activeColor: const Color(0xff1663F7),
            onChanged: onChanged,
          ),
        ),
        SizedBox(width: context.gapXXSmall),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: context.bodySmall,
              letterSpacing: context.letterSpacingNormal,
            ),
          ),
        ),
      ],
    );
  }

  void _pickDate({required bool isReturn}) async {
    final now = DateUtils.dateOnly(DateTime.now());
    final firstDate = isReturn && departureDate != null
        ? DateUtils.dateOnly(departureDate!)
        : now;
    final initialDate = isReturn && returnDate != null
        ? DateUtils.dateOnly(returnDate!)
        : isReturn && departureDate != null
        ? DateUtils.dateOnly(departureDate!)
        : departureDate != null
        ? DateUtils.dateOnly(departureDate!)
        : now;

    final picked = await showDialog<DateTime>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => CompactDatePickerDialog(
        initialDate: initialDate.isBefore(firstDate) ? firstDate : initialDate,
        firstDate: firstDate,
        lastDate: DateTime(2030, 12, 31),
      ),
    );

    if (picked != null) {
      setState(() {
        if (isReturn) {
          if (departureDate != null && picked.isBefore(departureDate!)) {
            returnDate = departureDate;
          } else {
            returnDate = picked;
          }
        } else {
          departureDate = picked;
          if (returnDate != null && picked.isAfter(returnDate!)) {
            returnDate = null;
          }
        }
      });
    }
  }
}
