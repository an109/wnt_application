import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wander_nova/views/visa/data/visa_passport_reader.dart';

/// A valid Indian TD3 MRZ (check digits computed): line 1 and line 2.
(String, String) mrz({
  required String surname,
  required String given,
  String number = 'Z1234567',
  String dob = '900101',
  String sex = 'M',
  String exp = '300528',
  String personal = '',
}) {
  final names = '${surname.replaceAll(' ', '<')}<<${given.replaceAll(' ', '<')}';
  final l1 = 'P<IND$names'.padRight(44, '<');
  final num9 = number.padRight(9, '<');
  final personal14 = personal.padRight(14, '<');
  // An empty personal number has the filler as its check digit.
  final personalCheck = personal.isEmpty ? '<' : '${mrzCheckDigit(personal14)}';
  final head = '$num9${mrzCheckDigit(num9)}IND$dob${mrzCheckDigit(dob)}$sex$exp${mrzCheckDigit(exp)}$personal14$personalCheck';
  final composite = head.substring(0, 10) + head.substring(13, 20) + head.substring(21, 43);
  return (l1, '$head${mrzCheckDigit(composite)}');
}

String printedNames(String surname, String given) =>
    'Type\nP\nSurname\n$surname\nGiven Name(s)\n$given\nNationality\nINDIAN\n';

