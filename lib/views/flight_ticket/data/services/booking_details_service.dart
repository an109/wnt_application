// ignore_for_file: avoid_print
import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';

class BookingDetailsModel {
  final int? bookingId;
  final String? pnr;
  final String? bookingDate;
  final String? origin;
  final String? destination;
  final String? travelDate;
  final bool? isLcc;
  final int? status;
  final String? validatingAirline;

  // Fare (aggregated from first passenger)
  final double? baseFare;
  final double? tax;
  final double? offeredFare;
  final double? publishedFare;
  final String? currency;

  final List<BookingPassengerDetail> passengers;
  final List<BookingSegmentDetail> segments;

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
    this.offeredFare,
    this.publishedFare,
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
    // Response has top-level "Itinerary" key (not Response > FlightItinerary)
    final itinerary = json['Itinerary'] as Map<String, dynamic>?;

    if (itinerary == null) {
      final errors = json['Errors'] as List?;
      final errMsg = errors?.isNotEmpty == true
          ? errors!.first?.toString()
          : 'No itinerary in response';
      return BookingDetailsModel(errorCode: -1, errorMessage: errMsg);
    }

    // Passengers
    final rawPax = itinerary['Passenger'] as List? ?? [];
    final passengers = rawPax
        .whereType<Map>()
        .map((p) => BookingPassengerDetail.fromJson(Map<String, dynamic>.from(p)))
        .toList();

    // Fare from first passenger's Fare object
    final firstPaxMap = rawPax.isNotEmpty ? rawPax.first as Map? : null;
    final fareData = firstPaxMap?['Fare'] as Map<String, dynamic>?;

    // Segments — flatten nested list if needed
    final rawSegs = itinerary['Segments'] as List? ?? [];
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
    final segments = flatSegs.map(BookingSegmentDetail.fromJson).toList();

    return BookingDetailsModel(
      bookingId: itinerary['BookingId'] as int?,
      pnr: itinerary['PNR'] as String?,
      bookingDate: itinerary['CreatedOn'] as String?,
      origin: itinerary['Origin'] as String?,
      destination: itinerary['Destination'] as String?,
      travelDate: itinerary['TravelDate'] as String?,
      isLcc: itinerary['IsLcc'] as bool?,
      status: itinerary['Status'] as int? ?? json['Status'] as int?,
      validatingAirline: itinerary['ValidatingAirlineCode'] as String?,
      baseFare: (fareData?['BaseFare_API'] as num?)?.toDouble(),
      tax: (fareData?['Tax_API'] as num?)?.toDouble(),
      offeredFare: (fareData?['TotalFare'] as num?)?.toDouble(),
      currency: fareData?['AgentPreferredCurrency'] as String?,
      passengers: passengers,
      segments: segments,
    );
  }
}

class BookingPassengerDetail {
  final int? paxId;
  final String? title;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? mobile;
  final bool? isLeadPax;
  final int? paxType;
  final String? gender;
  final String? dateOfBirth;
  final String? passportNo;
  final String? ticketNumber;
  final String? ticketStatus;
  final String? ticketIssueDate;
  // Parsed from PaxSeat / PaxBaggage — TBO's top-level Seat.Code is always null.
  final String? seatCode;
  final String? baggageCode;
  final int? baggageWeight;

  BookingPassengerDetail({
    this.paxId,
    this.title,
    this.firstName,
    this.lastName,
    this.email,
    this.mobile,
    this.isLeadPax,
    this.paxType,
    this.gender,
    this.dateOfBirth,
    this.passportNo,
    this.ticketNumber,
    this.ticketStatus,
    this.ticketIssueDate,
    this.seatCode,
    this.baggageCode,
    this.baggageWeight,
  });

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();

  factory BookingPassengerDetail.fromJson(Map<String, dynamic> json) {
    final ticket = json['Ticket'] as Map<String, dynamic>?;
    final rawStatus = ticket?['Status'] as String?;

    // PaxSeat contains the actual chosen seat (Seat.Code is always null from TBO).
    final paxSeatList = json['PaxSeat'] as List?;
    final firstSeat = paxSeatList?.whereType<Map>().firstOrNull;
    final seatCode = firstSeat?['Code'] as String?;

    // PaxBaggage contains the chosen baggage allowance.
    final paxBagList = json['PaxBaggage'] as List?;
    final firstBag = paxBagList?.whereType<Map>().firstOrNull;
    final baggageCode = firstBag?['Code'] as String?;
    final baggageWeight = (firstBag?['Weight'] as num?)?.toInt();

    return BookingPassengerDetail(
      paxId: json['PaxId'] as int?,
      title: json['Title'] as String?,
      firstName: json['FirstName'] as String?,
      lastName: json['LastName'] as String?,
      email: json['Email'] as String?,
      mobile: json['Mobile1'] as String?,
      isLeadPax: json['IsLeadPax'] as bool?,
      paxType: json['Type'] as int?,
      gender: json['Gender']?.toString(),
      dateOfBirth: json['DateOfBirth'] as String?,
      passportNo: json['PassportNo'] as String?,
      ticketNumber: ticket?['TicketNumber'] as String? ?? ticket?['TicketId']?.toString(),
      ticketStatus: (rawStatus == 'OK' || rawStatus == null) ? 'Confirmed' : rawStatus,
      ticketIssueDate: ticket?['IssueDate'] as String?,
      seatCode: seatCode,
      baggageCode: baggageCode,
      baggageWeight: baggageWeight,
    );
  }
}

