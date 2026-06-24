// ignore_for_file: avoid_print
import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';

/// Parses the TBO `GetBookingDetails` response envelope.
class BookingDetailsModel {
  final int? bookingId;
  final String? pnr;
  final String? bookingDate;
  final String? origin;
  final String? destination;
  final String? travelDate;
  final bool? isLcc;
  final int? status; // 1=Pending, 2=Confirmed, 3=Cancelled …
  final String? validatingAirline;

  // Fare
  final double? baseFare;
  final double? tax;
  final double? yqTax;
  final double? publishedFare;
  final double? offeredFare;
  final String? currency;

  // Passengers
  final List<BookingPassengerDetail> passengers;

  // Segments
  final List<BookingSegmentDetail> segments;

  // Error
  final int? errorCode;
  final String? errorMessage;

  BookingDetailsModel({
    this.bookingId,
    this.pnr,
    this.bookingDate,
    this.origin,
    this.destination,
    this.travelDate,
    this.isLcc,
    this.status,
    this.validatingAirline,
    this.baseFare,
    this.tax,
    this.yqTax,
    this.publishedFare,
    this.offeredFare,
    this.currency,
    this.passengers = const [],
    this.segments = const [],
    this.errorCode,
    this.errorMessage,
  });

  bool get isSuccess =>
      (errorCode == null || errorCode == 0) &&
      errorMessage == null &&
      bookingId != null;

  factory BookingDetailsModel.fromJson(Map<String, dynamic> json) {
    // TBO wraps response in {"Response":{...}}
    final resp = (json['Response'] as Map<String, dynamic>?) ?? json;
    final err = resp['Error'] as Map<String, dynamic>?;
    final errCode = err?['ErrorCode'] as int?;
    final errMsg = (err?['ErrorMessage'] as String?)?.trim();

    final itinerary = resp['FlightItinerary'] as Map<String, dynamic>?;
    if (itinerary == null) {
      return BookingDetailsModel(
        errorCode: errCode ?? -1,
        errorMessage: errMsg?.isNotEmpty == true
            ? errMsg
            : 'No itinerary in response',
      );
    }

    // Fare
    final fare = itinerary['Fare'] as Map<String, dynamic>?;

    // Passengers
    final rawPax = itinerary['Passenger'] as List? ?? [];
    final passengers = rawPax
        .whereType<Map>()
        .map((p) => BookingPassengerDetail.fromJson(
            Map<String, dynamic>.from(p)))
        .toList();

    // Segments — can be [[seg]] or [seg]
    final rawSegs = itinerary['Segments'] as List? ??
        itinerary['Segments_BE'] as List? ??
        [];
    final flatSegs = <Map<String, dynamic>>[];
    for (final item in rawSegs) {
      if (item is List) {
        for (final s in item) {
          if (s is Map) flatSegs.add(Map<String, dynamic>.from(s));
        }
      } else if (item is Map) {
        flatSegs.add(Map<String, dynamic>.from(item));
      }
    }
    final segments =
        flatSegs.map(BookingSegmentDetail.fromJson).toList();

    return BookingDetailsModel(
      bookingId: itinerary['BookingId'] as int?,
      pnr: itinerary['PNR'] as String?,
      bookingDate: itinerary['BookingDate'] as String?,
      origin: itinerary['Origin'] as String?,
      destination: itinerary['Destination'] as String?,
      travelDate: itinerary['TravelDate'] as String?,
      isLcc: itinerary['IsLcc'] as bool? ?? itinerary['IsLCC'] as bool?,
      status: itinerary['Status'] as int?,
      validatingAirline: itinerary['ValidatingAirline'] as String? ??
          itinerary['ValidatingAirlineCode'] as String?,
      baseFare: (fare?['BaseFare'] as num?)?.toDouble(),
      tax: (fare?['Tax'] as num?)?.toDouble(),
      yqTax: (fare?['YQTax'] as num?)?.toDouble(),
      publishedFare: (fare?['PublishedFare'] as num?)?.toDouble(),
      offeredFare: (fare?['OfferedFare'] as num?)?.toDouble(),
      currency: fare?['Currency'] as String?,
      passengers: passengers,
      segments: segments,
      errorCode: errCode,
      errorMessage: errMsg?.isNotEmpty == true ? errMsg : null,
    );
  }
}

