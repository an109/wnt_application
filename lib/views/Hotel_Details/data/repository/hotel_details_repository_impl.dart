import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entities/hotel_details_entity.dart';
import '../../domain/repository/hotel_details_entity.dart';
import '../data_source/hotel_details_api_service.dart';
import '../models/hotel_details_model.dart';

class HotelDetailsRepositoryImpl implements HotelDetailsRepository {
  final HotelDetailsApiService apiService;

  HotelDetailsRepositoryImpl(this.apiService);

  @override
  Future<DataState<List<HotelDetailsEntity>>> getHotelDetails({
    required String hotelCode,
    required String checkIn,
    required String checkOut,
    String? language,
    String? guestNationality,
  }) async {
    try {
      final response = await apiService.getHotelDetails(
        hotelCode: hotelCode,
        checkIn: checkIn,
        checkOut: checkOut,
        language: language,
        guestNationality: guestNationality,
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Check the status code from response body
        final status = data['Status'];
        if (status != null && status['Code'] == 200) {
          final hotelDetailsJson = data['HotelDetails'] as List;
          final hotelDetailsList = hotelDetailsJson
              .map((json) => HotelDetailsModel.fromJson(json))
              .toList();

          print('Successfully fetched ${hotelDetailsList.length} hotel details');
          return DataSuccess(hotelDetailsList);
        } else {
          final errorMessage = status?['Description'] ?? 'Failed to fetch hotel details';
          print('API returned error: $errorMessage');
          return DataFailed(
            DioException(
              requestOptions: RequestOptions(path: '/hotel-details'),
              error: errorMessage,
              type: DioExceptionType.badResponse,
              response: response,
            ),
          );
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: '/hotel-details'),
            error: 'HTTP Error: ${response.statusCode}',
            type: DioExceptionType.badResponse,
            response: response,
          ),
        );
      }
    } on DioException catch (e) {
      print('Repository Error: ${e.message}');
      return DataFailed(e);
    } catch (e) {
      print('Unknown Repository Error: $e');
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: '/hotel-details'),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}