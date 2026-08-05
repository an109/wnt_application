import '../../../../core/error/data_state.dart';
import '../../../airport/domain/entities/airport_entities.dart';
import '../../../airport/domain/usecases/get_airport_usecase.dart';

/// The destination a quote is priced for: an ISO-2 country code plus the
/// display name, both of which QuotesListing wants.
class TripDestination {
  final String countryCode;
  final String countryName;

  const TripDestination({required this.countryCode, required this.countryName});

  /// Used when the arrival airport can't be resolved. India is the safe
  /// default here — the app's inventory is India-originating, so a domestic
  /// trip is the likeliest miss.
  static const fallback = TripDestination(countryCode: 'IN', countryName: 'India');
}

/// Turns the booking's arrival airport code (e.g. "SIN") into the country the
/// insurance quote must be priced for (e.g. SG).
///
/// Reuses the airport search endpoint the app already ships. There is no
/// backend country-list endpoint, so the display name is just the ISO code.
/// Results are memoised for the process lifetime since the same airport is
/// queried on every re-price.
class ResolveTripDestinationUseCase {
  final GetAirportsUsecase getAirportsUsecase;

  ResolveTripDestinationUseCase({required this.getAirportsUsecase});

  static final Map<String, TripDestination> _cache = {};

  Future<TripDestination> call(String airportCode) async {
    final code = airportCode.trim().toUpperCase();
    if (code.isEmpty) return TripDestination.fallback;

    final cached = _cache[code];
    if (cached != null) return cached;

    final countryCode = await _countryCodeForAirport(code);
    if (countryCode == null) return TripDestination.fallback;

    final resolved = TripDestination(countryCode: countryCode, countryName: countryCode);
    _cache[code] = resolved;
    return resolved;
  }

  Future<String?> _countryCodeForAirport(String code) async {
    final result = await getAirportsUsecase.call(searchQuery: code);
    if (result is! DataSuccess<List<AirportEntity>>) return null;

    final airports = result.data ?? const <AirportEntity>[];
    if (airports.isEmpty) return null;

    // The search is fuzzy, so prefer the exact IATA match before falling back
    // to the first hit.
    final match = airports.firstWhere(
      (a) => a.airportCode.toUpperCase() == code,
      orElse: () => airports.first,
    );
    final country = match.countryCode.trim().toUpperCase();
    return country.isEmpty ? null : country;
  }
}
