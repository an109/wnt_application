import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entities/airport_entities.dart';
import '../../domain/repository/airport_repositories.dart';
import '../data_source/airport_api_service.dart';
import '../models/airport_response_model.dart';

class AirportRepositoryImpl implements AirportRepository {
  final AirportApiService apiService;

  AirportRepositoryImpl(this.apiService);

  @override
  Future<DataState<List<AirportEntity>>> getAirports({String? country}) async {
    try {
      // Call API service
      final response = await apiService.getAirports(country: country);

      // Check if response is successful
      if (response.statusCode == 200) {
        // Parse response using manual JSON
        final responseData = response.data as Map<String, dynamic>;
        final responseModel = AirportResponseModel.fromJson(responseData);

        if (responseModel.success) {
          // Convert models to entities
          final List<AirportEntity> airports = responseModel.data
              .map((model) => AirportEntity(
            airportCode: model.airportCode,
            airportName: model.airportName,
            cityCode: model.cityCode,
            cityName: model.cityName,
            countryCode: model.countryCode,
          ))
              .toList();

          return DataSuccess(airports);
        } else {
          return DataFailed(
            DioException(
              requestOptions: RequestOptions(path: ''),
              error: responseModel.message,
              type: DioExceptionType.badResponse,
              response: response,
            ),
          );
        }
      } else {
        return DataFailed(
          DioException.badResponse(
            statusCode: response.statusCode!,
            requestOptions: response.requestOptions,
            response: response,
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