import 'package:wander_nova/views/flight_booking/data/models/booking_request_model.dart';

class TicketRequestModel {
  final String endUserIp;
  final String traceId;
  final String tokenId;
  final int bookingId;
  final String pnr;
  final List<BookingPassengerModel> passengers;

  TicketRequestModel({
    required this.endUserIp,
    required this.traceId,
    required this.tokenId,
    required this.bookingId,
    required this.pnr,
    required this.passengers,
  });

  Map<String, dynamic> toJson() {
    return {
      'EndUserIp': endUserIp,
      'TraceId': traceId,
      'TokenId': tokenId,
      'BookingId': bookingId,
      'PNR': pnr,
      'Passengers': passengers.map((p) => p.toJson()).toList(),
    };
  }
}
