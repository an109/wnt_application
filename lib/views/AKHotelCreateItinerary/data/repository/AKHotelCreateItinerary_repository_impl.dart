import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/AKHotelCreateItinerary_entity.dart';
import '../../domain/repository/AKHotelCreateItinerary_repository.dart';
import '../data_source/AKHotelCreateItinerary_api_service.dart';
import '../model/AKHotelCreateItinerary_model.dart';

class AkHotelCreateItineraryRepositoryImpl implements AkHotelCreateItineraryRepository {
  final AkHotelCreateItineraryApiService apiService;

  AkHotelCreateItineraryRepositoryImpl(this.apiService);

  @override
  Future<DataState<AkHotelCreateItineraryEntity>> createItinerary(AkHotelCreateItineraryRequestEntity request) async {
    try {
      final requestModel = AkHotelCreateItineraryRequestModel.fromEntity(request);
      final response = await apiService.createItinerary(requestModel);
      final data = response.data;

      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        return DataSuccess(AkHotelCreateItineraryModel.fromJson(data));
      }

      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: '/api/akbar-hotels/create-itinerary/'),
          response: response,
          type: DioExceptionType.badResponse,
          error: 'Failed to create itinerary',
        ),
      );
    } on DioException catch (e) {
      print('Create Itinerary Repository Error: ${e.message}');
      return DataFailed(e);
    } catch (e) {
      print('Create Itinerary Repository Unknown Error: $e');
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: '/api/akbar-hotels/create-itinerary/'),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}
