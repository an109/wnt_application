import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';
import '../model/AKTravelCheckList_model.dart';

abstract class AkTravelCheckListApiService {
  Future<Response> getTravelCheckList(AkTravelCheckListRequestModel request);
}

class AkTravelCheckListApiServiceImpl implements AkTravelCheckListApiService {
  final Dio dio;

  AkTravelCheckListApiServiceImpl(this.dio);

  @override
  Future<Response> getTravelCheckList(AkTravelCheckListRequestModel request) async {
    try {
      print('CALLING GETTRAVELCHECKLIST API: ${Urls.getTravelCheckList}');
      print('Request Body: ${request.toJson()}');

      final response = await dio.post(
        Urls.getTravelCheckList,
        data: request.toJson(),
      );

      print('GetTravelCheckList Response Status: ${response.statusCode}');
      print('GetTravelCheckList Response Data: ${response.data}');

      return response;
    } on DioException catch (e) {
      print('GetTravelCheckList API Error: ${e.message}');
      print('GetTravelCheckList API Error Response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('GetTravelCheckList Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.getTravelCheckList),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}
