import 'entities/FlightBookEntity.dart';

// Display facts for one flight booking, derived from its `tbo_segments`
// (falling back to the plain booking fields for bookings without them).
// Shared by the Trip list card, Trip Details and the Ticket screen.

enum FlightTripState { upcoming, past, cancelled }

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

DateTime? parseTripDate(String? s) => (s == null || s.trim().isEmpty) ? null : DateTime.tryParse(s.trim());

/// "11 Dec 2026"
String tripDate(DateTime? d) => d == null ? '' : '${d.day} ${_months[d.month - 1]} ${d.year}';

/// "25 Aug, Tue"
String tripDayLabel(DateTime? d) => d == null ? '' : '${d.day} ${_months[d.month - 1]}, ${_weekdays[d.weekday - 1]}';

/// "10:30"
String tripTime(DateTime? d) =>
    d == null ? '' : '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// "10 Dec 2026, 14:25"
String tripDateTime(DateTime? d) => d == null ? '' : '${tripDate(d)}, ${tripTime(d)}';

String titleCase(String s) => s
    .replaceAll('_', ' ')
    .split(' ')
    .where((w) => w.isNotEmpty)
    .map((w) => '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
    .join(' ');

String plural(int n, String word) {
  if (n == 1) return '$n $word';
  return '$n ${word == 'Child' ? 'Children' : '${word}s'}';
}

bool _beforeToday(DateTime? d) {
  if (d == null) return false;
  final now = DateTime.now();
  return DateTime(d.year, d.month, d.day).isBefore(DateTime(now.year, now.month, now.day));
}

String _str(Map<String, dynamic> m, String key) => (m[key] ?? '').toString().trim();

/// "HH:MM:SS" / "HH:MM" → Duration.
Duration? _legDuration(String raw) {
  final parts = raw.split(':').map(int.tryParse).toList();
  if (parts.length < 2 || parts.any((p) => p == null)) return null;
  return Duration(hours: parts[0]!, minutes: parts[1]!);
}

String _durationLabel(Duration d) {
  final h = d.inHours, m = d.inMinutes % 60;
  if (h == 0) return '${m}m';
  return m == 0 ? '${h}h' : '${h}h ${m}m';
}

/// "15 KG" / "15 Kilograms" → "15 kg"; anything else as-is.
String _weight(String raw) {
  final m = RegExp(r'(\d+(?:\.\d+)?)\s*(kg|kilo)', caseSensitive: false).firstMatch(raw);
  return m != null ? '${m.group(1)} kg' : raw;
}

/// "Kochi (COK)" → COK; "COK" → COK; otherwise the place itself.
String _codeOf(String place) {
  final m = RegExp(r'\(([A-Z]{3})\)').firstMatch(place);
  return m != null ? m.group(1)! : place.trim();
}

String _placeOf(String place) => place.replaceAll(RegExp(r'\s*\([A-Z]{3}\)'), '').trim();

class FlightTripInfo {
  final FlightBookEntity booking;

  /// Onward legs (for a round trip: everything before the turnaround).
  final List<Map<String, dynamic>> legs;

  FlightTripInfo._(this.booking, this.legs);

  factory FlightTripInfo(FlightBookEntity b) => FlightTripInfo._(b, _onwardLegs(b.tboSegments));

  static List<Map<String, dynamic>> _onwardLegs(List<Map<String, dynamic>> segs) {
    if (segs.length < 2) return segs;
    if (_str(segs.last, 'toCode') != _str(segs.first, 'fromCode')) return segs;
    var split = segs.length - 1;
    var longest = Duration.zero;
    for (var i = 0; i < segs.length - 1; i++) {
      final arr = parseTripDate(_str(segs[i], 'arrivalTime'));
      final dep = parseTripDate(_str(segs[i + 1], 'departureTime'));
      if (arr == null || dep == null) continue;
      final gap = dep.difference(arr);
      if (gap > longest) {
        longest = gap;
        split = i;
      }
    }
    return segs.sublist(0, split + 1);
  }

  Map<String, dynamic> get _first => legs.isNotEmpty ? legs.first : const {};
  Map<String, dynamic> get _last => legs.isNotEmpty ? legs.last : const {};

  bool get hasSegments => legs.isNotEmpty;

  String get airline => _str(_first, 'airline').isNotEmpty ? _str(_first, 'airline') : 'Flight';
  String get airlineCode => _str(_first, 'airlineCode');

  /// "6E 1461"
  String get flightNumber {
    final number = _str(_first, 'flightNumber');
    if (number.isEmpty) return booking.flightNumber;
    if (airlineCode.isEmpty || number.toUpperCase().startsWith(airlineCode.toUpperCase())) return number;
    return '$airlineCode $number';
  }

  String get fromCode => _str(_first, 'fromCode').isNotEmpty ? _str(_first, 'fromCode') : _codeOf(booking.fromCity);
  String get fromCity => _str(_first, 'fromCity').isNotEmpty ? _str(_first, 'fromCity') : _placeOf(booking.fromCity);
  String get toCode => _str(_last, 'toCode').isNotEmpty ? _str(_last, 'toCode') : _codeOf(booking.toCity);
  String get toCity => _str(_last, 'toCity').isNotEmpty ? _str(_last, 'toCity') : _placeOf(booking.toCity);

  /// Arrival terminal of the last onward leg (the only terminal TBO gives).
  String get arrivalTerminal => _str(_last, 'terminal');

  DateTime? get departure => parseTripDate(_str(_first, 'departureTime')) ?? parseTripDate(booking.departureDate);
  DateTime? get arrival => parseTripDate(_str(_last, 'arrivalTime'));

  /// When the whole trip (incl. any return) is over.
  DateTime? get tripEnd =>
      parseTripDate(booking.returnDate) ??
      (booking.tboSegments.isNotEmpty ? parseTripDate(_str(booking.tboSegments.last, 'arrivalTime')) : null) ??
      arrival ??
      departure;

  FlightTripState get state => booking.isCancelled
      ? FlightTripState.cancelled
      : (_beforeToday(tripEnd) ? FlightTripState.past : FlightTripState.upcoming);

  bool get isConfirmed => booking.pnr.isNotEmpty && booking.pnr != 'null';

  int? get stops => legs.isEmpty ? null : legs.length - 1;

  String? get stopsLabel => stops == null ? null : (stops == 0 ? 'Non Stop' : plural(stops!, 'Stop'));

  /// Flying time plus layovers, when every leg has a duration.
  Duration? get totalDuration {
    if (legs.isEmpty) return null;
    var total = Duration.zero;
    for (var i = 0; i < legs.length; i++) {
      final d = _legDuration(_str(legs[i], 'duration'));
      if (d == null) return null;
      total += d;
      if (i < legs.length - 1) {
        final a = parseTripDate(_str(legs[i], 'arrivalTime'));
        final n = parseTripDate(_str(legs[i + 1], 'departureTime'));
        if (a != null && n != null) total += n.difference(a);
      }
    }
    return total;
  }

  String? get durationLabel => totalDuration == null ? null : _durationLabel(totalDuration!);

  /// "2h 20m (Non Stop)", or the trip type when nothing else is known.
  String get routeSummary {
    final parts = [
      if (durationLabel != null) durationLabel!,
      if (stopsLabel != null) durationLabel != null ? '($stopsLabel)' : stopsLabel!,
    ];
    return parts.isNotEmpty ? parts.join(' ') : titleCase(booking.flightType);
  }

  /// Web check-in window: within 48h of departure on a ticketed booking.
  bool get checkInOpen {
    final until = departure?.difference(DateTime.now());
    return state == FlightTripState.upcoming &&
        isConfirmed &&
        until != null &&
        !until.isNegative &&
        until <= const Duration(hours: 48);
  }

  String get cabinClass => booking.flightClass.isEmpty ? '' : titleCase(booking.flightClass);

  bool get isRoundTrip => booking.flightType.toLowerCase().contains('round');

  /// Check-in allowance per person ("20 kg"), from the first leg.
  String get checkInBaggage => _weight(_str(_first, 'baggage'));

  String get cabinBaggage => _weight(_str(_first, 'cabinBaggage'));

  int get adults => booking.passengersData.where((p) => p.paxType == 1).length;

  /// "2 Adults, 1 Child"
  String get paxLabel {
    final pax = booking.passengersData;
    if (pax.isEmpty) return plural(booking.passengers, 'Traveller');
    final children = pax.where((p) => p.paxType == 2).length;
    final infants = pax.where((p) => p.paxType == 3).length;
    return [
      if (adults > 0) plural(adults, 'Adult'),
      if (children > 0) plural(children, 'Child'),
      if (infants > 0) plural(infants, 'Infant'),
    ].join(', ');
  }

  String get paxCount {
    final n = booking.passengersData.isNotEmpty ? booking.passengersData.length : booking.passengers;
    return n > 0 ? plural(n, 'Traveller') : '';
  }
}
