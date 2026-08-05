import '../../domain/entity/AKHotelStartPay_entity.dart';

class AkHotelStartPayModel extends AkHotelStartPayEntity {
  const AkHotelStartPayModel({
    required super.success,
    required super.code,
    required super.transactionId,
    required super.bookStatus,
    required super.crsPnr,
  });

  factory AkHotelStartPayModel.fromJson(Map<String, dynamic> json) {
    return AkHotelStartPayModel(
      success: json['success'] == true,
      code: json['Code']?.toString() ?? '',
      transactionId: json['TransactionID']?.toString() ?? '',
      bookStatus: json['BookStatus']?.toString() ?? '',
      crsPnr: json['CRSPNR']?.toString() ?? '',
    );
  }
}
