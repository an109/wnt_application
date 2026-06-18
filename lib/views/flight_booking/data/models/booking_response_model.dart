class BookingResponseModel {
  final BookingResponseData? response;

  BookingResponseModel({this.response});

  factory BookingResponseModel.fromJson(Map<String, dynamic> json) {
    // TBO Book returns a flat dict: {"PNR":"...","BookingId":...,"Status":1,...}
    // Error timeouts wrap in: {"Response":{"Error":{...}}}
    final inner = (json['Response'] as Map<String, dynamic>?) ?? json;
    return BookingResponseModel(response: BookingResponseData.fromJson(inner));
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
    // Flat TBO response uses "Status":1 for success; wrapped uses "ResponseStatus":1
    final rawStatus = json['Status'];
    final status = rawStatus is int ? rawStatus : int.tryParse('$rawStatus');
    final rawBookingId = json['BookingId'];
    final bookingId = rawBookingId is int
        ? rawBookingId
        : rawBookingId != null ? int.tryParse('$rawBookingId') : null;
    return BookingResponseData(
      responseStatus: json['ResponseStatus'] as int? ?? status,
      error: json['Error'] != null
          ? BookingErrorData.fromJson(json['Error'] as Map<String, dynamic>)
          : null,
      traceId: json['TraceId'] as String?,
      pnr: json['PNR'] as String?,
      bookingId: bookingId,
      isPriceChanged: json['IsPriceChanged'] as bool?,
      isTimeChanged: json['IsTimeChanged'] as bool?,
      status: status,
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
