import '../../../../core/error/data_state.dart';

class FareRuleModel {
  final String? airline;
  final String? departureTime;
  final String? destination;
  final String? fareBasisCode;
  final dynamic fareInclusions;
  final String? fareRestriction;
  final String? fareRuleDetail;
  final int? flightId;
  final String? origin;
  final String? returnDate;

  FareRuleModel({
    this.airline,
    this.departureTime,
    this.destination,
    this.fareBasisCode,
    this.fareInclusions,
    this.fareRestriction,
    this.fareRuleDetail,
    this.flightId,
    this.origin,
    this.returnDate,
  });

  factory FareRuleModel.fromJson(Map<String, dynamic> json) {
    return FareRuleModel(
      airline: json['Airline'] as String?,
      departureTime: json['DepartureTime'] as String?,
      destination: json['Destination'] as String?,
      fareBasisCode: json['FareBasisCode'] as String?,
      fareInclusions: json['FareInclusions'],
      fareRestriction: json['FareRestriction'] as String?,
      fareRuleDetail: json['FareRuleDetail'] as String?,
      flightId: json['FlightId'] as int?,
      origin: json['Origin'] as String?,
      returnDate: json['ReturnDate'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Airline': airline,
      'DepartureTime': departureTime,
      'Destination': destination,
      'FareBasisCode': fareBasisCode,
      'FareInclusions': fareInclusions,
      'FareRestriction': fareRestriction,
      'FareRuleDetail': fareRuleDetail,
      'FlightId': flightId,
      'Origin': origin,
      'ReturnDate': returnDate,
    };
  }
}

class FareRuleResponseModel {
  final FareRuleErrorModel? error;
  final List<FareRuleModel>? fareRules;
  final int? responseStatus;
  final String? traceId;

  FareRuleResponseModel({
    this.error,
    this.fareRules,
    this.responseStatus,
    this.traceId,
  });

  factory FareRuleResponseModel.fromJson(Map<String, dynamic> json) {
    final response = json['Response'] as Map<String, dynamic>?;
    if (response == null) {
      return FareRuleResponseModel();
    }

    return FareRuleResponseModel(
      error: response['Error'] != null
          ? FareRuleErrorModel.fromJson(response['Error'] as Map<String, dynamic>)
          : null,
      fareRules: response['FareRules'] != null
          ? (response['FareRules'] as List)
          .map((item) => FareRuleModel.fromJson(item as Map<String, dynamic>))
          .toList()
          : null,
      responseStatus: response['ResponseStatus'] as int?,
      traceId: response['TraceId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Response': {
        'Error': error?.toJson(),
        'FareRules': fareRules?.map((item) => item.toJson()).toList(),
        'ResponseStatus': responseStatus,
        'TraceId': traceId,
      },
    };
  }
}

class FareRuleErrorModel {
  final int? errorCode;
  final String? errorMessage;

  FareRuleErrorModel({
    this.errorCode,
    this.errorMessage,
  });

  factory FareRuleErrorModel.fromJson(Map<String, dynamic> json) {
    return FareRuleErrorModel(
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

class FareRuleRequestModel {
  final String endUserIp;
  final String traceId;
  final String? tokenId;
  final String resultIndex;

  FareRuleRequestModel({
    required this.endUserIp,
    required this.traceId,
    this.tokenId,
    required this.resultIndex,
  });

  Map<String, dynamic> toJson() {
    return {
      'EndUserIp': endUserIp,
      'TraceId': traceId,
      'TokenId': tokenId,
      'ResultIndex': resultIndex,
    };

  }
}