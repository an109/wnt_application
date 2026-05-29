enum ContactType {
  email,
  phone,
}

extension ContactTypeExtension on ContactType {
  String get label {
    switch (this) {
      case ContactType.email:
        return 'Email';
      case ContactType.phone:
        return 'Phone';
    }
  }

  String get fieldName {
    switch (this) {
      case ContactType.email:
        return 'email';
      case ContactType.phone:
        return 'phone';
    }
  }
}