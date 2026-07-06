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
    // TBO expects local number in Mobile1 and country code separately in
    // Mobile1CountryCode. Prepending the country code (e.g. "91-6886888588")
    // causes TBO to reject the passenger mobile as invalid.
    final mobile = contactNo;

    // Clean SSR objects - remove Price and Currency
    final cleanedBaggage = baggage.map((b) {
      final cleaned = Map<String, dynamic>.from(b);
      cleaned.remove('Price');
      cleaned.remove('Currency');
      // Trim airline code
      if (cleaned['AirlineCode'] is String) {
        cleaned['AirlineCode'] = (cleaned['AirlineCode'] as String).trim();
      }
      return cleaned;
    }).toList();

    final cleanedMeal = mealDynamic.map((m) {
      final cleaned = Map<String, dynamic>.from(m);
      cleaned.remove('Price');
      cleaned.remove('Currency');
      // Trim airline code
      if (cleaned['AirlineCode'] is String) {
        cleaned['AirlineCode'] = (cleaned['AirlineCode'] as String).trim();
      }
      return cleaned;
    }).toList();

    final cleanedSeat = seatDynamic.map((s) {
      final cleaned = Map<String, dynamic>.from(s);
      cleaned.remove('Price');
      cleaned.remove('Currency');
      // Trim airline code
      if (cleaned['AirlineCode'] is String) {
        cleaned['AirlineCode'] = (cleaned['AirlineCode'] as String).trim();
      }
      return cleaned;
    }).toList();

    return {
      'Title': title,
      'FirstName': firstName,
      'LastName': lastName,
      'Type': paxType,
      'DateOfBirth': dateOfBirth,
      'Gender': gender,
      if (passportNo.isNotEmpty) 'PassportNo': passportNo,
      if (passportNo.isNotEmpty) 'PassportExpiry': passportExpiry,
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
      if (paxFare != null) ...{
        'BaseFare': paxFare['BaseFare'],
        'Tax': paxFare['Tax'],
        'YQTax': paxFare['YQTax'],
        'Fare_BE': paxFare,
      },
      // Use cleaned SSR objects without prices
      'PaxBaggage': cleanedBaggage,
      'PaxMeal': cleanedMeal,
      'PaxSeat': cleanedSeat.isEmpty ? null : cleanedSeat,
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

  // FareQuote nests FareBreakdown inside Fare; check both locations.
  final fareBreakdown = (clean['FareBreakdown']
      ?? (clean['Fare'] is Map ? (clean['Fare'] as Map<dynamic, dynamic>)['FareBreakdown'] : null)) as List?;
  final result = Map<String, dynamic>.from(clean);

  // TBO Book/Ticket uses Segments_BE; FareQuote returns Segments as [[seg]] (nested).
  // TBO expects a flat list [seg], so we flatten here.
  final rawSegs = clean['Segments'] ?? clean['Segments_BE'] ?? <dynamic>[];
  final flatSegs = <dynamic>[];
  for (final item in rawSegs as List) {
    if (item is List) {
      flatSegs.addAll(item);
    } else if (item != null) {
      flatSegs.add(item);
    }
  }
  result['Segments_BE'] = flatSegs;

  // Remove the raw nested Segments — Book/Ticket only uses Segments_BE.
  result.remove('Segments');

  // TBO Book/Ticket API requires flat Origin, Destination, TravelDate at the
  // Itinerary root level. FareQuote does not include these flat fields; we
  // derive them from the segments:
  //   Origin      → first segment's departure airport
  //   TravelDate  → first segment's departure time
  //   Destination → LAST segment's arrival airport (correct for connecting
  //                 flights; first segment's destination is a stopover, not
  //                 the final destination TBO expects)
  if (flatSegs.isNotEmpty) {
    final firstSeg = flatSegs[0];
    final lastSeg  = flatSegs[flatSegs.length - 1];

    String firstOriginCode = '';
    if (firstSeg is Map) {
      final originObj = firstSeg['Origin'];
      if (originObj is Map) {
        final airportObj = originObj['Airport'];
        if (airportObj is Map) {
          firstOriginCode = (airportObj['AirportCode'] as String?) ?? '';
          if (!result.containsKey('Origin')) {
            result['Origin'] = firstOriginCode;
          }
        }
        if (!result.containsKey('TravelDate')) {
          result['TravelDate'] = originObj['DepTime'] ?? '';
        }
      }
    }

    // For round-trip bookings the last segment returns to the departure city
    // (e.g. DEL→GOX→DEL). TBO's Book API requires Destination = the
    // turnaround airport (GOX), NOT the return airport (DEL). Sending
    // Origin == Destination causes "Origin & Destination cannot be same".
    // For one-way / connecting flights use the last segment's arrival.
    if (!result.containsKey('Destination')) {
      String destCode = '';
      if (lastSeg is Map) {
        final destObj = lastSeg['Destination'];
        if (destObj is Map) {
          final airportObj = destObj['Airport'];
          if (airportObj is Map) {
            destCode = (airportObj['AirportCode'] as String?) ?? '';
          }
        }
      }

      final isRoundTrip = flatSegs.length > 1 &&
          firstOriginCode.isNotEmpty &&
          firstOriginCode == destCode;

      if (isRoundTrip) {
        // Use the first segment's destination as the turnaround point
        final firstDestObj = (firstSeg as Map)['Destination'];
        if (firstDestObj is Map) {
          final airportObj = firstDestObj['Airport'];
          if (airportObj is Map) {
            destCode = (airportObj['AirportCode'] as String?) ?? destCode;
          }
        }
        print('buildItinerary: round-trip detected, Destination set to turnaround $destCode');
      }

      result['Destination'] = destCode;
    }
  }

  // MiniFareRules and FareRules must each have exactly one entry per segment.
  // TBO's Book .NET code indexes both as MiniFareRules[s] / FareRules[s]:
  //   • Too few  → "Index was out of range" (pad with empty / first entry)
  //   • Too many → "Index was out of range" (trim to flatSegs.length)
  for (final key in ['MiniFareRules', 'FareRules']) {
    final rawList = result[key];
    if (rawList is! List) continue;
    if (rawList.length == flatSegs.length) continue;

    List<dynamic> adjusted = List<dynamic>.from(rawList);
    if (flatSegs.length > rawList.length) {
      // Pad: too few entries.
      // MiniFareRules: pad with empty list (repeating the journey-level entry
      // causes TBO to misroute the mini-rule lookup for connecting flights).
      // FareRules: copy the first entry (TBO expects a per-segment object).
      final filler = key == 'MiniFareRules'
          ? <dynamic>[]
          : (rawList.isNotEmpty ? rawList[0] : <dynamic>[]);
      while (adjusted.length < flatSegs.length) {
        adjusted.add(filler);
      }
      print('buildItinerary: padded $key ${rawList.length}→${adjusted.length} for ${flatSegs.length} segs');
    } else {
      // Trim: FareQuote can return more entries than actual segments (e.g. a
      // round-trip FareQuote result used for a one-way booking).  Leaving extra
      // entries makes TBO index Segments[n] where n >= Segments.length.
      adjusted = adjusted.sublist(0, flatSegs.length);
      print('buildItinerary: trimmed $key ${rawList.length}→${adjusted.length} for ${flatSegs.length} segs');
    }
    result[key] = adjusted;
  }

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
  // The itinerary-level Fare is the complete fare object (TaxBreakup, OfferedFare,
  // VAT, etc.). TBO validates Fare_BE against its session cache; sending only
  // BaseFare+Tax+YQTax (4 fields) causes "Booking Failed Code 1" for many airlines.
  // Fix: use the full Fare as the base and override per-pax amounts from FareBreakdown.
  final itineraryFare = clean['Fare'] as Map<String, dynamic>?;

  result['Passenger'] = passengers.asMap().entries.map((entry) {
    final passenger = entry.value;

    Map<String, dynamic>? paxFare;
    if (fareBreakdown != null && fareBreakdown.isNotEmpty) {
      final matchedRows = fareBreakdown
          .whereType<Map>()
          .where((f) => f['PassengerType'] == passenger.paxType)
          .toList();

      final row = matchedRows.isNotEmpty
          ? matchedRows.first
          : fareBreakdown.whereType<Map>().first;

      final count = (row['PassengerCount'] as num?)?.toInt() ?? 1;
      final baseFare = ((row['BaseFare'] as num?)?.toDouble() ?? 0) / count;
      final tax     = ((row['Tax']      as num?)?.toDouble() ?? 0) / count;
      final yqTax   = ((row['YQTax']    as num?)?.toDouble() ?? 0) / count;

      // Start from the full itinerary Fare object; override per-passenger amounts.
      paxFare = itineraryFare != null
          ? Map<String, dynamic>.from(itineraryFare)
          : <String, dynamic>{};
      paxFare['BaseFare'] = double.parse(baseFare.toStringAsFixed(2));
      paxFare['Tax']      = double.parse(tax.toStringAsFixed(2));
      paxFare['YQTax']    = double.parse(yqTax.toStringAsFixed(2));
      paxFare['Currency'] =
          row['Currency'] ?? itineraryFare?['Currency'] ?? 'INR';
    } else if (itineraryFare != null) {
      paxFare = Map<String, dynamic>.from(itineraryFare);
    }

    return _tboFilterNulls(passenger.toJson(fare: paxFare));
  }).toList();

  // Build FlightNumber → TripIndicator map from flattened segments.
  // TBO SSR API sometimes returns WayType values that don't match the segment's
  // TripIndicator (e.g. WayType=2 for outward-leg FlightNumber on a round trip,
  // or WayType=2 for a one-way flight). TBO's Book API uses WayType as a
  // 1-based segment-index offset; a mismatch throws "Index was out of range".
  final flightToTripIndicator = <String, int>{};
  for (final seg in flatSegs) {
    if (seg is Map) {
      final fn = (seg['Airline'] as Map?)?['FlightNumber'] as String?;
      final ti = (seg['TripIndicator'] as int?) ?? 1;
      if (fn != null && fn.isNotEmpty) flightToTripIndicator[fn] = ti;
    }
  }
  final segFlightNumbers = flightToTripIndicator.keys.toSet();

  result['Passenger'] = (result['Passenger'] as List).map((pax) {
    if (pax is! Map<String, dynamic>) return pax;
    final updated = Map<String, dynamic>.from(pax);

    // --- PaxBaggage ---
    final paxBaggage = updated['PaxBaggage'];
    if (paxBaggage is List && paxBaggage.isNotEmpty) {
      final valid = <dynamic>[];
      for (final b in paxBaggage) {
        if (b is! Map<String, dynamic>) { valid.add(b); continue; }
        final fn = b['FlightNumber'] as String?;
        // Drop baggage for unknown flights (connecting flight safety check)
        if (fn != null && segFlightNumbers.isNotEmpty && !segFlightNumbers.contains(fn)) {
          print('buildItinerary: PaxBaggage dropped (unknown flight $fn)');
          continue;
        }
        final nb = Map<String, dynamic>.from(b);
        // Correct WayType to match the segment's actual TripIndicator
        final correctWayType = (fn != null ? flightToTripIndicator[fn] : null) ?? 1;
        if (nb['WayType'] != correctWayType) {
          print('buildItinerary: PaxBaggage WayType ${nb['WayType']}→$correctWayType for flight $fn');
          nb['WayType'] = correctWayType;
        }
        valid.add(nb);
      }
      updated['PaxBaggage'] = valid.isEmpty ? null : valid;
    }

    // --- PaxMeal ---
    // Apply the same flight-filter and WayType correction as PaxBaggage for
    // all segment counts.  A WayType=2 on a one-way (1-segment) flight causes
    // the same "Index was out of range" error in TBO's .NET code.
    final paxMeal = updated['PaxMeal'];
    if (paxMeal is List && paxMeal.isNotEmpty) {
      final valid = <dynamic>[];
      for (final m in paxMeal) {
        if (m is! Map<String, dynamic>) { valid.add(m); continue; }
        final fn = m['FlightNumber'] as String?;
        if (fn != null && segFlightNumbers.isNotEmpty && !segFlightNumbers.contains(fn)) {
          print('buildItinerary: PaxMeal dropped (unknown flight $fn)');
          continue;
        }
        final nm = Map<String, dynamic>.from(m);
        final correctWayType = (fn != null ? flightToTripIndicator[fn] : null) ?? 1;
        if (nm['WayType'] != correctWayType) {
          print('buildItinerary: PaxMeal WayType ${nm['WayType']}→$correctWayType for flight $fn');
          nm['WayType'] = correctWayType;
        }
        valid.add(nm);
      }
      updated['PaxMeal'] = valid.isEmpty ? null : valid;
    }

    // --- PaxSeat ---
    final paxSeat = updated['PaxSeat'];
    if (paxSeat is List && paxSeat.isNotEmpty) {
      final valid = <dynamic>[];
      for (final s in paxSeat) {
        if (s is! Map<String, dynamic>) { valid.add(s); continue; }
        final fn = s['FlightNumber'] as String?;
        if (fn != null && segFlightNumbers.isNotEmpty && !segFlightNumbers.contains(fn)) {
          print('buildItinerary: PaxSeat dropped (unknown flight $fn)');
          continue;
        }
        final ns = Map<String, dynamic>.from(s);
        final correctWayType = (fn != null ? flightToTripIndicator[fn] : null) ?? 1;
        if (ns['SeatWayType'] != correctWayType) {
          print('buildItinerary: PaxSeat SeatWayType ${ns['SeatWayType']}→$correctWayType for flight $fn');
          ns['SeatWayType'] = correctWayType;
        }
        valid.add(ns);
      }
      updated['PaxSeat'] = valid.isEmpty ? null : valid;
    }

    return updated;
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

  // Extra metadata read by our backend (ignored by TBO).
  final String flightType;
  final String fromCity;
  final String toCity;
  final String departureDate;

  BookingRequestModel({
    required this.endUserIp,
    required this.traceId,
    required this.tokenId,
    required this.resultIndex,
    required this.itinerary,
    required this.passengers,
    this.flightType = '',
    this.fromCity = '',
    this.toCity = '',
    this.departureDate = '',
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
      // Extra metadata for our backend.
      'flight_type': flightType,
      'from_city': fromCity,
      'to_city': toCity,
      'departure_date': departureDate,
    };
  }
}
