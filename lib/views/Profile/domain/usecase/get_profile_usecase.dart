

import 'package:wander_nova/views/Profile/domain/entities/ProfileEntity.dart';
import 'package:wander_nova/views/Profile/domain/repository/Profile_repository.dart';

import '../../../../core/error/data_state.dart';

class GetProfileUseCase {
  final ProfileRepository repository;

  GetProfileUseCase(this.repository);

  Future<DataState<ProfileEntity>> call() async {
    return await repository.getProfile();
  }
}