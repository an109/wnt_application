import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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

  /// True when [amountInr] is under this offer's minimum booking amount.
  bool isBelowMinimum(double amountInr) =>
      minAmount > 0 && amountInr > 0 && amountInr < minAmount;
}

class BankOfferService {
  final Dio _dio = sl<DioClient>().instance;

  Future<List<BankOffer>> fetchOffers({String type = 'flight'}) async {
    final response = await _dio.get(
      Urls.razorpayBankOffers,
      queryParameters: {'type': type},
      options: Options(headers: {'X-Domain': Urls.siteDomain}),
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

/// The one bank/card offer the traveller has applied (at most one), kept in
/// memory so it follows them from the offers list to the payment page.
///
/// It expires after an hour so a stale choice cannot follow someone into a
/// later booking. Only the offer's id is ever sent to the server, which
/// re-checks that the offer is still valid, so nothing here is trusted.
class BankOfferSelection {
  BankOfferSelection._();

  static const _maxAge = Duration(hours: 1);
  static DateTime? _at;

  /// Listen to this to rebuild when the choice changes.
  static final ValueNotifier<BankOffer?> selected = ValueNotifier<BankOffer?>(null);

  /// The applied offer, or null if none / it has expired.
  static BankOffer? get current {
    final o = selected.value;
    final at = _at;
    if (o == null || at == null) return null;
    if (DateTime.now().difference(at) > _maxAge) return null;
    return o;
  }

  static void select(BankOffer offer) {
    _at = DateTime.now();
    selected.value = offer;
  }

  static void clear() {
    _at = null;
    selected.value = null;
  }
}
