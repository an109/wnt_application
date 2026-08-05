import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/AKAcceptFareChange_entity.dart';
import '../../domain/repository/AKAcceptFareChange_repository.dart';
import '../data_source/AKAcceptFareChange_api_service.dart';
import '../model/AKAcceptFareChange_model.dart';

class AkAcceptFareChangeRepositoryImpl implements AkAcceptFareChangeRepository {
  final AkAcceptFareChangeApiService apiService;

  AkAcceptFareChangeRepositoryImpl(this.apiService);

  @override
  Future<DataState<AkAcceptFareChangeEntity>> acceptFareChange(
      AkAcceptFareChangeRequestEntity request) async {
    try {
      final requestModel = AkAcceptFareChangeRequestModel.fromEntity(request);
      final response = await apiService.acceptFareChange(requestModel);

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final model = AkAcceptFareChangeModel.fromJson(response.data as Map<String, dynamic>);
        return DataSuccess(model);
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: '/api/akbar/AcceptFareChange/'),
            response: response,
            type: DioExceptionType.badResponse,
            error: 'Failed to accept fare change',
          ),
        );
      }
    } on DioException catch (e) {
      print('AcceptFareChange Repository Error: ${e.message}');
      return DataFailed(e);
    } catch (e) {
      print('AcceptFareChange Repository Unknown Error: $e');
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: '/api/akbar/AcceptFareChange/'),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}
