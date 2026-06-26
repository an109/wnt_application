class TicketResponseModel {
  final TicketResponseData? response;

  TicketResponseModel({this.response});

  factory TicketResponseModel.fromJson(Map<String, dynamic> json) {
    // TBO Ticket returns a flat dict: {"PNR":"...","BookingId":...,"Status":1,...}
    // Error timeouts wrap in: {"Response":{"Error":{...}}}
    final inner = (json['Response'] as Map<String, dynamic>?) ?? json;
    return TicketResponseModel(response: TicketResponseData.fromJson(inner));
  }
}

class TicketResponseData {
  final int? responseStatus;
  final TicketErrorData? error;
  final String? traceId;
  final String? pnr;
  final int? bookingId;
  final List<TicketPassengerData>? passengers;

  TicketResponseData({
    this.responseStatus,
    this.error,
    this.traceId,
    this.pnr,
    this.bookingId,
    this.passengers,
  });

  factory TicketResponseData.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['Status'];
    final status = rawStatus is int ? rawStatus : int.tryParse('$rawStatus');

    final itinerary = json['Itinerary'] as Map<String, dynamic>?;

    // BookingId: prefer Itinerary.BookingId, fall back to root
    final rawBookingId = itinerary?['BookingId'] ?? json['BookingId'];
    final bookingId = rawBookingId is int
        ? rawBookingId
        : rawBookingId != null ? int.tryParse('$rawBookingId') : null;

    // PNR: prefer root (most reliable), fall back to Itinerary
    final pnr = (json['PNR'] as String?)?.isNotEmpty == true
        ? json['PNR'] as String
        : itinerary?['PNR'] as String?;

    // Passengers: root-level 'Passengers' list or Itinerary.Passenger list
    final passengersList =
        (json['Passengers'] as List?) ?? (itinerary?['Passenger'] as List?);

    return TicketResponseData(
      responseStatus: json['ResponseStatus'] as int? ?? status,
      error: json['Error'] != null
          ? TicketErrorData.fromJson(json['Error'] as Map<String, dynamic>)
          : null,
      traceId: json['TraceId'] as String?,
      pnr: pnr,
      bookingId: bookingId,
      passengers: passengersList != null
          ? passengersList
              .whereType<Map<String, dynamic>>()
              .map(TicketPassengerData.fromJson)
              .toList()
          : null,
    );
  }
}

class TicketErrorData {
  final int? errorCode;
  final String? errorMessage;

  TicketErrorData({this.errorCode, this.errorMessage});

  factory TicketErrorData.fromJson(Map<String, dynamic> json) {
    return TicketErrorData(
      errorCode: json['ErrorCode'],
      errorMessage: json['ErrorMessage'],
    );
  }
}

class TicketPassengerData {
  final int? paxId;
  final String? ticketId;
  final String? ticketNumber;
  final String? status;
  final String? firstName;
  final String? lastName;

  TicketPassengerData({
    this.paxId,
    this.ticketId,
    this.ticketNumber,
    this.status,
    this.firstName,
    this.lastName,
  });

  factory TicketPassengerData.fromJson(Map<String, dynamic> json) {
    // Ticket info can be at root level (some responses) or nested in Ticket object
    final ticket = json['Ticket'] as Map<String, dynamic>?;
    return TicketPassengerData(
      paxId: json['PaxId'],
      ticketId: ticket?['TicketId']?.toString() ?? json['TicketId']?.toString(),
      ticketNumber: ticket?['TicketNumber']?.toString() ?? json['TicketNumber']?.toString(),
      status: ticket?['Status']?.toString() ?? json['Status']?.toString(),
      firstName: json['FirstName'],
      lastName: json['LastName'],
    );
  }
}
