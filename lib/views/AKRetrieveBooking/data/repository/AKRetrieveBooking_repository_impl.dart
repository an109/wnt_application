import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/AKRetrieveBooking_entity.dart';
import '../../domain/repository/AKRetrieveBooking_repository.dart';
import '../data_source/AKRetrieveBooking_api_service.dart';
import '../model/AKRetrieveBooking_model.dart';

class AkRetrieveBookingRepositoryImpl implements AkRetrieveBookingRepository {
  final AkRetrieveBookingApiService apiService;

  AkRetrieveBookingRepositoryImpl(this.apiService);

  @override
  Future<DataState<AkRetrieveBookingEntity>> retrieveBooking(
      AkRetrieveBookingRequestEntity request) async {
    try {
      final requestModel = AkRetrieveBookingRequestModel.fromEntity(request);
      final response = await apiService.retrieveBooking(requestModel);

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final model = AkRetrieveBookingModel.fromJson(response.data as Map<String, dynamic>);
        return DataSuccess(model);
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: '/api/akbar/RetrieveBooking/'),
            response: response,
            type: DioExceptionType.badResponse,
            error: 'Failed to retrieve booking',
          ),
        );
      }
    } on DioException catch (e) {
      print('RetrieveBooking Repository Error: ${e.message}');
      return DataFailed(e);
    } catch (e) {
      print('RetrieveBooking Repository Unknown Error: $e');
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: '/api/akbar/RetrieveBooking/'),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}
