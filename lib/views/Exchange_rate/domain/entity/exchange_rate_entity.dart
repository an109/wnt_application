import 'package:equatable/equatable.dart';

class ExchangeRateEntity extends Equatable {
  final String result;
  final String documentation;
  final String termsOfUse;
  final String timeLastUpdateUnix;
  final String timeLastUpdateUtc;
  final String timeNextUpdateUnix;
  final String timeNextUpdateUtc;
  final String baseCode;
  final Map<String, double> conversionRates;

  const ExchangeRateEntity({
    required this.result,
    required this.documentation,
    required this.termsOfUse,
    required this.timeLastUpdateUnix,
    required this.timeLastUpdateUtc,
    required this.timeNextUpdateUnix,
    required this.timeNextUpdateUtc,
    required this.baseCode,
    required this.conversionRates,
  });

  @override
  List<Object?> get props => [
    result,
    documentation,
    termsOfUse,
    timeLastUpdateUnix,
    timeLastUpdateUtc,
    timeNextUpdateUnix,
    timeNextUpdateUtc,
    baseCode,
    conversionRates,
  ];
}