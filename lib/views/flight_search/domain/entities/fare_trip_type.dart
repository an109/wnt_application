import 'flight_entity.dart';

/// The five fare types the Akbar search/pricing chain accepts, as a single
/// source of truth for the wire string ('ON'/'RT'/'RS'/'DM'/'IM') and the
/// leg-count semantics each implies.
enum FareTripType {
  oneWay,
  roundTrip,
  specialReturn,
  domesticMulticity,
  internationalMulticity,
}

extension FareTripTypeWire on FareTripType {
  String get wireValue {
    switch (this) {
      case FareTripType.oneWay:
        return 'ON';
      case FareTripType.roundTrip:
        return 'RT';
      case FareTripType.specialReturn:
        return 'RS';
      case FareTripType.domesticMulticity:
        return 'DM';
      case FareTripType.internationalMulticity:
        return 'IM';
    }
  }

  /// RT/RS: exactly one outbound leg + one return leg back to the origin.
  bool get hasReturnLeg =>
      this == FareTripType.roundTrip || this == FareTripType.specialReturn;

  /// IM/DM: an arbitrary chain of N independent legs (no return-to-origin).
  bool get isMulticity =>
      this == FareTripType.domesticMulticity ||
      this == FareTripType.internationalMulticity;

  /// True for anything that needs the N-leg selector/pricing/booking flow
  /// instead of the plain one-way flat-list flow.
  bool get isMultiLeg => hasReturnLeg || isMulticity;

  static FareTripType fromWireValue(String value) {
    switch (value) {
      case 'RT':
        return FareTripType.roundTrip;
      case 'RS':
        return FareTripType.specialReturn;
      case 'DM':
        return FareTripType.domesticMulticity;
      case 'IM':
        return FareTripType.internationalMulticity;
      case 'ON':
      default:
        return FareTripType.oneWay;
    }
  }
}

/// One leg of a multicity search, as entered in search_card.dart's leg
/// editor — carried through to [FlightSearchScreen] since (unlike RT/RS'
/// single implicit return leg) multicity legs each have their own
/// from/to/date that the results screen needs to label and validate against.
class MultiCityLegSummary {
  final String from;
  final String to;
  final String fromCode;
  final String toCode;
  final DateTime date;

  const MultiCityLegSummary({
    required this.from,
    required this.to,
    required this.fromCode,
    required this.toCode,
    required this.date,
  });
}

/// A single leg's chosen flight, captured by the results screen's N-leg
/// selector once the user taps a card for that leg — threaded into
/// FlightDetailsPopup so the FlightInfo/SmartPricer/FareRule chain can send
/// every leg (not just the first) as its own `trips[]` entry with the right
/// `orderId`.
class FlightLegSelection {
  final int orderId;
  final String resultIndex;
  final double amount;
  final FlightEntity flight;

  const FlightLegSelection({
    required this.orderId,
    required this.resultIndex,
    required this.amount,
    required this.flight,
  });
}