class BookingSegmentDetail {
  final int? segmentId;
  final String? airlineCode;
  final String? airlineName;
  final String? flightNumber;
  final String? bookingClass;
  final String? fareClass;
  final String? originCode;
  final String? originName;
  final String? originCityName;
  final String? originTerminal;
  final String? destCode;
  final String? destName;
  final String? destCityName;
  final String? destTerminal;
  final String? depTime;
  final String? arrTime;
  // duration in minutes (parsed from "HH:MM:SS" string)
  final int? duration;
  final String? durationRaw;
  final String? baggage;
  final String? cabinBaggage;
  final String? cabinClass;
  final String? craft;
  final bool? stopOver;
  final int? stops;
  final bool? eTicketEligible;

  BookingSegmentDetail({
    this.segmentId,
    this.airlineCode,
    this.airlineName,
    this.flightNumber,
    this.bookingClass,
    this.fareClass,
    this.originCode,
    this.originName,
    this.originCityName,
    this.originTerminal,
    this.destCode,
    this.destName,
    this.destCityName,
    this.destTerminal,
    this.depTime,
    this.arrTime,
    this.duration,
    this.durationRaw,
    this.baggage,
    this.cabinBaggage,
    this.cabinClass,
    this.craft,
    this.stopOver,
    this.stops,
    this.eTicketEligible,
  });

  factory BookingSegmentDetail.fromJson(Map<String, dynamic> json) {
    // Origin and Destination are flat objects with AirportCode, AirportName, Terminal
    final origin = json['Origin'] as Map<String, dynamic>?;
    final dest = json['Destination'] as Map<String, dynamic>?;

    // Duration is "HH:MM:SS" — convert to minutes
    final durationStr = json['Duration'] as String?;
    int? durationMinutes;
    if (durationStr != null && durationStr.contains(':')) {
      final parts = durationStr.split(':');
      if (parts.length >= 2) {
        final h = int.tryParse(parts[0]) ?? 0;
        final m = int.tryParse(parts[1]) ?? 0;
        durationMinutes = h * 60 + m;
      }
    }

    return BookingSegmentDetail(
      segmentId: json['SegmentId'] as int?,
      // "Airline" is a string code (e.g. "SG"), not an object
      airlineCode: json['Airline'] as String?,
      airlineName: json['AirlineName'] as String?,
      flightNumber: json['FlightNumber'] as String?,
      bookingClass: json['BookingClass'] as String?,
      fareClass: json['FareFamilyClass'] as String? ?? json['BookingClass'] as String?,
      // Origin fields are direct children of the Origin object
      originCode: origin?['AirportCode'] as String?,
      originName: origin?['AirportName'] as String?,
      originCityName: origin?['CityName'] as String?,
      originTerminal: origin?['Terminal'] as String? ?? json['DepTerminal'] as String?,
      destCode: dest?['AirportCode'] as String?,
      destName: dest?['AirportName'] as String?,
      destCityName: dest?['CityName'] as String?,
      destTerminal: dest?['Terminal'] as String? ?? json['ArrTerminal'] as String?,
      // TBO GetBookingDetails uses DepartureDateTime / ArrivalDateTime at
      // segment level. Fall back to the nested DepTime/ArrTime inside Origin /
      // Destination (used by some response variants).
      depTime: json['DepartureTime'] as String?
          ?? json['DepartureDateTime'] as String?
          ?? origin?['DepTime'] as String?,
      arrTime: json['ArrivalTime'] as String?
          ?? json['ArrivalDateTime'] as String?
          ?? dest?['ArrTime'] as String?,
      duration: durationMinutes,
      durationRaw: durationStr,
      baggage: json['IncludedBaggage'] as String?,
      cabinBaggage: json['CabinBaggage'] as String?,
      cabinClass: json['CabinClass'] as String?,
      craft: json['Craft'] as String?,
      stopOver: json['StopOver'] as bool?,
      stops: json['Stops'] as int?,
      eTicketEligible: json['ETicketEligible'] as bool?,
    );
  }
}

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
      return BookingDetailsModel(errorCode: -1, errorMessage: e.toString());
    }
  }
}