void main() {
  group('names that end in K or C keep their last letter', () {
    for (final given in ['ASHOK', 'DEEPAK', 'KARTIK', 'ALOK', 'RITIK', 'MAYANK', 'ERIC', 'ISAAC', 'PATRICK', 'ZAKK']) {
      test(given, () {
        final (a, b) = mrz(surname: 'SHARMA', given: given);
        final r = readPassportMrz('$a\n$b')!;
        expect(r.givenNames, given);
        expect(r.surname, 'SHARMA');
        expect(r.namesAmbiguous, isFalse);
        expect(r.fullyVerified, isTrue);
      });
    }

    test('a surname ending in K, with given names after it', () {
      final (a, b) = mrz(surname: 'MALIK', given: 'SAMEER KUMAR');
      final r = readPassportMrz('$a\n$b')!;
      expect((r.surname, r.givenNames), ('MALIK', 'SAMEER KUMAR'));
    });

    test('a name that fills the line to column 44 and ends in K', () {
      final r = readPassportMrz('P<INDVENKATARAMANAN<<SUBRAMANIAN<KRISHNAMOORTHYK\n${mrz(surname: 'X', given: 'Y').$2}');
      // The line is longer than 44 here; it must not be mistaken for filler.
      expect(r, isNotNull);
      expect(r!.givenNames.endsWith('K'), isTrue);
    });

    test('a run that is all K/C with no "<" left is flagged, not guessed', () {
      final (a, b) = mrz(surname: 'SHARMA', given: 'DEEPAK');
      final garbled = a.replaceAll('<', 'K').replaceFirst('P', 'P<').substring(0, 44).replaceRange(1, 2, '<');
      final r = readPassportMrz('$garbled\n$b')!;
      expect(r.namesAmbiguous, isTrue);
    });
  });

  group('the filler after an 8-character passport number', () {
    for (final ch in ['K', 'U', 'C', 'S', 'L', 'E', '(', '[']) {
      test('read as "$ch"', () {
        final (a, b) = mrz(surname: 'SHARMA', given: 'RAJESH KUMAR');
        final bad = '${b.substring(0, 8)}$ch${b.substring(9)}';
        final r = readPassportMrz('$a\n$bad')!;
        expect(r.passportNumber, 'Z1234567');
        expect(r.fullyVerified, isTrue);
      });
    }

    test('a genuine 9-character alphanumeric number is left alone', () {
      final (a, b) = mrz(surname: 'ERIKSSON', given: 'ANNA MARIA', number: 'C01X00T47');
      final r = readPassportMrz('$a\n$b')!;
      expect(r.passportNumber, 'C01X00T47');
    });

    test('a 9-digit number is left alone', () {
      final (a, b) = mrz(surname: 'SMITH', given: 'JOHN', number: '123456789');
      expect(readPassportMrz('$a\n$b')!.passportNumber, '123456789');
    });
  });

  group('damaged filler runs in line 2', () {
    final (a, b) = mrz(surname: 'SHARMA', given: 'RAJESH');

    for (final ch in ['(', 'K', 'C', 'S', 'L', 'E', '[']) {
      test('every "<" read as "$ch"', () {
        final r = readPassportMrz('$a\n${b.replaceAll('<', ch)}')!;
        expect(r.passportNumber, 'Z1234567');
        expect(r.dob, DateTime(1990, 1, 1));
        expect(r.fullyVerified, isTrue);
      });
    }

    test('one filler lost in the personal-number field', () {
      final r = readPassportMrz('$a\n${b.substring(0, 30)}${b.substring(31)}')!;
      expect(r.passportNumber, 'Z1234567');
      expect(r.fullyVerified, isTrue);
    });

    test('two fillers lost in the personal-number field', () {
      final r = readPassportMrz('$a\n${b.substring(0, 30)}${b.substring(32)}')!;
      expect(r.fullyVerified, isTrue);
    });

    test('the filler after the number lost', () {
      final r = readPassportMrz('$a\n${b.substring(0, 8)}${b.substring(9)}')!;
      expect(r.passportNumber, 'Z1234567');
      expect(r.fullyVerified, isTrue);
    });

    test('extra fillers gained', () {
      final r = readPassportMrz('$a\n${b.substring(0, 30)}<<${b.substring(30)}')!;
      expect(r.passportNumber, 'Z1234567');
      expect(r.fullyVerified, isTrue);
    });

    test('a real personal number keeps its own K/C/S/L/E', () {
      final (a2, b2) = mrz(surname: 'ERIKSSON', given: 'ANNA MARIA', personal: 'ZE184226B');
      final r = readPassportMrz('$a2\n$b2')!;
      expect(r.fullyVerified, isTrue);
      expect(r.line2.substring(28, 37), 'ZE184226B');
    });

    test('line 2 split in two and spaced', () {
      final r = readPassportMrz('$a\n${b.substring(0, 22)}\n${b.substring(22)}')!;
      expect(r.fullyVerified, isTrue);
      final s = readPassportMrz('$a\n${b.substring(0, 10)} ${b.substring(10, 20)} ${b.substring(20)}')!;
      expect(s.fullyVerified, isTrue);
    });
  });

  group('never accepts a line whose digits do not check out', () {
    test('tampered passport-number check digit', () {
      final (a, b) = mrz(surname: 'SHARMA', given: 'RAJESH');
      final bad = '${b.substring(0, 9)}${(int.parse(b[9]) + 1) % 10}${b.substring(10)}';
      expect(readPassportMrz('$a\n$bad'), isNull);
    });

    test('a changed digit in the passport number', () {
      final (a, b) = mrz(surname: 'SHARMA', given: 'RAJESH');
      final bad = b.replaceFirst('Z1234567', 'Z1234577');
      expect(readPassportMrz('$a\n$bad'), isNull);
    });

    test('random text never parses', () {
      final rnd = Random(7);
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789<';
      for (var i = 0; i < 400; i++) {
        final len = 38 + rnd.nextInt(14);
        final line = List.generate(len, (_) => chars[rnd.nextInt(chars.length)]).join();
        expect(readPassportMrz('P<INDSHARMA<<RAJESH\n$line'), isNull, reason: line);
      }
    });
  });

  group('names are checked against the printed ones', () {
    test('identical → confirmed', () {
      final (a, b) = mrz(surname: 'SHARMA', given: 'RAJESH KUMAR');
      final r = reconcilePassportNames(readPassportMrz('$a\n$b')!, [printedNames('SHARMA', 'RAJESH KUMAR')]);
      expect(r.namesConfirmed, isTrue);
      expect((r.surname, r.givenNames), ('SHARMA', 'RAJESH KUMAR'));
    });

    test('no printed names could be read → names kept, not confirmed', () {
      final (a, b) = mrz(surname: 'SHARMA', given: 'RAJESH KUMAR');
      final r = reconcilePassportNames(readPassportMrz('$a\n$b')!, ['some other text', '']);
      expect(r.namesConfirmed, isFalse);
      expect((r.surname, r.givenNames), ('SHARMA', 'RAJESH KUMAR'));
    });

    test('a K lost at the end of the MRZ name is restored from the printed one', () {
      final (a, b) = mrz(surname: 'SHARMA', given: 'ASHO');
      final r = reconcilePassportNames(readPassportMrz('$a\n$b')!, [printedNames('SHARMA', 'ASHOK')]);
      expect(r.givenNames, 'ASHOK');
      expect(r.namesConfirmed, isFalse); // the two sources disagreed: ask the traveller
    });

    test('a damaged "<<" separator is repaired from the printed names', () {
      final (a, b) = mrz(surname: 'SHARMA', given: 'RAJESH KUMAR');
      for (final sep in ['CC', 'SS', 'CK', 'KC', 'C<', '<S']) {
        final l1 = a.replaceFirst('SHARMA<<RAJESH', 'SHARMA${sep}RAJESH');
        final r = reconcilePassportNames(readPassportMrz('$l1\n$b')!, [printedNames('SHARMA', 'RAJESH KUMAR')]);
        expect((r.surname, r.givenNames), ('SHARMA', 'RAJESH KUMAR'), reason: sep);
        expect(r.namesConfirmed, isFalse, reason: sep);
      }
    });

    test('an ambiguous all-K run is settled by the printed name', () {
      final (a, b) = mrz(surname: 'SHARMA', given: 'DEEPAK');
      final garbled = 'P<INDSHARMA<<DEEPAKKKKKKKKKKKKKKKKKKKKKKKKKKK'.substring(0, 44);
      final read = readPassportMrz('$garbled\n$b')!;
      expect(read.namesAmbiguous, isTrue);
      final r = reconcilePassportNames(read, [printedNames('SHARMA', 'DEEPAK')]);
      expect(r.givenNames, 'DEEPAK');
    });

    test('an unrelated difference is not "corrected" from the printed text', () {
      final (a, b) = mrz(surname: 'SHARMA', given: 'RAJESH');
      // The printed OCR has an M read as N — the MRZ is the better source.
      final r = reconcilePassportNames(readPassportMrz('$a\n$b')!, [printedNames('SHARNA', 'RAJESH')]);
      expect(r.surname, 'SHARMA');
      expect(r.namesConfirmed, isFalse);
    });

    test('line 1 is rebuilt from the final names', () {
      final (a, b) = mrz(surname: 'SHARMA', given: 'ASHO');
      final r = reconcilePassportNames(readPassportMrz('$a\n$b')!, [printedNames('SHARMA', 'ASHOK')]);
      expect(r.line1, 'P<INDSHARMA<<ASHOK'.padRight(44, '<'));
      expect(r.line1.length, 44);
    });

    test('the best of several OCR passes is used', () {
      final (a, b) = mrz(surname: 'SHARMA', given: 'RAJESH KUMAR');
      final r = reconcilePassportNames(readPassportMrz('$a\n$b')!,
          ['garbage', printedNames('SHARNA', 'RAJESH KUMAR'), printedNames('SHARMA', 'RAJESH KUMAR')]);
      expect(r.namesConfirmed, isTrue);
    });
  });

  group('photo-page fields', () {
    final (a, b) = mrz(surname: 'SHARMA', given: 'RAJESH');
    final m = readPassportMrz('$a\n$b')!;

    test('place of birth, normal order', () {
      final f = readPassportFront(
          'Place of Birth / जन्म स्थान\nNEW DELHI\nPlace of Issue\nDELHI\nDate of Issue\n29/05/2020\n', m);
      expect(f.placeOfBirth, 'New Delhi');
      expect(f.issueDate, DateTime(2020, 5, 29));
    });

    test('place of birth on the same line as its label', () {
      expect(readPassportFront('Place of Birth NEW DELHI\n', m).placeOfBirth, 'New Delhi');
    });

    test('labels listed before their values are never taken as the place', () {
      final f = readPassportFront(
          'Date of Birth\nPlace of Birth\nPlace of Issue\nDate of Issue\n01/01/1990\nNEW DELHI\nDELHI\n29/05/2020\n', m);
      expect(f.placeOfBirth, isNot(contains('Issue')));
      expect(f.placeOfBirth, isNot(contains('Birth')));
    });

    test('an unreadable place of birth is left empty, not another label', () {
      expect(readPassportFront('Place of Birth\nPlace of Issue\nDELHI\nDate of Issue\n29/05/2020\n', m).placeOfBirth,
          isNot(contains('Issue')));
    });

    test('back page: an address line that contains "sex" or "type" is still an address', () {
      final back = readPassportBack('Name of Father\nRAJESH KUMAR\nAddress\n12 ESSEX ROAD\nTYPEWRITER LANE\nFile Number\nDL0012345678901\n');
      expect(back.address, contains('ESSEX ROAD'));
    });
  });
}
