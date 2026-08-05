import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/AKTravelCheckList_entity.dart';
import '../../domain/repository/AKTravelCheckList_repository.dart';
import '../data_source/AKTravelCheckList_api_service.dart';
import '../model/AKTravelCheckList_model.dart';

class AkTravelCheckListRepositoryImpl implements AkTravelCheckListRepository {
  final AkTravelCheckListApiService apiService;

  AkTravelCheckListRepositoryImpl(this.apiService);

  @override
  Future<DataState<AkTravelCheckListEntity>> getTravelCheckList(
      AkTravelCheckListRequestEntity request) async {
    try {
      final requestModel = AkTravelCheckListRequestModel.fromEntity(request);
      final response = await apiService.getTravelCheckList(requestModel);

      if (response.statusCode != 200) {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: '/api/akbar/GetTravelCheckList/'),
            response: response,
            type: DioExceptionType.badResponse,
            error: 'Failed to fetch travel checklist',
          ),
        );
      }

      // Called before GetSPricer resolved for this tui: the backend answers
      // with the raw string "invalid Pricing TUI" instead of JSON. Surface
      // this as a normal Loaded state with unavailable:true rather than a
      // failure, so callers fall back to conservative requirements instead
      // of misreading "no data" as "nothing is mandatory".
      if (response.data is! Map<String, dynamic>) {
        return DataSuccess(AkTravelCheckListModel.unavailable());
      }

      final model = AkTravelCheckListModel.fromJson(response.data as Map<String, dynamic>);
      return DataSuccess(model);
    } on DioException catch (e) {
      print('GetTravelCheckList Repository Error: ${e.message}');
      return DataFailed(e);
    } catch (e) {
      print('GetTravelCheckList Repository Unknown Error: $e');
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: '/api/akbar/GetTravelCheckList/'),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}
