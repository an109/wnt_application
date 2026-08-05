import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';
import '../model/AKHotelSearchInit_model.dart';

abstract class AkHotelSearchInitApiService {
  Future<Response> searchInit(AkHotelSearchInitRequestModel request);
}

class AkHotelSearchInitApiServiceImpl implements AkHotelSearchInitApiService {
  final Dio dio;

  AkHotelSearchInitApiServiceImpl(this.dio);

  @override
  Future<Response> searchInit(AkHotelSearchInitRequestModel request) async {
    try {
      print('CALLING AKBAR HOTEL SEARCH INIT API: ${Urls.akHotelSearchInit}');
      print('Request Body: ${request.toJson()}');

      final response = await dio.post(
        Urls.akHotelSearchInit,
        data: request.toJson(),
      );

      print('Search Init Response Status: ${response.statusCode}');
      print('Search Init Response Data: ${response.data}');

      return response;
    } on DioException catch (e) {
      print('Search Init API Error: ${e.message}');
      print('Search Init API Error Response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('Search Init Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.akHotelSearchInit),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}
