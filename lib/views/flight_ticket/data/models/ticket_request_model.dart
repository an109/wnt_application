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

  TicketRequestModel.lcc({
    required this.endUserIp,
    required this.traceId,
    required this.resultIndex,
    required this.itinerary,
    required this.passengers,
  })  : isLcc = true,
        bookingId = null,
        pnr = null;

  TicketRequestModel.nonLcc({
    required this.endUserIp,
    required this.traceId,
    required this.bookingId,
    required this.pnr,
  })  : isLcc = false,
        resultIndex = null,
        itinerary = null,
        passengers = const [];

  Map<String, dynamic> toJson() => isLcc ? _lccJson() : _nonLccJson();

  /// Builds the complete TBO Ticket LCC payload. Same pass-through rules as
  /// Book — backend only injects TokenId, so all required TBO fields must be
  /// present here. `ResultId`/`IPAddress` naming matches `ticket_lcc()` in
  /// the service; full FareQuote Itinerary with Passengers merged inside.
  Map<String, dynamic> _lccJson() {
    return {
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
      'IsPriceChangeAccepted': false,
      'FlightBookingSource': 100,
    };
  }

  Map<String, dynamic> _nonLccJson() {
    return {
      'EndUserIp': endUserIp,
      'TokenId': '',
      'TrackingId': traceId,
      'IPAddress': endUserIp,
      'EndUserBrowserAgent': 'Mozilla/5.0',
      'UserData': '',
      'PointOfSale': 'IN',
      'RequestOrigin': 'API',
      'IsHoldEligibleForLcc': false,
      'NoOfSeatAvailable': 9,
      'OperatingCarrier': '',
      'SegmentIndicator': 1,
      'PNR': pnr,
      'BookingId': bookingId,
    };
  }
}
