import 'package:dio/dio.dart';

import '../../../../core/constants/urls.dart';
import '../../domain/entity/benefit_entity.dart';

/// Talks to /api/benefits/. Every cap lives on the server, so this layer only
/// parses answers — it never decides how much credit a booking may take.
abstract class BenefitApiService {
  Future<BenefitSummary?> getSummary();

  Future<({bool ok, String message, double amount})> claimMilestone(
    String code, {
    String? deviceId,
  });

  /// Asks how much credit [amount] of [bookingType] can absorb.
  ///
  /// [marginAmount] is what the booking actually earns. Flights can work it
  /// out (GrossFare − NetFare from the pricing response) and should always
  /// send it: without it the server falls back to a deliberately low assumed
  /// margin and the traveller is offered less than they could have had.
  Future<BenefitQuote> quote({
    required String bookingType,
    required double amount,
    double? marginAmount,
  });

  Future<BenefitHold> hold({
    required String bookingType,
    required double amount,
    required double redeemAmount,
    double? marginAmount,
    String bookingRef,
  });

  Future<bool> capture(String holdReference, {String bookingRef});

  Future<bool> release(String holdReference, {String reason});
}

class BenefitApiServiceImpl implements BenefitApiService {
  final Dio dio;

  BenefitApiServiceImpl(this.dio);

  static double _d(dynamic v) =>
      v == null ? 0 : double.tryParse(v.toString()) ?? 0;

  static int _i(dynamic v) =>
      v == null ? 0 : int.tryParse(v.toString()) ?? 0;

  @override
  Future<BenefitSummary?> getSummary() async {
    try {
      final res = await dio.get(Urls.benefitSummary);
      final data = res.data;
      if (data is! Map || data['success'] != true) return null;

      final balance = (data['balance'] as Map?) ?? const {};
      final progress = (data['progress'] as Map?) ?? const {};
      final tierBlock = (data['tier'] as Map?) ?? const {};

      return BenefitSummary(
        enabled: data['enabled'] == true,
        headlineAmount: _d(data['headline_amount']),
        termsUrl: (data['terms_url'] ?? '').toString(),
        benefitBalance: _d(balance['benefit_balance']),
        availableBenefitBalance: _d(balance['available_benefit_balance']),
        walletBalance: _d(balance['wallet_balance']),
        currency: (balance['currency'] ?? 'INR').toString(),
        totalPossible: _d(progress['total_possible']),
        totalEarned: _d(progress['total_earned']),
        milestones: [
          for (final m in (data['milestones'] as List? ?? const []))
            BenefitMilestone(
              code: (m['code'] ?? '').toString(),
              label: (m['label'] ?? '').toString(),
              description: (m['description'] ?? '').toString(),
              amount: _d(m['amount']),
              icon: (m['icon'] ?? '').toString(),
              repeatable: m['repeatable'] == true,
              maxClaims: _i(m['max_claims']),
              claimsMade: _i(m['claims_made']),
              earned: _d(m['earned']),
              completed: m['completed'] == true,
            ),
        ],
        tier: BenefitTierProgress(
          current: (tierBlock['current'] ?? 'bronze').toString(),
          counts: {
            for (final e in ((tierBlock['counts'] as Map?) ?? const {}).entries)
              e.key.toString(): _i(e.value),
          },
          lifetimeSpend: _d(tierBlock['lifetime_spend']),
          totalCashbackEarned: _d(tierBlock['total_cashback_earned']),
          allTiers: [
            for (final t in (tierBlock['all_tiers'] as List? ?? const []))
              _parseTier(t as Map),
          ],
        ),
        referralCode: (data['referral_code'] ?? '').toString(),
      );
    } on DioException catch (e) {
      print('BENEFIT SUMMARY error: ${e.response?.statusCode} ${e.message}');
      return null;
    } catch (e) {
      print('BENEFIT SUMMARY parse error: $e');
      return null;
    }
  }

  static BenefitTier _parseTier(Map t) {
    final requires = (t['requires'] as Map?) ?? const {};
    return BenefitTier(
      tier: (t['tier'] ?? '').toString(),
      label: (t['label'] ?? '').toString(),
      rank: _i(t['rank']),
      colour: (t['colour'] ?? '').toString(),
      perks: [for (final p in (t['perks'] as List? ?? const [])) p.toString()],
      requiredFlights: _i(requires['flight_bookings']),
      requiredHotels: _i(requires['hotel_bookings']),
      requiredHolidays: _i(requires['holiday_bookings']),
      requiredTotal: _i(requires['total_bookings']),
      cashbackPercent: {
        for (final e
            in ((t['cashback_percent'] as Map?) ?? const {}).entries)
          e.key.toString(): _d(e.value),
      },
      cashbackMaxAmount: _d(t['cashback_max_amount']),
      achieved: t['achieved'] == true,
      stillNeeded: {
        for (final e in ((t['still_needed'] as Map?) ?? const {}).entries)
          e.key.toString(): _i(e.value),
      },
    );
  }

