class BookingResponseModel {
  final BookingResponseData? response;

  BookingResponseModel({this.response});

  factory BookingResponseModel.fromJson(Map<String, dynamic> json) {
    return BookingResponseModel(
      response: json['Response'] != null
          ? BookingResponseData.fromJson(json['Response'])
          : null,
    );
  }
}

class BookingResponseData {
  final int? responseStatus;
  final BookingErrorData? error;
  final String? traceId;
  final String? pnr;
  final int? bookingId;
  final bool? isPriceChanged;
  final bool? isTimeChanged;
  final int? status;

  BookingResponseData({
    this.responseStatus,
    this.error,
    this.traceId,
    this.pnr,
    this.bookingId,
    this.isPriceChanged,
    this.isTimeChanged,
    this.status,
  });

  factory BookingResponseData.fromJson(Map<String, dynamic> json) {
    return BookingResponseData(
      responseStatus: json['ResponseStatus'],
      error: json['Error'] != null
          ? BookingErrorData.fromJson(json['Error'])
          : null,
      traceId: json['TraceId'],
      pnr: json['PNR'],
      bookingId: json['BookingId'],
      isPriceChanged: json['IsPriceChanged'],
      isTimeChanged: json['IsTimeChanged'],
      status: json['Status'],
    );
  }
}

class BookingErrorData {
  final int? errorCode;
  final String? errorMessage;

  BookingErrorData({this.errorCode, this.errorMessage});

  factory BookingErrorData.fromJson(Map<String, dynamic> json) {
    return BookingErrorData(
      errorCode: json['ErrorCode'],
      errorMessage: json['ErrorMessage'],
    );
  }
}
