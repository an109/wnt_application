/// One traveller on a holiday booking.
///
/// The DIY API takes only a lead name/phone/email on the enquiry, so this is
/// collected for the booking record the app saves through
/// `Urls.holidayBookings` and for the consultant's reference. It maps onto the
/// same field names the existing saved-travellers endpoint (`Urls.travellers`)
/// uses, so a traveller picked from "Select From List" and one typed fresh are
/// the same shape.
class DiyTraveller {
  final String title;
  final String firstName;
  final String lastName;

  /// ISO `yyyy-MM-dd`, or empty when not collected.
  final String dob;
  final String gender;
  final String phone;

  /// 'Adult' or 'Child' — mirrors the saved-traveller `paxType`.
  final String paxType;

  const DiyTraveller({
    this.title = '',
    this.firstName = '',
    this.lastName = '',
    this.dob = '',
    this.gender = '',
    this.phone = '',
    this.paxType = 'Adult',
  });

  bool get isChild => paxType.toLowerCase() == 'child';

  String get fullName => [firstName, lastName]
      .where((p) => p.trim().isNotEmpty)
      .join(' ')
      .trim();

  bool get isComplete => firstName.trim().isNotEmpty && lastName.trim().isNotEmpty;

  /// Whole years between [dob] and today; null when no usable date of birth.
  int? get age {
    final born = DateTime.tryParse(dob);
    if (born == null) return null;
    final now = DateTime.now();
    var years = now.year - born.year;
    final hadBirthday = now.month > born.month ||
        (now.month == born.month && now.day >= born.day);
    if (!hadBirthday) years--;
    return years < 0 ? null : years;
  }

  DiyTraveller copyWith({
    String? title,
    String? firstName,
    String? lastName,
    String? dob,
    String? gender,
    String? phone,
    String? paxType,
  }) {
    return DiyTraveller(
      title: title ?? this.title,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      paxType: paxType ?? this.paxType,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'firstName': firstName,
        'lastName': lastName,
        'dob': dob,
        'gender': gender,
        'phone': phone,
        'paxType': paxType,
      };

  /// The booking API's shape — POST /trips/{id}/book/ `travellers[]`.
  Map<String, dynamic> toBookingJson() => {
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        'gender': gender,
        if (dob.isNotEmpty) 'dob': dob,
        'pax_type': isChild ? 'Child' : 'Adult',
        'phone': phone,
      };

  /// Reads both the saved-traveller shape (camelCase, as
  /// `Urls.travellers` returns) and a plain snake_case row.
  factory DiyTraveller.fromJson(Map<String, dynamic> j) {
    String pick(List<String> keys) {
      for (final k in keys) {
        final v = j[k];
        if (v != null && v.toString().trim().isNotEmpty) return v.toString();
      }
      return '';
    }

    return DiyTraveller(
      title: pick(['title']),
      firstName: pick(['firstName', 'first_name']),
      lastName: pick(['lastName', 'last_name']),
      dob: pick(['dob', 'date_of_birth']),
      gender: pick(['gender']),
      phone: pick(['phone', 'mobile', 'contact']),
      paxType: pick(['paxType', 'pax_type']).isEmpty
          ? 'Adult'
          : pick(['paxType', 'pax_type']),
    );
  }
}
