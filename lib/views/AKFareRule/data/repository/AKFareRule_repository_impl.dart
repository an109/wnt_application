import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/AKFareRule_entity.dart';
import '../../domain/repository/AKFareRule_repository.dart';
import '../data_source/AKFareRule_api_service.dart';
import '../model/AKFareRule_model.dart';

class AkFareRuleRepositoryImpl implements AkFareRuleRepository {
  final AkFareRuleApiService apiService;

  AkFareRuleRepositoryImpl(this.apiService);

  @override
  Future<DataState<AkFareRuleEntity>> getFareRule(AkFareRuleRequestEntity request) async {
    try {
      final requestModel = AkFareRuleRequestModel.fromEntity(request);
      final response = await apiService.getFareRule(requestModel);

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final model = AkFareRuleModel.fromJson(response.data as Map<String, dynamic>);
        return DataSuccess(model);
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: '/api/akbar/FareRule/'),
            response: response,
            type: DioExceptionType.badResponse,
            error: 'Failed to fetch fare rules',
          ),
        );
      }
    } on DioException catch (e) {
      print('FareRule Repository Error: ${e.message}');
      return DataFailed(e);
    } catch (e) {
      print('FareRule Repository Unknown Error: $e');
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: '/api/akbar/FareRule/'),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}
