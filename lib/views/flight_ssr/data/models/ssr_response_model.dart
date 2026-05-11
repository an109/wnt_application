import 'baggage_model.dart';
import 'meal_dynamic_model.dart';
import 'seat_dynamic_model.dart';
import 'special_service_model.dart';

class SsrResponseModel {
  final SsrResponseData? response;

  SsrResponseModel({this.response});

  factory SsrResponseModel.fromJson(Map<String, dynamic> json) {
    return SsrResponseModel(
      response: json['Response'] != null
          ? SsrResponseData.fromJson(json['Response'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Response': response?.toJson(),
    };
  }
}

class SsrResponseData {
  final int? responseStatus;
  final SsrError? error;
  final String? traceId;
  final List<List<BaggageModel>>? baggage;
  final List<List<MealDynamicModel>>? mealDynamic;
  final List<SeatDynamicModel>? seatDynamic;
  final List<SpecialServiceModel>? specialServices;

  SsrResponseData({
    this.responseStatus,
    this.error,
    this.traceId,
    this.baggage,
    this.mealDynamic,
    this.seatDynamic,
    this.specialServices,
  });

  factory SsrResponseData.fromJson(Map<String, dynamic> json) {
    return SsrResponseData(
      responseStatus: json['ResponseStatus'] as int?,
      error: json['Error'] != null ? SsrError.fromJson(json['Error']) : null,
      traceId: json['TraceId'] as String?,
      baggage: (json['Baggage'] as List?)?.map((item) =>
          (item as List).map((i) => BaggageModel.fromJson(i)).toList()
      ).toList(),
      mealDynamic: (json['MealDynamic'] as List?)?.map((item) =>
          (item as List).map((i) => MealDynamicModel.fromJson(i)).toList()
      ).toList(),
      seatDynamic: (json['SeatDynamic'] as List?)?.map((item) =>
          SeatDynamicModel.fromJson(item)
      ).toList(),
      specialServices: (json['SpecialServices'] as List?)?.map((item) =>
          SpecialServiceModel.fromJson(item)
      ).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ResponseStatus': responseStatus,
      'Error': error?.toJson(),
      'TraceId': traceId,
      'Baggage': baggage?.map((item) =>
          item.map((i) => i.toJson()).toList()
      ).toList(),
      'MealDynamic': mealDynamic?.map((item) =>
          item.map((i) => i.toJson()).toList()
      ).toList(),
      'SeatDynamic': seatDynamic?.map((item) => item.toJson()).toList(),
      'SpecialServices': specialServices?.map((item) => item.toJson()).toList(),
    };
  }
}

class SsrError {
  final int? errorCode;
  final String? errorMessage;

  SsrError({this.errorCode, this.errorMessage});

  factory SsrError.fromJson(Map<String, dynamic> json) {
    return SsrError(
      errorCode: json['ErrorCode'] as int?,
      errorMessage: json['ErrorMessage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ErrorCode': errorCode,
      'ErrorMessage': errorMessage,
    };
  }
}