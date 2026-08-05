import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/akflight_search_entity.dart';
import '../../domain/repository/akflight_Search_repository.dart';
import '../data_source/akflight_Search_api_service.dart';
import '../model/akflight_Search_model.dart';

class AkFlightSearchRepositoryImpl implements AkFlightSearchRepository {
  final AkFlightSearchApiService apiService;

  AkFlightSearchRepositoryImpl(this.apiService);

  @override
  Future<DataState<AkFlightSearchEntity>> searchFlights(
      FlightSearchRequestEntity request) async {
    try {
      final requestModel = FlightSearchRequestModel.fromEntity(request);
      final response = await apiService.searchFlights(requestModel);

      return DataSuccess(response);
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}