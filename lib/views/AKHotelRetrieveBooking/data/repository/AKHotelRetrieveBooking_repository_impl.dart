import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/AKHotelRetrieveBooking_entity.dart';
import '../../domain/repository/AKHotelRetrieveBooking_repository.dart';
import '../data_source/AKHotelRetrieveBooking_api_service.dart';
import '../model/AKHotelRetrieveBooking_model.dart';

class AkHotelRetrieveBookingRepositoryImpl implements AkHotelRetrieveBookingRepository {
  final AkHotelRetrieveBookingApiService apiService;

  AkHotelRetrieveBookingRepositoryImpl(this.apiService);

  @override
  Future<DataState<AkHotelRetrieveBookingEntity>> retrieveBooking(AkHotelRetrieveBookingRequestEntity request) async {
    try {
      final response = await apiService.retrieveBooking(request.referenceNumber);
      final data = response.data;

      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        return DataSuccess(AkHotelRetrieveBookingModel.fromJson(data));
      }

      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: '/api/akbar-hotels/retrieve-booking/'),
          response: response,
          type: DioExceptionType.badResponse,
          error: 'Failed to retrieve booking',
        ),
      );
    } on DioException catch (e) {
      print('Retrieve Booking Repository Error: ${e.message}');
      return DataFailed(e);
    } catch (e) {
      print('Retrieve Booking Repository Unknown Error: $e');
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: '/api/akbar-hotels/retrieve-booking/'),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}
