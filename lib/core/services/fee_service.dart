import 'package:dio/dio.dart';
import '../constants/urls.dart';

/// Which service a payment-page fee is for. The names match the prefixes the
/// admin "Taxes & Margins" screen stores them under (flights_*, hotels_*,
/// transfers_*).
enum FeeServiceType { flights, hotels, transfers }

/// Convenience + platform + booking-management fee for one payment.
class FeeBreakdown {
  final double convenienceFee;
  final double platformFee;
  final double bookingMgmtFee;

  /// 'admin-slab' | 'master' | 'default' | 'none' — where the numbers came from.
  final String source;

  const FeeBreakdown({
    this.convenienceFee = 0,
    this.platformFee = 0,
    this.bookingMgmtFee = 0,
    this.source = 'none',
  });

  static const zero = FeeBreakdown();

  double get total => convenienceFee + platformFee + bookingMgmtFee;
  bool get isZero => total <= 0;

  /// Body for the backend's `fee_breakdown` field (the keys the website sends).
  Map<String, dynamic> toJson() => {
        'convenience_fee': convenienceFee,
        'platform_fee': platformFee,
        'booking_mgmt_fee': bookingMgmtFee,
      };
}

class _Slab {
  final double min;
  final double? max;
  final double conv;
  final double platform;
  final double bookingMgmt;
  const _Slab(this.min, this.max, this.conv, this.platform, this.bookingMgmt);
}

/// Payment-page fees, driven by the admin dashboard's Taxes & Margins — the
/// same `/api/tax-margin/` data and the same rules the website uses
/// (TaxMarginContext.jsx), so a fare costs the same fees in the app and on the
/// site.
///
/// Priority per service: admin fare-range slabs → admin single values →
/// code-level default slabs. Fees are always charged on the displayed fare,
/// on top of it.
class FeeService {
  FeeService._();
  static final FeeService instance = FeeService._();

  /// The website sends its own hostname; the backend serves the admin master
  /// settings for any domain that is not a reseller's.
  static const _domain = 'thewandernova.com';

  // Same table as DEFAULT_FEE_SLABS in the website; band picked on the INR fare.
  static const _defaultSlabs = <(double, double, double, double)>[
    (3000, 2.50, 2.00, 1.50),
    (15000, 5.00, 0.70, 0.30),
    (30000, 4.00, 1.40, 0.60),
    (50000, 3.00, 2.10, 0.90),
    (70000, 2.50, 2.45, 1.05),
    (100000, 2.00, 2.80, 1.20),
    (double.infinity, 1.50, 3.15, 1.35),
  ];

  Map<String, dynamic> _margin = const {};
  final Map<FeeServiceType, List<_Slab>> _slabs = {
    for (final s in FeeServiceType.values) s: <_Slab>[],
  };
  Future<void>? _loading;
  bool _loaded = false;

  bool get isLoaded => _loaded;

  /// Fetches the admin settings once; later callers share the same request.
  /// Never throws — if the call fails the fees fall back to the defaults, and
  /// the next call tries again.
  Future<void> ensureLoaded() {
    if (_loaded) return Future.value();
    return _loading ??= _fetch().whenComplete(() => _loading = null);
  }

  /// Force a re-read (e.g. before opening a payment page, so an edit the admin
  /// just made is picked up).
  Future<void> refresh() {
    _loaded = false;
    return ensureLoaded();
  }

  /// Loads settings from an already-fetched `/api/tax-margin/` response body.
  /// The network call goes through here too, and tests call it directly.
  void applyResponse(Map<String, dynamic> data) {
    final margin = data['tax_margin'];
    if (margin is Map) _margin = Map<String, dynamic>.from(margin);
    _slabs
      ..clear()
      ..addAll(_parseSlabs(data['fee_slabs']));
    _loaded = true;
  }

