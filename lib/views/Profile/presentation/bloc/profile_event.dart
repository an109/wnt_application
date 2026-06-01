import 'package:equatable/equatable.dart';
import '../../domain/entities/ProfileEntity.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class GetProfileEvent extends ProfileEvent {
  const GetProfileEvent();
}

class UpdateProfileEvent extends ProfileEvent {
  final ProfileEntity profile;

  const UpdateProfileEvent(this.profile);

  @override
  List<Object?> get props => [profile];
}

class PatchProfileEvent extends ProfileEvent {
  final ProfileEntity profile;

  const PatchProfileEvent(this.profile);

  @override
  List<Object?> get props => [profile];
}

class UpdateProfileFieldEvent extends ProfileEvent {
  final Map<String, dynamic> fields;

  const UpdateProfileFieldEvent(this.fields);

  @override
  List<Object?> get props => [fields];
}