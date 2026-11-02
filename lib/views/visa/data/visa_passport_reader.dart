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

  /// The names match the ones printed on the photo page. The check digits do
  /// not cover line 1, so a name read from the MRZ alone is only "read", never
  /// "verified": OCR confuses the `<` filler with K and C, which can add or
  /// remove letters.
  final bool namesConfirmed;

  /// The MRZ could not say where the name ended (a trailing K or C could be a
  /// letter or a misread filler), so the name may be a letter short or long.
  final bool namesAmbiguous;

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
    this.namesConfirmed = false,
    this.namesAmbiguous = false,
  });

  VisaMrz withNames({
    required String surname,
    required String givenNames,
    required bool confirmed,
    bool ambiguous = false,
  }) {
    final issuing = RegExp(r'^[A-Z]{3}$').hasMatch(issuingCountry) ? issuingCountry : nationality;
    return VisaMrz(
      line1: _buildLine1(issuing, surname, givenNames),
      line2: line2,
      issuingCountry: issuingCountry,
      surname: surname,
      givenNames: givenNames,
      passportNumber: passportNumber,
      nationality: nationality,
      dob: dob,
      sex: sex,
      expiry: expiry,
      // A passport is only "fully verified" with a name to go with it.
      fullyVerified: fullyVerified && surname.isNotEmpty,
      namesConfirmed: confirmed,
      namesAmbiguous: ambiguous,
    );
  }

  /// "Male" / "Female" / "Others", as the form expects.
  String get gender => switch (sex) { 'M' => 'Male', 'F' => 'Female', _ => 'Others' };

  String get nationalityName => visaCountryForIso3(nationality);
}

