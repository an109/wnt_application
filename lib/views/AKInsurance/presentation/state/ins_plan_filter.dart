import 'package:flutter/foundation.dart';

import '../../domain/entity/AKInsurance_entity.dart';

/// How the plan list is ordered. The labels are the ones the sort sheet and
/// the filter sheet show.
enum InsSortBy {
  popularity('Popularity'),
  premiumLowToHigh('Premium (Low to High)'),
  premiumHighToLow('Premium (High to Low)'),
  coverageHighToLow('Coverage (High to Low)');

  const InsSortBy(this.label);

  final String label;
}

/// One selectable coverage band, with how many live plans fall in it.
///
/// Bands are derived from the plans the provider actually returned — never
/// a fixed ladder — so a destination that only has USD 50k/100k cover shows
/// exactly those two rows.
@immutable
class InsCoverageBand {
  final double from;
  final double to;
  final String currency;
  final int count;

  const InsCoverageBand({
    required this.from,
    required this.to,
    required this.currency,
    required this.count,
  });

  bool contains(double value) => value >= from && value <= to;

  String get label {
    String fmt(double v) {
      if (v >= 1000000) {
        final m = v / 1000000;
        return '${m == m.roundToDouble() ? m.round() : m.toStringAsFixed(1)}M';
      }
      if (v >= 1000) {
        final k = v / 1000;
        return '${k == k.roundToDouble() ? k.round() : k.toStringAsFixed(1)}K';
      }
      return v.round().toString();
    }

    if (from == to) return '$currency ${fmt(to)}';
    return '$currency ${fmt(from)} - ${fmt(to)}';
  }
}

/// The supplier rows on the filter sheet, with live counts.
@immutable
class InsSupplierOption {
  final String name;
  final int count;

  const InsSupplierOption({required this.name, required this.count});
}

/// Everything the Sort and Filter sheets can change about the plan list.
@immutable
class InsPlanFilter {
  final InsSortBy sortBy;

  /// Supplier names to keep. Empty means "no supplier filter".
  final Set<String> suppliers;

  /// Coverage values to keep, as the `from` edge of a chosen band.
  final Set<double> coverageFloors;

  const InsPlanFilter({
    this.sortBy = InsSortBy.popularity,
    this.suppliers = const {},
    this.coverageFloors = const {},
  });

  InsPlanFilter copyWith({
    InsSortBy? sortBy,
    Set<String>? suppliers,
    Set<double>? coverageFloors,
  }) {
    return InsPlanFilter(
      sortBy: sortBy ?? this.sortBy,
      suppliers: suppliers ?? this.suppliers,
      coverageFloors: coverageFloors ?? this.coverageFloors,
    );
  }

  bool get isActive =>
      suppliers.isNotEmpty ||
      coverageFloors.isNotEmpty ||
      sortBy != InsSortBy.popularity;

  /// How many filter groups are in play — drives the badge on the Filter
  /// button.
  int get activeCount =>
      (suppliers.isEmpty ? 0 : 1) + (coverageFloors.isEmpty ? 0 : 1);

  // ------------------------------------------------------------- derive

  /// The supplier rows for [plans], with counts, alphabetical.
  static List<InsSupplierOption> suppliersOf(
    List<AkInsurancePlanEntity> plans,
  ) {
    final counts = <String, int>{};
    for (final p in plans) {
      final name = p.provider.trim().isEmpty ? 'Other' : p.provider.trim();
      counts[name] = (counts[name] ?? 0) + 1;
    }
    final rows = [
      for (final e in counts.entries)
        InsSupplierOption(name: e.key, count: e.value),
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return rows;
  }

  /// The coverage rows for [plans]: one row per distinct sum insured the
  /// provider quoted, smallest first.
  static List<InsCoverageBand> coverageBandsOf(
    List<AkInsurancePlanEntity> plans,
  ) {
    final counts = <double, int>{};
    var currency = 'USD';
    for (final p in plans) {
      if (p.sumInsured <= 0) continue;
      counts[p.sumInsured] = (counts[p.sumInsured] ?? 0) + 1;
      if (p.currency.isNotEmpty) currency = p.currency;
    }
    final values = counts.keys.toList()..sort();
    return [
      for (final v in values)
        InsCoverageBand(
          from: v,
          to: v,
          currency: currency,
          count: counts[v]!,
        ),
    ];
  }

  // -------------------------------------------------------------- apply

  /// Filters then sorts. The provider's own ordering is treated as its
  /// popularity ranking, so [InsSortBy.popularity] leaves the list alone.
  List<AkInsurancePlanEntity> apply(List<AkInsurancePlanEntity> plans) {
    var out = plans.where((p) {
      final name = p.provider.trim().isEmpty ? 'Other' : p.provider.trim();
      if (suppliers.isNotEmpty && !suppliers.contains(name)) return false;
      if (coverageFloors.isNotEmpty && !coverageFloors.contains(p.sumInsured)) {
        return false;
      }
      return true;
    }).toList();

    switch (sortBy) {
      case InsSortBy.popularity:
        break;
      case InsSortBy.premiumLowToHigh:
        out.sort((a, b) => a.premium.compareTo(b.premium));
      case InsSortBy.premiumHighToLow:
        out.sort((a, b) => b.premium.compareTo(a.premium));
      case InsSortBy.coverageHighToLow:
        out.sort((a, b) => b.sumInsured.compareTo(a.sumInsured));
    }
    return out;
  }
}
