/// Reads passports from OCR text: the machine-readable zone (MRZ) of the
/// photo page, verified with its ICAO 9303 check digits, and the labelled
/// fields of the back page of Indian passports.
library;

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

/// OCR often reads O for 0, I for 1 … in fields that can only be digits.
String _digits(String s) => s
    .replaceAll('O', '0')
    .replaceAll('Q', '0')
    .replaceAll('D', '0')
    .replaceAll('I', '1')
    .replaceAll('L', '1')
    .replaceAll('Z', '2')
    .replaceAll('S', '5')
    .replaceAll('B', '8')
    .replaceAll('G', '6');

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

/// Finds and verifies the passport MRZ in OCR [text]. Returns null unless
/// every check digit passes, so typed-over or edited data never verifies.
VisaMrz? readPassportMrz(String text) {
  final lines = text
      .split('\n')
      .map(_clean)
      .where((l) => l.length >= 30 && l.contains('<'))
      .toList();
  for (var i = 0; i < lines.length - 1; i++) {
    if (!lines[i].startsWith('P')) continue;
    final mrz = _parse(lines[i], lines[i + 1]);
    if (mrz != null) return mrz;
  }
  return null;
}

VisaMrz? _parse(String a, String b) {
  final l1 = a.padRight(44, '<').substring(0, 44);
  final l2 = b.padRight(44, '<').substring(0, 44);
  if (!l1.startsWith('P')) return null;

  final number = l2.substring(0, 9);
  final numberCheck = _digits(l2[9]);
  final dobRaw = _digits(l2.substring(13, 19));
  final dobCheck = _digits(l2[19]);
  final expRaw = _digits(l2.substring(21, 27));
  final expCheck = _digits(l2[27]);
  final personal = l2.substring(28, 42);
  final personalCheck = l2[42] == '<' ? '0' : _digits(l2[42]);
  final finalCheck = _digits(l2[43]);

  if ('${mrzCheckDigit(number)}' != numberCheck) return null;
  if ('${mrzCheckDigit(dobRaw)}' != dobCheck) return null;
  if ('${mrzCheckDigit(expRaw)}' != expCheck) return null;
  if ('${mrzCheckDigit(personal)}' != personalCheck) return null;
  final composite = '$number$numberCheck$dobRaw$dobCheck$expRaw$expCheck$personal$personalCheck';
  if ('${mrzCheckDigit(composite)}' != finalCheck) return null;

  final dob = _date(dobRaw, future: false);
  final expiry = _date(expRaw, future: true);
  if (dob == null || expiry == null) return null;

  final names = l1.substring(5).split('<<');
  String words(String s) => s.split('<').where((w) => w.isNotEmpty).join(' ');
  final surname = words(names.first);
  final given = names.length > 1 ? words(names.sublist(1).join('<<')) : '';
  if (surname.isEmpty) return null;

  return VisaMrz(
    line1: l1,
    line2: l2.replaceRange(9, 10, numberCheck),
    issuingCountry: l1.substring(2, 5).replaceAll('<', ''),
    surname: surname,
    givenNames: given,
    passportNumber: number.replaceAll('<', ''),
    nationality: l2.substring(10, 13).replaceAll('<', ''),
    dob: dob,
    sex: l2[20],
    expiry: expiry,
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
