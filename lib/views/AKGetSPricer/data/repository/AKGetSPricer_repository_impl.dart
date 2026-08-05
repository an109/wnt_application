import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/AKGetSPricer_entity.dart';
import '../../domain/repository/AKGetSPricer_repository.dart';
import '../data_source/AKGetSPricer_api_service.dart';
import '../model/AKGetSPricer_model.dart';

class AkGetSPricerRepositoryImpl implements AkGetSPricerRepository {
  final AkGetSPricerApiService apiService;

  AkGetSPricerRepositoryImpl(this.apiService);

  @override
  Future<DataState<AkGetSPricerEntity>> getSPricer(
      AkGetSPricerRequestEntity request) async {
    try {
      final requestModel = AkGetSPricerRequestModel.fromEntity(request);
      final response = await apiService.getSPricer(requestModel);

      if (response.statusCode == 200) {
        final model = AkGetSPricerModel.fromJson(response.data);
        return DataSuccess(model);
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: '/api/akbar/GetSPricer/'),
            response: response,
            type: DioExceptionType.badResponse,
            error: 'Failed to fetch flight price',
          ),
        );
      }
    } on DioException catch (e) {
      print('GetSPricer Repository Error: ${e.message}');
      return DataFailed(e);
    } catch (e) {
      print('GetSPricer Repository Unknown Error: $e');
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: '/api/akbar/GetSPricer/'),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}
