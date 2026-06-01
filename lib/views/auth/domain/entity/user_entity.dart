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
    // Check if tokens exist at root level or inside 'tokens' object
    Map<String, dynamic>? tokens;

    if (json['tokens'] != null) {
      tokens = json['tokens'] as Map<String, dynamic>?;
    } else if (json['access'] != null) {
      // Tokens are at root level
      tokens = {
        'access': json['access'],
        'refresh': json['refresh'],
      };
    }

    return UserEntity(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      name: json['name'],
      firstname: json['firstname'],
      lastname: json['lastname'],
      accessToken: tokens?['access'] ?? json['access_token'] ?? json['token'],
      refreshToken: tokens?['refresh'] ?? json['refresh_token'],
      userType: json['type']?.toString() ?? json['user_type'],
      platform: json['platform'],
      isloggedin: json['isloggedin'],
    );
  }

  // factory UserEntity.fromJson(Map<String, dynamic> json) {
  //   final tokens = json['tokens'] as Map<String, dynamic>?;
  //   return UserEntity(
  //     id: json['id']?.toString() ?? '',
  //     email: json['email'] ?? '',
  //     name: json['name'],
  //     firstname: json['firstname'],
  //     lastname: json['lastname'],
  //     accessToken: tokens?['access'],
  //     refreshToken: json['refresh'],
  //     userType: json['type']?.toString() ?? json['user_type'],
  //     platform: json['platform'],
  //     isloggedin: json['isloggedin'],
  //   );
  // }

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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'firstname': firstname,
      'lastname': lastname,
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'user_type': userType,
      'platform': platform,
      'isloggedin': isloggedin,
    };
  }
}