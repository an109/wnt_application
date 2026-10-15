import 'package:equatable/equatable.dart';

// ---------------------------------------------------------------------------
// Request
// ---------------------------------------------------------------------------

class AkFareFamilyDetailsTripRequestEntity extends Equatable {
  final String index;
  final double amount;
  final int orderId;

  const AkFareFamilyDetailsTripRequestEntity({
    required this.index,
    required this.amount,
    required this.orderId,
  });

  @override
  List<Object?> get props => [index, amount, orderId];
}

class AkFareFamilyDetailsRequestEntity extends Equatable {
  final String tui;
  final List<AkFareFamilyDetailsTripRequestEntity> trips;
  final List<String> tuis;
  final String tripType;

  const AkFareFamilyDetailsRequestEntity({
    required this.tui,
    required this.trips,
    this.tuis = const [],
    this.tripType = 'ON',
  });

  @override
  List<Object?> get props => [tui, trips, tuis, tripType];
}

// ---------------------------------------------------------------------------
// Response
// ---------------------------------------------------------------------------

/// One fare family option returned by the FareFamilyDetails endpoint.
/// [index] matches the result-index from the search API. [label] is the
/// human-readable family name (e.g. "SAVER", "FLEXI") as returned by Akbar;
/// falls back to null when the API does not include one, so the UI can fall
/// back to its rank-based labels.
/// [checkin] and [cabin] are baggage allowances from the FareFamilyDetails
/// endpoint (e.g. "15 Kg", "7 Kg"). [fareRule] is the raw fare-rule payload.
class AkFareFamilyOptionEntity extends Equatable {
  final String index;
  final String? label;
  final double amount;
  final bool refundable;
  final String? checkin;
  final String? cabin;
  final dynamic fareRule;

  const AkFareFamilyOptionEntity({
    required this.index,
    this.label,
    required this.amount,
    required this.refundable,
    this.checkin,
    this.cabin,
    this.fareRule,
  });

  AkFareFamilyOptionEntity copyWithBaggage({
    String? checkin,
    String? cabin,
    dynamic fareRule,
  }) => AkFareFamilyOptionEntity(
        index: index,
        label: label,
        amount: amount,
        refundable: refundable,
        checkin: checkin ?? this.checkin,
        cabin: cabin ?? this.cabin,
        fareRule: fareRule ?? this.fareRule,
      );

  @override
  List<Object?> get props => [index, label, amount, refundable, checkin, cabin];
}

class AkFareFamilyDetailsEntity extends Equatable {
  final bool success;
  /// Fare options keyed by result-index string.
  final Map<String, AkFareFamilyOptionEntity> options;
  final Map<String, dynamic> raw;

  const AkFareFamilyDetailsEntity({
    required this.success,
    required this.options,
    required this.raw,
  });

  @override
  List<Object?> get props => [success, options, raw];
}