String _buildLine1(String issuing, String surname, String given) {
  final names = '${surname.replaceAll(' ', '<')}<<${given.replaceAll(' ', '<')}';
  return 'P<$issuing$names'.padRight(44, '<').substring(0, 44);
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

/// OCR reads the `<` filler as one of several brackets; map them back so the
/// line keeps its length instead of losing characters.
String _clean(String line) => line
    .toUpperCase()
    .replaceAll(RegExp(r'\s'), '')
    .replaceAll(RegExp(r'[«‹〈⟨《＜(\[{]'), '<')
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

/// Letters OCR reads in place of the `<` filler.
final _fillerLike = RegExp(r'[KCSLE]');

String _fix(String s, int from, int to, Map<String, String> map) {
  final b = StringBuffer(s.substring(0, from));
  for (var i = from; i < to; i++) {
    b.write(map[s[i]] ?? s[i]);
  }
  b.write(s.substring(to));
  return b.toString();
}

/// The number as read, then single-character repairs of typical OCR
/// mistakes: a letter read where a digit is printed (O→0, S→5 …), and at
/// the first position — normally a letter — a digit read for a letter.
///
/// An 8-character number (every Indian passport) is followed by one `<`
/// filler. OCR often reads that filler as K, C, S or L — and K and U cannot
/// even be told apart from it by the check digit — so a letter in the ninth
/// place of an otherwise numeric number is read as the filler first.
Iterable<String> _numberVariants(String number) sync* {
  const letterToDigit = {'O': '0', 'D': '0', 'Q': '0', 'I': '1', 'L': '1', 'S': '5', 'B': '8', 'Z': '2', 'G': '6'};
  const digitToLetter = {'0': 'O', '1': 'I', '5': 'S', '8': 'B', '2': 'Z', '6': 'G'};
  if (number.length == 9 && _ninthIsFiller(number)) {
    yield '${number.substring(0, 8)}<';
  }
  yield number;
  for (var i = 0; i < number.length; i++) {
    final c = number[i];
    final to = i == 0 ? digitToLetter[c] : letterToDigit[c];
    if (to != null) yield number.replaceRange(i, i + 1, to);
  }
}

bool _ninthIsFiller(String number) {
  if (number.length != 9 || RegExp(r'[0-9<]').hasMatch(number[8])) return false;
  return RegExp(r'\d').allMatches(number.substring(0, 8)).length >= 6;
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

/// The personal-number field (14 characters) as read, then with filler
/// look-alikes put back. A real personal number (letters and digits, then
/// fillers) is tried untouched first, so its own K/C/S/L/E are not lost.
Iterable<String> _personalVariants(String p) sync* {
  yield p;
  final trailing = p.replaceFirstMapped(RegExp(r'[<KCSLE]+$'), (m) => '<' * m[0]!.length);
  if (trailing != p) yield trailing;
  final all = p.replaceAll(_fillerLike, '<');
  if (all != p && all != trailing && ('<'.allMatches(all).length >= 3)) yield all;
}

/// The personal-number check digit as read, then as a filler (`<`).
Iterable<String> _personalCheckVariants(String c) sync* {
  if (c == '<' || RegExp(r'^\d$').hasMatch(c)) {
    yield c;
    return;
  }
  final digit = _toDigit[c];
  if (digit != null) yield digit;
  if (_fillerLike.hasMatch(c)) yield '<';
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
  final sexChar = s[20] == 'H' || s[20] == 'N' ? 'M' : s[20];
  s = s.replaceRange(20, 21, sexChar);

  if (!RegExp(r'^\d$').hasMatch(s[9]) || !RegExp(r'^\d{7}$').hasMatch(s.substring(13, 20))) return null;
  if (!RegExp(r'^\d{7}$').hasMatch(s.substring(21, 28)) || !RegExp(r'^[A-Z<]{3}$').hasMatch(s.substring(10, 13))) {
    return null;
  }

  _Line2? partial;
  for (final personal in _personalVariants(s.substring(28, 42))) {
    for (final check in _personalCheckVariants(s[42])) {
      final r = _checkLine2(s.substring(0, 28) + personal + check + s[43]);
      if (r == null) continue;
      if (r.full) return r;
      partial ??= r;
    }
  }
  return partial;
}

/// Checks one repaired candidate. Null unless the number, birth-date and
/// expiry digits pass.
_Line2? _checkLine2(String s) {
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
  // number can't be "repaired" into another valid-looking one. The one
  // exception is the filler after an 8-character number: it is the filler
  // whatever the OCR called it, and the check digit cannot tell K or U from
  // it, so it is accepted on the number's own check digit.
  final read = s.substring(0, 9);
  String? number;
  var full = false;
  for (final v in _numberVariants(read)) {
    if ('${mrzCheckDigit(v)}' != s[9]) continue;
    final line = v + s.substring(9);
    final ok = fullFor(line);
    final fillerRepair = v != read && v.substring(0, 8) == read.substring(0, 8) && v[8] == '<';
    if (v == read || ok || fillerRepair) {
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

/// 44-character versions of an OCR line whose length is off: characters lost
/// or gained, usually in the run of fillers.
Iterable<String> _alignments(String c) sync* {
  if (c.length == 44) {
    yield c;
    return;
  }
  if (c.length < 44) {
    yield c.padRight(44, '<');
    // A filler lost after an 8-character number: the check digit is then
    // the ninth character.
    if (c.length == 43 && RegExp(r'^\w{8}\d').hasMatch(c)) {
      yield '${c.substring(0, 8)}<${c.substring(8)}';
    }
  } else {
    for (var off = 0; off + 44 <= c.length; off++) {
      yield c.substring(off, off + 44);
    }
  }
  // Fillers lost or added in the personal-number field: keep the first 28
  // characters and the last 2, and resize what lies between.
  if (c.length >= 38 && c.length <= 52) {
    final mid = c.substring(28, c.length - 2);
    final fixed = mid.length >= 14 ? mid.substring(0, 14) : mid.padRight(14, '<');
    yield c.substring(0, 28) + fixed + c.substring(c.length - 2);
  }
}

class _Names {
  final String surname;
  final String given;
  final bool ambiguous;
  const _Names(this.surname, this.given, this.ambiguous);
}

/// Strips the run of fillers that ends a names field. OCR reads the `<`
/// filler as K or C, but K and C also end real names (ASHOK, DEEPAK, ERIC), so
/// the run is not simply thrown away:
///  * a K/C directly before a correctly read `<` is a letter of the name
///    (up to two of them, as in PATRICK);
///  * more than two, or a run with no `<` left at all, cannot be told apart
///    from misread fillers. Nothing is kept and the name is flagged.
(String, bool) _trimFiller(String names) {
  final m = RegExp(r'[<KC]+$').firstMatch(names);
  if (m == null) return (names, false);
  final run = m[0]!;
  final head = names.substring(0, m.start);
  final firstFiller = run.indexOf('<');
  if (firstFiller == -1) {
    // Nothing but K/C: one or two is simply how the name ends; a longer run
    // is a whole line of misread fillers.
    return run.length <= 2 ? (names, false) : (head, true);
  }
  final prefix = run.substring(0, firstFiller);
  if (prefix.length <= 2) return (head + prefix, false);
  return (head, true);
}

/// Surname and given names from MRZ line 1, or null when unreadable.
_Names? _namesFromLine1(String line) {
  if (line.length < 10 || !line.startsWith('P')) return null;
  var (names, ambiguous) = _trimFiller(line.substring(5));
  var parts = names.split('<<');
  if (parts.length == 1) {
    // "<<" read as "K<", "<K" or "KK". Only a guess: such a name is flagged
    // so it is checked against the printed one.
    final m = RegExp(r'K<|<K|KK').firstMatch(names);
    if (m != null) {
      parts = [names.substring(0, m.start), names.substring(m.end)];
      ambiguous = true;
    }
  }
  String words(String s) => s.split('<').where((w) => w.isNotEmpty).join(' ');
  final surname = words(parts.first.replaceAll(RegExp(r'[0-9]'), ''));
  final given = parts.length > 1 ? words(parts.sublist(1).join('<').replaceAll(RegExp(r'[0-9]'), '')) : '';
  if (surname.isEmpty) return null;
  return _Names(surname, given, ambiguous);
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
    if (c.length < 38 || c.length > 60) continue;
    for (final aligned in _alignments(c)) {
      final l2 = _parseLine2(aligned);
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
  String? issuing;
  _Names? names;
  for (var j = bestIndex - 1; j >= 0 && j >= bestIndex - 3; j--) {
    final l = lines[j];
    if (l.length >= 25 && l.startsWith('P')) {
      final fixed = l.length > 1 && l[1] != '<' ? 'P<${l.substring(2)}' : l;
      names = _namesFromLine1(fixed);
      if (names != null) {
        issuing = fixed.length >= 5 ? fixed.substring(2, 5).replaceAll('<', '') : null;
        break;
      }
    }
  }
  final printed = names == null ? _namesFromLabels(text) : null;
  final surname = names?.surname ?? printed?.$1 ?? '';
  final given = names?.given ?? printed?.$2 ?? '';
  final nat = best.nationality;
  debugPrint('[MRZ] read ${best.number} full=${best.full} names=${names != null} ambiguous=${names?.ambiguous}');

  return VisaMrz(
    line1: _buildLine1(RegExp(r'^[A-Z]{3}$').hasMatch(issuing ?? '') ? issuing! : nat, surname, given),
    line2: best.text,
    issuingCountry: (RegExp(r'^[A-Z]{3}$').hasMatch(issuing ?? '') ? issuing! : nat),
    surname: surname,
    givenNames: given,
    passportNumber: best.number,
    nationality: nat,
    dob: best.dob,
    sex: best.sex,
    expiry: best.expiry,
    fullyVerified: best.full && surname.isNotEmpty,
    namesAmbiguous: names?.ambiguous ?? false,
  );
}

/// Letters only, upper case — names compared without spacing or punctuation.
String _squash(String s) => s.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');

int _distance(String a, String b) {
  if (a == b) return 0;
  var prev = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final cur = List<int>.filled(b.length + 1, 0)..[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      cur[j] = [prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost].reduce((x, y) => x < y ? x : y);
    }
    prev = cur;
  }
  return prev[b.length];
}

String _tidy(String s) => s.trim().replaceAll(RegExp(r'\s+'), ' ');

/// Checks the names read from the MRZ against the ones printed on the photo
/// page, which are in an ordinary typeface and are not hit by the `<` mix-ups.
///
///  * identical → the names are confirmed;
///  * a small difference (a letter or two added or lost) → the printed names
///    are used, and the traveller is asked to check them;
///  * nothing printed could be read, or it is very different → the MRZ names
///    are kept and not confirmed.
///
/// [ocrTexts] are the OCR results of every attempt made on the photo.
VisaMrz reconcilePassportNames(VisaMrz mrz, Iterable<String> ocrTexts) {
  final mrzS = _squash(mrz.surname), mrzG = _squash(mrz.givenNames);
  (String, String)? bestPrinted;
  var bestDistance = 1 << 30;
  for (final t in ocrTexts) {
    final p = _namesFromLabels(t);
    if (p == null) continue;
    final printedS = _squash(p.$1), printedG = _squash(p.$2);
    // A name shorter than 2 letters is an OCR scrap, not a name.
    if (printedS.length + printedG.length < 2) continue;
    final d = _distance(printedS + printedG, mrzS + mrzG);
    if (d < bestDistance) {
      bestDistance = d;
      bestPrinted = p;
    }
  }
  final printed = bestPrinted;
  if (printed == null) {
    return mrz.withNames(surname: mrz.surname, givenNames: mrz.givenNames, confirmed: false, ambiguous: mrz.namesAmbiguous);
  }
  final printedS = _squash(printed.$1), printedG = _squash(printed.$2);
  if (printedS == mrzS && printedG == mrzG) {
    return mrz.withNames(surname: mrz.surname, givenNames: mrz.givenNames, confirmed: true);
  }
  final mrzAll = mrzS + mrzG, printedAll = printedS + printedG;
  if (bestDistance == 0) {
    // The same letters, only split differently (surname and given names
    // swapped or merged): the printed split is the right one.
    return mrz.withNames(surname: _tidy(printed.$1), givenNames: _tidy(printed.$2), confirmed: true);
  }
  // The printed spelling replaces the MRZ one only when the difference is the
  // kind OCR makes in the MRZ — a K or C added or lost at the end of a name,
  // or filler letters in the middle. Any other difference is as likely to be a
  // mistake in the printed text, so the MRZ is kept and the traveller asked.
  if (bestDistance <= 3 && (mrz.namesAmbiguous || _fillerDifference(printedAll, mrzAll))) {
    return mrz.withNames(surname: _tidy(printed.$1), givenNames: _tidy(printed.$2), confirmed: false);
  }
  return mrz.withNames(surname: mrz.surname, givenNames: mrz.givenNames, confirmed: false, ambiguous: mrz.namesAmbiguous);
}

/// True when [mrz] and [printed] differ only by filler look-alike letters
/// (K, C, S, L, E): up to two added at the end of [mrz], or up to three extra
/// ones inside it.
bool _fillerDifference(String printed, String mrz) {
  if (printed.length > mrz.length && printed.startsWith(mrz)) {
    final rest = printed.substring(mrz.length);
    return rest.length <= 2 && RegExp(r'^[KC]+$').hasMatch(rest);
  }
  final extra = mrz.length - printed.length;
  if (extra < 1 || extra > 3) return false;
  var p = 0;
  for (var m = 0; m < mrz.length; m++) {
    if (p < printed.length && mrz[m] == printed[p]) {
      p++;
    } else if (!_fillerLike.hasMatch(mrz[m])) {
      return false;
    }
  }
  return p == printed.length;
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
  for (var i = 0; i < lines.length; i++) {
    final lower = lines[i].toLowerCase();
    if (!lower.contains('place of birth')) continue;
    // "Place of Birth NEW DELHI" on one line.
    final sameLine = lines[i].replaceFirst(RegExp(r'place of birth', caseSensitive: false), '');
    final inline = sameLine.split('/').first.replaceAll(RegExp(r'[^A-Za-z .,\-]'), '').trim();
    if (inline.length >= 3 && _isValueLine(inline)) {
      place = inline;
    } else {
      place = _value2(lines, i);
    }
    break;
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

/// Printed labels of an Indian passport page that begin a line. Matched at the
/// start of the line only, so a value that merely contains one of these words
/// (ESSEX, a street called "Type Road") is not mistaken for a label.
final _labelStart = RegExp(
  r'^(place of|date of|surname|given name|nationality|sex\b|type\b|country code|code\b|authority|'
  r'issuing|republic|holder|signature|photo)',
  caseSensitive: false,
);

bool _isValueLine(String l) {
  final lower = l.toLowerCase();
  if (l.length < 2) return false;
  const labels = ['name of', 'father', 'mother', 'spouse', 'address', 'passport', 'file', '/'];
  if (labels.any(lower.contains)) return false;
  if (_labelStart.hasMatch(l)) return false;
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
