import '../../../../core/error/data_state.dart';
import '../entities/ProfileEntity.dart';


abstract class ProfileRepository {
  Future<DataState<ProfileEntity>> getProfile();
  Future<DataState<ProfileEntity>> updateProfile(ProfileEntity profile);
  Future<DataState<ProfileEntity>> patchProfile(ProfileEntity profile);
}