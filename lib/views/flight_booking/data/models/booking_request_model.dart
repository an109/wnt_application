// ignore_for_file: avoid_print
import 'dart:convert';

class BookingPassengerModel {
  final String title;
  final String firstName;
  final String lastName;
  final int paxType;
  final String dateOfBirth;
  final int gender;
  final String passportNo;
  final String passportExpiry;
  final String addressLine1;
  final String city;
  final String countryCode;
  final String countryName;
  final String nationality;
  final String contactNo;
  final String email;
  final bool isLeadPax;
  final String mobileCountryCode;
  final Map<String, dynamic>? fare;
  final List<Map<String, dynamic>> baggage;
  final List<Map<String, dynamic>> mealDynamic;
  final List<Map<String, dynamic>> seatDynamic;

  BookingPassengerModel({
    required this.title,
    required this.firstName,
    required this.lastName,
    required this.paxType,
    required this.dateOfBirth,
    required this.gender,
    required this.passportNo,
    required this.passportExpiry,
    this.addressLine1 = 'Test Address',
    this.city = 'Test City',
    this.countryCode = 'IN',
    this.countryName = 'India',
    required this.nationality,
    required this.contactNo,
    required this.email,
    required this.isLeadPax,
    this.fare,
    this.baggage = const [],
    this.mealDynamic = const [],
    this.seatDynamic = const [],
    this.mobileCountryCode = '91'
  });

  /// [fare] overrides this passenger's own [fare] when provided — used to inject
  /// the FareQuote result-level fare into each passenger for Book/Ticket.
  Map<String, dynamic> toJson({Map<String, dynamic>? fare}) {
    final paxFare = fare ?? this.fare;
    final mobile = contactNo.startsWith(mobileCountryCode)
        ? contactNo
        : '$mobileCountryCode-$contactNo';

    return {
      'Title': title,
      'FirstName': firstName,
      'LastName': lastName,
      'Type': paxType,
      // 'PaxType': paxType,
      'DateOfBirth': dateOfBirth,
      'Gender': gender,
      // 'PassportNo': passportNo.isEmpty ? null : passportNo,
      // 'PassportExpiry': passportExpiry,
      if (passportNo.isNotEmpty) 'PassportNo': passportNo,
      // if (passportNo.isNotEmpty) 'PassportExpiry': passportExpiry,
      'AddressLine1': addressLine1,
      'AddressLine2': countryName,
      'City': {
        'CityCode': '',
        'CityName': city,
        'CountryCode': countryCode,
      },
      'Country': {
        'CountryCode': countryCode,
        'CountryName': countryName,
      },
      'Nationality': {
        'CountryCode': nationality,
        'CountryName': nationality == 'IN' ? 'India' : countryName,
      },
      'Email': email,
      'Mobile1': mobile,
      'Mobile1CountryCode': mobileCountryCode,
      'IsLeadPax': isLeadPax,
      // if (paxFare != null) 'Fare': paxFare,
      if (paxFare != null) ...{
        'BaseFare': paxFare['BaseFare'],
        'Tax': paxFare['Tax'],
        'YQTax': paxFare['YQTax'],
        'Fare_BE': paxFare,
      },
      'PaxBaggage': baggage,
      'PaxMeal': mealDynamic,
      // 'PaxSeat': seatDynamic,
      'PaxSeat': seatDynamic.isEmpty ? null : seatDynamic,
    };
  }
}

Map<String, dynamic> _tboFilterNulls(Map<String, dynamic> map) {
  final out = <String, dynamic>{};
  for (final e in map.entries) {
    if (e.value == null) continue;
    if (e.value is Map<String, dynamic>) {
      out[e.key] = _tboFilterNulls(e.value as Map<String, dynamic>);
    } else if (e.value is List) {
      out[e.key] = _tboFilterList(e.value as List);
    } else {
      out[e.key] = e.value;
    }
  }
  return out;
}

List<dynamic> _tboFilterList(List<dynamic> list) {
  return list.map((item) {
    if (item is Map<String, dynamic>) return _tboFilterNulls(item);
    if (item is List) return _tboFilterList(item);
    return item;
  }).toList();
}

