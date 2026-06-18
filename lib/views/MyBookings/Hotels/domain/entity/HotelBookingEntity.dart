import 'package:equatable/equatable.dart';

class HotelBookingListEntity extends Equatable {
  final int id;
  final dynamic reseller;
  final dynamic user;
  final String confirmationNumber;
  final String bookingReferenceId;
  final String tboBookingId;
  final String hotelName;
  final String hotelCode;
  final String hotelAddress;
  final String hotelCity;
  final String hotelCountry;
  final int hotelStars;
  final String hotelImage;
  final String roomType;
  final String checkIn;
  final String checkOut;
  final int nights;
  final int rooms;
  final int guests;
  final int adults;
  final int children;
  final String totalFare;
  final String tax;
  final String currency;
  final String guestName;
  final String email;
  final String phone;
  final String paymentMode;
  final String checkoutId;
  final String guestReference;
  final String status;
  final String? bookingDate;
  final String created;
  final String updated;

  const HotelBookingListEntity({
    required this.id,
    this.reseller,
    this.user,
    required this.confirmationNumber,
    required this.bookingReferenceId,
    required this.tboBookingId,
    required this.hotelName,
    required this.hotelCode,
    required this.hotelAddress,
    required this.hotelCity,
    required this.hotelCountry,
    required this.hotelStars,
    required this.hotelImage,
    required this.roomType,
    required this.checkIn,
    required this.checkOut,
    required this.nights,
    required this.rooms,
    required this.guests,
    required this.adults,
    required this.children,
    required this.totalFare,
    required this.tax,
    required this.currency,
    required this.guestName,
    required this.email,
    required this.phone,
    required this.paymentMode,
    required this.checkoutId,
    required this.guestReference,
    required this.status,
    this.bookingDate,
    required this.created,
    required this.updated,
  });

  @override
  List<Object?> get props => [
    id, reseller, user, confirmationNumber, bookingReferenceId, tboBookingId,
    hotelName, hotelCode, hotelAddress, hotelCity, hotelCountry, hotelStars,
    hotelImage, roomType, checkIn, checkOut, nights, rooms, guests, adults,
    children, totalFare, tax, currency, guestName, email, phone, paymentMode,
    checkoutId, guestReference, status, bookingDate, created, updated,
  ];
}