  /// Forget everything loaded (tests).
  void reset() {
    _margin = const {};
    _slabs.updateAll((_, __) => <_Slab>[]);
    _loaded = false;
    _loading = null;
  }

  Future<void> _fetch() async {
    try {
      final res = await Dio().get(
        Urls.taxMargin,
        queryParameters: {'domain': _domain},
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );
      final data = res.data;
      if (res.statusCode == 200 && data is Map) {
        applyResponse(Map<String, dynamic>.from(data));
      }
    } catch (_) {
      // Keep whatever was loaded before (or the defaults).
    }
  }

  static Map<FeeServiceType, List<_Slab>> _parseSlabs(dynamic rows) {
    final out = {for (final s in FeeServiceType.values) s: <_Slab>[]};
    if (rows is! List) return out;
    for (final r in rows) {
      if (r is! Map) continue;
      final match = FeeServiceType.values.where((s) => s.name == r['service']);
      if (match.isEmpty) continue;
      final service = match.first;
      final rawMax = r['max_amount'];
      final max = (rawMax == null || '$rawMax'.isEmpty)
          ? null
          : double.tryParse('$rawMax');
      out[service]!.add(_Slab(
        double.tryParse('${r['min_amount']}') ?? 0,
        max,
        double.tryParse('${r['convenience_percent']}') ?? 0,
        double.tryParse('${r['platform_percent']}') ?? 0,
        double.tryParse('${r['booking_mgmt_percent']}') ?? 0,
      ));
    }
    for (final list in out.values) {
      list.sort((a, b) => a.min.compareTo(b.min));
    }
    return out;
  }

  double _num(String key) => double.tryParse('${_margin[key]}') ?? 0;

  /// Fees for [service] on [fare] (INR). [round] is whole rupees for flights
  /// and hotels, paise for transfers — same as the website.
  FeeBreakdown feeFor(FeeServiceType service, double fare) {
    if (fare <= 0) return FeeBreakdown.zero;
    final cents = service == FeeServiceType.transfers;
    double round(double v) => cents ? (v * 100).roundToDouble() / 100 : v.roundToDouble();

    FeeBreakdown fromPercents(double conv, double platform, double mgmt, String source) {
      return FeeBreakdown(
        convenienceFee: round(fare * conv / 100),
        platformFee: round(fare * platform / 100),
        bookingMgmtFee: round(fare * mgmt / 100),
        source: source,
      );
    }

    // 1. Admin fare-range slabs.
    final slabs = _slabs[service] ?? const <_Slab>[];
    if (slabs.isNotEmpty) {
      final slab = slabs.cast<_Slab?>().firstWhere(
                (s) => fare >= s!.min && (s.max == null || fare < s.max!),
                orElse: () => null,
              ) ??
          slabs.reversed.cast<_Slab?>().firstWhere(
                (s) => fare >= s!.min,
                orElse: () => null,
              ) ??
          slabs.first;
      return fromPercents(slab.conv, slab.platform, slab.bookingMgmt, 'admin-slab');
    }

    // 2. Admin single values (percent of fare, or a flat amount).
    final p = service.name;
    double single(String kind) {
      final v = _num('${p}_${kind}_value');
      if (v <= 0) return 0;
      return '${_margin['${p}_${kind}_type']}' == 'flat' ? round(v) : round(fare * v / 100);
    }

    final hasMaster = _num('${p}_convenience_value') > 0 ||
        _num('${p}_platform_value') > 0 ||
        _num('${p}_booking_mgmt_value') > 0;
    if (hasMaster) {
      return FeeBreakdown(
        convenienceFee: single('convenience'),
        platformFee: single('platform'),
        bookingMgmtFee: single('booking_mgmt'),
        source: 'master',
      );
    }

    // 3. Code-level defaults.
    final d = _defaultSlabs.firstWhere((s) => fare < s.$1, orElse: () => _defaultSlabs.last);
    return fromPercents(d.$2, d.$3, d.$4, 'default');
  }
}
