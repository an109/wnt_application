class AirportModel {
  final String airportCode;
  final String airportName;
  final String cityCode;
  final String cityName;
  final String countryCode;

  AirportModel({
    required this.airportCode,
    required this.airportName,
    required this.cityCode,
    required this.cityName,
    required this.countryCode,
  });

  factory AirportModel.fromJson(Map<String, dynamic> json) {
    return AirportModel(
      airportCode: json['AIRPORTCODE'] ?? '',
      airportName: json['AIRPORTNAME'] ?? '',
      cityCode: json['CITYCODE'] ?? '',
      cityName: json['CITYNAME'] ?? '',
      countryCode: json['COUNTRYCODE'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'AIRPORTCODE': airportCode,
      'AIRPORTNAME': airportName,
      'CITYCODE': cityCode,
      'CITYNAME': cityName,
      'COUNTRYCODE': countryCode,
    };
  }
}