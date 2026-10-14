import 'package:intl/intl.dart';

import '../../../../UI_helper/currency_converter.dart';
import '../../../Visa_popularDestinaton/domain/entities/visa_destination_entity.dart';
import 'visa_countries.dart';

/// Visa categories of the "Type" filter.
enum VisaKind { visaFree, onArrival, eVisa, sticker }

extension VisaKindLabel on VisaKind {
  String get label => switch (this) {
        VisaKind.visaFree => 'Visa Free',
        VisaKind.onArrival => 'Visa on Arrival',
        VisaKind.eVisa => 'e-Visa',
        VisaKind.sticker => 'Sticker Visa',
      };

  /// Short upper-case form for the destination cards.
  String get badge => switch (this) {
        VisaKind.visaFree => 'VISA FREE',
        VisaKind.onArrival => 'ON ARRIVAL',
        VisaKind.eVisa => 'E-VISA',
        VisaKind.sticker => 'STICKER',
      };
}

/// Buckets of the "Visa delivery" filter.
enum VisaDelivery { instant, within24h, days3to5, days5to7, days8to30 }

extension VisaDeliveryLabel on VisaDelivery {
  String get label => switch (this) {
        VisaDelivery.instant => 'Instant',
        VisaDelivery.within24h => 'Within 24 Hours',
        VisaDelivery.days3to5 => '3-5 Days',
        VisaDelivery.days5to7 => '5-7 Days',
        VisaDelivery.days8to30 => '8-30 Days',
      };

  bool matches(Duration d) {
    final h = d.inMinutes / 60;
    return switch (this) {
      VisaDelivery.instant => h <= 6,
      VisaDelivery.within24h => h > 6 && h <= 24,
      VisaDelivery.days3to5 => h > 24 && h <= 5 * 24,
      VisaDelivery.days5to7 => h > 5 * 24 && h <= 7 * 24,
      VisaDelivery.days8to30 => h > 7 * 24 && h <= 30 * 24,
    };
  }
}

/// Document levels of the "Document" filter.
enum VisaDocs { onlyPassport, bankStatements, incomeTax, otherVisa }

extension VisaDocsLabel on VisaDocs {
  String get label => switch (this) {
        VisaDocs.onlyPassport => 'Only Passport',
        VisaDocs.bankStatements => 'Passport & Bank Statements',
        VisaDocs.incomeTax => 'Passport, Bank Statements & Income Tax Return',
        VisaDocs.otherVisa => 'With US/UK/Schengen visa',
      };
}

/// Processing time parsed from free text such as "48-96 Hours",
/// "Upto 5 Working Days" or "6 Weeks- 10 Weeks". Uses the upper bound.
class VisaProcessing {
  final Duration duration;
  final bool workingDays;
  const VisaProcessing(this.duration, {this.workingDays = false});

  static final _part = RegExp(
    r'(\d+)\s*(?:-\s*(\d+))?\s*(minute|min|hour|hr|working day|business day|day|week|month)',
  );

  static VisaProcessing? parse(String raw) {
    final text = raw.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    if (text.contains('instant')) return const VisaProcessing(Duration.zero);
    Duration? max;
    for (final m in _part.allMatches(text)) {
      final n = int.parse(m.group(2) ?? m.group(1)!);
      final unit = m.group(3)!;
      final d = switch (unit) {
        'minute' || 'min' => Duration(minutes: n),
        'hour' || 'hr' => Duration(hours: n),
        'week' => Duration(days: n * 7),
        'month' => Duration(days: n * 30),
        _ => Duration(days: n),
      };
      if (max == null || d > max) max = d;
    }
    if (max == null) return null;
    return VisaProcessing(
      max,
      workingDays: text.contains('working') || text.contains('business'),
    );
  }

  /// When the visa is guaranteed if applied at [from]; working days skip
  /// weekends.
  DateTime guaranteedFrom(DateTime from) {
    if (!workingDays || duration.inDays == 0) return from.add(duration);
    var date = from;
    var left = duration.inDays;
    while (left > 0) {
      date = date.add(const Duration(days: 1));
      if (date.weekday != DateTime.saturday && date.weekday != DateTime.sunday) left--;
    }
    return date;
  }

  /// "1 day", "10 days", "6 hours" — for "guaranteed in …" copy.
  String get humanized {
    if (duration.inHours < 1) return '${duration.inMinutes} minutes';
    if (duration.inHours < 24) {
      return duration.inHours == 1 ? '1 hour' : '${duration.inHours} hours';
    }
    final days = (duration.inHours / 24).ceil();
    return days == 1 ? '1 day' : '$days days';
  }
}

extension VisaTypeRules on VisaTypeEntity {
  /// Category stated by the admin or the visa title, or null when the title
  /// does not say (then the destination decides, see [VisaDestinationRules.kindOf]).
  VisaKind? get statedKind {
    switch (category.toLowerCase()) {
      case 'visa_free':
        return VisaKind.visaFree;
      case 'on_arrival':
        return VisaKind.onArrival;
      case 'e_visa':
        return VisaKind.eVisa;
      case 'sticker':
        return VisaKind.sticker;
    }
    final t = title.toLowerCase();
    final compact = t.replaceAll(RegExp(r'[\s\-–]'), '');
    if (feesInr == 0 || t.contains('visa free') || t.contains('free visa')) {
      return VisaKind.visaFree;
    }
    if (t.contains('arrival') || compact.contains('voa')) return VisaKind.onArrival;
    if (compact.contains('evisa') ||
        RegExp(r'\beta\b').hasMatch(t) ||
        t.contains('electronic')) {
      return VisaKind.eVisa;
    }
    if (t.contains('sticker') || t.contains('embassy')) return VisaKind.sticker;
    return null;
  }

