import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';

abstract class ProfileApiService {
  Future<Response> getProfile();
  Future<Response> updateProfile(Map<String, dynamic> profileData);
  Future<Response> patchProfile(Map<String, dynamic> profileData);
}

class ProfileApiServiceImpl implements ProfileApiService {
  final Dio dio;

  ProfileApiServiceImpl(this.dio);

  @override
  Future<Response> getProfile() async {
    try {
      print('CALLING GET PROFILE API: ${Urls.userProfile}');

      final response = await dio.get(Urls.userProfile);

      print('GET PROFILE RESPONSE: ${response.data}');
      return response;
    } on DioException catch (e) {
      print('GET PROFILE API Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('GET PROFILE Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.userProfile),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }

  @override
  Future<Response> updateProfile(Map<String, dynamic> profileData) async {
    try {
      print('CALLING PUT PROFILE API: ${Urls.updateUserProfile}');
      print('REQUEST DATA: $profileData');

      final response = await dio.put(
        Urls.updateUserProfile,
        data: profileData,
      );

      print('PUT PROFILE RESPONSE: ${response.data}');
      return response;
    } on DioException catch (e) {
      print('PUT PROFILE API Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('PUT PROFILE Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.updateUserProfile),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }

  @override
  Future<Response> patchProfile(Map<String, dynamic> profileData) async {
    try {
      print('CALLING PATCH PROFILE API: ${Urls.updateUserProfile}');
      print('REQUEST DATA: $profileData');

      final response = await dio.patch(
        Urls.updateUserProfile,
        data: profileData,
      );

      print('PATCH PROFILE RESPONSE: ${response.data}');
      return response;
    } on DioException catch (e) {
      print('PATCH PROFILE API Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('PATCH PROFILE Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.updateUserProfile),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}