Map<String, dynamic> buildItinerary(
    Map<String, dynamic> rawItinerary,
    List<BookingPassengerModel> passengers, {
    String traceId = '',
}) {
  // Deep-filter ALL null values from rawItinerary before spreading.
  // TBO's .NET code throws NullReferenceException on any explicitly-null field
  // at any nesting level (Fare.ChargeBU, Airline.OperatingCarrier, etc.).
  final clean = _tboFilterNulls(rawItinerary);
  // final fare = clean['Fare'];
  //
  // final result = Map<String, dynamic>.from(clean);

  final fareBreakdown = clean['FareBreakdown'] as List?;
  final result = Map<String, dynamic>.from(clean);

  // TBO Book/Ticket uses Segments_BE; FareQuote returns Segments.
  result['Segments_BE'] = clean['Segments'] ?? clean['Segments_BE'] ?? [];

  // FareQuote returns "ValidatingAirline" (no "Code" suffix); Book needs "ValidatingAirlineCode".
  result['ValidatingAirlineCode'] =
      clean['ValidatingAirlineCode'] ?? clean['ValidatingAirline'] ?? '';

  // FareQuote returns IsLCC (all-caps); backend LCC-detect reads IsLcc (mixed).
  result['IsLcc'] = clean['IsLcc'] ?? clean['IsLCC'] ?? false;

  // Booking-specific resets.
  result['BookingId'] = 0;
  result['BookingMode'] = 1;
  result['PaymentMode'] = 0;
  result['PNR'] = '';
  result['PNRStatus'] = 0;
  result['Ticketed'] = false;
  result['TokenId'] = '';
  result['TrackingId'] =
      traceId.isNotEmpty ? traceId : (clean['TraceId'] ?? '');

  result.remove('Passengers');
  // result['Passenger'] = passengers
  //     .map((p) => p.toJson(
  //   fare: fare is Map<String, dynamic> ? fare : null,
  // ))
  //     .toList();
  result['Passenger'] = passengers.asMap().entries.map((entry) {
    final index = entry.key;
    final passenger = entry.value;

    Map<String, dynamic>? paxFare;
    if (fareBreakdown != null && fareBreakdown.isNotEmpty) {
      final adultFareRows = fareBreakdown
          .whereType<Map>()
          .where((f) => f['PassengerType'] == passenger.paxType)
          .toList();

      final row = adultFareRows.isNotEmpty
          ? adultFareRows.first
          : fareBreakdown.whereType<Map>().first;

      final count = (row['PassengerCount'] as num?)?.toInt() ?? 1;
      final baseFare = ((row['BaseFare'] as num?)?.toDouble() ?? 0) / count;
      final tax = ((row['Tax'] as num?)?.toDouble() ?? 0) / count;
      final yqTax = ((row['YQTax'] as num?)?.toDouble() ?? 0) / count;

      paxFare = {
        'BaseFare': double.parse(baseFare.toStringAsFixed(2)),
        'Tax': double.parse(tax.toStringAsFixed(2)),
        'YQTax': double.parse(yqTax.toStringAsFixed(2)),
        'Currency': row['Currency'] ?? clean['Fare']?['Currency'] ?? 'INR',
      };
    }

    // return passenger.toJson(fare: paxFare);
    return _tboFilterNulls(passenger.toJson(fare: paxFare));
  }).toList();

  print('====== buildItinerary (null-filtered, ${result.keys.length} keys) ======');
  print(jsonEncode(result));
  print('=========================================================================');

  return result;
}

/// TBO Book request (Non-LCC flow).
///
/// `/tbo/Book/` is a pass-through to TBO, so this must be the COMPLETE TBO Book
/// payload: an `Itinerary` (FareQuote result + Passengers) wrapped in booking
/// metadata. Mirrors the backend's `TBOUniversalAirService.book()`. TokenId is
/// left empty — the backend injects the real TBO token.
class BookingRequestModel {
  final String endUserIp;
  final String traceId;
  final String tokenId;
  final String resultIndex;

  /// The raw TBO FareQuote result object (the `Itinerary` source).
  final Map<String, dynamic> itinerary;
  final List<BookingPassengerModel> passengers;

  BookingRequestModel({
    required this.endUserIp,
    required this.traceId,
    required this.tokenId,
    required this.resultIndex,
    required this.itinerary,
    required this.passengers,
  });

  /// Builds the complete TBO Book API payload. The backend `book_raw` is a
  /// pure pass-through (it only injects TokenId), so this must match the TBO
  /// staging Booking/Book endpoint format exactly.
  ///
  /// Key differences from the old minimal format:
  ///   - `ResultId`  (not `ResultIndex`)
  ///   - `IPAddress` (not `EndUserIp`)
  ///   - Full FareQuote `Itinerary` with `Passengers` merged inside
  ///   - All required TBO envelope fields present
  Map<String, dynamic> toJson() {
    return {
      'TokenId': '',
      'ResultId': resultIndex,
      'IPAddress': endUserIp,
      'Itinerary': buildItinerary(itinerary, passengers, traceId: traceId),
      'PNR': '',
      'BookingId': '',
      'CorporateCode': '',
      'ConfirmPriceChangeTicket': false,
      'IsGenerateTicketRequestFromQueues': false,
      'SegmentAnalyticsToken': '',
      'TrackingId': traceId,
      'EndUserBrowserAgent': 'Mozilla/5.0',
      'PointOfSale': 'IN',
      'RequestOrigin': 'API',
      'UserData': '',
      'WebServerIP': '',
      'FlightBookingSource': 72,
    };
  }
}
