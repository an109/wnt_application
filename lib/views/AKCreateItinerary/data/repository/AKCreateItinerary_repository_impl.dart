import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/AKCreateItinerary_entity.dart';
import '../../domain/repository/AKCreateItinerary_repository.dart';
import '../data_source/AKCreateItinerary_api_service.dart';
import '../model/AKCreateItinerary_model.dart';

class AkCreateItineraryRepositoryImpl implements AkCreateItineraryRepository {
  final AkCreateItineraryApiService apiService;

  AkCreateItineraryRepositoryImpl(this.apiService);

  @override
  Future<DataState<AkCreateItineraryEntity>> createItinerary(
      AkCreateItineraryRequestEntity request) async {
    try {
      final requestModel = AkCreateItineraryRequestModel.fromEntity(request);
      final response = await apiService.createItinerary(requestModel);

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final model = AkCreateItineraryModel.fromJson(response.data as Map<String, dynamic>);
        return DataSuccess(model);
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: '/api/akbar/CreateItinerary/'),
            response: response,
            type: DioExceptionType.badResponse,
            error: 'Failed to create itinerary',
          ),
        );
      }
    } on DioException catch (e) {
      print('CreateItinerary Repository Error: ${e.message}');
      return DataFailed(e);
    } catch (e) {
      print('CreateItinerary Repository Unknown Error: $e');
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: '/api/akbar/CreateItinerary/'),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}
