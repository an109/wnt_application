import 'package:equatable/equatable.dart';

class FlightBookEntity extends Equatable {
  final int id;
  final String flightType;
  final String flightNumber;
  final String fromCity;
  final String toCity;
  final String departureDate;
  final String? returnDate;
  final int passengers;
  final String flightClass;
  final dynamic user;
  final String guestReference;
  final String bookingToken;
  final List<dynamic> segments;
  final String? name;
  final String email;
  final String phone;
  final String passportNumber;
  final dynamic passportExpiry;
  final String bookingDate;
  final String pnr;
  final String tboBookingId;
  final dynamic checkoutId;
  final dynamic ccavenueOrderId;
  final String totalAmount;
  final String currency;
  final String? paidVia;
  final Map<String, dynamic> ssrSelections;
  final List<PassengerDataEntity> passengersData;
  final String created;
  final String updated;

  const FlightBookEntity({
    required this.id,
    required this.flightType,
    required this.flightNumber,
    required this.fromCity,
    required this.toCity,
    required this.departureDate,
    this.returnDate,
    required this.passengers,
    required this.flightClass,
    this.user,
    required this.guestReference,
    required this.bookingToken,
    required this.segments,
    this.name,
    required this.email,
    required this.phone,
    required this.passportNumber,
    this.passportExpiry,
    required this.bookingDate,
    required this.pnr,
    required this.tboBookingId,
    this.checkoutId,
    this.ccavenueOrderId,
    required this.totalAmount,
    required this.currency,
    this.paidVia,
    required this.ssrSelections,
    required this.passengersData,
    required this.created,
    required this.updated,
  });

  @override
  List<Object?> get props => [
    id,
    flightType,
    flightNumber,
    fromCity,
    toCity,
    departureDate,
    returnDate,
    passengers,
    flightClass,
    user,
    guestReference,
    bookingToken,
    segments,
    name,
    email,
    phone,
    passportNumber,
    passportExpiry,
    bookingDate,
    pnr,
    tboBookingId,
    checkoutId,
    ccavenueOrderId,
    totalAmount,
    currency,
    paidVia,
    ssrSelections,
    passengersData,
    created,
    updated,
  ];
}

class PassengerDataEntity extends Equatable {
  final String email;
  final String phone;
  final String title;
  final int paxType;
  final dynamic tboMeal;
  final dynamic tboSeat;
  final String lastName;
  final String firstName;
  final bool isLeadPax;
  final String passportNo;
  final String dateOfBirth;
  final String nationality;
  final String ticketNumber;

  const PassengerDataEntity({
    required this.email,
    required this.phone,
    required this.title,
    required this.paxType,
    this.tboMeal,
    this.tboSeat,
    required this.lastName,
    required this.firstName,
    required this.isLeadPax,
    required this.passportNo,
    required this.dateOfBirth,
    required this.nationality,
    required this.ticketNumber,
  });

  @override
  List<Object?> get props => [
    email,
    phone,
    title,
    paxType,
    tboMeal,
    tboSeat,
    lastName,
    firstName,
    isLeadPax,
    passportNo,
    dateOfBirth,
    nationality,
    ticketNumber,
  ];
}