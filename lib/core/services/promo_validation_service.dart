import 'package:dio/dio.dart';
import '../constants/urls.dart';
import '../../views/MainApi/domain/entities/general_setting_entity.dart';

/// Which part of the app a promo code is being applied in. The values are the
/// `category` names the admin dashboard tags promo codes with.
enum PromoScope {
  flights('flight_booking'),
  hotels('hotel_booking'),
  transport('transport_booking');

  final String category;
  const PromoScope(this.category);
}

class PromoValidationResult {
  /// Set when the backend accepted the code.
  final PromoCodeEntity? promo;

  /// Why the code was refused (shown to the customer as is).
  final String? error;

  /// True when the backend could not be reached — nothing was decided.
  final bool unreachable;

  const PromoValidationResult.accepted(PromoCodeEntity this.promo)
      : error = null,
        unreachable = false;
  const PromoValidationResult.rejected(String this.error)
      : promo = null,
        unreachable = false;
  const PromoValidationResult.unreachable()
      : promo = null,
        error = null,
        unreachable = true;

  bool get isAccepted => promo != null;
}

/// Asks the backend to validate a promo code typed in by hand — the same
/// `/api/promo-codes/validate/` call the website uses. The server checks that
/// the code exists and is active, is inside its dates, matches the booking
/// type, and that [amountInInr] meets the admin's minimum purchase. This also
/// covers hidden codes that never appear in the public offers list.
class PromoValidationService {
  PromoValidationService._();

  static const _domain = 'thewandernova.com';

  static Future<PromoValidationResult> validate({
    required String code,
    required PromoScope scope,
    required double amountInInr,
  }) async {
    try {
      final res = await Dio().post(
        '${Urls.baseUrl}promo-codes/validate/',
        queryParameters: {'domain': _domain},
        data: {
          'code': code.trim().toUpperCase(),
          'category': scope.category,
          'amount': amountInInr,
        },
        options: Options(
          validateStatus: (s) => s != null && s < 500,
          receiveTimeout: const Duration(seconds: 12),
          sendTimeout: const Duration(seconds: 12),
        ),
      );
      final data = res.data;
      if (data is Map && data['success'] == true && data['promo'] is Map) {
        final p = Map<String, dynamic>.from(data['promo'] as Map);
        final rawMin = p['min_purchase']?.toString().replaceAll(',', '');
        return PromoValidationResult.accepted(PromoCodeEntity(
          code: '${p['code'] ?? code}',
          category: '${p['category'] ?? scope.category}',
          discountType: '${p['discount_type'] ?? ''}',
          discountValue: '${p['discount_value'] ?? 0}',
          description: '${p['description'] ?? ''}',
          minPurchase: double.tryParse(rawMin ?? '') ?? 0,
        ));
      }
      final message = data is Map ? data['error']?.toString() : null;
      return PromoValidationResult.rejected(
        (message == null || message.isEmpty) ? 'Invalid promo code' : message,
      );
    } on DioException {
      return const PromoValidationResult.unreachable();
    } catch (_) {
      return const PromoValidationResult.unreachable();
    }
  }
}
