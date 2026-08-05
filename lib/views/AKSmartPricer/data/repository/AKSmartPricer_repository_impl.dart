import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/AKSmartPricer_entity.dart';
import '../../domain/repository/AKSmartPricer_repository.dart';
import '../data_source/AKSmartPricer_api_service.dart';
import '../model/AKSmartPricer_model.dart';

class AkSmartPricerRepositoryImpl implements AkSmartPricerRepository {
  final AkSmartPricerApiService apiService;

  AkSmartPricerRepositoryImpl(this.apiService);

  @override
  Future<DataState<AkSmartPricerEntity>> getSmartPricer(
      AkSmartPricerRequestEntity request) async {
    try {
      final requestModel = AkSmartPricerRequestModel.fromEntity(request);
      final response = await apiService.getSmartPricer(requestModel);

      if (response.statusCode == 200) {
        final model = AkSmartPricerModel.fromJson(response.data);
        return DataSuccess(model);
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: '/api/akbar/SmartPricer/'),
            response: response,
            type: DioExceptionType.badResponse,
            error: 'Failed to fetch smart price',
          ),
        );
      }
    } on DioException catch (e) {
      print('SmartPricer Repository Error: ${e.message}');
      return DataFailed(e);
    } catch (e) {
      print('SmartPricer Repository Unknown Error: $e');
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: '/api/akbar/SmartPricer/'),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}