class BookingPassengerDetail {
  final String? firstName;
  final String? lastName;
  final int? paxType;
  final String? gender;
  final String? ticketNumber;
  final String? ticketStatus;
  final String? dateOfBirth;
  final String? passportNo;

  BookingPassengerDetail({
    this.firstName,
    this.lastName,
    this.paxType,
    this.gender,
    this.ticketNumber,
    this.ticketStatus,
    this.dateOfBirth,
    this.passportNo,
  });

  String get fullName =>
      '${firstName ?? ''} ${lastName ?? ''}'.trim();

  factory BookingPassengerDetail.fromJson(Map<String, dynamic> json) {
    final ticket = json['Ticket'] as Map<String, dynamic>?;
    return BookingPassengerDetail(
      firstName: json['FirstName'] as String?,
      lastName: json['LastName'] as String?,
      paxType: json['PaxType'] as int? ?? json['Type'] as int?,
      gender: json['Gender']?.toString(),
      ticketNumber: ticket?['TicketNumber'] as String? ??
          ticket?['TicketId']?.toString(),
      ticketStatus: ticket?['Status'] as String? ?? 'Confirmed',
      dateOfBirth: json['DateOfBirth'] as String?,
      passportNo: json['PassportNo'] as String?,
    );
  }
}

class BookingSegmentDetail {
  final String? airlineCode;
  final String? airlineName;
  final String? flightNumber;
  final String? fareClass;
  final String? originCode;
  final String? originName;
  final String? originTerminal;
  final String? destCode;
  final String? destName;
  final String? destTerminal;
  final String? depTime;
  final String? arrTime;
  final int? duration;
  final String? baggage;
  final String? cabinBaggage;

  BookingSegmentDetail({
    this.airlineCode,
    this.airlineName,
    this.flightNumber,
    this.fareClass,
    this.originCode,
    this.originName,
    this.originTerminal,
    this.destCode,
    this.destName,
    this.destTerminal,
    this.depTime,
    this.arrTime,
    this.duration,
    this.baggage,
    this.cabinBaggage,
  });

  factory BookingSegmentDetail.fromJson(Map<String, dynamic> json) {
    final airline = json['Airline'] as Map<String, dynamic>?;
    final origin = json['Origin'] as Map<String, dynamic>?;
    final dest = json['Destination'] as Map<String, dynamic>?;
    final origAirport = origin?['Airport'] as Map<String, dynamic>?;
    final destAirport = dest?['Airport'] as Map<String, dynamic>?;
    return BookingSegmentDetail(
      airlineCode: airline?['AirlineCode'] as String?,
      airlineName: airline?['AirlineName'] as String?,
      flightNumber: airline?['FlightNumber'] as String?,
      fareClass: airline?['FareClass'] as String?,
      originCode: origAirport?['AirportCode'] as String?,
      originName: origAirport?['AirportName'] as String?,
      originTerminal: origAirport?['Terminal'] as String?,
      destCode: destAirport?['AirportCode'] as String?,
      destName: destAirport?['AirportName'] as String?,
      destTerminal: destAirport?['Terminal'] as String?,
      depTime: origin?['DepTime'] as String?,
      arrTime: dest?['ArrTime'] as String?,
      duration: json['Duration'] as int?,
      baggage: json['Baggage'] as String?,
      cabinBaggage: json['CabinBaggage'] as String?,
    );
  }
}

/// Calls `POST /api/tbo/GetBookingDetails/` with the given PNR.
class BookingDetailsService {
  final Dio dio;
  BookingDetailsService(this.dio);

  Future<BookingDetailsModel> fetch(String pnr) async {
    try {
      print('GetBookingDetails → PNR=$pnr  url=${Urls.getBookingDetails}');
      final response = await dio.post(
        Urls.getBookingDetails,
        data: {'PNR': pnr},
      );
      print('GetBookingDetails ← status=${response.statusCode}');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return BookingDetailsModel.fromJson(data);
      }
      return BookingDetailsModel(
          errorCode: -1, errorMessage: 'Unexpected response format');
    } on DioException catch (e) {
      print('GetBookingDetails DioError: ${e.message}');
      return BookingDetailsModel(
          errorCode: -1, errorMessage: e.message ?? 'Network error');
    } catch (e) {
      print('GetBookingDetails Error: $e');
      return BookingDetailsModel(
          errorCode: -1, errorMessage: e.toString());
    }
  }
}
