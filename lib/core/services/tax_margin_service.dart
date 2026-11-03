import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:wander_nova/core/constants/urls.dart';

/// A single fee slab from the admin's fare-range configuration.
class TaxMarginSlab {
  final String service;
  final double minAmount;
  final double maxAmount;
  final double conveniencePercent;
  final double platformPercent;
  final double bookingMgmtPercent;

  const TaxMarginSlab({
    required this.service,
    required this.minAmount,
    required this.maxAmount,
    required this.conveniencePercent,
    required this.platformPercent,
    required this.bookingMgmtPercent,
  });

  factory TaxMarginSlab.fromJson(Map<String, dynamic> json) => TaxMarginSlab(
        service: json['service']?.toString() ?? '',
        minAmount: double.tryParse(json['min_amount']?.toString() ?? '') ?? 0,
        maxAmount: double.tryParse(json['max_amount']?.toString() ?? '') ?? double.infinity,
        conveniencePercent: double.tryParse(json['convenience_percent']?.toString() ?? '') ?? 0,
        platformPercent: double.tryParse(json['platform_percent']?.toString() ?? '') ?? 0,
        bookingMgmtPercent: double.tryParse(json['booking_mgmt_percent']?.toString() ?? '') ?? 0,
      );

  bool coversAmount(double amount) => amount >= minAmount && amount <= maxAmount;
}

/// Per-service fee configuration from /api/tax-margin/.
class TaxMarginFees {
  final String convenienceType; // 'percent' or 'flat'
  final double convenienceValue;
  final String bookingMgmtType;
  final double bookingMgmtValue;
  final String platformType;
  final double platformValue;
  final List<TaxMarginSlab> slabs;

  const TaxMarginFees({
    this.convenienceType = 'percent',
    this.convenienceValue = 0,
    this.bookingMgmtType = 'percent',
    this.bookingMgmtValue = 0,
    this.platformType = 'percent',
    this.platformValue = 0,
    this.slabs = const [],
  });

  static const empty = TaxMarginFees();

  /// Compute the three fees for a given fare amount.
  /// Slabs (when present for this service) take priority over flat/percent values.
  TaxMarginBreakdown compute(double fareAmount) {
    final slab = slabs
        .where((s) => s.service == 'flights' && s.coversAmount(fareAmount))
        .firstOrNull;

    if (slab != null) {
      return TaxMarginBreakdown(
        convenienceFee: fareAmount * slab.conveniencePercent / 100,
        platformFee: fareAmount * slab.platformPercent / 100,
        bookingMgmtFee: fareAmount * slab.bookingMgmtPercent / 100,
      );
    }

    return TaxMarginBreakdown(
      convenienceFee: _applyFee(fareAmount, convenienceType, convenienceValue),
      platformFee: _applyFee(fareAmount, platformType, platformValue),
      bookingMgmtFee: _applyFee(fareAmount, bookingMgmtType, bookingMgmtValue),
    );
  }

  static double _applyFee(double amount, String type, double value) {
    if (value <= 0) return 0;
    return type == 'percent' ? amount * value / 100 : value;
  }
}

/// The computed fee amounts for a booking.
class TaxMarginBreakdown {
  final double convenienceFee;
  final double platformFee;
  final double bookingMgmtFee;

  const TaxMarginBreakdown({
    this.convenienceFee = 0,
    this.platformFee = 0,
    this.bookingMgmtFee = 0,
  });

  double get total => convenienceFee + platformFee + bookingMgmtFee;

  bool get hasAnyFee => total > 0;
}

/// Fetches and caches the public tax-margin settings.
class TaxMarginService {
  TaxMarginFees? _cached;

  Future<TaxMarginFees> fetchFlightFees() async {
    if (_cached != null) return _cached!;
    try {
      final res = await Dio().get('${Urls.taxMargin}?domain=localhost');
      if (res.statusCode == 200 && res.data is Map) {
        final margin = res.data['tax_margin'];
        if (margin is Map) {
          final slabs = <TaxMarginSlab>[];
          final rawSlabs = margin['fee_slabs'];
          if (rawSlabs is List) {
            for (final s in rawSlabs) {
              if (s is Map<String, dynamic>) slabs.add(TaxMarginSlab.fromJson(s));
            }
          }
          _cached = TaxMarginFees(
            convenienceType: margin['flights_convenience_type']?.toString() ?? 'percent',
            convenienceValue: double.tryParse(margin['flights_convenience_value']?.toString() ?? '') ?? 0,
            bookingMgmtType: margin['flights_booking_mgmt_type']?.toString() ?? 'percent',
            bookingMgmtValue: double.tryParse(margin['flights_booking_mgmt_value']?.toString() ?? '') ?? 0,
            platformType: margin['flights_platform_type']?.toString() ?? 'percent',
            platformValue: double.tryParse(margin['flights_platform_value']?.toString() ?? '') ?? 0,
            slabs: slabs,
          );
          return _cached!;
        }
      }
    } catch (e) {
      debugPrint('[TaxMargin] fetch error: $e');
    }
    return TaxMarginFees.empty;
  }

  void clearCache() => _cached = null;
}
