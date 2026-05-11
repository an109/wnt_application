import 'package:equatable/equatable.dart';

class FareRuleEntity extends Equatable {
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

  const FareRuleEntity({
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

  @override
  List<Object?> get props => [
    airline,
    departureTime,
    destination,
    fareBasisCode,
    fareInclusions,
    fareRestriction,
    fareRuleDetail,
    flightId,
    origin,
    returnDate,
  ];
}

class FareRuleResponseEntity extends Equatable {
  final FareRuleErrorEntity? error;
  final List<FareRuleEntity>? fareRules;
  final int? responseStatus;
  final String? traceId;

  const FareRuleResponseEntity({
    this.error,
    this.fareRules,
    this.responseStatus,
    this.traceId,
  });

  @override
  List<Object?> get props => [error, fareRules, responseStatus, traceId];
}

class FareRuleErrorEntity extends Equatable {
  final int? errorCode;
  final String? errorMessage;

  const FareRuleErrorEntity({
    this.errorCode,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [errorCode, errorMessage];
}

class FareRuleRequestEntity extends Equatable {
  final String endUserIp;
  final String traceId;
  final String? tokenId;
  final String resultIndex;

  const FareRuleRequestEntity({
    required this.endUserIp,
    required this.traceId,
    this.tokenId,
    required this.resultIndex,
  });

  @override
  List<Object?> get props => [endUserIp, traceId, tokenId, resultIndex];
}