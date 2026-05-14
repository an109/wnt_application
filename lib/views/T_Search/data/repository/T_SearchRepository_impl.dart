import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entities/T_SearchEntity.dart';
import '../../domain/repository/T_SearchRepository.dart';
import '../data_source/T_Search_api_service.dart';
import '../models/T_SearchModels.dart';

class TransportSearchRepositoryImpl implements TransportSearchRepository {
  final TransportSearchApiService apiService;

  TransportSearchRepositoryImpl(this.apiService);

  @override
  Future<DataState<TransportSearchEntity>> searchTransport({
    required String startAddress,
    required String endAddress,
    required String pickupDatetime,
    required int numPassengers,
    required String currency,
    required String mode,
  }) async {
    try {
      final response = await apiService.searchTransport(
        startAddress: startAddress,
        endAddress: endAddress,
        pickupDatetime: pickupDatetime,
        numPassengers: numPassengers,
        currency: currency,
        mode: mode,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final transportSearchModel = TransportSearchModel.fromJson(response.data);
        return DataSuccess(transportSearchModel);
      } else {
        return  DataFailed(
          DioException(
            requestOptions: RequestOptions(path: ''),
            error: 'Unexpected status code',
            type: DioExceptionType.badResponse,
          ),
        );
      }
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