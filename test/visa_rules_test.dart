import 'package:flutter_test/flutter_test.dart';
import 'package:wander_nova/views/Visa_popularDestinaton/domain/entities/visa_destination_entity.dart';
import 'package:wander_nova/views/visa/data/visa_passport_reader.dart';
import 'package:wander_nova/views/visa/presentation/utils/visa_countries.dart';
import 'package:wander_nova/views/visa/presentation/utils/visa_rules.dart';
import 'package:wander_nova/views/visa/presentation/widgets/visa_checkout_sheets.dart';

VisaTypeEntity _type(String title, {num fee = 100, String processing = '', String category = ''}) =>
    VisaTypeEntity(
      stay: '30 Days',
      entry: 'Single',
      title: title,
      taxInr: 0,
      feesInr: fee,
      popular: false,
      validity: '60 days',
      processing: processing,
      taxCurrency: 'INR',
      feesCurrency: 'USD',
      category: category,
    );

VisaPopularDestinationEntity _dest(String name, String region) => VisaPopularDestinationEntity(
      id: 1,
      reseller: 1,
      name: name,
      region: region,
      price: '0',
      priceCurrency: 'USD',
      processingTime: '',
      imageUrl: '',
      visaTypes: const [],
      requirementsItems: const [],
      priceIncludesItems: const [],
      showInPopular: true,
      isActive: true,
    );