  VisaProcessing? get parsedProcessing => VisaProcessing.parse(processing);

  bool get isFree => feesInr == 0;

  /// Fee for display in the user's currency. Falls back to the fee's own
  /// currency when no exchange rate is cached, instead of showing the raw
  /// number with the wrong symbol.
  String get feeLabel {
    if (isFree) return 'Free';
    final amount = feesInr.toDouble();
    final preferred = CurrencyConverter.getPreferredCurrency();
    if (feesCurrency.toUpperCase() == preferred.toUpperCase()) return visaMoney(amount);
    final converted = CurrencyConverter.convert(
      amount: amount,
      fromCurrency: feesCurrency,
      toCurrency: preferred,
    );
    if (converted == amount) return CurrencyConverter.format(amount, feesCurrency);
    return visaMoney(converted);
  }
}

/// Destinations that issue embassy (sticker) visas when the title does not
/// say otherwise.
const _stickerCountries = {
  'US', 'GB', 'CA', 'JP', 'CN', 'IE', 'ZA', 'KR', 'CY',
};

extension VisaDestinationRules on VisaPopularDestinationEntity {
  /// Visa type shown on cards: the admin's "popular" one, else the first.
  VisaTypeEntity? get primaryType {
    if (visaTypes.isEmpty) return null;
    // No firstWhere/orElse: the runtime list is List<VisaTypeModel>, which
    // rejects an orElse typed for the entity.
    for (final t in visaTypes) {
      if (t.popular) return t;
    }
    return visaTypes.first;
  }

  String get cardImage => imageUrl.isNotEmpty ? imageUrl : heroBannerImage;

  String get heroImage => heroBannerImage.isNotEmpty ? heroBannerImage : imageUrl;

  String? get countryCode => visaCountryCode(name);

  /// Visa category of [type]: what its title states, else sticker for
  /// Schengen and embassy countries and e-Visa for the rest.
  VisaKind kindOf(VisaTypeEntity type) {
    final stated = type.statedKind;
    if (stated != null) return stated;
    if (region.toLowerCase().contains('schengen') || _stickerCountries.contains(countryCode)) {
      return VisaKind.sticker;
    }
    return VisaKind.eVisa;
  }

  Set<VisaKind> get kinds => visaTypes.map(kindOf).toSet();

  /// Visa-free and on-arrival visas use the short entry-form flow (Thailand
  /// TDAC design); every other visa uses the full "cost visa" flow.
  bool usesEntryFormFlow(VisaTypeEntity type) {
    final kind = kindOf(type);
    return kind == VisaKind.visaFree || kind == VisaKind.onArrival;
  }

  /// Fastest processing among the visa types, falling back to the
  /// destination-level text.
  VisaProcessing? get fastestProcessing {
    VisaProcessing? best;
    for (final t in visaTypes) {
      final p = t.parsedProcessing;
      if (p != null && (best == null || p.duration < best.duration)) best = p;
    }
    return best ?? VisaProcessing.parse(processingTime);
  }

  VisaDocs get docs {
    final text = [...requirementsItems, ...requiredDocuments].join(' ').toLowerCase();
    if (RegExp(r'\b(us|usa|uk|schengen)\b').hasMatch(text) && text.contains('visa')) {
      return VisaDocs.otherVisa;
    }
    if (text.contains('income tax') || text.contains('itr') || text.contains('salary')) {
      return VisaDocs.incomeTax;
    }
    if (text.contains('bank') || text.contains('financial') || text.contains('funds') ||
        text.contains('income proof')) {
      return VisaDocs.bankStatements;
    }
    return VisaDocs.onlyPassport;
  }

  /// "USA", "UAE", "South Korea" … for the small circles and headings.
  String get shortName {
    const shorts = {
      'United States of America': 'USA',
      'United States': 'USA',
      'United Arab Emirates': 'UAE',
      'United Kingdom': 'UK',
      'Hong Kong - SAR of China': 'Hong Kong',
    };
    final s = shorts[name];
    if (s != null) return s;
    return name.split(RegExp(r'[/(]')).first.trim();
  }
}

final DateFormat visaDateTimeFormat = DateFormat('d MMM yyyy, h:mm a');
final DateFormat visaDateFormat = DateFormat('d MMM yyyy');
final DateFormat visaShortDateFormat = DateFormat('dd/MM/yy');

/// "₹4,820" in the user's preferred currency.
String visaMoney(double amount) {
  final currency = CurrencyConverter.getPreferredCurrency();
  final symbol = CurrencyConverter.getSymbol(currency);
  final f = NumberFormat.decimalPattern(currency == 'INR' ? 'en_IN' : 'en_US');
  return '$symbol${f.format(amount.round())}';
}

/// "16th Oct 2026".
String visaOrdinalDate(DateTime d) {
  final day = d.day;
  final suffix = (day >= 11 && day <= 13)
      ? 'th'
      : switch (day % 10) { 1 => 'st', 2 => 'nd', 3 => 'rd', _ => 'th' };
  return '$day$suffix ${DateFormat('MMM yyyy').format(d)}';
}
