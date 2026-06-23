// import 'package:equatable/equatable.dart';
//
// class BookingEntity extends Equatable {
//   final int id;
//   final int userId;
//   final String status;
//   final String email;
//   final String phoneNumber;
//   final String firstName;
//   final String lastName;
//   final String currency;
//   final String amountPaid;
//   final String totalPrice;
//   final bool canCancel;
//   final bool cancelled;
//   final String? reservationTimestamp;
//   final String? cancelledTimestamp;
//   final String providerName;
//   final String confirmationNumber;
//   final String created;
//   final String updated;
//   final String destination;
//   final String type;
//   final int applicantCount;
//   final String bookedDate;
//   final String category;
//
//   const BookingEntity({
//     required this.id,
//     required this.userId,
//     required this.status,
//     required this.email,
//     required this.phoneNumber,
//     required this.firstName,
//     required this.lastName,
//     required this.currency,
//     required this.amountPaid,
//     required this.totalPrice,
//     required this.canCancel,
//     required this.cancelled,
//     this.reservationTimestamp,
//     this.cancelledTimestamp,
//     required this.providerName,
//     required this.confirmationNumber,
//     required this.created,
//     required this.updated,
//     required this.destination,
//     required this.applicantCount,
//     required this.bookedDate,
//     required this.category,
//     required this.type,
//   });
//
//   @override
//   List<Object?> get props => [
//     id, userId, status, email, phoneNumber, firstName, lastName, currency,
//     amountPaid, totalPrice, canCancel, cancelled, reservationTimestamp,
//     cancelledTimestamp, providerName, confirmationNumber, created, updated, destination,
//     applicantCount, bookedDate, category, type
//   ];
// }

import 'package:equatable/equatable.dart';

class BookingEntity extends Equatable {
  final int id;
  final int userId;
  final String status;
  final String email;
  final String phoneNumber;
  final String firstName;
  final String lastName;
  final String currency;
  final String amountPaid;
  final String totalPrice;
  final bool canCancel;
  final bool cancelled;
  final String? reservationTimestamp;
  final String? cancelledTimestamp;
  final String providerName;
  final String confirmationNumber;
  final String created;
  final String updated;
  final String imageUrl;

  // --- NEW UI-SPECIFIC FIELDS (ADD THESE) ---
  final String destination;
  final String type;
  final int applicantCount;
  final String bookedDate;
  final String category;
  final String startAddress;        // NEW
  final String endAddress;          // NEW
  final String pickupDatetime;      // NEW
  final String flightNumber;        // NEW
  final String vehicleName;         // NEW
  final String rawTotalPrice;      // From raw_request.display_total_price
  final String rawCurrency;

  @override
  List<Object?> get props => [
    id, userId, status, email, phoneNumber, firstName, lastName, currency,
    amountPaid, totalPrice, canCancel, cancelled, reservationTimestamp,
    cancelledTimestamp, providerName, confirmationNumber, created, updated,
    destination, type, applicantCount, bookedDate, category,
    startAddress, endAddress, pickupDatetime, flightNumber, vehicleName,
    rawTotalPrice, rawCurrency,imageUrl
  ];

  const BookingEntity({
    required this.id,
    required this.userId,
    required this.status,
    required this.email,
    required this.phoneNumber,
    required this.firstName,
    required this.lastName,
    required this.currency,
    required this.amountPaid,
    required this.totalPrice,
    required this.canCancel,
    required this.cancelled,
    this.reservationTimestamp,
    this.cancelledTimestamp,
    required this.providerName,
    required this.confirmationNumber,
    required this.created,
    required this.updated,
    required this.destination,
    required this.type,
    required this.applicantCount,
    required this.bookedDate,
    required this.category,
    this.startAddress = '',
    this.endAddress = '',
    this.pickupDatetime = '',
    this.flightNumber = '',
    this.vehicleName = '',
    this.rawTotalPrice = '0.00',
    this.rawCurrency = 'USD',
    this.imageUrl = ''
  });
}