class AppleAuthRequestModel {
  final String token;
  final String? firstName;
  final String? lastName;
  final String? email;

  AppleAuthRequestModel({
    required this.token,
    this.firstName,
    this.lastName,
    this.email,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {'token': token};

    final bool hasName =
        (firstName != null && firstName!.isNotEmpty) ||
        (lastName != null && lastName!.isNotEmpty);
    final bool hasEmail = email != null && email!.isNotEmpty;

    // Apple only sends name/email on first authorization — forward them so the
    // backend can create the account with a real name.
    if (hasName || hasEmail) {
      final Map<String, dynamic> user = {};
      if (hasName) {
        user['name'] = {
          if (firstName != null && firstName!.isNotEmpty) 'firstName': firstName,
          if (lastName != null && lastName!.isNotEmpty) 'lastName': lastName,
        };
      }
      if (hasEmail) {
        user['email'] = email;
      }
      data['user'] = user;
    }

    return data;
  }
}
