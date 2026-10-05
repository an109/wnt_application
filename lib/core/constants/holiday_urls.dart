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
  static const String baseUrl = 'http://192.168.1.6:8000//api/v1/app/';
  //static const String baseUrl = 'https://diy.thewandernova.com/api/v1/app/';

  /// No trailing slash — for callers that append their own path.
  static const String basesUrl = 'http://192.168.1.6:8000/api/v1/app';
   //static const String basesUrl = 'https://diy.thewandernova.com/api/v1/app';
  
  // ----- Discovery (no trip yet) -----

  /// The "Travelling to" list: regions ("kerala") and cities ("alleppey-in").
  /// The `slug` of a chosen row feeds [packages].
  static const String destinations = '$basesUrl/destinations/';

  /// Places with trending packages, cities folded into their state.
  static const String trendingDestinations = '$basesUrl/destinations/trending/';

  /// The "Holiday By Theme" tiles.
  static const String themes = '$basesUrl/themes/';

  /// Terms, exclusions and the cancellation policy — the paperwork's own.
  static const String policies = '$basesUrl/policies/';

  // ----- Packages (keyed by share_id — the saved package, never changes) -----

  /// Search submit. Takes origin / destination / adults as query parameters.
  ///
  /// Deliberately never sent a departure date: each package has a fixed date,
  /// so a date filter returns an empty list. The customer's own date is
  /// applied later through [packagePrice].
  static const String packages = '$basesUrl/packages/';

  /// The Holiday form in one POST body — from, to, date, rooms, the Filters
  /// sheet and the sort — answered with cards, the "25/63 Packages" pair and
  /// a count beside every filter option.
  static const String packageSearch = '$basesUrl/packages/search/';

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

  /// Rooms of the hotel on a stop (or, with `?hotel_ref=`, of another one).
  static String tripStopRooms(String tripId, String stopId) =>
      '$basesUrl/trips/$tripId/stops/$stopId/rooms/';

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

  // ----- Booking (the DIY booking behind a trip) -----

  /// Raises the booking for a trip.
  static String tripBook(String tripId) => '$basesUrl/trips/$tripId/book/';

  /// A payment link for one instalment of the booking.
  static String bookingPay(String bookingId) =>
      '$basesUrl/bookings/$bookingId/pay/';

  /// Records payments the webhook may not have, and returns the booking.
  /// A Razorpay order for one instalment, for the in-app checkout.
  static String bookingOrder(String bookingId) =>
      '$basesUrl/bookings/$bookingId/order/';

  /// Signature check + record for an in-app payment.
  static String bookingVerify(String bookingId) =>
      '$basesUrl/bookings/$bookingId/verify/';

  static String bookingSync(String bookingId) =>
      '$basesUrl/bookings/$bookingId/sync/';

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
