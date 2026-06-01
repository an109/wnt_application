import 'package:dio/dio.dart';
import 'package:wander_nova/views/Profile/data/model/Profile_model.dart';
import 'package:wander_nova/views/Profile/domain/entities/ProfileEntity.dart';
import 'package:wander_nova/views/Profile/data/data_source/Profile_api_service.dart';
import 'package:wander_nova/views/Profile/domain/repository/Profile_repository.dart';
import '../../../../core/error/data_state.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileApiService apiService;

  ProfileRepositoryImpl(this.apiService);

  @override
  Future<DataState<ProfileEntity>> getProfile() async {
    try {
      final response = await apiService.getProfile();

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;

        if (data is Map<String, dynamic> && data['success'] == true) {
          final profileData = data['profile'] as Map<String, dynamic>;
          final profileModel = ProfileModel.fromJson(profileData);
          final profileEntity = _mapToEntity(profileModel);

          return DataSuccess(profileEntity);
        }
      }

      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: 'getProfile'),
          error: 'Invalid response format',
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: RequestOptions(path: 'getProfile')),
        ),
      );
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: 'getProfile'),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  @override
  Future<DataState<ProfileEntity>> updateProfile(ProfileEntity profile) async {
    try {
      final profileModel = _mapToModel(profile);
      final updateData = profileModel.toUpdateJson();

      final response = await apiService.updateProfile(updateData);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;

        if (data is Map<String, dynamic> && data['success'] == true) {
          final profileData = data['profile'] as Map<String, dynamic>;
          final updatedProfileModel = ProfileModel.fromJson(profileData);
          final updatedProfileEntity = _mapToEntity(updatedProfileModel);

          return DataSuccess(updatedProfileEntity);
        }
      }

      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: 'updateProfile'),
          error: 'Invalid response format',
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: RequestOptions(path: 'updateProfile')),
        ),
      );
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: 'updateProfile'),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  @override
  Future<DataState<ProfileEntity>> patchProfile(ProfileEntity profile) async {
    try {
      final profileModel = _mapToModel(profile);
      final updateData = profileModel.toUpdateJson();

      final response = await apiService.patchProfile(updateData);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;

        if (data is Map<String, dynamic> && data['success'] == true) {
          final profileData = data['profile'] as Map<String, dynamic>;
          final patchedProfileModel = ProfileModel.fromJson(profileData);
          final patchedProfileEntity = _mapToEntity(patchedProfileModel);

          return DataSuccess(patchedProfileEntity);
        }
      }

      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: 'patchProfile'),
          error: 'Invalid response format',
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: RequestOptions(path: 'patchProfile')),
        ),
      );
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: 'patchProfile'),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  ProfileEntity _mapToEntity(ProfileModel model) {
    return ProfileEntity(
      id: model.id,
      title: model.title,
      firstName: model.firstName,
      lastName: model.lastName,
      email: model.email,
      phoneCode: model.phoneCode,
      phoneNumber: model.phoneNumber,
      dob: model.dob,
      address: model.address,
      city: model.city,
      state: model.state,
      country: model.country,
      pinCode: model.pinCode,
      platform: model.platform,
      newsletter: model.newsletter,
      smsAlerts: model.smsAlerts,
      created: model.created,
      updated: model.updated,
    );
  }

  ProfileModel _mapToModel(ProfileEntity entity) {
    return ProfileModel(
      id: entity.id,
      title: entity.title,
      firstName: entity.firstName,
      lastName: entity.lastName,
      email: entity.email,
      phoneCode: entity.phoneCode,
      phoneNumber: entity.phoneNumber,
      dob: entity.dob,
      address: entity.address,
      city: entity.city,
      state: entity.state,
      country: entity.country,
      pinCode: entity.pinCode,
      platform: entity.platform,
      newsletter: entity.newsletter,
      smsAlerts: entity.smsAlerts,
      created: entity.created,
      updated: entity.updated,
    );
  }
}