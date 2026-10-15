import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/AKFareFamilyDetails_entity.dart';
import '../../domain/repository/AKFareFamilyDetails_repository.dart';
import '../data_source/AKFareFamilyDetails_api_service.dart';
import '../model/AKFareFamilyDetails_model.dart';

class AkFareFamilyDetailsRepositoryImpl
    implements AkFareFamilyDetailsRepository {
  final AkFareFamilyDetailsApiService apiService;

  AkFareFamilyDetailsRepositoryImpl(this.apiService);

  @override
  Future<DataState<AkFareFamilyDetailsEntity>> getFareFamilyDetails(
      AkFareFamilyDetailsRequestEntity request) async {
    try {
      final requestModel =
          AkFareFamilyDetailsRequestModel.fromEntity(request);
      final response =
          await apiService.getFareFamilyDetails(requestModel);

      if (response.statusCode == 200 &&
          response.data is Map<String, dynamic>) {
        final model = AkFareFamilyDetailsModel.fromJson(
            response.data as Map<String, dynamic>);
        return DataSuccess(model);
      } else {
        return DataFailed(
          DioException(
            requestOptions:
                RequestOptions(path: '/api/akbar/FareFamilyDetails/'),
            response: response,
            type: DioExceptionType.badResponse,
            error: 'Failed to fetch fare family details',
          ),
        );
      }
    } on DioException catch (e) {
      print('FareFamilyDetails Repository Error: ${e.message}');
      return DataFailed(e);
    } catch (e) {
      print('FareFamilyDetails Repository Unknown Error: $e');
      return DataFailed(
        DioException(
          requestOptions:
              RequestOptions(path: '/api/akbar/FareFamilyDetails/'),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}
