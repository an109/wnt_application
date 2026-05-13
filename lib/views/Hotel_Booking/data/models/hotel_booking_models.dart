class HotelBookingModel {
  final StatusModel status;
  final List<HotelResultModel> hotelResult;

  HotelBookingModel({
    required this.status,
    required this.hotelResult,
  });

  factory HotelBookingModel.fromJson(Map<String, dynamic> json) {
    return HotelBookingModel(
      status: StatusModel.fromJson(json['Status']),
      hotelResult: (json['HotelResult'] as List?)
          ?.map((e) => HotelResultModel.fromJson(e))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Status': status.toJson(),
      'HotelResult': hotelResult.map((e) => e.toJson()).toList(),
    };
  }
}

class StatusModel {
  final int code;
  final String description;

  StatusModel({
    required this.code,
    required this.description,
  });

  factory StatusModel.fromJson(Map<String, dynamic> json) {
    return StatusModel(
      code: json['Code'] ?? 0,
      description: json['Description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Code': code,
      'Description': description,
    };
  }
}

class HotelResultModel {
  final String hotelCode;
  final String currency;
  final List<RoomModel> rooms;
  final List<String> rateConditions;

  HotelResultModel({
    required this.hotelCode,
    required this.currency,
    required this.rooms,
    required this.rateConditions,
  });

  factory HotelResultModel.fromJson(Map<String, dynamic> json) {
    return HotelResultModel(
      hotelCode: json['HotelCode'] ?? '',
      currency: json['Currency'] ?? '',
      rooms: (json['Rooms'] as List?)
          ?.map((e) => RoomModel.fromJson(e))
          .toList() ??
          [],
      rateConditions: (json['RateConditions'] as List?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'HotelCode': hotelCode,
      'Currency': currency,
      'Rooms': rooms.map((e) => e.toJson()).toList(),
      'RateConditions': rateConditions,
    };
  }
}

class RoomModel {
  final List<String> name;
  final String bookingCode;
  final String inclusion;
  final List<List<Map<String, dynamic>>> dayRates;
  final double totalFare;
  final double totalTax;
  final String recommendedSellingRate;
  final List<String> roomPromotion;
  final List<CancelPolicyModel> cancelPolicies;
  final String mealType;
  final bool isRefundable;
  final List<List<SupplementModel>> supplements;
  final bool withTransfers;
  final List<String> amenities;

  RoomModel({
    required this.name,
    required this.bookingCode,
    required this.inclusion,
    required this.dayRates,
    required this.totalFare,
    required this.totalTax,
    required this.recommendedSellingRate,
    required this.roomPromotion,
    required this.cancelPolicies,
    required this.mealType,
    required this.isRefundable,
    required this.supplements,
    required this.withTransfers,
    required this.amenities,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      name: (json['Name'] as List?)?.map((e) => e.toString()).toList() ?? [],
      bookingCode: json['BookingCode'] ?? '',
      inclusion: json['Inclusion'] ?? '',
      dayRates: (json['DayRates'] as List?)
          ?.map((day) => (day as List)
          .map((rate) => Map<String, dynamic>.from(rate))
          .toList())
          .toList() ??
          [],
      totalFare: (json['TotalFare'] ?? 0).toDouble(),
      totalTax: (json['TotalTax'] ?? 0).toDouble(),
      recommendedSellingRate: json['RecommendedSellingRate'] ?? '',
      roomPromotion:
      (json['RoomPromotion'] as List?)?.map((e) => e.toString()).toList() ??
          [],
      cancelPolicies: (json['CancelPolicies'] as List?)
          ?.map((e) => CancelPolicyModel.fromJson(e))
          .toList() ??
          [],
      mealType: json['MealType'] ?? '',
      isRefundable: json['IsRefundable'] ?? false,
      supplements: (json['Supplements'] as List?)
          ?.map((supp) => (supp as List)
          .map((s) => SupplementModel.fromJson(s))
          .toList())
          .toList() ??
          [],
      withTransfers: json['WithTransfers'] ?? false,
      amenities:
      (json['Amenities'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Name': name,
      'BookingCode': bookingCode,
      'Inclusion': inclusion,
      'DayRates': dayRates,
      'TotalFare': totalFare,
      'TotalTax': totalTax,
      'RecommendedSellingRate': recommendedSellingRate,
      'RoomPromotion': roomPromotion,
      'CancelPolicies': cancelPolicies.map((e) => e.toJson()).toList(),
      'MealType': mealType,
      'IsRefundable': isRefundable,
      'Supplements': supplements.map((supp) => supp.map((s) => s.toJson()).toList()).toList(),
      'WithTransfers': withTransfers,
      'Amenities': amenities,
    };
  }
}

class CancelPolicyModel {
  final String fromDate;
  final String chargeType;
  final double cancellationCharge;

  CancelPolicyModel({
    required this.fromDate,
    required this.chargeType,
    required this.cancellationCharge,
  });

  factory CancelPolicyModel.fromJson(Map<String, dynamic> json) {
    return CancelPolicyModel(
      fromDate: json['FromDate'] ?? '',
      chargeType: json['ChargeType'] ?? '',
      cancellationCharge: (json['CancellationCharge'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'FromDate': fromDate,
      'ChargeType': chargeType,
      'CancellationCharge': cancellationCharge,
    };
  }
}

class SupplementModel {
  final int index;
  final String type;
  final String description;
  final double price;
  final String currency;

  SupplementModel({
    required this.index,
    required this.type,
    required this.description,
    required this.price,
    required this.currency,
  });

  factory SupplementModel.fromJson(Map<String, dynamic> json) {
    return SupplementModel(
      index: json['Index'] ?? 0,
      type: json['Type'] ?? '',
      description: json['Description'] ?? '',
      price: (json['Price'] ?? 0).toDouble(),
      currency: json['Currency'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Index': index,
      'Type': type,
      'Description': description,
      'Price': price,
      'Currency': currency,
    };
  }
}