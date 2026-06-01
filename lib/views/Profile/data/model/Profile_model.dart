import 'dart:convert';

class ProfileModel {
  final int id;
  final String title;
  final String firstName;
  final String lastName;
  final String? email;
  final String phoneCode;
  final String phoneNumber;
  final String? dob;
  final String address;
  final String city;
  final String state;
  final String country;
  final String pinCode;
  final String platform;
  final bool newsletter;
  final bool smsAlerts;
  final DateTime created;
  final DateTime updated;

  ProfileModel({
    required this.id,
    required this.title,
    required this.firstName,
    required this.lastName,
    this.email,
    required this.phoneCode,
    required this.phoneNumber,
    this.dob,
    required this.address,
    required this.city,
    required this.state,
    required this.country,
    required this.pinCode,
    required this.platform,
    required this.newsletter,
    required this.smsAlerts,
    required this.created,
    required this.updated,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'],
      phoneCode: json['phoneCode'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      dob: json['dob'],
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
      pinCode: json['pinCode'] ?? '',
      platform: json['platform'] ?? '',
      newsletter: json['newsletter'] ?? false,
      smsAlerts: json['smsAlerts'] ?? false,
      created: json['created'] != null
          ? DateTime.parse(json['created'])
          : DateTime.now(),
      updated: json['updated'] != null
          ? DateTime.parse(json['updated'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneCode': phoneCode,
      'phoneNumber': phoneNumber,
      'dob': dob,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'pinCode': pinCode,
      'platform': platform,
      'newsletter': newsletter,
      'smsAlerts': smsAlerts,
      'created': created.toIso8601String(),
      'updated': updated.toIso8601String(),
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'title': title,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneCode': phoneCode,
      'phoneNumber': phoneNumber,
      'dob': dob,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'pinCode': pinCode,
      'newsletter': newsletter,
      'smsAlerts': smsAlerts,
    };
  }

  ProfileModel copyWith({
    int? id,
    String? title,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneCode,
    String? phoneNumber,
    String? dob,
    String? address,
    String? city,
    String? state,
    String? country,
    String? pinCode,
    String? platform,
    bool? newsletter,
    bool? smsAlerts,
    DateTime? created,
    DateTime? updated,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      title: title ?? this.title,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneCode: phoneCode ?? this.phoneCode,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dob: dob ?? this.dob,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      pinCode: pinCode ?? this.pinCode,
      platform: platform ?? this.platform,
      newsletter: newsletter ?? this.newsletter,
      smsAlerts: smsAlerts ?? this.smsAlerts,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }
}