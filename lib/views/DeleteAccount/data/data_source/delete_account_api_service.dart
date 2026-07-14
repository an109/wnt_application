import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';

abstract class DeleteAccountApiService {
  Future<Response> deleteAccount({required String token, String? password});
}

class DeleteAccountApiServiceImpl implements DeleteAccountApiService {
  final Dio dio;

  DeleteAccountApiServiceImpl(this.dio);

  @override
  Future<Response> deleteAccount({required String token, String? password}) async {
    try {
      final data = <String, dynamic>{'token': token};
      if (password != null && password.isNotEmpty) {
        data['password'] = password;
      }

      print('CALLING DELETE ACCOUNT API: ${Urls.deleteAccount}');

      final response = await dio.post(Urls.deleteAccount, data: data);

      print('DELETE ACCOUNT RESPONSE STATUS: ${response.statusCode}');
      print('DELETE ACCOUNT RESPONSE DATA: ${response.data}');

      return response;
    } on DioException catch (e) {
      print('API Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.deleteAccount),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}
