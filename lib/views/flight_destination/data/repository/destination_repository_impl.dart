import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/repository/destination_repository.dart';
import '../data_source/destination_api_service.dart';
import '../models/destination_model.dart';

class DestinationRepositoryImpl implements DestinationRepository {
  final DestinationApiService apiService;

  DestinationRepositoryImpl(this.apiService);

  @override
  Future<DataState<DestinationSearchModel>> searchDestinations({
    required String query,
    String? countryCode,
    int limit = 100,
  }) async {
    try {
      final response = await apiService.searchDestinations(
        query: query,
        countryCode: countryCode,
        limit: limit,
      );

      if (response.statusCode == 200) {
        DestinationSearchModel result =
        DestinationSearchModel.fromJson(response.data);

        return DataSuccess(result);
      } else {
        return  DataFailed(
          DioException(
            requestOptions: RequestOptions(path: ''),
            error: 'Failed to search destinations',
            type: DioExceptionType.badResponse,
          ),
        );
      }
    } on DioException catch (e) {
      return DataFailed(e);
    }
  }
}