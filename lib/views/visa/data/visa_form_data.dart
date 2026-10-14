/// Form state of the visa application (Figma "free Applica…"). Serialised
/// for drafts and mapped onto the backend `extraDetails` fields.
class VisaTravellerForm {
  String firstName;
  String lastName;
  String passportNo;
  String passportFrom;
  DateTime? passportIssued;
  DateTime? passportExpiry;
  DateTime? dob;
  String placeOfBirth;
  String gender;
  String occupation;
  /// Employed | Self Employed | Not Working | Student.
  String employment;
  /// Local path of the passport photo page the user attached.
  String? passportScanPath;
  // Cost-visa flow (selfie + passport scan).
  String fatherName;
  String motherName;
  String oldPassportNo;
  String? selfiePath;
  String? passportBackPath;
  /// Verified MRZ of the scanned passport; the backend re-checks it.
  String mrzLine1;
  String mrzLine2;

  bool get passportVerified => mrzLine1.isNotEmpty && mrzLine2.isNotEmpty;

  VisaTravellerForm({
    this.firstName = '',
    this.lastName = '',
    this.passportNo = '',
    this.passportFrom = 'India',
    this.passportIssued,
    this.passportExpiry,
    this.dob,
    this.placeOfBirth = '',
    this.gender = '',
    this.occupation = '',
    this.employment = '',
    this.passportScanPath,
    this.fatherName = '',
    this.motherName = '',
    this.oldPassportNo = '',
    this.selfiePath,
    this.passportBackPath,
    this.mrzLine1 = '',
    this.mrzLine2 = '',
  });

  String get initials {
    final a = firstName.trim().isEmpty ? '' : firstName.trim()[0];
    final b = lastName.trim().isEmpty ? '' : lastName.trim()[0];
    final s = '$a$b'.toUpperCase();
    return s.isEmpty ? '?' : s;
  }

  /// Backend title derived from gender; the form has no title field.
  String get title => gender == 'Female' ? 'Ms' : 'Mr';

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'passportNo': passportNo,
        'passportFrom': passportFrom,
        'passportIssued': passportIssued?.toIso8601String(),
        'passportExpiry': passportExpiry?.toIso8601String(),
        'dob': dob?.toIso8601String(),
        'placeOfBirth': placeOfBirth,
        'gender': gender,
        'occupation': occupation,
        'employment': employment,
        'passportScanPath': passportScanPath,
        'fatherName': fatherName,
        'motherName': motherName,
        'oldPassportNo': oldPassportNo,
        'selfiePath': selfiePath,
        'passportBackPath': passportBackPath,
        'mrzLine1': mrzLine1,
        'mrzLine2': mrzLine2,
      };

  factory VisaTravellerForm.fromJson(Map<String, dynamic> j) => VisaTravellerForm(
        firstName: j['firstName'] ?? '',
        lastName: j['lastName'] ?? '',
        passportNo: j['passportNo'] ?? '',
        passportFrom: j['passportFrom'] ?? 'India',
        passportIssued: DateTime.tryParse(j['passportIssued'] ?? ''),
        passportExpiry: DateTime.tryParse(j['passportExpiry'] ?? ''),
        dob: DateTime.tryParse(j['dob'] ?? ''),
        placeOfBirth: j['placeOfBirth'] ?? '',
        gender: j['gender'] ?? '',
        occupation: j['occupation'] ?? '',
        employment: j['employment'] ?? '',
        passportScanPath: j['passportScanPath'],
        fatherName: j['fatherName'] ?? '',
        motherName: j['motherName'] ?? '',
        oldPassportNo: j['oldPassportNo'] ?? '',
        selfiePath: j['selfiePath'],
        passportBackPath: j['passportBackPath'],
        mrzLine1: j['mrzLine1'] ?? '',
        mrzLine2: j['mrzLine2'] ?? '',
      );
}

/// Trip details shared by every traveller on the application.
class VisaTripForm {
  String arrivalFlight;
  DateTime? arrivalDate;
  String hotel;
  DateTime? departureDate;
  String departureFlight;
  String location;
  String email;
  String phone;

  VisaTripForm({
    this.arrivalFlight = '',
    this.arrivalDate,
    this.hotel = '',
    this.departureDate,
    this.departureFlight = '',
    this.location = '',
    this.email = '',
    this.phone = '',
  });

  Map<String, dynamic> toJson() => {
        'arrivalFlight': arrivalFlight,
        'arrivalDate': arrivalDate?.toIso8601String(),
        'hotel': hotel,
        'departureDate': departureDate?.toIso8601String(),
        'departureFlight': departureFlight,
        'location': location,
        'email': email,
        'phone': phone,
      };

  factory VisaTripForm.fromJson(Map<String, dynamic> j) => VisaTripForm(
        arrivalFlight: j['arrivalFlight'] ?? '',
        arrivalDate: DateTime.tryParse(j['arrivalDate'] ?? ''),
        hotel: j['hotel'] ?? '',
        departureDate: DateTime.tryParse(j['departureDate'] ?? ''),
        departureFlight: j['departureFlight'] ?? '',
        location: j['location'] ?? '',
        email: j['email'] ?? '',
        phone: j['phone'] ?? '',
      );
}
