import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/AKFlightInfo_entity.dart';
import '../../domain/repository/AKFlightInfo_repository.dart';
import '../data_source/AKFlightInfo_api_service.dart';
import '../model/AKFlightInfo_model.dart';

class AkFlightInfoRepositoryImpl implements AkFlightInfoRepository {
  final AkFlightInfoApiService apiService;

  AkFlightInfoRepositoryImpl(this.apiService);

  @override
  Future<DataState<AkFlightInfoEntity>> getFlightInfo(
      AkFlightInfoRequestEntity request) async {
    try {
      final requestModel = AkFlightInfoRequestModel.fromEntity(request);
      final response = await apiService.getFlightInfo(requestModel);

      if (response.statusCode == 200) {
        final flightInfoModel = AkFlightInfoModel.fromJson(response.data);
        return DataSuccess(flightInfoModel);
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: '/api/akbar/FlightInfo/'),
            response: response,
            type: DioExceptionType.badResponse,
            error: 'Failed to fetch flight info',
          ),
        );
      }
    } on DioException catch (e) {
      print('FlightInfo Repository Error: ${e.message}');
      return DataFailed(e);
    } catch (e) {
      print('FlightInfo Repository Unknown Error: $e');
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: '/api/akbar/FlightInfo/'),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}
