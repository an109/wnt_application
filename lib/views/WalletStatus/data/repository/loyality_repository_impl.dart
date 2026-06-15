import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/loyality_entity.dart';
import '../../domain/repository/loyality_repository.dart';
import '../data_source/loyality_api_service.dart';
import '../model/loyality_model.dart';

class LoyaltyRepositoryImpl implements LoyaltyRepository {
  final LoyaltyApiService _apiService;

  LoyaltyRepositoryImpl(this._apiService);

  @override
  Future<DataState<LoyaltyEntity>> getUserLoyalty() async {
    try {
      final response = await _apiService.getUserLoyalty();

      if (response.statusCode == 200) {
        final loyaltyModel = LoyaltyModel.fromJson(response.data);
        return DataSuccess(loyaltyModel);
      } else {
        return DataFailed(
          DioException(
            error: 'Failed to load loyalty data',
            response: response,
            type: DioExceptionType.badResponse,
            requestOptions: response.requestOptions,
          ),
        );
      }
    } on DioException catch (e) {
      return DataFailed(e);
    }
  }
}