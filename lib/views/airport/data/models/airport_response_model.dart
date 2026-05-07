import 'airport_model.dart';

class AirportResponseModel {
  final bool success;
  final String message;
  final List<AirportModel> data;

  AirportResponseModel({
    required this.success,
    required this.message,
    required this.data,
  });

  factory AirportResponseModel.fromJson(Map<String, dynamic> json) {
    return AirportResponseModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => AirportModel.fromJson(item as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }
}