void main() {
  group('VisaProcessing.parse', () {
    test('uses the upper bound of ranges', () {
      expect(VisaProcessing.parse('48-96 Hours')!.duration, const Duration(hours: 96));
      expect(VisaProcessing.parse('6 Weeks- 10 Weeks')!.duration, const Duration(days: 70));
      expect(VisaProcessing.parse('48 Hours - 4 Weeks')!.duration, const Duration(days: 28));
    });
    test('reads minutes, working days and instant', () {
      expect(VisaProcessing.parse('60 Minutes')!.duration, const Duration(minutes: 60));
      final p = VisaProcessing.parse('Upto 5 Working Days')!;
      expect(p.duration, const Duration(days: 5));
      expect(p.workingDays, isTrue);
      expect(VisaProcessing.parse('Instant')!.duration, Duration.zero);
    });
    test('returns null for text without a duration', () {
      expect(VisaProcessing.parse('Schengen'), isNull);
      expect(VisaProcessing.parse(''), isNull);
    });
    test('working days skip weekends', () {
      // Friday + 1 working day = Monday.
      final friday = DateTime(2026, 10, 9, 10);
      expect(VisaProcessing.parse('1 Working Day')!.guaranteedFrom(friday), DateTime(2026, 10, 12, 10));
    });
    test('humanized', () {
      expect(VisaProcessing.parse('24 Hours')!.humanized, '1 day');
      expect(VisaProcessing.parse('3 Weeks')!.humanized, '21 days');
      expect(VisaProcessing.parse('6 Hours')!.humanized, '6 hours');
    });
  });

  group('visa kind', () {
    test('classifies titles from live data', () {
      expect(_type('Turkey E visa').statedKind, VisaKind.eVisa);
      expect(_type('Standard E- visa').statedKind, VisaKind.eVisa);
      expect(_type('Kenya ETA').statedKind, VisaKind.eVisa);
      expect(_type('Indonesia E - VOA').statedKind, VisaKind.onArrival);
      expect(_type('Turkey Sticker Visa- Tourism & Business').statedKind, VisaKind.sticker);
      expect(_type('Germany Tourist Visa').statedKind, isNull);
      expect(_type('Lakshadeep Entry Permit', fee: 0).statedKind, VisaKind.visaFree);
    });
    test('admin category wins', () {
      expect(_type('Germany Tourist Visa', category: 'e_visa').statedKind, VisaKind.eVisa);
    });
    test('"beta" is not an ETA', () {
      expect(_type('Beta Tourist Visa').statedKind, isNull);
    });
    test('destination decides when the title does not', () {
      expect(_dest('United Arab Emirates', 'Middle East').kindOf(_type('30 Days Single Entry Visa')), VisaKind.eVisa);
      expect(_dest('Germany', 'Schengen').kindOf(_type('Germany Tourist Visa')), VisaKind.sticker);
      expect(_dest('United States of America', 'North America').kindOf(_type('B2 - Tourist Visa')), VisaKind.sticker);
      expect(_dest('Turkey', 'Europe').kindOf(_type('Turkey E visa')), VisaKind.eVisa);
    });
  });

  group('country codes', () {
    test('maps backend names', () {
      expect(visaCountryCode('United States of America'), 'US');
      expect(visaCountryCode('South Korea/ Republic of Korea'), 'KR');
      expect(visaCountryCode('Côte d’Ivoire ( Ivory Coast )'), 'CI');
      expect(visaCountryCode('Eswatini (Swasiland)'), 'SZ');
      expect(visaCountryCode('Ukraine'), 'UA');
      expect(visaCountryCode('Lakshadeep'), 'IN');
      expect(visaCountryCode('Atlantis'), isNull);
    });
  });

  test('validity days', () {
    expect(visaValidityDays('60 days'), 60);
    expect(visaValidityDays('1 Year'), 365);
    expect(visaValidityDays('3 months- 1 year'), 90);
    expect(visaValidityDays(''), 30);
  });

  group('passport MRZ', () {
    // ICAO 9303 specimen.
    const l1 = 'P<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<<<<<<<<<';
    const l2 = 'L898902C36UTO7408122F1204159ZE184226B<<<<<10';

    test('reads a valid MRZ out of noisy OCR text', () {
      final mrz = readPassportMrz('REPUBLIC OF UTOPIA\nPassport\n$l1\nL898902C3 6UTO7408122F12O4159ZE184226B«««<<10\n');
      expect(mrz, isNotNull);
      expect(mrz!.surname, 'ERIKSSON');
      expect(mrz.givenNames, 'ANNA MARIA');
      expect(mrz.passportNumber, 'L898902C3');
      expect(mrz.dob, DateTime(1974, 8, 12));
      expect(mrz.expiry, DateTime(2012, 4, 15));
      expect(mrz.gender, 'Female');
    });
    test('rejects edited data', () {
      expect(readPassportMrz('$l1\n${l2.replaceFirst('L898902C3', 'L898902C4')}'), isNull);
      expect(readPassportMrz('$l1\n${l2.replaceFirst('740812', '740813')}'), isNull);
      expect(readPassportMrz('no passport here'), isNull);
    });
    test('reads the back page of an Indian passport', () {
      final back = readPassportBack('''
Name of Father / Legal Guardian
MUSSA YUSUF SHAIKH
Name of Mother
KEHMA MUSSA SHAIKH
Name of Spouse
Address
101/88,A WING,SATYAM APARTMENT,SECTOR 19
KHARGHAR,NAVI MUMBAI
Old Passport No. with Date and Place of Issue
R5865131 12/03/2012 MUMBAI
File No.
TH2068835409215
''');
      expect(back.fatherName, 'Mussa Yusuf Shaikh');
      expect(back.motherName, 'Kehma Mussa Shaikh');
      expect(back.oldPassportNumber, 'R5865131');
      expect(back.fileNumber, 'TH2068835409215');
      expect(back.looksValid, isTrue);
      expect(readPassportBack('random text').looksValid, isFalse);
    });
  });

  group('passport MRZ from real phone OCR', () {
    // A valid Indian passport MRZ (check digits computed, not hard-coded).
    String line2() {
      const number = 'P3114819<';
      const dob = '980922';
      const exp = '340921';
      const personal = '<<<<<<<<<<<<<<';
      final a = '$number${mrzCheckDigit(number)}IND$dob${mrzCheckDigit(dob)}F$exp${mrzCheckDigit(exp)}$personal';
      final pc = '0';
      final comp = '$number${mrzCheckDigit(number)}$dob${mrzCheckDigit(dob)}$exp${mrzCheckDigit(exp)}$personal$pc';
      return '$a<${mrzCheckDigit(comp)}';
    }
    const l1 = 'P<INDSINGH<<ANJLI<<<<<<<<<<<<<<<<<<<<<<<<<<<';

    test('clean MRZ is fully verified', () {
      final m = readPassportMrz('REPUBLIC OF INDIA\n$l1\n${line2()}')!;
      expect(m.passportNumber, 'P3114819');
      expect(m.surname, 'SINGH');
      expect(m.givenNames, 'ANJLI');
      expect(m.nationality, 'IND');
      expect(m.dob, DateTime(1998, 9, 22));
      expect(m.expiry, DateTime(2034, 9, 21));
      expect(m.gender, 'Female');
      expect(m.fullyVerified, isTrue);
    });

    test('K for <, O for 0, spaces and a split line still read', () {
      final noisy2 = line2().replaceAll('<<<<<<<<<<<<<<', 'KK<KKKK<<KKK<K').replaceFirst('980922', '98O922');
      final split = '${noisy2.substring(0, 20)} \n${noisy2.substring(20)}';
      final noisy1 = 'PKINDSINGH<<ANJLI<<<<KKKKK<<<<<<<KKKK<<<<<<';
      final m = readPassportMrz('Passport\n$noisy1\n$split')!;
      expect(m.passportNumber, 'P3114819');
      expect(m.dob, DateTime(1998, 9, 22));
      expect(m.surname, 'SINGH');
      expect(m.fullyVerified, isTrue);
    });

    test('a letter read for a digit in the number is repaired by both check digits', () {
      // 'P3114819' read as 'P311481S'… use a number whose OCR slip is S for 5.
      const number = 'K5123456<';
      const dob = '980922', exp = '340921', personal = '<<<<<<<<<<<<<<';
      final head = '$number${mrzCheckDigit(number)}';
      final comp = '$head$dob${mrzCheckDigit(dob)}$exp${mrzCheckDigit(exp)}${personal}0';
      final good = '${head}IND$dob${mrzCheckDigit(dob)}F$exp${mrzCheckDigit(exp)}$personal<${mrzCheckDigit(comp)}';
      final m = readPassportMrz('$l1\n${good.replaceFirst('K5123456', 'KS123456')}');
      expect(m?.passportNumber, 'K5123456');
      expect(m?.fullyVerified, isTrue);
    });

    test('names fall back to the printed labels when line 1 is unreadable', () {
      final m = readPassportMrz('Surname\nSINGH\nGiven Name(s)\nANJLI\n${line2()}')!;
      expect(m.surname, 'SINGH');
      expect(m.givenNames, 'ANJLI');
      expect(m.line1.startsWith('P<IND'), isTrue);
    });

    test('a broken date check is still rejected', () {
      expect(readPassportMrz('$l1\n${line2().replaceFirst('980922', '980923')}'), isNull);
    });
  });
}
