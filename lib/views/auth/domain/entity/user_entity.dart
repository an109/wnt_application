import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String? name;
  final String? firstname;
  final String? lastname;
  final String? accessToken;
  final String? refreshToken;
  final String? userType;
  final String? platform;
  final bool? isloggedin;

  const UserEntity({
    required this.id,
    required this.email,
    this.name,
    this.firstname,
    this.lastname,
    this.accessToken,
    this.refreshToken,
    this.userType,
    this.platform,
    this.isloggedin,
  });

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      name: json['name'],
      firstname: json['firstname'],
      lastname: json['lastname'],
      accessToken: json['access_token'] ?? json['token'],
      refreshToken: json['refresh_token'],
      userType: json['type']?.toString() ?? json['user_type'],
      platform: json['platform'],
      isloggedin: json['isloggedin'],
    );
  }

  @override
  List<Object?> get props => [
    id,
    email,
    name,
    firstname,
    lastname,
    accessToken,
    refreshToken,
    userType,
    platform,
    isloggedin,
  ];
}