import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entities/visa_destination_entity.dart';
import '../../domain/repository/visa_destination_repository.dart';
import '../data_source/visa_destination_api_service.dart';
import '../model/visa_destination_model.dart';

class VisaPopularDestinationRepositoryImpl implements VisaPopularDestinationRepository {
  final VisaPopularDestinationApiService apiService;

  VisaPopularDestinationRepositoryImpl(this.apiService);

  @override
  Future<DataState<List<VisaPopularDestinationEntity>>> getVisaDestinations({
    String? domain,
  }) async {
    try {
      final response = await apiService.getVisaDestinations(domain: domain);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final success = data['success'] as bool? ?? false;

        if (success) {
          final destinationsJson = data['destinations'] as List<dynamic>? ?? [];
          final destinations = destinationsJson
              .map((json) => VisaPopularDestinationModel.fromJson(json as Map<String, dynamic>))
              .toList();

          print('Successfully fetched ${destinations.length} visa destinations');
          return DataSuccess(destinations);
        } else {
          print('API returned success: false');
          return DataFailed(
            DioException(
              requestOptions: RequestOptions(path: '/visa-popular-destinations/'),
              error: data['message'] ?? 'API returned unsuccessful response',
              type: DioExceptionType.badResponse,
              response: response,
            ),
          );
        }
      } else {
        print('Unexpected response status: ${response.statusCode}');
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: '/visa-popular-destinations/'),
            error: 'Unexpected response: ${response.statusCode}',
            type: DioExceptionType.badResponse,
            response: response,
          ),
        );
      }
    } on DioException catch (e) {
      print('Repository DioException: ${e.message}');
      return DataFailed(e);
    } catch (e) {
      print('Repository Unknown Error: $e');
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: '/visa-popular-destinations/'),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}