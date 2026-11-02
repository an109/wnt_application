/// Reads passports from OCR text: the machine-readable zone (MRZ) of the
/// photo page, verified with its ICAO 9303 check digits, and the labelled
/// fields of the back page of Indian passports.
library;

import 'package:flutter/foundation.dart';

/// Data from a TD3 (passport) MRZ whose check digits all passed.
class VisaMrz {
  final String line1;
  final String line2;
  final String issuingCountry;
  final String surname;
  final String givenNames;
  final String passportNumber;
  final String nationality;
  final DateTime dob;
  final String sex;
  final DateTime expiry;
  /// All five ICAO check digits passed. When false, only the passport
  /// number, birth date and expiry checks passed: the details are filled in
  /// but stay editable, and the MRZ is not sent for the backend check.
  final bool fullyVerified;

  const VisaMrz({
    required this.line1,
    required this.line2,
    required this.issuingCountry,
    required this.surname,
    required this.givenNames,
    required this.passportNumber,
    required this.nationality,
    required this.dob,
    required this.sex,
    required this.expiry,
    this.fullyVerified = true,
  });

  /// "Male" / "Female" / "Others", as the form expects.
  String get gender => switch (sex) { 'M' => 'Male', 'F' => 'Female', _ => 'Others' };

  String get nationalityName => visaCountryForIso3(nationality);
}

const _weights = [7, 3, 1];

int _value(String c) {
  final u = c.codeUnitAt(0);
  if (u >= 48 && u <= 57) return u - 48;
  if (u >= 65 && u <= 90) return u - 55;
  return 0; // '<'
}

/// ICAO 9303 check digit of [field].
int mrzCheckDigit(String field) {
  var sum = 0;
  for (var i = 0; i < field.length; i++) {
    sum += _value(field[i]) * _weights[i % 3];
  }
  return sum % 10;
}

String _clean(String line) => line
    .toUpperCase()
    .replaceAll(RegExp(r'\s'), '')
    .replaceAll('«', '<')
    .replaceAll('‹', '<')
    .replaceAll(RegExp(r'[^A-Z0-9<]'), '');

DateTime? _date(String yymmdd, {required bool future}) {
  if (!RegExp(r'^\d{6}$').hasMatch(yymmdd)) return null;
  final yy = int.parse(yymmdd.substring(0, 2));
  final mm = int.parse(yymmdd.substring(2, 4));
  final dd = int.parse(yymmdd.substring(4, 6));
  if (mm < 1 || mm > 12 || dd < 1 || dd > 31) return null;
  final now = DateTime.now().year % 100;
  // Expiry dates are in this century; birth years later than this year
  // belong to the last one.
  final century = future ? 2000 : (yy > now ? 1900 : 2000);
  final d = DateTime(century + yy, mm, dd);
  return d.month == mm ? d : null;
}

/// Letters OCR reads where the standard only allows digits, and back.
const _toDigit = {'O': '0', 'Q': '0', 'D': '0', 'U': '0', 'I': '1', 'L': '1', 'T': '1', 'Z': '2', 'S': '5', 'B': '8', 'G': '6'};
const _toLetter = {'0': 'O', '1': 'I', '2': 'Z', '5': 'S', '8': 'B', '6': 'G'};

String _fix(String s, int from, int to, Map<String, String> map) {
  final b = StringBuffer(s.substring(0, from));
  for (var i = from; i < to; i++) {
    b.write(map[s[i]] ?? s[i]);
  }
  b.write(s.substring(to));
  return b.toString();
}

/// Filler runs: OCR reads `<` as `K` (or `C`) when several stand together.
String _fixFiller(String s) => s.replaceAllMapped(RegExp(r'[<KC]{3,}$'), (m) => '<' * m[0]!.length);

/// The number as read, then single-character repairs of typical OCR
/// mistakes: a letter read where a digit is printed (O→0, S→5 …), and at
/// the first position — normally a letter — a digit read for a letter.
Iterable<String> _numberVariants(String number) sync* {
  const letterToDigit = {'O': '0', 'D': '0', 'Q': '0', 'I': '1', 'L': '1', 'S': '5', 'B': '8', 'Z': '2', 'G': '6'};
  const digitToLetter = {'0': 'O', '1': 'I', '5': 'S', '8': 'B', '2': 'Z', '6': 'G'};
  yield number;
  for (var i = 0; i < number.length; i++) {
    final c = number[i];
    final to = i == 0 ? digitToLetter[c] : letterToDigit[c];
    if (to != null) yield number.replaceRange(i, i + 1, to);
  }
}