  @override
  Future<({bool ok, String message, double amount})> claimMilestone(
    String code, {
    String? deviceId,
  }) async {
    try {
      final res = await dio.post(Urls.benefitClaim, data: {
        'code': code,
        if (deviceId != null && deviceId.isNotEmpty) 'device_id': deviceId,
      });
      final data = (res.data as Map?) ?? const {};
      return (
        ok: data['success'] == true,
        message: (data['message'] ?? '').toString(),
        amount: _d(data['amount']),
      );
    } on DioException catch (e) {
      final data = (e.response?.data as Map?) ?? const {};
      return (
        ok: false,
        message: (data['error'] ?? 'Could not claim this benefit').toString(),
        amount: 0.0,
      );
    }
  }

  @override
  Future<BenefitQuote> quote({
    required String bookingType,
    required double amount,
    double? marginAmount,
  }) async {
    try {
      final res = await dio.post(Urls.benefitQuote, data: {
        'booking_type': bookingType,
        'amount': amount,
        if (marginAmount != null) 'margin_amount': marginAmount,
      });
      final data = (res.data as Map?) ?? const {};
      if (data['success'] != true) {
        return BenefitQuote.unavailable(
          (data['error'] ?? 'Benefits unavailable').toString(),
        );
      }
      return BenefitQuote(
        success: true,
        bookingType: (data['booking_type'] ?? bookingType).toString(),
        bookingAmount: _d(data['booking_amount']),
        maxRedeemable: _d(data['max_redeemable']),
        reason: (data['reason'] ?? '').toString(),
        availableBalance: _d(data['available_benefit_balance']),
      );
    } on DioException catch (e) {
      // A traveller who is not signed in simply sees no benefit row, which is
      // the correct outcome — not an error worth interrupting checkout for.
      final data = (e.response?.data as Map?) ?? const {};
      return BenefitQuote.unavailable(
        (data['error'] ?? 'Benefits unavailable right now').toString(),
      );
    }
  }

  @override
  Future<BenefitHold> hold({
    required String bookingType,
    required double amount,
    required double redeemAmount,
    double? marginAmount,
    String bookingRef = '',
  }) async {
    try {
      final res = await dio.post(Urls.benefitHold, data: {
        'booking_type': bookingType,
        'amount': amount,
        'redeem_amount': redeemAmount,
        if (marginAmount != null) 'margin_amount': marginAmount,
        if (bookingRef.isNotEmpty) 'booking_ref': bookingRef,
      });
      final data = (res.data as Map?) ?? const {};
      if (data['success'] != true) {
        return BenefitHold.failed(
          (data['error'] ?? 'Could not apply benefit').toString(),
        );
      }
      final expiry = data['expires_at']?.toString();
      return BenefitHold(
        success: true,
        holdReference: (data['hold_reference'] ?? '').toString(),
        appliedAmount: _d(data['applied_amount']),
        remainingToPay: _d(data['remaining_to_pay']),
        expiresAt: expiry == null ? null : DateTime.tryParse(expiry),
      );
    } on DioException catch (e) {
      final data = (e.response?.data as Map?) ?? const {};
      return BenefitHold.failed(
        (data['error'] ?? 'Could not apply benefit').toString(),
      );
    }
  }

  @override
  Future<bool> capture(String holdReference, {String bookingRef = ''}) async {
    try {
      final res = await dio.post(Urls.benefitCapture, data: {
        'hold_reference': holdReference,
        if (bookingRef.isNotEmpty) 'booking_ref': bookingRef,
      });
      return (res.data as Map?)?['success'] == true;
    } on DioException catch (e) {
      // The booking is already paid for by this point; a failed capture is a
      // reconciliation problem for the server, not something to fail the
      // traveller's booking over.
      print('BENEFIT CAPTURE failed for $holdReference: ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> release(String holdReference,
      {String reason = 'Payment not completed'}) async {
    try {
      final res = await dio.post(Urls.benefitRelease, data: {
        'hold_reference': holdReference,
        'reason': reason,
      });
      return (res.data as Map?)?['success'] == true;
    } on DioException catch (e) {
      // Worst case the hold's TTL expires on the server and the credit comes
      // back on its own, so this is safe to swallow.
      print('BENEFIT RELEASE failed for $holdReference: ${e.message}');
      return false;
    }
  }
}
