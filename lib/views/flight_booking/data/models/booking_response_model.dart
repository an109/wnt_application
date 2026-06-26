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

  // factory BookingResponseData.fromJson(Map<String, dynamic> json) {
  //   // Flat TBO response uses "Status":1 for success; wrapped uses "ResponseStatus":1
  //   final rawStatus = json['Status'];
  //   final status = rawStatus is int ? rawStatus : int.tryParse('$rawStatus');
  //   final rawBookingId = json['BookingId'];
  //   final bookingId = rawBookingId is int
  //       ? rawBookingId
  //       : rawBookingId != null ? int.tryParse('$rawBookingId') : null;
  //
  //   // TBO Book failures come in two shapes:
  //   //   • Single error object: {"Error":{"ErrorCode":...,"ErrorMessage":"..."}}
  //   //   • Errors array:        {"Errors":[{"Code":30,"UserMessage":"Passport..."}]}
  //   // Normalise both into a single BookingErrorData so callers don't need to
  //   // know which format was used.
  //   BookingErrorData? parsedError;
  //   if (json['Error'] != null) {
  //     parsedError = BookingErrorData.fromJson(json['Error'] as Map<String, dynamic>);
  //   } else if (json['Errors'] is List) {
  //     final errors = json['Errors'] as List;
  //     if (errors.isNotEmpty && errors.first is Map) {
  //       final first = errors.first as Map<String, dynamic>;
  //       parsedError = BookingErrorData(
  //         errorCode: first['Code'] as int? ?? first['ErrorCode'] as int?,
  //         errorMessage: (first['UserMessage'] as String?)?.trim()
  //             ?? first['ErrorMessage'] as String?,
  //       );
  //     }
  //   }
  //
  //   return BookingResponseData(
  //     responseStatus: json['ResponseStatus'] as int? ?? status,
  //     error: parsedError,
  //     traceId: json['TraceId'] as String?,
  //     pnr: json['PNR'] as String?,
  //     bookingId: bookingId,
  //     isPriceChanged: json['IsPriceChanged'] as bool?,
  //     isTimeChanged: json['IsTimeChanged'] as bool?,
  //     status: status,
  //   );
  // }
  factory BookingResponseData.fromJson(Map<String, dynamic> json) {
    // First, check if there's an Itinerary object
    final itinerary = json['Itinerary'] as Map<String, dynamic>?;

    // Get bookingId from Itinerary first
    int? bookingId;
    if (itinerary != null) {
      final rawBookingId = itinerary['BookingId'];
      bookingId = rawBookingId is int
          ? rawBookingId
          : rawBookingId != null ? int.tryParse('$rawBookingId') : null;
    }
    // Fallback to root level if not found in Itinerary
    if (bookingId == null) {
      final rawBookingId = json['BookingId'];
      bookingId = rawBookingId is int
          ? rawBookingId
          : rawBookingId != null ? int.tryParse('$rawBookingId') : null;
    }

    // Get PNR from Itinerary first, fallback to root
    String? pnr;
    if (itinerary != null) {
      pnr = itinerary['PNR'] as String?;
    }
    if (pnr == null || pnr.isEmpty) {
      pnr = json['PNR'] as String?;
    }

    // Get Status from Itinerary or root
    int? status;
    if (itinerary != null) {
      final rawStatus = itinerary['Status'];
      status = rawStatus is int ? rawStatus : int.tryParse('$rawStatus');
    }
    if (status == null) {
      final rawStatus = json['Status'];
      status = rawStatus is int ? rawStatus : int.tryParse('$rawStatus');
    }

    // TBO Book failures come in two shapes:
    //   • Single error object: {"Error":{"ErrorCode":...,"ErrorMessage":"..."}}
    //   • Errors array:        {"Errors":[{"Code":30,"UserMessage":"Passport..."}]}
    BookingErrorData? parsedError;
    if (json['Error'] != null) {
      parsedError = BookingErrorData.fromJson(json['Error'] as Map<String, dynamic>);
    } else if (json['Errors'] is List) {
      final errors = json['Errors'] as List;
      if (errors.isNotEmpty && errors.first is Map) {
        final first = errors.first as Map<String, dynamic>;
        parsedError = BookingErrorData(
          errorCode: first['Code'] as int? ?? first['ErrorCode'] as int?,
          errorMessage: (first['UserMessage'] as String?)?.trim()
              ?? first['ErrorMessage'] as String?,
        );
      }
    }

    return BookingResponseData(
      responseStatus: json['ResponseStatus'] as int? ?? status,
      error: parsedError,
      traceId: json['TraceId'] as String? ?? json['TrackingId'] as String?,
      pnr: pnr,
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
