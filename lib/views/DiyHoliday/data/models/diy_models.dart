/// Models for the DIY Holidays API (https://diy.thewandernova.com/api/v1/app/).
///
/// Every model parses defensively: the API mixes strings and numbers for
/// money/ratings and omits optional keys entirely, so nothing here assumes a
/// field is present or of a given primitive type.
library;

// ---------------------------------------------------------------- helpers

String _str(dynamic v) => v == null ? '' : v.toString();

int _int(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(_str(v)) ?? 0;
}

double _dbl(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse(_str(v)) ?? 0;
}

bool _bool(dynamic v) {
  if (v is bool) return v;
  final s = _str(v).toLowerCase();
  return s == 'true' || s == '1';
}

List<String> _strList(dynamic v) {
  if (v is List) return v.map(_str).where((e) => e.isNotEmpty).toList();
  return const [];
}

Map<String, dynamic> _map(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

List<Map<String, dynamic>> _mapList(dynamic v) =>
    v is List ? v.whereType<Map>().map(_map).toList() : const [];

/// The API hands back lists either bare (`[...]`) or wrapped
/// (`{"results": [...]}`) depending on the endpoint.
List<Map<String, dynamic>> unwrapList(dynamic data) {
  if (data is List) return _mapList(data);
  if (data is Map) return _mapList(data['results']);
  return const [];
}

// ----------------------------------------------------------- 1. destinations

/// One entry of GET /destinations/ — a region ("kerala") or a city
/// ("alleppey-in"). [slug] is what the search form sends as `destination`.
class DiyDestination {
  final String kind; // 'region' | 'city'
  final String slug;
  final String name;
  final String state;
  final String countryName;
  final String countryCode;
  final int packageCount;
  final List<String> cities;

  const DiyDestination({
    required this.kind,
    required this.slug,
    required this.name,
    required this.state,
    required this.countryName,
    required this.countryCode,
    required this.packageCount,
    required this.cities,
  });

  factory DiyDestination.fromJson(Map<String, dynamic> j) => DiyDestination(
        kind: _str(j['kind']),
        slug: _str(j['slug']),
        name: _str(j['name']),
        state: _str(j['state']),
        countryName: _str(j['country_name']),
        countryCode: _str(j['country_code']),
        packageCount: _int(j['package_count']),
        cities: _strList(j['cities']),
      );

  /// "State" / "Country" style label shown on the right of the search list.
  String get kindLabel {
    if (kind == 'region') return state.isNotEmpty ? 'State' : 'Region';
    return countryName.isNotEmpty && countryName != state ? 'City' : 'City';
  }

  String get subtitle {
    final parts = <String>[];
    if (state.isNotEmpty && state != name) parts.add(state);
    if (countryName.isNotEmpty) parts.add(countryName);
    return parts.join(', ');
  }

  Map<String, dynamic> toJson() => {
        'kind': kind,
        'slug': slug,
        'name': name,
        'state': state,
        'country_name': countryName,
        'country_code': countryCode,
        'package_count': packageCount,
        'cities': cities,
      };
}

// ----------------------------------------------------------------- 2. themes

class DiyTheme {
  final String slug;
  final String label;
  final String blurb;

  /// Artwork for the tile. The live endpoint returns slug/label/blurb only,
  /// so this is empty today and the tile falls back to its gradient. Parsed
  /// here so the Figma photo tile lights up the moment the backend sends an
  /// `image` (or `image_url`) without another app release.
  final String image;

  const DiyTheme({
    required this.slug,
    required this.label,
    required this.blurb,
    this.image = '',
  });

  bool get hasImage => image.isNotEmpty;

  factory DiyTheme.fromJson(Map<String, dynamic> j) => DiyTheme(
        slug: _str(j['slug']),
        label: _str(j['label']),
        blurb: _str(j['blurb']),
        image: _str(j['image'] ?? j['image_url']),
      );
}

// --------------------------------------------------------------- 3. packages

class DiyPackageSummary {
  final String shareId;
  final String title;
  final String destination;
  final String countryCode;
  final int nights;
  final int days;
  final String origin;
  final String originSlug;
  final String departureDate;
  final int adults;
  final int children;
  final List<String> themes;
  final String currency;
  final double priceWithFlight;
  final double priceWithoutFlight;
  final bool hasCabItinerary;
  final String image;
  final bool priceIsStale;

  // --- Figma fields the live API does not send yet -------------------------
  // Parsed defensively so each one starts working the moment the backend
  // adds it, with no app change beyond flipping its DiyFeatures flag.

  /// Star rating out of 5. Waiting on `rating`.
  final double rating;

  /// Number of reviews behind [rating]. Waiting on `review_count`.
  final int reviewCount;

  /// e.g. "4 Star Hotel". Waiting on `hotel_class_label`.
  final String hotelClassLabel;

  /// e.g. "Selected Meals". Waiting on `meal_plan_label`.
  final String mealPlanLabel;

  /// Deposit that books the package. Waiting on `part_payment.amount`.
  final double partPaymentAmount;

  /// Pre-rendered countdown, e.g. "05h 24m". Waiting on `deal.ends_in`.
  final String dealEndsInLabel;

  const DiyPackageSummary({
    required this.shareId,
    required this.title,
    required this.destination,
    required this.countryCode,
    required this.nights,
    required this.days,
    required this.origin,
    required this.originSlug,
    required this.departureDate,
    required this.adults,
    required this.children,
    required this.themes,
    required this.currency,
    required this.priceWithFlight,
    required this.priceWithoutFlight,
    required this.hasCabItinerary,
    required this.image,
    required this.priceIsStale,
    this.rating = 0,
    this.reviewCount = 0,
    this.hotelClassLabel = '',
    this.mealPlanLabel = '',
    this.partPaymentAmount = 0,
    this.dealEndsInLabel = '',
  });

  factory DiyPackageSummary.fromJson(Map<String, dynamic> j) =>
      DiyPackageSummary(
        shareId: _str(j['share_id']),
        title: _str(j['title']),
        destination: _str(j['destination']),
        countryCode: _str(j['country_code']),
        nights: _int(j['nights']),
        days: _int(j['days']),
        origin: _str(j['origin']),
        originSlug: _str(j['origin_slug']),
        departureDate: _str(j['departure_date']),
        adults: _int(j['adults']),
        children: _int(j['children']),
        themes: _strList(j['themes']),
        currency: _str(j['currency']).isEmpty ? 'INR' : _str(j['currency']),
        priceWithFlight: _dbl(j['price_with_flight']),
        priceWithoutFlight: _dbl(j['price_without_flight']),
        hasCabItinerary: _bool(j['has_cab_itinerary']),
        image: _str(j['image']),
        priceIsStale: _bool(j['price_is_stale']),
        rating: _dbl(j['rating']),
        reviewCount: _int(j['review_count']),
        hotelClassLabel: _str(j['hotel_class_label']),
        mealPlanLabel: _str(j['meal_plan_label']),
        partPaymentAmount: _dbl(
          j['part_payment'] is Map ? j['part_payment']['amount'] : null,
        ),
        dealEndsInLabel:
            _str(j['deal'] is Map ? j['deal']['ends_in'] : null),
      );

  double priceFor(bool withFlight) =>
      withFlight ? priceWithFlight : priceWithoutFlight;
}

class DiyPackagePage {
  final int count;
  final int page;
  final int pageSize;
  final bool hasNext;
  final List<DiyPackageSummary> results;

  const DiyPackagePage({
    required this.count,
    required this.page,
    required this.pageSize,
    required this.hasNext,
    required this.results,
  });

  factory DiyPackagePage.fromJson(dynamic data) {
    final j = _map(data);
    return DiyPackagePage(
      count: _int(j['count']),
      page: _int(j['page']),
      pageSize: _int(j['page_size']),
      hasNext: _bool(j['has_next']),
      results:
          unwrapList(data).map(DiyPackageSummary.fromJson).toList(),
    );
  }

  static const empty = DiyPackagePage(
    count: 0,
    page: 1,
    pageSize: 20,
    hasNext: false,
    results: [],
  );
}

// ------------------------------------------------------- itinerary rows/days

/// A single line inside a day: FLIGHT, HOTEL, HOTEL_CHECKOUT, TRANSFER,
/// SIGHTSEEING, MEAL or ACTIVITY. The shape of [detail] varies by [kind], so
/// the typed getters below only read what that kind actually carries.
class DiyRow {
  final String kind;
  final String title;
  final int order;
  final int nights;
  final String destination;
  final String transferKind;
  final String places;
  final int durationMinutes;
  final bool complimentary;
  final List<DiyPoi> pois;
  final Map<String, dynamic> detail;

  const DiyRow({
    required this.kind,
    required this.title,
    required this.order,
    required this.nights,
    required this.destination,
    required this.transferKind,
    required this.places,
    required this.durationMinutes,
    required this.complimentary,
    required this.pois,
    required this.detail,
  });

  factory DiyRow.fromJson(Map<String, dynamic> j) => DiyRow(
        kind: _str(j['kind']),
        title: _str(j['title']),
        order: _int(j['order']),
        nights: _int(j['nights']),
        destination: _str(j['destination']),
        transferKind: _str(j['transfer_kind']),
        places: _str(j['places']),
        durationMinutes: _int(j['duration_minutes']),
        complimentary: _bool(j['complimentary']),
        pois: _mapList(j['pois']).map(DiyPoi.fromJson).toList(),
        detail: _map(j['detail']),
      );

  // -- FLIGHT
  String get flightNumber => _str(detail['flight_number']);
  String get carrierName => _str(detail['carrier_name']);
  String get carrier => _str(detail['carrier']);
  String get departureAt => _str(detail['departure_at']);
  String get arrivalAt => _str(detail['arrival_at']);
  int get flightDurationMinutes => _int(detail['duration_minutes']);
  int get stops => _int(detail['stops']);
  String get baggageChecked => _str(_map(detail['baggage'])['checked']);

  // -- HOTEL
  String get hotelName => _str(detail['name']);
  String get starRating => _str(detail['star_rating']);
  String get reviewRating => _str(detail['review_rating']);
  String get roomName => _str(detail['room_name']);
  String get boardBasis => _str(detail['board_basis']);
  String get location => _str(detail['location']);
  String get heroImage => _str(detail['hero_image']);
  List<String> get images => _strList(detail['images']);
  String get checkIn => _str(detail['check_in']);
  String get checkOut => _str(detail['check_out']);

  // -- ACTIVITY
  String get shortDescription => _str(detail['short_description']);
  String get inclusions => _str(detail['inclusions']);
}

class DiyPoi {
  final String name;
  final String image;
  final int durationMinutes;

  const DiyPoi({
    required this.name,
    required this.image,
    required this.durationMinutes,
  });

  factory DiyPoi.fromJson(Map<String, dynamic> j) => DiyPoi(
        name: _str(j['name']),
        image: _str(j['image']),
        durationMinutes: _int(j['duration_minutes']),
      );
}

class DiyDay {
  final int day;
  final String date;
  final String label;
  final String destination;
  final String fromDestination;
  final bool isTransit;
  final bool isDeparture;
  final List<DiyRow> rows;

  const DiyDay({
    required this.day,
    required this.date,
    required this.label,
    required this.destination,
    required this.fromDestination,
    required this.isTransit,
    required this.isDeparture,
    required this.rows,
  });

  factory DiyDay.fromJson(Map<String, dynamic> j) {
    final rows = _mapList(j['rows']).map(DiyRow.fromJson).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return DiyDay(
      day: _int(j['day']),
      date: _str(j['date']),
      label: _str(j['label']),
      destination: _str(j['destination']),
      fromDestination: _str(j['from_destination']),
      isTransit: _bool(j['is_transit']),
      isDeparture: _bool(j['is_departure']),
      rows: rows,
    );
  }
}

class DiyCounts {
  final int days;
  final int meals;
  final int hotels;
  final int addOns;
  final int flights;
  final int transfers;
  final int activities;

  const DiyCounts({
    required this.days,
    required this.meals,
    required this.hotels,
    required this.addOns,
    required this.flights,
    required this.transfers,
    required this.activities,
  });

  factory DiyCounts.fromJson(dynamic v) {
    final j = _map(v);
    return DiyCounts(
      days: _int(j['days']),
      meals: _int(j['meals']),
      hotels: _int(j['hotels']),
      addOns: _int(j['add_ons']),
      flights: _int(j['flights']),
      transfers: _int(j['transfers']),
      activities: _int(j['activities']),
    );
  }
}

/// The cab currently attached to a package/trip (not the list of choices —
/// that is [DiyCabOptions]).
class DiyCab {
  final bool isIncluded;
  final String selected;
  final String label;
  final int seats;
  final int luggage;
  final String image;

  const DiyCab({
    required this.isIncluded,
    required this.selected,
    required this.label,
    required this.seats,
    required this.luggage,
    required this.image,
  });

  factory DiyCab.fromJson(dynamic v) {
    final j = _map(v);
    return DiyCab(
      isIncluded: _bool(j['is_included']),
      selected: _str(j['selected']),
      label: _str(j['label']),
      seats: _int(j['seats']),
      luggage: _int(j['luggage']),
      image: _str(j['image']),
    );
  }
}

// --------------------------------------------------- 4. package detail (view)

class DiyPackageDetail {
  final String shareId;
  final String title;
  final String origin;
  final String originSlug;
  final String destination;
  final String destinationSlug;
  final String departureDate;
  final String countryCode;
  final int nights;
  final int adults;
  final int children;
  final List<String> themes;
  final String currency;
  final bool flightIncluded;
  final double price;
  final double priceWithFlight;
  final double priceWithoutFlight;
  final String validUntil;
  final bool priceIsStale;
  final bool isAvailable;
  final List<DiyDay> days;
  final DiyCounts counts;
  final DiyCab cab;

  const DiyPackageDetail({
    required this.shareId,
    required this.title,
    required this.origin,
    required this.originSlug,
    required this.destination,
    required this.destinationSlug,
    required this.departureDate,
    required this.countryCode,
    required this.nights,
    required this.adults,
    required this.children,
    required this.themes,
    required this.currency,
    required this.flightIncluded,
    required this.price,
    required this.priceWithFlight,
    required this.priceWithoutFlight,
    required this.validUntil,
    required this.priceIsStale,
    required this.isAvailable,
    required this.days,
    required this.counts,
    required this.cab,
  });

  factory DiyPackageDetail.fromJson(dynamic data) {
    final j = _map(data);
    return DiyPackageDetail(
      shareId: _str(j['share_id']),
      title: _str(j['title']),
      origin: _str(j['origin']),
      originSlug: _str(j['origin_slug']),
      destination: _str(j['destination']),
      destinationSlug: _str(j['destination_slug']),
      departureDate: _str(j['departure_date']),
      countryCode: _str(j['country_code']),
      nights: _int(j['nights']),
      adults: _int(j['adults']),
      children: _int(j['children']),
      themes: _strList(j['themes']),
      currency: _str(j['currency']).isEmpty ? 'INR' : _str(j['currency']),
      flightIncluded: _bool(j['flight_included']),
      price: _dbl(j['price']),
      priceWithFlight: _dbl(j['price_with_flight']),
      priceWithoutFlight: _dbl(j['price_without_flight']),
      validUntil: _str(j['valid_until']),
      priceIsStale: _bool(j['price_is_stale']),
      isAvailable: j['is_available'] == null ? true : _bool(j['is_available']),
      days: _mapList(j['days']).map(DiyDay.fromJson).toList(),
      counts: DiyCounts.fromJson(j['counts']),
      cab: DiyCab.fromJson(j['cab']),
    );
  }
}

// ------------------------------------------------------------ 5/6. the trip

class DiyStop {
  final String stopId;
  final String destination;
  final int nights;

  const DiyStop({
    required this.stopId,
    required this.destination,
    required this.nights,
  });

  factory DiyStop.fromJson(Map<String, dynamic> j) => DiyStop(
        stopId: _str(j['stop_id']),
        destination: _str(j['destination']),
        nights: _int(j['nights']),
      );
}

/// The customer's own trip. Returned by POST /price/ and by every mutation
/// (flight/hotel/cab/activity), each time carrying the refreshed
/// [grandTotal] — so no separate price call is ever needed after a change.
class DiyTrip {
  final String tripId;
  final String shareId;
  final String title;
  final String origin;
  final String departureDate;
  final int adults;
  final int children;
  final bool flightIncluded;
  final String currency;
  final double grandTotal;
  final bool isFinal;
  final List<String> incomplete;
  final List<DiyDay> days;
  final List<DiyStop> stops;
  final DiyCounts counts;
  final DiyCab cab;

  const DiyTrip({
    required this.tripId,
    required this.shareId,
    required this.title,
    required this.origin,
    required this.departureDate,
    required this.adults,
    required this.children,
    required this.flightIncluded,
    required this.currency,
    required this.grandTotal,
    required this.isFinal,
    required this.incomplete,
    required this.days,
    required this.stops,
    required this.counts,
    required this.cab,
  });

  /// Parses a trip payload.
  ///
  /// The mutation endpoints (change flight/hotel/cab, add activity) answer
  /// with a *partial* trip — the refreshed itinerary and `grand_total`, but
  /// not always the header fields such as `origin`, `departure_date`,
  /// `adults` or `stops`. Pass the trip being replaced as [previous] and any
  /// key the response omits is carried over instead of being reset to
  /// empty/zero.
  factory DiyTrip.fromJson(dynamic data, {DiyTrip? previous}) {
    final j = _map(data);
    // Some routes nest the trip under `trip`, others return it flat.
    final t = j['trip'] is Map ? _map(j['trip']) : j;

    T pick<T>(String key, T parsed, T Function(DiyTrip) fallback) {
      if (t.containsKey(key) && t[key] != null) return parsed;
      return previous == null ? parsed : fallback(previous);
    }

    final tripId = _str(t['trip_id']).isNotEmpty
        ? _str(t['trip_id'])
        : (_str(t['id']).isNotEmpty ? _str(t['id']) : previous?.tripId ?? '');

    return DiyTrip(
      tripId: tripId,
      shareId: pick('share_id', _str(t['share_id']), (p) => p.shareId),
      title: pick('title', _str(t['title']), (p) => p.title),
      origin: pick('origin', _str(t['origin']), (p) => p.origin),
      departureDate: pick(
        'departure_date',
        _str(t['departure_date']),
        (p) => p.departureDate,
      ),
      adults: pick('adults', _int(t['adults']), (p) => p.adults),
      children: pick('children', _int(t['children']), (p) => p.children),
      flightIncluded: pick(
        'flight_included',
        _bool(t['flight_included']),
        (p) => p.flightIncluded,
      ),
      currency: _str(t['currency']).isNotEmpty
          ? _str(t['currency'])
          : (previous?.currency ?? 'INR'),
      // Always the response's own — a mutation exists to change this.
      grandTotal: t.containsKey('grand_total')
          ? _dbl(t['grand_total'])
          : (previous?.grandTotal ?? 0),
      isFinal: pick('is_final', _bool(t['is_final']), (p) => p.isFinal),
      incomplete: pick(
        'incomplete',
        _strList(t['incomplete']),
        (p) => p.incomplete,
      ),
      days: pick(
        'days',
        _mapList(t['days']).map(DiyDay.fromJson).toList(),
        (p) => p.days,
      ),
      stops: pick(
        'stops',
        _mapList(t['stops']).map(DiyStop.fromJson).toList(),
        (p) => p.stops,
      ),
      counts: pick('counts', DiyCounts.fromJson(t['counts']), (p) => p.counts),
      cab: pick('cab', DiyCab.fromJson(t['cab']), (p) => p.cab),
    );
  }
}

// ------------------------------------------------------------- 7/8. flights

class DiyFlightOption {
  final String offerRef;
  final String title;
  final String flightNumber;
  final String carrier;
  final String carrierName;
  final String carrierLogo;
  final String departureAt;
  final String arrivalAt;
  final int durationMinutes;
  final int stops;
  final String baggageCabin;
  final String baggageChecked;
  final double total;
  final double delta;
  final bool isSelected;
  final bool refundable;
  final int seatsAvailable;

  const DiyFlightOption({
    required this.offerRef,
    required this.title,
    required this.flightNumber,
    required this.carrier,
    required this.carrierName,
    required this.carrierLogo,
    required this.departureAt,
    required this.arrivalAt,
    required this.durationMinutes,
    required this.stops,
    required this.baggageCabin,
    required this.baggageChecked,
    required this.total,
    required this.delta,
    required this.isSelected,
    required this.refundable,
    required this.seatsAvailable,
  });

  factory DiyFlightOption.fromJson(Map<String, dynamic> j) => DiyFlightOption(
        offerRef: _str(j['offer_ref']),
        title: _str(j['title']),
        flightNumber: _str(j['flight_number']),
        carrier: _str(j['carrier']),
        carrierName: _str(j['carrier_name']),
        carrierLogo: _str(j['carrier_logo']),
        departureAt: _str(j['departure_at']),
        arrivalAt: _str(j['arrival_at']),
        durationMinutes: _int(j['duration_minutes']),
        stops: _int(j['stops']),
        baggageCabin: _str(j['baggage_cabin']),
        baggageChecked: _str(j['baggage_checked']),
        total: _dbl(j['total']),
        delta: _dbl(j['delta']),
        isSelected: _bool(j['is_selected']),
        refundable: _bool(j['refundable']),
        seatsAvailable: _int(j['seats_available']),
      );
}

// -------------------------------------------------------------- 9/10. hotels

class DiyHotelOption {
  final String hotelRef;
  final String name;
  final String starRating;
  final String reviewRating;
  final int reviewCount;
  final String location;
  final String distanceKm;
  final String heroImage;
  final List<String> images;
  final double total;
  final double delta;
  final bool isSelected;
  final bool freeBreakfast;

  const DiyHotelOption({
    required this.hotelRef,
    required this.name,
    required this.starRating,
    required this.reviewRating,
    required this.reviewCount,
    required this.location,
    required this.distanceKm,
    required this.heroImage,
    required this.images,
    required this.total,
    required this.delta,
    required this.isSelected,
    required this.freeBreakfast,
  });

  factory DiyHotelOption.fromJson(Map<String, dynamic> j) => DiyHotelOption(
        hotelRef: _str(j['hotel_ref']),
        name: _str(j['name']),
        starRating: _str(j['star_rating']),
        reviewRating: _str(j['review_rating']),
        reviewCount: _int(j['review_count']),
        location: _str(j['location']),
        distanceKm: _str(j['distance_km']),
        heroImage: _str(j['hero_image']),
        images: _strList(j['images']),
        total: _dbl(j['total']),
        delta: _dbl(j['delta']),
        isSelected: _bool(j['is_selected']),
        freeBreakfast: _bool(j['free_breakfast']),
      );

  /// Star rating comes back as "2.0"/"3" — round it for the star chips.
  int get stars => _dbl(starRating).round();
}

// ------------------------------------------------------- 11/12/13. add-ons

class DiyAddon {
  final String id;
  final String name;
  final String destination;
  final String category;
  final int durationMinutes;
  final String shortDescription;
  final String image;
  final String currency;
  final double pricePerPerson;
  final String priceNote;
  final bool isComplimentary;

  const DiyAddon({
    required this.id,
    required this.name,
    required this.destination,
    required this.category,
    required this.durationMinutes,
    required this.shortDescription,
    required this.image,
    required this.currency,
    required this.pricePerPerson,
    required this.priceNote,
    required this.isComplimentary,
  });

  factory DiyAddon.fromJson(Map<String, dynamic> j) => DiyAddon(
        id: _str(j['id']),
        name: _str(j['name']),
        destination: _str(j['destination']),
        category: _str(j['category']),
        durationMinutes: _int(j['duration_minutes']),
        shortDescription: _str(j['short_description']),
        image: _str(j['image']),
        currency: _str(j['currency']).isEmpty ? 'INR' : _str(j['currency']),
        pricePerPerson: _dbl(j['price_per_person']),
        priceNote: _str(j['price_note']),
        isComplimentary: _bool(j['is_complimentary']),
      );
}

/// POST /trips/{trip}/activities/ answers with the id of the *trip activity*
/// that was created — the handle needed to DELETE it again — plus the
/// refreshed trip.
class DiyAddedActivity {
  final String id;
  final DiyTrip trip;

  const DiyAddedActivity({required this.id, required this.trip});

  factory DiyAddedActivity.fromJson(dynamic data, {DiyTrip? previous}) {
    final j = _map(data);
    final id = _str(j['id']).isNotEmpty
        ? _str(j['id'])
        : _str(_map(j['activity'])['id']);
    return DiyAddedActivity(
      id: id,
      trip: DiyTrip.fromJson(data, previous: previous),
    );
  }
}

// ------------------------------------------------------------ 14. customise

/// POST /packages/{share}/customise/ — a price probe that does NOT create a
/// trip, used to show "what would this cost" while the user ticks add-ons.
class DiyCustomiseQuote {
  final String currency;
  final double total;
  final double basePrice;
  final double addOnsTotal;
  final Map<String, dynamic> raw;

  const DiyCustomiseQuote({
    required this.currency,
    required this.total,
    required this.basePrice,
    required this.addOnsTotal,
    required this.raw,
  });

  factory DiyCustomiseQuote.fromJson(dynamic data) {
    final j = _map(data);
    // The payload has settled on `total`/`grand_total` at different times —
    // take whichever is present rather than showing ₹0.
    final total = [
      j['grand_total'],
      j['total'],
      j['price'],
    ].firstWhere((v) => v != null, orElse: () => 0);
    return DiyCustomiseQuote(
      currency: _str(j['currency']).isEmpty ? 'INR' : _str(j['currency']),
      total: _dbl(total),
      basePrice: _dbl(j['base_price'] ?? j['package_price']),
      addOnsTotal: _dbl(j['add_ons_total'] ?? j['addons_total']),
      raw: j,
    );
  }
}

// -------------------------------------------------------------- 15. enquiry

class DiyEnquiryResult {
  final String reference;
  final String message;

  const DiyEnquiryResult({required this.reference, required this.message});

  factory DiyEnquiryResult.fromJson(dynamic data) {
    final j = _map(data);
    return DiyEnquiryResult(
      reference: _str(j['reference']).isNotEmpty
          ? _str(j['reference'])
          : _str(j['enquiry_reference'] ?? j['id']),
      message: _str(j['message']),
    );
  }
}

// ------------------------------------------------------------------- cab

class DiyCabOption {
  final String code;
  final String name;
  final String label;
  final int seats;
  final int luggage;
  final String image;
  final bool isSelected;

  const DiyCabOption({
    required this.code,
    required this.name,
    required this.label,
    required this.seats,
    required this.luggage,
    required this.image,
    required this.isSelected,
  });

  factory DiyCabOption.fromJson(Map<String, dynamic> j) => DiyCabOption(
        code: _str(j['code']),
        name: _str(j['name']),
        label: _str(j['label']),
        seats: _int(j['seats']),
        luggage: _int(j['luggage']),
        image: _str(j['image']),
        isSelected: _bool(j['is_selected']),
      );
}

class DiyCabOptions {
  final bool isIncluded;
  final String selected;
  final List<DiyCabOption> options;

  const DiyCabOptions({
    required this.isIncluded,
    required this.selected,
    required this.options,
  });

  factory DiyCabOptions.fromJson(dynamic data) {
    final j = _map(data);
    return DiyCabOptions(
      isIncluded: _bool(j['is_included']),
      selected: _str(j['selected']),
      options: _mapList(j['options']).map(DiyCabOption.fromJson).toList(),
    );
  }

  static const empty =
      DiyCabOptions(isIncluded: false, selected: '', options: []);
}
