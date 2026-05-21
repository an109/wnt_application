import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entities/holiday_destination_entity.dart';
import '../../domain/repository/holiday_repository.dart';
import '../data_source/holiday_destination_api_service.dart';
import '../models/holiday_destination_model.dart';

class HolidayRepositoryImpl implements HolidayRepository {
  final HolidayApiService apiService;

  HolidayRepositoryImpl(this.apiService);

  @override
  Future<DataState<List<HolidayDestinationEntity>>> getPopularDestinations({String? domain}) async {
    try {
      final response = await apiService.getPopularDestinations(domain: domain);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['success'] == true && data['destinations'] != null) {
          final List<dynamic> destinationsJson = data['destinations'];
          final destinations = destinationsJson
              .map((json) => HolidayDestinationModel.fromJson(json))
              .toList();

          return DataSuccess(destinations);
        } else {
          return  DataFailed(
            DioException(
              requestOptions: RequestOptions(path: ''),
              error: 'Invalid response format',
              type: DioExceptionType.badResponse,
              response: Response(
                requestOptions: RequestOptions(path: ''),
                statusCode: 200,
                data: data,
              ),
            ),
          );
        }
      } else {
        return  DataFailed(
          DioException(
            requestOptions: RequestOptions(path: ''),
            error: 'Failed to fetch destinations',
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 500,
            ),
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