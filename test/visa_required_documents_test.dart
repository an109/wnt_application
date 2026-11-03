import 'package:flutter_test/flutter_test.dart';
import 'package:wander_nova/views/Visa_popularDestinaton/data/model/visa_destination_model.dart';
import 'package:wander_nova/views/Visa_popularDestinaton/domain/entities/visa_destination_entity.dart';
import 'package:wander_nova/views/visa/data/visa_form_data.dart';

VisaPopularDestinationModel destination(List<dynamic> docs) =>
    VisaPopularDestinationModel.fromJson({
      'id': 1,
      'name': 'United Arab Emirates',
      'visa_types': <dynamic>[],
      'required_documents': docs,
    });

void main() {
  group('required documents from the dashboard', () {
    test('keep their label, description, required flag and occupation', () {
      final d = destination([
        {'label': 'Passport', 'description': 'Photo page', 'required': true, 'occupation': 'All'},
        {'label': 'Salary Slip', 'required': false, 'occupation': 'Employee'},
      ]);
      expect(d.requiredDocuments.length, 2);
      expect(d.requiredDocuments.first.description, 'Photo page');
      expect(d.requiredDocuments.last.required, isFalse);
      expect(d.requiredDocuments.last.occupation, 'Employee');
      expect(d.requiredDocumentLabels, ['Passport', 'Salary Slip']);
    });

    test('a plain label is a document everyone provides', () {
      final d = destination(['Passport']);
      expect(d.requiredDocuments.single.forEveryone, isTrue);
      expect(d.requiredDocuments.single.required, isTrue);
      expect(d.documentsFor('Student').single.label, 'Passport');
    });

    test('an empty occupation and a blank label are dropped or defaulted', () {
      final d = destination([
        {'label': '  '},
        {'label': 'Passport', 'occupation': ''},
      ]);
      expect(d.requiredDocuments.single.label, 'Passport');
      expect(d.requiredDocuments.single.occupation, 'All');
    });
  });

  group('filtering by occupation', () {
    final d = destination([
      {'label': 'Passport', 'occupation': 'All'},
      {'label': 'Salary Slip', 'occupation': 'Employee'},
      {'label': 'Student ID', 'occupation': 'Student'},
    ]);

    test('shows the shared documents plus the traveller’s own', () {
      expect(d.documentsFor('Employee').map((e) => e.label), ['Passport', 'Salary Slip']);
      expect(d.documentsFor('student').map((e) => e.label), ['Passport', 'Student ID']);
    });

    test('an unknown occupation asks only for the shared ones', () {
      expect(d.documentsFor('').map((e) => e.label), ['Passport']);
      expect(d.documentsFor('Astronaut').map((e) => e.label), ['Passport']);
    });
  });

  group('employment to dashboard occupation', () {
    test('maps every answer the app offers', () {
      expect(visaEmploymentOptions.map(visaOccupationFor).toList(),
          ['Employee', 'Self-Employed', 'Homemaker', 'Student']);
    });

    test('falls back to the typed occupation, and is empty when unknown', () {
      expect(visaOccupationOf(VisaTravellerForm(occupation: 'Student')), 'Student');
      expect(visaOccupationOf(VisaTravellerForm(employment: 'Employed', occupation: 'Student')), 'Employee');
      expect(visaOccupationOf(VisaTravellerForm(occupation: 'Pilot')), '');
    });
  });

  test('a traveller keeps one file per document', () {
    final doc = const VisaRequiredDocument(label: 'Salary Slip', occupation: 'Employee');
    final t = VisaTravellerForm()..documentPaths[doc.key] = '/tmp/slip.pdf';
    final restored = VisaTravellerForm.fromJson(t.toJson());
    expect(restored.documentPaths[doc.key], '/tmp/slip.pdf');
  });
}