class _Line2 {
  final String text;
  final String number;
  final String nationality;
  final DateTime dob;
  final DateTime expiry;
  final String sex;
  final bool full;
  const _Line2(this.text, this.number, this.nationality, this.dob, this.expiry, this.sex, this.full);
}

/// Parses a 44-character TD3 line 2, correcting OCR look-alikes by
/// position. Null unless the passport number, birth date and expiry check
/// digits pass.
_Line2? _parseLine2(String raw) {
  if (raw.length != 44) return null;
  var s = raw;
  s = _fix(s, 9, 10, _toDigit);
  s = _fix(s, 10, 13, _toLetter);
  s = _fix(s, 13, 20, _toDigit);
  s = _fix(s, 21, 28, _toDigit);
  s = _fix(s, 43, 44, _toDigit);
  final personal = s.substring(28, 42);
  if ('<'.allMatches(personal).length >= 3 || RegExp(r'^[<KC]+$').hasMatch(personal)) {
    s = s.substring(0, 28) + personal.replaceAll(RegExp(r'[KC]'), '<') + s.substring(42);
  }
  if (s[42] != '<') s = _fix(s, 42, 43, _toDigit);
  final sexChar = s[20] == 'H' || s[20] == 'N' ? 'M' : s[20];
  s = s.replaceRange(20, 21, sexChar);

  if (!RegExp(r'^\d$').hasMatch(s[9]) || !RegExp(r'^\d{7}$').hasMatch(s.substring(13, 20))) return null;
  if (!RegExp(r'^\d{7}$').hasMatch(s.substring(21, 28)) || !RegExp(r'^[A-Z<]{3}$').hasMatch(s.substring(10, 13))) {
    return null;
  }

  if ('${mrzCheckDigit(s.substring(13, 19))}' != s[19]) return null;
  if ('${mrzCheckDigit(s.substring(21, 27))}' != s[27]) return null;
  final dob = _date(s.substring(13, 19), future: false);
  final expiry = _date(s.substring(21, 27), future: true);
  if (dob == null || expiry == null) return null;

  bool fullFor(String line) {
    final personalCheck = line[42] == '<' ? '0' : line[42];
    final composite = line.substring(0, 10) + line.substring(13, 20) + line.substring(21, 43);
    return '${mrzCheckDigit(line.substring(28, 42))}' == personalCheck &&
        RegExp(r'^\d$').hasMatch(line[43]) &&
        '${mrzCheckDigit(composite)}' == line[43];
  }

  // The number as read must match its check digit; a look-alike repair is
  // accepted only when the composite digit confirms it too, so a changed
  // number can't be "repaired" into another valid-looking one.
  final read = s.substring(0, 9);
  String? number;
  var full = false;
  for (final v in _numberVariants(read)) {
    if ('${mrzCheckDigit(v)}' != s[9]) continue;
    final line = v + s.substring(9);
    final ok = fullFor(line);
    if (v == read || ok) {
      number = v;
      full = ok;
      break;
    }
  }
  if (number == null) return null;
  s = number + s.substring(9);

  return _Line2(s, number.replaceAll('<', ''), s.substring(10, 13).replaceAll('<', ''), dob, expiry,
      s[20], full);
}

/// Surname and given names from MRZ line 1, or null when unreadable.
(String, String)? _namesFromLine1(String line) {
  if (line.length < 10 || !line.startsWith('P')) return null;
  var names = _fixFiller(line.substring(5));
  names = names.replaceAll(RegExp(r'<+$'), '');
  var parts = names.split('<<');
  if (parts.length == 1) {
    // "<<" read as "K<", "<K" or "KK".
    final m = RegExp(r'K<|<K|KK').firstMatch(names);
    if (m != null) parts = [names.substring(0, m.start), names.substring(m.end)];
  }
  String words(String s) => s.split('<').where((w) => w.isNotEmpty).join(' ');
  final surname = words(parts.first.replaceAll(RegExp(r'[0-9]'), ''));
  final given = parts.length > 1 ? words(parts.sublist(1).join('<').replaceAll(RegExp(r'[0-9]'), '')) : '';
  if (surname.isEmpty) return null;
  return (surname, given);
}

