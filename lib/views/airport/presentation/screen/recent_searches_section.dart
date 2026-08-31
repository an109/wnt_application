import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';
import '../../../../core/error/data_state.dart';
import '../../../../core/utils/route_observer.dart';
import '../../../../core/utils/storage/shared_preference.dart';
import '../../../../injection_container.dart';
import '../../../AKFlight_tui/domain/entity/akflight_search_entity.dart';
import '../../../AKFlight_tui/domain/usecase/akflight_search_usecase.dart';
import '../../../flight_search/domain/entities/fare_trip_type.dart';
import '../../../flight_search/presentation/screen/flight_search_screen.dart';

const String _icFlight = 'assets/NewIcons/flightSearch.png';

/// Reads back whatever `SearchCard` already saves to `PreferencesManager`
/// (`addToSearchHistory`) and shows the last few searches below the hero
/// card. Tapping one re-runs that exact search and jumps straight to
/// results — no need to refill FROM/TO/date/travellers.
class RecentSearchesSection extends StatefulWidget {
  const RecentSearchesSection({super.key});

  @override
  State<RecentSearchesSection> createState() => _RecentSearchesSectionState();
}

class _RecentSearchesSectionState extends State<RecentSearchesSection>
    with RouteAware {
  List<Map<String, dynamic>> _history = [];
  bool _loaded = false;
  int? _searchingIndex;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  // Coming back to this screen (e.g. after a search finished and the user
  // hit back, or a new search just got saved) — reload instead of showing
  // the snapshot this widget happened to load on its first build.
  @override
  void didPopNext() => _loadHistory();

  /// Same route + same date(s) is "the same search" — keep only the newest
  /// (history is already newest-first) instead of stacking duplicate cards.

  List<Map<String, dynamic>> _dedupe(List<Map<String, dynamic>> entries) {
    final seen = <String>{};
    final result = <Map<String, dynamic>>[];

    for (final entry in entries) {
      final fromMap = entry['fromAirport'];
      final toMap = entry['toAirport'];

      if (fromMap is! Map || toMap is! Map) continue;

      final fromCode =
          (fromMap['code'] as String?)?.trim().toUpperCase() ?? '';
      final toCode =
          (toMap['code'] as String?)?.trim().toUpperCase() ?? '';

      final departureDate = entry['departureDate'] as String?;

      // Calculate total travellers
      final adults = entry['adults'] as int? ?? 1;
      final children = entry['children'] as int? ?? 0;
      final infants = entry['infants'] as int? ?? 0;

      final totalTravellers = adults + children + infants;

      // Same FROM + TO + DATE + TOTAL TRAVELLERS = same search
      final key =
          '$fromCode|$toCode|$departureDate|$totalTravellers';

      // History is newest-first, so keep only the newest duplicate.
      if (seen.add(key)) {
        result.add(entry);
      }
    }

    return result;
  }


  Future<void> _loadHistory() async {
    try {
      final prefsManager = await PreferencesManager.create(
        await SharedPreferences.getInstance(),
      );
      // Always re-read from preferences (never cache a static list) so this
      // reflects whatever was searched most recently.
      final history = prefsManager.getSearchHistory();
      // Multi-city searches aren't captured in this history shape (no
      // per-leg airports saved), so a saved entry missing a FROM/TO code
      // isn't safely re-runnable here — skip it rather than show a broken
      // card.
      final usable = history.where((entry) {
        final from = entry['fromAirport'];
        final to = entry['toAirport'];
        return from is Map &&
            to is Map &&
            (from['code'] as String?)?.isNotEmpty == true &&
            (to['code'] as String?)?.isNotEmpty == true;
      }).toList();

      if (!mounted) return;
      setState(() {
        _history = _dedupe(usable);
        _loaded = true;
      });
    } catch (e) {
      debugPrint('Error loading recent searches: $e');
      if (mounted) setState(() => _loaded = true);
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

  Future<void> _repeatSearch(int index) async {
    if (_searchingIndex != null) return;
    final entry = _history[index];

    setState(() => _searchingIndex = index);
    try {
      final fromMap = entry['fromAirport'] as Map;
      final toMap = entry['toAirport'] as Map;
      final isRoundTrip = entry['isRoundTrip'] as bool? ?? false;
      final isSpecialFare = entry['isSpecialFare'] as bool? ?? false;
      final departureDate = entry['departureDate'] != null
          ? DateTime.parse(entry['departureDate'] as String)
          : DateUtils.dateOnly(DateTime.now());
      final returnDateRaw = entry['returnDate'];
      final returnDate =
      isRoundTrip && returnDateRaw != null ? DateTime.parse(returnDateRaw as String) : null;
      final adults = entry['adults'] as int? ?? 1;
      final children = entry['children'] as int? ?? 0;
      final infants = entry['infants'] as int? ?? 0;
      final travelClass = entry['travelClass'] as String? ?? 'Economy';

      final fareType = isRoundTrip
          ? (isSpecialFare ? FareTripType.specialReturn : FareTripType.roundTrip)
          : FareTripType.oneWay;

      final tuiRequest = FlightSearchRequestEntity(
        adults: adults,
        children: children,
        infants: infants,
        cabin: _cabinCode(travelClass),
        fareType: fareType.wireValue,
        trips: [
          TripEntity(
            from: fromMap['code'] as String,
            to: toMap['code'] as String,
            onwardDate: DateFormat('yyyy-MM-dd').format(departureDate),
            returnDate: returnDate != null
                ? DateFormat('yyyy-MM-dd').format(returnDate)
                : null,
          ),
        ],
      );

      final result = await sl<AkFlightSearchUseCase>().call(tuiRequest);
      if (!mounted) return;

      if (result is DataSuccess<AkFlightSearchEntity> && result.data != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FlightSearchScreen(
              tui: result.data!.tui,
              from: fromMap['city'] as String? ?? fromMap['code'] as String,
              to: toMap['city'] as String? ?? toMap['code'] as String,
              fromCode: fromMap['code'] as String,
              toCode: toMap['code'] as String,
              fromAirport: fromMap['name'] as String? ?? '',
              toAirport: toMap['name'] as String? ?? '',
              date: departureDate,
              travellers: adults + children + infants,
              adults: adults,
              children: children,
              infants: infants,
              travelClass: travelClass,
              isRoundTrip: isRoundTrip,
              returnDate: returnDate,
              fareType: fareType.wireValue,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.error?.message ?? 'Failed to search flights',
              style: TextStyle(fontSize: context.bodyMedium),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: $e',
            style: TextStyle(fontSize: context.bodyMedium),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _searchingIndex = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _history.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.wp(4)),
          child: Text(
            'Recent Searches',
            style: TextStyle(
              fontSize: context.fs(24),
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(height: context.h(12)),
        Container(
          height: context.h(98),
          // width: context.w(214),
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: context.w(5),
                offset: Offset(context.w(0), context.h(2)),
              ),
            ],
          ),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: context.wp(4)),
            itemCount: _history.length,
            separatorBuilder: (_, __) => SizedBox(width: context.w(12)),
            itemBuilder: (_, index) => _recentSearchCard(index),
          ),
        ),
      ],
    );
  }

  Widget _recentSearchCard(int index) {
    final entry = _history[index];
    final fromMap = entry['fromAirport'] as Map;
    final toMap = entry['toAirport'] as Map;
    final fromCode = fromMap['code'] as String? ?? '';
    final toCode = toMap['code'] as String? ?? '';
    final adults = entry['adults'] as int? ?? 1;
    final children = entry['children'] as int? ?? 0;
    final infants = entry['infants'] as int? ?? 0;
    final travellers = adults + children + infants;
    final departureDate = entry['departureDate'] != null
        ? DateTime.tryParse(entry['departureDate'] as String)
        : null;
    final isSearching = _searchingIndex == index;

    return GestureDetector(
      onTap: () => _repeatSearch(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: context.w(214),
        height: context.h(81),
        padding: EdgeInsets.all(context.w(12)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.r(12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              offset: const Offset(0, 4),
              blurRadius: 5.5,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Flight',
              style: TextStyle(
                fontSize: context.fs(9.5),
                fontWeight: FontWeight.w600,
                color: Color(0xFF74777E),
                letterSpacing: 0.4,
              ),
            ),
            SizedBox(height: context.h(11)),
            Row(
              children: [
                Text(
                  fromCode,
                  style: TextStyle(
                    fontSize: context.fs(12),
                    fontWeight: FontWeight.w700,
                    color: AppColors.AppBlue,
                  ),
                ),

                // Small gap after FROM code
                SizedBox(width: context.w(20)),

                // Orange line
                Container(
                  width: context.w(28),
                  height: 1,
                  color: AppColors.OrangeColor,
                ),

                // Flight icon
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.w(4)),
                  child: Image.asset(
                    _icFlight,
                    width: context.w(11.67),
                    height: context.w(11.67),
                    fit: BoxFit.contain,
                  ),
                ),

                // Orange line
                Container(
                  width: context.w(28),
                  height: 1,
                  color: AppColors.OrangeColor,
                ),

                // Small gap before TO code
                SizedBox(width: context.w(20)),

                Text(
                  toCode,
                  style: TextStyle(
                    fontSize: context.fs(12),
                    fontWeight: FontWeight.w700,
                    color: AppColors.AppBlue,
                  ),
                ),
              ],
            ),
            SizedBox(height: context.h(8)),
            Row(
              children: [
                Expanded(
                  child: Text(
                    departureDate != null
                        ? "${DateFormat('dd MMM').format(departureDate)} • $travellers ${travellers > 1 ? 'Adults' : 'Adult'}"
                        : "$travellers ${travellers > 1 ? 'Adults' : 'Adult'}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.fs(10),
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF44474E),
                    ),
                  ),
                ),
                SizedBox(width: context.w(6)),
                if (isSearching)
                  SizedBox(
                    width: context.w(16),
                    height: context.w(16),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(AppColors.orange),
                    ),
                  )
                else
                  Container(
                    width: context.w(22),
                    height: context.w(22),
                    decoration: const BoxDecoration(
                      color: AppColors.textPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward,
                      size: context.w(12),
                      color: AppColors.white,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
