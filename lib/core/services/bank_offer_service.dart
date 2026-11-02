import 'package:dio/dio.dart';
import '../constants/urls.dart';
import '../../injection_container.dart';
import '../network/dio_client.dart';

class BankOffer {
  final int id;
  final String title;
  final String displayText;
  final String terms;
  final String bankName;
  final String code;
  final String? logoUrl;
  final double minAmount;
  final DateTime? validTill;

  BankOffer({
    required this.id,
    required this.title,
    required this.displayText,
    required this.terms,
    required this.bankName,
    required this.code,
    this.logoUrl,
    required this.minAmount,
    this.validTill,
  });

  factory BankOffer.fromJson(Map<String, dynamic> json) {
    return BankOffer(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      displayText: json['display_text'] as String? ?? '',
      terms: json['terms'] as String? ?? '',
      bankName: json['bank_name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      logoUrl: json['logo_url'] as String?,
      minAmount: double.tryParse('${json['min_amount']}') ?? 0,
      validTill: json['valid_till'] != null
          ? DateTime.tryParse(json['valid_till'] as String)
          : null,
    );
  }

  bool get hasCode => code.isNotEmpty;
}

class BankOfferService {
  final Dio _dio = sl<DioClient>().instance;

  Future<List<BankOffer>> fetchOffers({String type = 'flight'}) async {
    final response = await _dio.get(
      Urls.razorpayBankOffers,
      queryParameters: {'type': type},
    );
    final data = response.data as Map<String, dynamic>;
    if (data['success'] == true) {
      final list = data['offers'] as List<dynamic>;
      return list
          .map((e) => BankOffer.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
