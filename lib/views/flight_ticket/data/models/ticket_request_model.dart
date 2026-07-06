

import 'package:wander_nova/views/flight_booking/data/models/booking_request_model.dart';

/// TBO Ticket request. Two shapes, matching the backend pass-through
/// (`tbo_ticket` detects LCC via `Itinerary.IsLcc`):
///
/// * [TicketRequestModel.lcc] — LCC airlines (SpiceJet/IndiGo). Does Book +
///   Ticket in a single call; carries the full `Itinerary` (FareQuote result +
///   Passengers). Mirrors `TBOUniversalAirService.ticket_lcc()`.
/// * [TicketRequestModel.nonLcc] — GDS airlines. Called after Book with the
///   returned `PNR` + `BookingId`. Mirrors `ticket_non_lcc()`.
///
/// TokenId is left empty in both — the backend injects the real TBO token.
class TicketRequestModel {
  final String endUserIp;
  final String traceId;
  final bool isLcc;

  // Non-LCC
  final int? bookingId;
  final String? pnr;

  // LCC
  final String? resultIndex;
  final Map<String, dynamic>? itinerary;
  final List<BookingPassengerModel> passengers;

  final String? flightType;
  final String? fromCity;
  final String? toCity;
  final String? departureDate;

  TicketRequestModel.lcc({
    required this.endUserIp,
    required this.traceId,
    required this.resultIndex,
    required this.itinerary,
    required this.passengers,
    this.flightType,
    this.fromCity,
    this.toCity,
    this.departureDate,
  })  : isLcc = true,
        bookingId = null,
        pnr = null;

  TicketRequestModel.nonLcc({
    required this.endUserIp,
    required this.traceId,
    required this.bookingId,
    required this.pnr,
    this.itinerary,
    this.passengers = const [],
    this.resultIndex,
    this.flightType,
    this.fromCity,
    this.toCity,
    this.departureDate,
  })  : isLcc = false;

  Map<String, dynamic> toJson() => isLcc ? _lccJson() : _nonLccJson();

  /// Builds the complete TBO Ticket LCC payload. Same pass-through rules as
  /// Book — backend only injects TokenId, so all required TBO fields must be
  /// present here. `ResultId`/`IPAddress` naming matches `ticket_lcc()` in
  /// the service; full FareQuote Itinerary with Passengers merged inside.
  Map<String, dynamic> _lccJson() {
    final Map<String, dynamic> payload = {
      'TokenId': '',
      'ResultId': resultIndex,
      'IPAddress': endUserIp,
      'Itinerary': buildItinerary(itinerary!, passengers, traceId: traceId),
      'PNR': '',
      'BookingId': 0,
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
      'IsPriceChangeAccepted': true,
      'FlightBookingSource': 100,
    };

    // Add flight details if available
    if (flightType != null && flightType!.isNotEmpty) {
      payload['flight_type'] = flightType;
    }
    if (fromCity != null && fromCity!.isNotEmpty) {
      payload['from_city'] = fromCity;
    }
    if (toCity != null && toCity!.isNotEmpty) {
      payload['to_city'] = toCity;
    }
    if (departureDate != null && departureDate!.isNotEmpty) {
      payload['departure_date'] = departureDate;
    }

    return payload;
  }

  // Non-LCC Ticket (GDS airlines like Air India) needs the Itinerary with
  // Passenger + booking identifiers so TBO can issue e-tickets.  We use the
  // FareQuote-based Itinerary (valid Segments, not the Book response which has
  // Segments:null) and stamp in the PNR/BookingId obtained from the Book call.
  // buildItinerary() in booking_request_model.dart already trims MiniFareRules
  // and corrects WayTypes, so this Itinerary is safe to forward to TBO.
  // ConfirmPriceChangeTicket is always true because:
  //   • Book Status=5 (On Hold) often comes with IsPriceChanged=true
  //   • Without this flag TBO's .NET code dereferences a null error-return object
  Map<String, dynamic> _nonLccJson() {
    final fullItinerary = Map<String, dynamic>.from(itinerary ?? {});
    fullItinerary['PNR'] = pnr;
    fullItinerary['BookingId'] = bookingId;

    final Map<String, dynamic> payload = {
      'TokenId': '',
      'ResultId': resultIndex ?? '',
      'IPAddress': endUserIp,
      'Itinerary': fullItinerary,
      'PNR': pnr,
      'BookingId': bookingId,
      'CorporateCode': '',
      'ConfirmPriceChangeTicket': true,
      'IsGenerateTicketRequestFromQueues': false,
      'SegmentAnalyticsToken': '',
      'TrackingId': traceId,
      'EndUserBrowserAgent': 'Mozilla/5.0',
      'PointOfSale': 'IN',
      'RequestOrigin': 'API',
      'UserData': '',
      'WebServerIP': '',
      'IsHoldEligibleForLcc': false,
      'NoOfSeatAvailable': 9,
      'OperatingCarrier': '',
      'SegmentIndicator': 1,
      'IsPriceChangeAccepted': true,
      'FlightBookingSource': 72,
    };

    // Add flight details if available
    if (flightType != null && flightType!.isNotEmpty) {
      payload['flight_type'] = flightType;
    }
    if (fromCity != null && fromCity!.isNotEmpty) {
      payload['from_city'] = fromCity;
    }
    if (toCity != null && toCity!.isNotEmpty) {
      payload['to_city'] = toCity;
    }
    if (departureDate != null && departureDate!.isNotEmpty) {
      payload['departure_date'] = departureDate;
    }

    return payload;
  }
}


  // Map<String, dynamic> _lccJson() {
  //   return {
  //     'TokenId': '',
  //     'ResultId': resultIndex,
  //     'IPAddress': endUserIp,
  //     'Itinerary': buildItinerary(itinerary!, passengers, traceId: traceId),
  //     'PNR': '',
  //     'BookingId': 0,
  //     'CorporateCode': '',
  //     'ConfirmPriceChangeTicket': false,
  //     'IsGenerateTicketRequestFromQueues': false,
  //     'SegmentAnalyticsToken': '',
  //     'TrackingId': traceId,
  //     'EndUserBrowserAgent': 'Mozilla/5.0',
  //     'PointOfSale': 'IN',
  //     'RequestOrigin': 'API',
  //     'UserData': '',
  //     'WebServerIP': '',
  //     'IsPriceChangeAccepted': true,
  //     'FlightBookingSource': 100,
  //   };
  // }
  //
  // Map<String, dynamic> _nonLccJson() {
  //   final fullItinerary = Map<String, dynamic>.from(itinerary ?? {});
  //   // Stamp PNR and BookingId from the Book response into the Itinerary.
  //   fullItinerary['PNR'] = pnr;
  //   fullItinerary['BookingId'] = bookingId;
  //
  //   return {
  //     'TokenId': '',
  //     'ResultId': resultIndex ?? '',
  //     'IPAddress': endUserIp,
  //     'Itinerary': fullItinerary,
  //     'PNR': pnr,
  //     'BookingId': bookingId,
  //     'CorporateCode': '',
  //     'ConfirmPriceChangeTicket': false,
  //     'IsGenerateTicketRequestFromQueues': false,
  //     'SegmentAnalyticsToken': '',
  //     'TrackingId': traceId,
  //     'EndUserBrowserAgent': 'Mozilla/5.0',
  //     'PointOfSale': 'IN',
  //     'RequestOrigin': 'API',
  //     'UserData': '',
  //     'WebServerIP': '',
  //     'IsPriceChangeAccepted': true,
  //     'FlightBookingSource': 72,
  //   };
  // }

