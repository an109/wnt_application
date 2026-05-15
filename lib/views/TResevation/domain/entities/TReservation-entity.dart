// lib/features/transport_reservations/domain/entities/transport_reservation_entity.dart
import 'package:equatable/equatable.dart';

class TransportReservationEntity extends Equatable {
  final String searchId;
  final String resultId;
  final String firstName;
  final String email;
  final String phoneNumber;
  final CustomerInfoEntity customerInfo;
  final List<PassengerEntity> passengers;
  final int numPassengers;
  final String currency;
  final String selectedCurrency;
  final String displayCurrency;
  final double displayTotalPrice;
  final double displayBasePrice;
  final double displayRideBasePrice;
  final double displayDiscountAmount;
  final List<String> optionalAmenities;
  final int userId;
  final dynamic guestReference;
  final String tripStartAddress;
  final String tripEndAddress;
  final String tripPickupDatetime;
  final String tripPickupDatetimePretty;
  final String tripReturnPickupDatetime;
  final String tripReturnPickupDatetimePretty;
  final String tripType;
  final String vehicleName;
  final String providerName;
  final String paidVia;
  final String paymentGateway;
  final String paymentReferenceId;
  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String specialInstructions;
  final String notes;
  final String flightNumber;
  final String airline;
  final String? couponCode;
  final List<ExtraPaxInfoEntity>? extraPaxInfo;

  const TransportReservationEntity({
    required this.searchId,
    required this.resultId,
    required this.firstName,
    required this.email,
    required this.phoneNumber,
    required this.customerInfo,
    required this.passengers,
    required this.numPassengers,
    required this.currency,
    required this.selectedCurrency,
    required this.displayCurrency,
    required this.displayTotalPrice,
    required this.displayBasePrice,
    required this.displayRideBasePrice,
    required this.displayDiscountAmount,
    required this.optionalAmenities,
    required this.userId,
    this.guestReference,
    required this.tripStartAddress,
    required this.tripEndAddress,
    required this.tripPickupDatetime,
    required this.tripPickupDatetimePretty,
    this.tripReturnPickupDatetime = '',
    this.tripReturnPickupDatetimePretty = '',
    required this.tripType,
    required this.vehicleName,
    required this.providerName,
    required this.paidVia,
    required this.paymentGateway,
    required this.paymentReferenceId,
    required this.razorpayOrderId,
    required this.razorpayPaymentId,
    this.specialInstructions = '',
    this.notes = '',
    this.flightNumber = '',
    this.airline = '',
    this.couponCode,
    this.extraPaxInfo,
  });

  @override
  List<Object?> get props => [
    searchId, resultId, firstName, email, phoneNumber, customerInfo,
    passengers, numPassengers, currency, selectedCurrency, displayCurrency,
    displayTotalPrice, displayBasePrice, displayRideBasePrice,
    displayDiscountAmount, optionalAmenities, userId, guestReference,
    tripStartAddress, tripEndAddress, tripPickupDatetime,
    tripPickupDatetimePretty, tripReturnPickupDatetime,
    tripReturnPickupDatetimePretty, tripType, vehicleName, providerName,
    paidVia, paymentGateway, paymentReferenceId, razorpayOrderId,
    razorpayPaymentId, specialInstructions, notes, flightNumber, airline,
    couponCode, extraPaxInfo,
  ];
}

class CustomerInfoEntity extends Equatable {
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;

  const CustomerInfoEntity({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
  });

  @override
  List<Object?> get props => [firstName, lastName, email, phoneNumber];
}

class PassengerEntity extends Equatable {
  final String firstName;
  final String lastName;
  final String email;

  const PassengerEntity({
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  @override
  List<Object?> get props => [firstName, lastName, email];
}

class ExtraPaxInfoEntity extends Equatable {
  final String firstName;
  final String lastName;

  const ExtraPaxInfoEntity({
    required this.firstName,
    required this.lastName,
  });

  @override
  List<Object?> get props => [firstName, lastName];
}