/// Names printed on the photo page under "Surname" / "Given Name(s)".
(String, String)? _namesFromLabels(String text) {
  final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
  String after(bool Function(String) isLabel) {
    for (var i = 0; i < lines.length; i++) {
      if (isLabel(lines[i].toLowerCase())) {
        for (var j = i + 1; j < lines.length && j <= i + 2; j++) {
          final v = lines[j];
          if (RegExp(r'^[A-Z][A-Z .\-]{1,}$').hasMatch(v) && !v.contains('NAME')) return v.trim();
        }
      }
    }
    return '';
  }

  final surname = after((l) => l.contains('surname'));
  final given = after((l) => l.contains('given name'));
  if (surname.isEmpty && given.isEmpty) return null;
  return (surname, given);
}

/// Finds the passport MRZ in OCR [text] and checks its digits. Returns null
/// when no line 2 passes the passport-number, birth-date and expiry checks.
VisaMrz? readPassportMrz(String text) {
  final lines = text.split('\n').map(_clean).where((l) => l.isNotEmpty).toList();

  // Line 2 may come out whole, split in two, or with stray characters.
  final candidates = <(int, String)>[];
  for (var i = 0; i < lines.length; i++) {
    candidates.add((i, lines[i]));
    if (i + 1 < lines.length) candidates.add((i, lines[i] + lines[i + 1]));
  }
  _Line2? best;
  var bestIndex = -1;
  for (final (index, c) in candidates) {
    if (c.length < 40 || c.length > 60) continue;
    final padded = c.length < 44 ? c.padRight(44, '<') : c;
    for (var off = 0; off + 44 <= padded.length; off++) {
      final l2 = _parseLine2(padded.substring(off, off + 44));
      if (l2 != null && (best == null || (l2.full && !best.full))) {
        best = l2;
        bestIndex = index;
      }
      if (best?.full == true) break;
    }
    if (best?.full == true) break;
  }
  if (best == null) {
    debugPrint('[MRZ] no valid line 2 in ${lines.length} OCR lines');
    return null;
  }

  // Line 1: the "P<…" line just above line 2.
  String? line1;
  (String, String)? names;
  for (var j = bestIndex - 1; j >= 0 && j >= bestIndex - 3; j--) {
    final l = lines[j];
    if (l.length >= 25 && l.startsWith('P')) {
      final fixed = l.length > 1 && l[1] != '<' ? 'P<${l.substring(2)}' : l;
      names = _namesFromLine1(fixed);
      if (names != null) {
        line1 = _fixFiller(fixed).padRight(44, '<').substring(0, 44);
        break;
      }
    }
  }
  names ??= _namesFromLabels(text);
  final surname = names?.$1 ?? '';
  final given = names?.$2 ?? '';
  final nat = best.nationality;
  line1 ??= 'P<$nat${surname.replaceAll(' ', '<')}<<${given.replaceAll(' ', '<')}'
      .padRight(44, '<')
      .substring(0, 44);
  debugPrint('[MRZ] read ${best.number} full=${best.full} names=${names != null}');

  return VisaMrz(
    line1: line1,
    line2: best.text,
    issuingCountry: line1.substring(2, 5).replaceAll('<', ''),
    surname: surname,
    givenNames: given,
    passportNumber: best.number,
    nationality: nat,
    dob: best.dob,
    sex: best.sex,
    expiry: best.expiry,
    fullyVerified: best.full && surname.isNotEmpty,
  );
}

/// Fields the photo page prints outside the MRZ (best effort).
class VisaPassportFront {
  final DateTime? issueDate;
  final String placeOfBirth;
  const VisaPassportFront({this.issueDate, this.placeOfBirth = ''});
}

final _dateRe = RegExp(r'\b(\d{2})[/.-](\d{2})[/.-](\d{4})\b');

VisaPassportFront readPassportFront(String text, VisaMrz mrz) {
  DateTime? issue;
  for (final m in _dateRe.allMatches(text)) {
    final d = DateTime.tryParse('${m.group(3)}-${m.group(2)}-${m.group(1)}');
    if (d == null) continue;
    final sameAs = (DateTime x) => x.year == d.year && x.month == d.month && x.day == d.day;
    if (sameAs(mrz.dob) || sameAs(mrz.expiry)) continue;
    if (d.isBefore(mrz.expiry) && d.isAfter(mrz.dob)) issue = d;
  }
  final lines = text.split('\n').map((l) => l.trim()).toList();
  var place = '';
  for (var i = 0; i < lines.length - 1; i++) {
    if (lines[i].toLowerCase().contains('place of birth')) {
      place = _value2(lines, i);
      break;
    }
  }
  return VisaPassportFront(issueDate: issue, placeOfBirth: _title(place));
}

