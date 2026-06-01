

import 'package:wander_nova/core/error/data_state.dart';
import 'package:wander_nova/views/Profile/domain/entities/ProfileEntity.dart';
import 'package:wander_nova/views/Profile/domain/repository/Profile_repository.dart';

class PatchProfileUseCase {
  final ProfileRepository repository;

  PatchProfileUseCase(this.repository);

  Future<DataState<ProfileEntity>> call(ProfileEntity profile) async {
    return await repository.patchProfile(profile);
  }
}