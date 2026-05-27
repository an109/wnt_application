import '../../domain/entity/exchange_rate_entity.dart';

class ExchangeRateModel extends ExchangeRateEntity {
  const ExchangeRateModel({
    required String result,
    required String documentation,
    required String termsOfUse,
    required String timeLastUpdateUnix,
    required String timeLastUpdateUtc,
    required String timeNextUpdateUnix,
    required String timeNextUpdateUtc,
    required String baseCode,
    required Map<String, double> conversionRates,
  }) : super(
    result: result,
    documentation: documentation,
    termsOfUse: termsOfUse,
    timeLastUpdateUnix: timeLastUpdateUnix,
    timeLastUpdateUtc: timeLastUpdateUtc,
    timeNextUpdateUnix: timeNextUpdateUnix,
    timeNextUpdateUtc: timeNextUpdateUtc,
    baseCode: baseCode,
    conversionRates: conversionRates,
  );

  factory ExchangeRateModel.fromJson(Map<String, dynamic> json) {
    final rates = json['conversion_rates'] as Map<String, dynamic>?;
    final parsedRates = rates?.map((key, value) => MapEntry(key, (value as num).toDouble())) ?? {};

    return ExchangeRateModel(
      result: json['result']?.toString() ?? '',
      documentation: json['documentation']?.toString() ?? '',
      termsOfUse: json['terms_of_use']?.toString() ?? '',
      timeLastUpdateUnix: json['time_last_update_unix']?.toString() ?? '',
      timeLastUpdateUtc: json['time_last_update_utc']?.toString() ?? '',
      timeNextUpdateUnix: json['time_next_update_unix']?.toString() ?? '',
      timeNextUpdateUtc: json['time_next_update_utc']?.toString() ?? '',
      baseCode: json['base_code']?.toString() ?? '',
      conversionRates: parsedRates,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'result': result,
      'documentation': documentation,
      'terms_of_use': termsOfUse,
      'time_last_update_unix': timeLastUpdateUnix,
      'time_last_update_utc': timeLastUpdateUtc,
      'time_next_update_unix': timeNextUpdateUnix,
      'time_next_update_utc': timeNextUpdateUtc,
      'base_code': baseCode,
      'conversion_rates': conversionRates,
    };
  }

  ExchangeRateModel copyWith({
    String? result,
    String? documentation,
    String? termsOfUse,
    String? timeLastUpdateUnix,
    String? timeLastUpdateUtc,
    String? timeNextUpdateUnix,
    String? timeNextUpdateUtc,
    String? baseCode,
    Map<String, double>? conversionRates,
  }) {
    return ExchangeRateModel(
      result: result ?? this.result,
      documentation: documentation ?? this.documentation,
      termsOfUse: termsOfUse ?? this.termsOfUse,
      timeLastUpdateUnix: timeLastUpdateUnix ?? this.timeLastUpdateUnix,
      timeLastUpdateUtc: timeLastUpdateUtc ?? this.timeLastUpdateUtc,
      timeNextUpdateUnix: timeNextUpdateUnix ?? this.timeNextUpdateUnix,
      timeNextUpdateUtc: timeNextUpdateUtc ?? this.timeNextUpdateUtc,
      baseCode: baseCode ?? this.baseCode,
      conversionRates: conversionRates ?? this.conversionRates,
    );
  }
}