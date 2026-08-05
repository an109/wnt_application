import 'package:equatable/equatable.dart';

// ---------------------------------------------------------------------------
// Request
// ---------------------------------------------------------------------------

class AkSsrRequestEntity extends Equatable {
  // Pricing TUI (GetSPricer's returned TUI).
  final String tui;
  final bool afterPricing;

  // Order IDs of every leg to fetch add-ons for — [1] for a plain one-way,
  // [1, 2] for round trip/multi-city. Without this the backend defaults to
  // just OrderID 1, so a round trip's return leg never gets add-on options.
  final List<int> orderIds;

  const AkSsrRequestEntity({
    required this.tui,
    this.afterPricing = true,
    this.orderIds = const [1],
  });

  @override
  List<Object?> get props => [tui, afterPricing, orderIds];
}

// ---------------------------------------------------------------------------
// Response
// ---------------------------------------------------------------------------

class AkSsrItemEntity extends Equatable {
  final int id;
  final String code;
  final String description;
  final double charge;
  // MEALS | BAGGAGE | SPORTS | SEAT | ...
  final String typeName;
  final bool isFree;

  const AkSsrItemEntity({
    required this.id,
    required this.code,
    required this.description,
    required this.charge,
    required this.typeName,
    required this.isFree,
  });

  @override
  List<Object?> get props => [id, code, description, charge, typeName, isFree];
}

class AkSsrSegmentEntity extends Equatable {
  final int fuid;
  final List<AkSsrItemEntity> items;

  const AkSsrSegmentEntity({required this.fuid, required this.items});

  @override
  List<Object?> get props => [fuid, items];
}

class AkSsrJourneyEntity extends Equatable {
  // True only when the airline allows more than one SSR selection per
  // passenger/segment/type group.
  final bool multiSelectAllowed;
  final List<AkSsrSegmentEntity> segments;

  const AkSsrJourneyEntity({
    required this.multiSelectAllowed,
    required this.segments,
  });

  @override
  List<Object?> get props => [multiSelectAllowed, segments];
}

class AkSsrTripEntity extends Equatable {
  final List<AkSsrJourneyEntity> journey;

  const AkSsrTripEntity({required this.journey});

  @override
  List<Object?> get props => [journey];
}

class AkSsrEntity extends Equatable {
  final bool success;
  final String tui;
  final List<AkSsrTripEntity> trips;

  const AkSsrEntity({
    required this.success,
    required this.tui,
    required this.trips,
  });

  /// True when at least one segment on any journey has SSR options to show.
  bool get hasOptions => trips.any(
        (t) => t.journey.any((j) => j.segments.any((s) => s.items.isNotEmpty)),
      );

  @override
  List<Object?> get props => [success, tui, trips];
}
