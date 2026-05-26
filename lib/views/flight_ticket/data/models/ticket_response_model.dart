class TicketResponseModel {
  final TicketResponseData? response;

  TicketResponseModel({this.response});

  factory TicketResponseModel.fromJson(Map<String, dynamic> json) {
    return TicketResponseModel(
      response: json['Response'] != null
          ? TicketResponseData.fromJson(json['Response'])
          : null,
    );
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
    return TicketResponseData(
      responseStatus: json['ResponseStatus'],
      error: json['Error'] != null
          ? TicketErrorData.fromJson(json['Error'])
          : null,
      traceId: json['TraceId'],
      pnr: json['PNR'],
      bookingId: json['BookingId'],
      passengers: json['Passengers'] != null
          ? (json['Passengers'] as List)
              .map((p) => TicketPassengerData.fromJson(p))
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
    return TicketPassengerData(
      paxId: json['PaxId'],
      ticketId: json['TicketId']?.toString(),
      ticketNumber: json['TicketNumber']?.toString(),
      status: json['Status']?.toString(),
      firstName: json['FirstName'],
      lastName: json['LastName'],
    );
  }
}
