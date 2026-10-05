import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/holiday_urls.dart';
import 'models/diy_models.dart';

/// Thrown by every [DiyHolidayApi] call so screens can show one message
/// without reaching for DioException internals.
class DiyApiException implements Exception {
  final String message;
  final int? statusCode;

  /// Present on 422 from the cab endpoint: the seat/luggage numbers the
  /// backend reports for the party size.
  final Map<String, dynamic>? detail;

  DiyApiException(this.message, {this.statusCode, this.detail});

  bool get isUnprocessable => statusCode == 422;

  @override
  String toString() => message;
}

/// The DIY Holidays backend.
///
/// Deliberately kept on its own [Dio] rather than the app-wide [DioClient]:
/// it lives on a different host (diy.thewandernova.com), takes no auth
/// header, and needs long read timeouts (hotel search is ~19s, the
/// with-flight price call ~7s). Routing it through the shared client would
/// attach the app's bearer token and its 401-refresh interceptor to a
/// service that has no idea about either.
class DiyHolidayApi {
  /// The host lives in [HolidayUrls] alongside every DIY path, the same way
  /// the main API's host lives in `Urls`.
  static const String baseUrl = HolidayUrls.baseUrl;

  final Dio _dio;

  DiyHolidayApi({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                // Hotel options take ~19s on a cold stop; keep generous room.
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 120),
                sendTimeout: const Duration(seconds: 60),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
                // Every POST goes out as raw JSON — the API rejects
                // form/text bodies with "Expected a dictionary, but got str."
                contentType: Headers.jsonContentType,
                responseType: ResponseType.json,
              ),
            );

  // ------------------------------------------------------------- plumbing

  Future<dynamic> _get(String path, {Map<String, dynamic>? query}) async {
    try {
      final res = await _dio.get(
        path,
        queryParameters: (query?..removeWhere((_, v) => v == null))?.isEmpty ??
                true
            ? null
            : query,
      );
      return res.data;
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    try {
      final res = await _dio.post(path, data: body);
      return res.data;
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  Future<dynamic> _put(String path) async {
    try {
      final res = await _dio.put(path);
      return res.data;
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  Future<dynamic> _delete(String path) async {
    try {
      final res = await _dio.delete(path);
      return res.data;
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  DiyApiException _toException(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;

    String message = 'Something went wrong. Please try again.';
    Map<String, dynamic>? detail;

    if (data is Map) {
      final err = data['error'];
      if (err is Map) {
        message = (err['message'] ?? message).toString();
        if (err['detail'] is Map) {
          detail = Map<String, dynamic>.from(err['detail']);
        }
      } else if (data['detail'] != null) {
        message = data['detail'].toString();
      } else if (data['message'] != null) {
        message = data['message'].toString();
      }
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      message = 'The request took too long. Please try again.';
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'No internet connection.';
    }

    debugPrint(
      'DIY API error [$status] ${e.requestOptions.method} '
      '${e.requestOptions.uri}\n  sent: ${e.requestOptions.data}\n'
      '  body: $data',
    );
    return DiyApiException(message, statusCode: status, detail: detail);
  }

  // ------------------------------------------------- 1. destinations ("to")

  /// GET /destinations/ — the "Travelling to" list. Returns regions
  /// ("kerala") and cities ("alleppey-in"); the `slug` feeds [searchPackages].
  Future<List<DiyDestination>> getDestinations() async {
    final data = await _get(HolidayUrls.destinations);
    return unwrapList(data).map(DiyDestination.fromJson).toList();
  }

  // ------------------------------------------------------------ 2. themes

  /// GET /themes/ — the "Holiday By Theme" tiles.
  Future<List<DiyTheme>> getThemes() async {
    final data = await _get(HolidayUrls.themes);
    return unwrapList(data).map(DiyTheme.fromJson).toList();
  }

  /// GET /policies/ — terms, exclusions and the cancellation policy.
  Future<DiyPolicies> getPolicies() async {
    final data = await _get(HolidayUrls.policies);
    return DiyPolicies.fromJson(data);
  }

  // ------------------------------------------------------------ 3. search

  /// GET /packages/ — the search form's submit.
  ///
  /// The departure date is deliberately NOT sent: each package has a fixed
  /// date, so a date filter returns nothing. The customer's own date is
  /// applied later through [priceForDates].
  Future<DiyPackagePage> searchPackages({
    String? origin,
    String? destination,
    int? adults,
    int? children,
    String? theme,
    String? flight, // 'with' | 'without'
    num? maxPrice,
    int? nights,
    int? page,
  }) async {
    final data = await _get(HolidayUrls.packages, query: {
      'origin': origin,
      'destination': destination,
      'adults': adults,
      'children': children,
      'theme': theme,
      'flight': flight,
      // Must go out as a whole number: the backend silently ignores
      // `max_price=15000.0` (returns every package) but honours
      // `max_price=15000`, and Dio would serialise a double with the `.0`.
      'max_price': maxPrice?.round(),
      'nights': nights,
      'page': page,
    });
    return DiyPackagePage.fromJson(data);
  }

  /// POST /packages/search/ — the results screen and the Filters sheet.
  ///
  /// Takes the whole form. `origin` and the departure date are echoed, not
  /// filtered on: a saved package can be taken from any city on any date, and
  /// [priceForDates] prices it for theirs. Card prices are the saved ones, per
  /// adult.
  Future<DiySearchResult> searchPackagesByBody({
    String? origin,
    String? destination,
    DateTime? departureDate,
    required List<Map<String, dynamic>> rooms,
    // null shows both kinds of package; true only those sold with flights,
    // false only land packages.
    bool? withFlight,
    Map<String, dynamic> filters = const {},
    String sort = 'popularity',
    int page = 1,
    int pageSize = 20,
  }) async {
    final data = await _post(HolidayUrls.packageSearch, {
      'origin': origin ?? '',
      'destination': destination ?? '',
      if (departureDate != null) 'departure_date': _ymd(departureDate),
      'rooms': rooms,
      'flight': withFlight == null
          ? 'any'
          : HolidayUrls.flightMode(withFlight: withFlight),
      'filters': filters,
      'sort': sort,
      'page': page,
      'page_size': pageSize,
    });
    return DiySearchResult.fromJson(data);
  }

  // ------------------------------------------------- 4. saved package view

  /// GET /packages/{share_id}/ — the saved package at its published price.
  /// `flight=without` drops the flight rows and lowers the price.
  Future<DiyPackageDetail> getPackage(
    String shareId, {
    bool withFlight = true,
  }) async {
    final data = await _get(
      HolidayUrls.package(shareId),
      query: {'flight': HolidayUrls.flightMode(withFlight: withFlight)},
    );
    return DiyPackageDetail.fromJson(data);
  }

  // ------------------------------------------ 5. real price → creates trip

  /// POST /packages/{share_id}/price/ — reprices the package against the
  /// customer's own date and party, and creates the trip.
  ///
  /// `flight: with` takes ~7s (live fares), `without` returns immediately —
  /// callers must show a loading state. The returned `trip_id` is what every
  /// later customisation works on.
  ///
  /// [rooms] is the Rooms & Guests split with every child's age
  /// (`[{"adults": 2, "child_ages": [6]}]`). When sent it replaces [adults]
  /// and [children], which older backends still read.
  Future<DiyTrip> priceForDates({
    required String shareId,
    required DateTime departureDate,
    required int adults,
    int children = 0,
    List<Map<String, dynamic>>? rooms,
    String? origin,
    bool withFlight = true,
  }) async {
    try {
      final data = await _post(HolidayUrls.packagePrice(shareId), {
        'departure_date': _ymd(departureDate),
        'adults': adults,
        'children': children,
        if (rooms != null && rooms.isNotEmpty) 'rooms': rooms,
        if (origin != null && origin.isNotEmpty) 'origin': origin,
        'flight': HolidayUrls.flightMode(withFlight: withFlight),
      });
      return DiyTrip.fromJson(data);
    } on DiyApiException catch (e) {
      // Confirmed against the live API: the same request that succeeds with
      // `children: 0` answers 500 (HTML error page, no JSON detail) as soon
      // as children > 0. Say so rather than showing the generic message.
      if (children > 0 && e.statusCode == 500) {
        throw DiyApiException(
          'This package cannot be priced with children yet. '
          'Try again with adults only, or send an enquiry and a consultant '
          'will price it for you.',
          statusCode: e.statusCode,
        );
      }
      rethrow;
    }
  }

  // ---------------------------------------------------------- 6. view trip

  /// GET /trips/{trip_id}/ — the live trip, including `stops[]` whose
  /// `stop_id` is needed to browse or change that stay's hotel.
  Future<DiyTrip> getTrip(String tripId) async {
    final data = await _get(HolidayUrls.trip(tripId));
    return DiyTrip.fromJson(data);
  }

  // ------------------------------------------------------- 7/8. flights

  /// GET /trips/{trip_id}/flights/{outbound|return}/
  Future<List<DiyFlightOption>> getFlightOptions({
    required String tripId,
    required bool outbound,
  }) async {
    final data =
await _get(HolidayUrls.tripFlights(
      tripId,
      HolidayUrls.flightDirection(outbound: outbound),
    ));
    return unwrapList(data).map(DiyFlightOption.fromJson).toList();
  }

  /// POST /trips/{trip_id}/flights/{direction}/ — returns the whole trip
  /// with the new grand total, so no follow-up price call is needed.
  Future<DiyTrip> changeFlight({
    required String tripId,
    required bool outbound,
    required String offerRef,
    DiyTrip? previous,
  }) async {
    final data = await _post(
      HolidayUrls.tripFlights(
        tripId,
        HolidayUrls.flightDirection(outbound: outbound),
      ),
      {'offer_ref': offerRef},
    );
    return DiyTrip.fromJson(data, previous: previous);
  }

  /// DELETE /trips/{trip_id}/flights/{direction}/ — drops that leg; the
  /// customer makes their own way for it. Answers with the repriced trip.
  Future<DiyTrip> removeFlight({
    required String tripId,
    required bool outbound,
    DiyTrip? previous,
  }) async {
    final data = await _delete(HolidayUrls.tripFlights(
      tripId,
      HolidayUrls.flightDirection(outbound: outbound),
    ));
    return DiyTrip.fromJson(data, previous: previous);
  }

  /// PUT /trips/{trip_id}/flights/{direction}/ — puts a dropped leg back
  /// with a freshly searched flight; the other leg stays as it was. A live
  /// search.
  Future<DiyTrip> restoreFlight({
    required String tripId,
    required bool outbound,
    DiyTrip? previous,
  }) async {
    final data = await _put(HolidayUrls.tripFlights(
      tripId,
      HolidayUrls.flightDirection(outbound: outbound),
    ));
    return DiyTrip.fromJson(data, previous: previous);
  }

  // -------------------------------------------------------- 9/10. hotels

  /// GET /trips/{trip_id}/stops/{stop_id}/hotels/ — ~40 options; the first
  /// call for a stop takes ~19s.
  Future<List<DiyHotelOption>> getHotelOptions({
    required String tripId,
    required String stopId,
  }) async {
    final data = await _get(HolidayUrls.tripStopHotels(tripId, stopId));
    return unwrapList(data).map(DiyHotelOption.fromJson).toList();
  }

  /// POST /trips/{trip_id}/stops/{stop_id}/hotels/ — `room_ref` is optional;
  /// omitting it lets the backend pick a room.
  Future<DiyTrip> changeHotel({
    required String tripId,
    required String stopId,
    required String hotelRef,
    String? roomRef,
    DiyTrip? previous,
  }) async {
    final data = await _post(HolidayUrls.tripStopHotels(tripId, stopId), {
      'hotel_ref': hotelRef,
      if (roomRef != null && roomRef.isNotEmpty) 'room_ref': roomRef,
    });
    return DiyTrip.fromJson(data, previous: previous);
  }

  /// GET /trips/{trip_id}/stops/{stop_id}/rooms/ — without [hotelRef], the
  /// hotel already on the stay with its photos, facilities and rooms; with
  /// it, that hotel's rooms. A live supplier search.
  Future<DiyHotelRooms> getRooms({
    required String tripId,
    required String stopId,
    String? hotelRef,
  }) async {
    final data = await _get(
      HolidayUrls.tripStopRooms(tripId, stopId),
      query: {
        if (hotelRef != null && hotelRef.isNotEmpty) 'hotel_ref': hotelRef,
      },
    );
    return DiyHotelRooms.fromJson(data);
  }

  // ----------------------------------------------------- 11/12/13. add-ons

  /// GET /packages/{share_id}/addons/ — the activities that can be added.
  Future<List<DiyAddon>> getAddons(String shareId) async {
    final data = await _get(HolidayUrls.packageAddons(shareId));
    return unwrapList(data).map(DiyAddon.fromJson).toList();
  }

  /// POST /trips/{trip_id}/activities/ — adds the activity and returns the
  /// refreshed trip.
  ///
  /// The spec says the response carries the new trip-activity `id` to use
  /// with [removeActivity]. The deployed API does not: it answers with the
  /// trip alone (`trip_id, currency, grand_total, is_final, incomplete,
  /// days, counts, cab`) and the trip's own ACTIVITY rows carry no id
  /// either, so [DiyAddedActivity.id] comes back empty and the add cannot be
  /// undone from the app. Passing the add-on's own id to the delete route is
  /// rejected with 404 "That add-on is not on this trip." The parsing here
  /// already picks the id up the moment the backend starts sending one.
  Future<DiyAddedActivity> addActivity({
    required String tripId,
    required String activityId,
    required int day,
    DiyTrip? previous,
  }) async {
    final data = await _post(HolidayUrls.tripActivities(tripId), {
      'activity': activityId,
      'day': day,
    });
    return DiyAddedActivity.fromJson(data, previous: previous);
  }

  /// DELETE /trips/{trip_id}/activities/{trip_activity_id}/
  Future<void> removeActivity({
    required String tripId,
    required String tripActivityId,
  }) async {
    await _delete(HolidayUrls.tripActivity(tripId, tripActivityId));
  }

  // -------------------------------------------------------- 14. customise

  /// POST /packages/{share_id}/customise/ — price probe that does not create
  /// a trip, used while the customer is still ticking add-ons.
  Future<DiyCustomiseQuote> customise({
    required String shareId,
    required List<String> addOnIds,
    bool withFlight = true,
  }) async {
    final data = await _post(HolidayUrls.packageCustomise(shareId), {
      'add_on_ids': addOnIds,
      'flight': HolidayUrls.flightMode(withFlight: withFlight),
    });
    return DiyCustomiseQuote.fromJson(data);
  }

  // ---------------------------------------------------------- 15. enquiry

  /// POST /packages/{share_id}/enquiry/ — hands the lead to a consultant and
  /// returns the customer-facing reference.
  Future<DiyEnquiryResult> submitEnquiry({
    required String shareId,
    required String customerName,
    required String customerPhone,
    required String customerEmail,
    required DateTime departureDate,
    required int adults,
    int children = 0,
    bool withFlight = true,
    List<String> addOnIds = const [],
    required String quotedTotal,
    String message = '',
  }) async {
    final data = await _post(HolidayUrls.packageEnquiry(shareId), {
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_email': customerEmail,
      'flight': HolidayUrls.flightMode(withFlight: withFlight),
      'departure_date': _ymd(departureDate),
      'adults': adults,
      'children': children,
      'add_on_ids': addOnIds,
      'quoted_total': quotedTotal,
      'message': message,
    });
    return DiyEnquiryResult.fromJson(data);
  }

  // ---------------------------------------------------------------- cab

  /// GET /trips/{trip_id}/cab/ — only classes that seat the party are
  /// offered. Transfers are derived from the cab, so changing it rewrites
  /// the transfer rows too; there is no separate transfer endpoint.
  Future<DiyCabOptions> getCabOptions(String tripId) async {
    final data = await _get(HolidayUrls.tripCab(tripId));
    return DiyCabOptions.fromJson(data);
  }

  /// POST /trips/{trip_id}/cab/ — 422 when the chosen class cannot seat the
  /// party; the seat counts come back in [DiyApiException.detail].
  Future<DiyTrip> changeCab({
    required String tripId,
    required String code,
    DiyTrip? previous,
  }) async {
    final data = await _post(HolidayUrls.tripCab(tripId), {'code': code});
    return DiyTrip.fromJson(data, previous: previous);
  }

  /// DELETE /trips/{trip_id}/cab/ — takes the car, and every transfer and
  /// sightseeing drive with it, off the trip. Answers with the repriced trip.
  Future<DiyTrip> removeCab({required String tripId, DiyTrip? previous}) async {
    final data = await _delete(HolidayUrls.tripCab(tripId));
    return DiyTrip.fromJson(data, previous: previous);
  }

  // ------------------------------------------------------------ booking

  /// POST /trips/{trip_id}/book/ — raises the DIY booking: price and
  /// cancellation terms frozen, the customer, travellers, GST state and
  /// arrival/departure details on it.
  Future<DiyBooking> bookTrip({
    required String tripId,
    required String customerName,
    required String customerPhone,
    required String customerEmail,
    required String gstState,
    required List<Map<String, dynamic>> travellers,
    Map<String, dynamic>? arrival,
    Map<String, dynamic>? departure,
    required bool termsAccepted,
  }) async {
    final data = await _post(HolidayUrls.tripBook(tripId), {
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_email': customerEmail,
      'gst_state': gstState,
      'travellers': travellers,
      if (arrival != null) 'arrival': arrival,
      if (departure != null) 'departure': departure,
      'terms_accepted': termsAccepted,
    });
    return DiyBooking.fromJson(data);
  }

  /// POST /bookings/{booking_id}/pay/ — a Razorpay link for one instalment.
  Future<DiyPaymentLink> payBooking({
    required String bookingId,
    required int percent,
  }) async {
    final data = await _post(
      HolidayUrls.bookingPay(bookingId),
      {'percent': percent},
    );
    return DiyPaymentLink.fromJson(data);
  }

  /// POST /bookings/{booking_id}/sync/ — records anything paid on the
  /// booking's links and answers with where it stands.
  Future<DiyBooking> syncBooking(String bookingId) async {
    final data = await _post(HolidayUrls.bookingSync(bookingId), {});
    return DiyBooking.fromJson(data);
  }

  // --------------------------------------------------------------- utils

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
