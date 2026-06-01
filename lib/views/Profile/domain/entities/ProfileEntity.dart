import 'package:equatable/equatable.dart';

class ProfileEntity extends Equatable {
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

  const ProfileEntity({
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

  ProfileEntity copyWith({
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
    return ProfileEntity(
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

  @override
  List<Object?> get props => [
    id,
    title,
    firstName,
    lastName,
    email,
    phoneCode,
    phoneNumber,
    dob,
    address,
    city,
    state,
    country,
    pinCode,
    platform,
    newsletter,
    smsAlerts,
    created,
    updated,
  ];
}