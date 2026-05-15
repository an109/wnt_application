import 'package:equatable/equatable.dart';

import '../../domain/entities/TReservation-entity.dart';

abstract class TransportReservationEvent extends Equatable {
  const TransportReservationEvent();

  @override
  List<Object?> get props => [];
}

class CreateTransportReservationEvent extends TransportReservationEvent {
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
  final String tripStartAddress;
  final String tripEndAddress;
  final String tripPickupDatetime;
  final String tripType;
  final String vehicleName;
  final String providerName;
  final String paidVia;
  final String paymentGateway;
  final String paymentReferenceId;
  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String? specialInstructions;
  final String? notes;
  final String? flightNumber;
  final String? airline;
  final String? couponCode;
  final List<ExtraPaxInfoEntity>? extraPaxInfo;

  const CreateTransportReservationEvent({
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
    required this.tripStartAddress,
    required this.tripEndAddress,
    required this.tripPickupDatetime,
    required this.tripType,
    required this.vehicleName,
    required this.providerName,
    required this.paidVia,
    required this.paymentGateway,
    required this.paymentReferenceId,
    required this.razorpayOrderId,
    required this.razorpayPaymentId,
    this.specialInstructions,
    this.notes,
    this.flightNumber,
    this.airline,
    this.couponCode,
    this.extraPaxInfo,
  });

  @override
  List<Object?> get props => [
    searchId,
    resultId,
    firstName,
    email,
    phoneNumber,
    customerInfo,
    passengers,
    numPassengers,
    currency,
    selectedCurrency,
    displayCurrency,
    displayTotalPrice,
    displayBasePrice,
    displayRideBasePrice,
    displayDiscountAmount,
    optionalAmenities,
    tripStartAddress,
    tripEndAddress,
    tripPickupDatetime,
    tripType,
    vehicleName,
    providerName,
    paidVia,
    paymentGateway,
    paymentReferenceId,
    razorpayOrderId,
    razorpayPaymentId,
    specialInstructions,
    notes,
    flightNumber,
    airline,
    couponCode,
    extraPaxInfo,
  ];
}