/// Fields of the back page of an Indian passport.
class VisaPassportBack {
  final String fatherName;
  final String motherName;
  final String spouseName;
  final String address;
  final String oldPassportNumber;
  final String fileNumber;

  const VisaPassportBack({
    this.fatherName = '',
    this.motherName = '',
    this.spouseName = '',
    this.address = '',
    this.oldPassportNumber = '',
    this.fileNumber = '',
  });

  /// The page is accepted only when it clearly is a passport back page.
  bool get looksValid => fileNumber.isNotEmpty || fatherName.isNotEmpty || motherName.isNotEmpty;
}

VisaPassportBack readPassportBack(String text) {
  final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
  String after(String label) {
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].toLowerCase().contains(label)) return _value2(lines, i);
    }
    return '';
  }

  final upper = text.toUpperCase();
  final file = RegExp(r'\b[A-Z]{2}\d{10,13}\b').firstMatch(upper)?.group(0) ?? '';
  var old = '';
  final oldIdx = upper.indexOf('OLD PASSPORT');
  if (oldIdx >= 0) {
    old = RegExp(r'\b[A-Z]\d{7}\b').firstMatch(upper.substring(oldIdx))?.group(0) ?? '';
  }
  final addressStart = lines.indexWhere((l) => l.toLowerCase().contains('address'));
  var address = '';
  if (addressStart >= 0) {
    address = lines
        .skip(addressStart + 1)
        .takeWhile((l) => !l.toLowerCase().contains('old passport') && !l.toLowerCase().contains('file'))
        .where(_isValueLine)
        .take(4)
        .join(', ');
  }
  return VisaPassportBack(
    fatherName: _title(after('father')),
    motherName: _title(after('mother')),
    spouseName: _title(after('spouse')),
    address: address,
    oldPassportNumber: old,
    fileNumber: file,
  );
}

/// The first line after [i] that holds a value rather than another label.
String _value2(List<String> lines, int i) {
  for (var j = i + 1; j < lines.length && j <= i + 3; j++) {
    if (_isValueLine(lines[j])) return lines[j];
  }
  return '';
}

bool _isValueLine(String l) {
  final lower = l.toLowerCase();
  if (l.length < 2) return false;
  const labels = ['name of', 'father', 'mother', 'spouse', 'address', 'passport', 'file', '/'];
  if (labels.any(lower.contains)) return false;
  // Hindi labels: Devanagari block.
  if (RegExp(r'[ऀ-ॿ]').hasMatch(l)) return false;
  return RegExp(r'[A-Za-z]').hasMatch(l);
}

String _title(String s) => s
    .trim()
    .split(RegExp(r'\s+'))
    .where((w) => w.isNotEmpty)
    .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
    .join(' ');

const _iso3 = {
  'IND': 'India', 'USA': 'United States', 'GBR': 'United Kingdom', 'ARE': 'United Arab Emirates',
  'AUS': 'Australia', 'CAN': 'Canada', 'DEU': 'Germany', 'D': 'Germany', 'FRA': 'France', 'ITA': 'Italy',
  'ESP': 'Spain', 'NLD': 'Netherlands', 'CHN': 'China', 'JPN': 'Japan', 'KOR': 'South Korea',
  'SGP': 'Singapore', 'MYS': 'Malaysia', 'THA': 'Thailand', 'IDN': 'Indonesia', 'PHL': 'Philippines',
  'VNM': 'Vietnam', 'NPL': 'Nepal', 'BGD': 'Bangladesh', 'LKA': 'Sri Lanka', 'PAK': 'Pakistan',
  'SAU': 'Saudi Arabia', 'QAT': 'Qatar', 'OMN': 'Oman', 'KWT': 'Kuwait', 'BHR': 'Bahrain',
  'EGY': 'Egypt', 'ZAF': 'South Africa', 'NZL': 'New Zealand', 'RUS': 'Russia', 'TUR': 'Turkey',
  'IRL': 'Ireland', 'CHE': 'Switzerland', 'BRA': 'Brazil', 'MEX': 'Mexico', 'KEN': 'Kenya',
  'NGA': 'Nigeria', 'AFG': 'Afghanistan',
};

String visaCountryForIso3(String code) => _iso3[code] ?? code;
