/// Endpoints for the DIY Holidays backend.
///
/// Kept out of [Urls] on purpose: this is a different host
/// (diy.thewandernova.com) with its own API version prefix, no auth header,
/// and much longer read timeouts than the main API. Mixing it into [Urls]
/// would invite someone to route it through the shared [DioClient], which
/// would attach the app's bearer token and 401-refresh interceptor to a
/// service that understands neither.
///
/// Same shape as [Urls]: a base, then one member per endpoint — plain
/// constants where the path is fixed, functions where an id is interpolated.
class HolidayUrls {
  // static const String baseUrl = 'http://127.0.0.1:8000/api/v1/app/';
  static const String baseUrl = 'https://diy.thewandernova.com/api/v1/app/';

  /// No trailing slash — for callers that append their own path.
  static const String basesUrl = 'https://diy.thewandernova.com/api/v1/app';

  // ----- Discovery (no trip yet) -----

  /// The "Travelling to" list: regions ("kerala") and cities ("alleppey-in").
  /// The `slug` of a chosen row feeds [packages].
  static const String destinations = '$basesUrl/destinations/';

  /// The "Holiday By Theme" tiles.
  static const String themes = '$basesUrl/themes/';

  // ----- Packages (keyed by share_id — the saved package, never changes) -----

  /// Search submit. Takes origin / destination / adults as query parameters.
  ///
  /// Deliberately never sent a departure date: each package has a fixed date,
  /// so a date filter returns an empty list. The customer's own date is
  /// applied later through [packagePrice].
  static const String packages = '$basesUrl/packages/';

  /// The saved package at its published price.
  /// `?flight=without` drops the flight rows and lowers the price.
  static String package(String shareId) => '$basesUrl/packages/$shareId/';

  /// Reprices against the customer's real date and party size, and creates
  /// the trip. Returns the `trip_id` every later customisation works on.
  ///
  /// `flight=with` takes ~7s (live fares); `without` returns immediately.
  static String packagePrice(String shareId) =>
      '$basesUrl/packages/$shareId/price/';

  /// The activities that can be added to this package.
  static String packageAddons(String shareId) =>
      '$basesUrl/packages/$shareId/addons/';

  /// Price probe that does NOT create a trip — for use while the customer is
  /// still ticking add-ons.
  static String packageCustomise(String shareId) =>
      '$basesUrl/packages/$shareId/customise/';

  /// Hands the lead to a consultant and returns a customer-facing reference.
  static String packageEnquiry(String shareId) =>
      '$basesUrl/packages/$shareId/enquiry/';

  // ----- Trips (keyed by trip_id — the customer's own trip) -----

  /// The live trip. `stops[]` carries the `stop_id` each stay's hotel list
  /// and hotel change are addressed by.
  static String trip(String tripId) => '$basesUrl/trips/$tripId/';

  /// Flight options for one leg. GET lists them, POST changes to one.
  /// [direction] is [outbound] or [inbound].
  static String tripFlights(String tripId, String direction) =>
      '$basesUrl/trips/$tripId/flights/$direction/';

  /// Hotel options for one stop. GET lists (~40 options, ~19s on a cold
  /// stop), POST changes to one.
  static String tripStopHotels(String tripId, String stopId) =>
      '$basesUrl/trips/$tripId/stops/$stopId/hotels/';

  /// POST adds an activity to a day of the trip.
  static String tripActivities(String tripId) =>
      '$basesUrl/trips/$tripId/activities/';

  /// DELETE removes a previously added activity. [tripActivityId] is the id
  /// from the add response — NOT the add-on's own id, which the API rejects.
  static String tripActivity(String tripId, String tripActivityId) =>
      '$basesUrl/trips/$tripId/activities/$tripActivityId/';

  /// Cab class. GET lists only classes that seat the party; POST changes it
  /// and 422s with seat counts when the class is too small.
  ///
  /// There is no separate transfer endpoint — transfers are derived from the
  /// route and cab, so changing the cab rewrites the transfer rows too.
  static String tripCab(String tripId) => '$basesUrl/trips/$tripId/cab/';

  // ----- Enumerated path segments -----

  /// Departure leg.
  static const String outbound = 'outbound';

  /// Return leg.
  static const String inbound = 'return';

  static String flightDirection({required bool outbound}) =>
      outbound ? HolidayUrls.outbound : inbound;

  /// Value for the `flight` query parameter / body field.
  static String flightMode({required bool withFlight}) =>
      withFlight ? 'with' : 'without';
}
