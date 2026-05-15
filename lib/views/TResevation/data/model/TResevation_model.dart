import '../../domain/entities/TReservation-entity.dart';

class TransportReservationModel {
  final String searchId;
  final String resultId;
  final String firstName;
  final String email;
  final String phoneNumber;
  final CustomerInfoModel customerInfo;
  final List<PassengerModel> passengers;
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
  final List<ExtraPaxInfoModel>? extraPaxInfo;

  const TransportReservationModel({
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

  factory TransportReservationModel.fromJson(Map<String, dynamic> json) {
    return TransportReservationModel(
      searchId: json['search_id'] ?? '',
      resultId: json['result_id'] ?? '',
      firstName: json['first_name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      customerInfo: CustomerInfoModel.fromJson(json['customer_info'] ?? {}),
      passengers: (json['passengers'] as List<dynamic>?)
          ?.map((p) => PassengerModel.fromJson(p))
          .toList() ??
          [],
      numPassengers: json['num_passengers'] ?? 0,
      currency: json['currency'] ?? '',
      selectedCurrency: json['selected_currency'] ?? '',
      displayCurrency: json['display_currency'] ?? '',
      displayTotalPrice: (json['display_total_price'] ?? 0).toDouble(),
      displayBasePrice: (json['display_base_price'] ?? 0).toDouble(),
      displayRideBasePrice: (json['display_ride_base_price'] ?? 0).toDouble(),
      displayDiscountAmount: (json['display_discount_amount'] ?? 0).toDouble(),
      optionalAmenities: (json['optional_amenities'] as List<dynamic>?)
          ?.map((a) => a.toString())
          .toList() ??
          [],
      userId: json['user_id'] ?? 0,
      guestReference: json['guest_reference'],
      tripStartAddress: json['trip_start_address'] ?? '',
      tripEndAddress: json['trip_end_address'] ?? '',
      tripPickupDatetime: json['trip_pickup_datetime'] ?? '',
      tripPickupDatetimePretty: json['trip_pickup_datetime_pretty'] ?? '',
      tripReturnPickupDatetime: json['trip_return_pickup_datetime'] ?? '',
      tripReturnPickupDatetimePretty:
      json['trip_return_pickup_datetime_pretty'] ?? '',
      tripType: json['trip_type'] ?? '',
      vehicleName: json['vehicle_name'] ?? '',
      providerName: json['provider_name'] ?? '',
      paidVia: json['paid_via'] ?? '',
      paymentGateway: json['payment_gateway'] ?? '',
      paymentReferenceId: json['payment_reference_id'] ?? '',
      razorpayOrderId: json['razorpay_order_id'] ?? '',
      razorpayPaymentId: json['razorpay_payment_id'] ?? '',
      specialInstructions: json['special_instructions'] ?? '',
      notes: json['notes'] ?? '',
      flightNumber: json['flight_number'] ?? '',
      airline: json['airline'] ?? '',
      couponCode: json['coupon_code'],
      extraPaxInfo: (json['extra_pax_info'] as List<dynamic>?)
          ?.map((e) => ExtraPaxInfoModel.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'search_id': searchId,
      'result_id': resultId,
      'first_name': firstName,
      'email': email,
      'phone_number': phoneNumber,
      'customer_info': customerInfo.toJson(),
      'passengers': passengers.map((p) => p.toJson()).toList(),
      'num_passengers': numPassengers,
      'currency': currency,
      'selected_currency': selectedCurrency,
      'display_currency': displayCurrency,
      'display_total_price': displayTotalPrice,
      'display_base_price': displayBasePrice,
      'display_ride_base_price': displayRideBasePrice,
      'display_discount_amount': displayDiscountAmount,
      'optional_amenities': optionalAmenities,
      'user_id': userId,
      'guest_reference': guestReference,
      'trip_start_address': tripStartAddress,
      'trip_end_address': tripEndAddress,
      'trip_pickup_datetime': tripPickupDatetime,
      'trip_pickup_datetime_pretty': tripPickupDatetimePretty,
      'trip_return_pickup_datetime': tripReturnPickupDatetime,
      'trip_return_pickup_datetime_pretty': tripReturnPickupDatetimePretty,
      'trip_type': tripType,
      'vehicle_name': vehicleName,
      'provider_name': providerName,
      'paid_via': paidVia,
      'payment_gateway': paymentGateway,
      'payment_reference_id': paymentReferenceId,
      'razorpay_order_id': razorpayOrderId,
      'razorpay_payment_id': razorpayPaymentId,
      'special_instructions': specialInstructions,
      'notes': notes,
      'flight_number': flightNumber,
      'airline': airline,
      if (couponCode != null) 'coupon_code': couponCode,
      if (extraPaxInfo != null)
        'extra_pax_info': extraPaxInfo!.map((e) => e.toJson()).toList(),
    };
  }

  // Convert Model to Entity
  TransportReservationEntity toEntity() {
    return TransportReservationEntity(
      searchId: searchId,
      resultId: resultId,
      firstName: firstName,
      email: email,
      phoneNumber: phoneNumber,
      customerInfo: customerInfo.toEntity(),
      passengers: passengers.map((p) => p.toEntity()).toList(),
      numPassengers: numPassengers,
      currency: currency,
      selectedCurrency: selectedCurrency,
      displayCurrency: displayCurrency,
      displayTotalPrice: displayTotalPrice,
      displayBasePrice: displayBasePrice,
      displayRideBasePrice: displayRideBasePrice,
      displayDiscountAmount: displayDiscountAmount,
      optionalAmenities: optionalAmenities,
      userId: userId,
      guestReference: guestReference,
      tripStartAddress: tripStartAddress,
      tripEndAddress: tripEndAddress,
      tripPickupDatetime: tripPickupDatetime,
      tripPickupDatetimePretty: tripPickupDatetimePretty,
      tripReturnPickupDatetime: tripReturnPickupDatetime,
      tripReturnPickupDatetimePretty: tripReturnPickupDatetimePretty,
      tripType: tripType,
      vehicleName: vehicleName,
      providerName: providerName,
      paidVia: paidVia,
      paymentGateway: paymentGateway,
      paymentReferenceId: paymentReferenceId,
      razorpayOrderId: razorpayOrderId,
      razorpayPaymentId: razorpayPaymentId,
      specialInstructions: specialInstructions,
      notes: notes,
      flightNumber: flightNumber,
      airline: airline,
      couponCode: couponCode,
      extraPaxInfo: extraPaxInfo?.map((e) => e.toEntity()).toList(),
    );
  }
}

// ============ Nested Models ============

class CustomerInfoModel {
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;

  const CustomerInfoModel({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
  });

  factory CustomerInfoModel.fromJson(Map<String, dynamic> json) {
    return CustomerInfoModel(
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone_number': phoneNumber,
    };
  }

  CustomerInfoEntity toEntity() {
    return CustomerInfoEntity(
      firstName: firstName,
      lastName: lastName,
      email: email,
      phoneNumber: phoneNumber,
    );
  }
}

class PassengerModel {
  final String firstName;
  final String lastName;
  final String email;

  const PassengerModel({
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  factory PassengerModel.fromJson(Map<String, dynamic> json) {
    return PassengerModel(
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
    };
  }

  PassengerEntity toEntity() {
    return PassengerEntity(
      firstName: firstName,
      lastName: lastName,
      email: email,
    );
  }
}

class ExtraPaxInfoModel {
  final String firstName;
  final String lastName;

  const ExtraPaxInfoModel({
    required this.firstName,
    required this.lastName,
  });

  factory ExtraPaxInfoModel.fromJson(Map<String, dynamic> json) {
    return ExtraPaxInfoModel(
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
    };
  }

  ExtraPaxInfoEntity toEntity() {
    return ExtraPaxInfoEntity(
      firstName: firstName,
      lastName: lastName,
    );
  }
}