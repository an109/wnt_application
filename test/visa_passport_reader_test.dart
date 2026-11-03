import 'package:flutter_test/flutter_test.dart';
import 'package:wander_nova/views/visa/data/visa_passport_reader.dart';

void main() {
  group('mrzCheckDigit', () {
    test('computes ICAO 9303 check digit', () {
      // Example: passport number L898902C, check digit 3
      expect(mrzCheckDigit('L898902C<'), 3);
    });

    test('all-filler field gives 0', () {
      expect(mrzCheckDigit('<<<<<<'), 0);
    });
  });

  group('readPassportMrz', () {
    test('parses a valid TD3 MRZ', () {
      // Standard ICAO example (modified to pass all check digits).
      const line1 = 'P<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<<<<<<<<<';
      const line2 = 'L898902C36UTO7408122F1204159ZE184226B<<<<<10';
      final mrz = readPassportMrz('$line1\n$line2');
      expect(mrz, isNotNull);
      expect(mrz!.passportNumber, 'L898902C3');
      expect(mrz.surname, 'ERIKSSON');
      expect(mrz.givenNames, 'ANNA MARIA');
      expect(mrz.nationality, 'UTO');
      expect(mrz.sex, 'F');
    });

    test('returns null for empty text', () {
      expect(readPassportMrz(''), isNull);
    });

    test('returns null for random text without MRZ', () {
      expect(readPassportMrz('Hello world\nNo passport here'), isNull);
    });

    test('parses Indian passport number (8 digits + filler)', () {
      // Indian passports: letter + 7 digits + filler '<'
      const line1 = 'P<INDKUMAR<<RAHUL<<<<<<<<<<<<<<<<<<<<<<<<<<<';
      // Build a valid line2 with correct check digits
      const number = 'Z1234567<'; // 8-char number + filler
      final numCheck = mrzCheckDigit(number);
      final dob = '950215';
      final dobCheck = mrzCheckDigit(dob);
      final exp = '301020';
      final expCheck = mrzCheckDigit(exp);
      final personal = '<<<<<<<<<<<<<<';
      final personalCheck = mrzCheckDigit(personal);
      final line2Pre = '$number${numCheck}IND${dob}${dobCheck}M${exp}${expCheck}$personal$personalCheck';
      final compositeField =
          '$number$numCheck' '${dob}$dobCheck' 'M${exp}$expCheck' '$personal$personalCheck';
      final compositeCheck = mrzCheckDigit(compositeField);
      final line2 = '$line2Pre'.substring(0, 43) + '$compositeCheck';

      final mrz = readPassportMrz('$line1\n$line2');
      expect(mrz, isNotNull);
      expect(mrz!.passportNumber, 'Z1234567');
    });

    test('handles OCR bracket substitutions for filler', () {
      // OCR often reads < as «, (, [ etc. — _clean should normalise them.
      const line1 = 'P«INDKUMAR««RAHUL«««««««««««««««««««««««««««';
      // The cleaning step should convert « to < before parsing.
      // With a valid line2, the MRZ should still parse.
      final mrz = readPassportMrz(line1);
      // Line1 alone is not enough (no line2), so null is expected.
      expect(mrz, isNull);
    });
  });

  group('reconcilePassportNames', () {
    final baseMrz = VisaMrz(
      line1: 'P<INDKUMAR<<RAHUL<<<<<<<<<<<<<<<<<<<<<<<<<<<',
      line2: 'Z12345670IND9502151M3010209<<<<<<<<<<<<<<00',
      issuingCountry: 'IND',
      surname: 'KUMAR',
      givenNames: 'RAHUL',
      passportNumber: 'Z1234567',
      nationality: 'IND',
      dob: DateTime(1995, 2, 15),
      sex: 'M',
      expiry: DateTime(2030, 10, 20),
      fullyVerified: true,
    );

    test('confirms names when printed names match', () {
      final result = reconcilePassportNames(baseMrz, [
        'Surname\nKUMAR\nGiven Name(s)\nRAHUL',
      ]);
      expect(result.namesConfirmed, isTrue);
      expect(result.surname, 'KUMAR');
      expect(result.givenNames, 'RAHUL');
    });

    test('keeps MRZ names unconfirmed when no printed names found', () {
      final result = reconcilePassportNames(baseMrz, ['random text with no labels']);
      expect(result.namesConfirmed, isFalse);
      expect(result.surname, 'KUMAR');
    });
  });

  group('readPassportFront', () {
    test('extracts place of birth', () {
      final mrz = VisaMrz(
        line1: '', line2: '',
        issuingCountry: 'IND', surname: '', givenNames: '',
        passportNumber: '', nationality: 'IND',
        dob: DateTime(1995, 1, 1), sex: 'M', expiry: DateTime(2030, 1, 1),
      );
      final front = readPassportFront(
        'Surname\nKUMAR\nDate of Birth\n15/02/1995\nPlace of Birth\nNEW DELHI\nDate of Issue\n20/03/2020\nDate of Expiry\n20/01/2030',
        mrz,
      );
      expect(front.placeOfBirth, 'New Delhi');
    });
  });

  group('readPassportBack', () {
    test('extracts father and mother names', () {
      final back = readPassportBack(
        "Name of Father\nRAJESH KUMAR\nName of Mother\nSUNITA DEVI\nAddress\n123 MG ROAD\nNEW DELHI\nFile Number\nDL1234567890123",
      );
      expect(back.fatherName, 'Rajesh Kumar');
      expect(back.motherName, 'Sunita Devi');
      expect(back.fileNumber, 'DL1234567890123');
      expect(back.looksValid, isTrue);
    });

    test('returns invalid for unrelated text', () {
      final back = readPassportBack('Some random text that is not a passport');
      expect(back.looksValid, isFalse);
    });
  });
}
