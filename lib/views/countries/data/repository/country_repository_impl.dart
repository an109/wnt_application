import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entities/country_entity.dart';
import '../../domain/repository/country_repository.dart';
import '../data_source/country_api_service.dart';
import '../models/country_model.dart';

class CountryRepositoryImpl implements CountryRepository {
  final CountryApiService countryApiService;

  CountryRepositoryImpl(this.countryApiService);

  @override
  Future<DataState<List<CountryEntity>>> getCountryList() async {
    try {
      final response = await countryApiService.getCountryList();

      if (response.statusCode == 200) {
        final responseData = response.data;

        // Check if Status code is 200 in response body
        final status = responseData['Status'];
        if (status != null && status['Code'] == 200) {
          final countryListJson = responseData['CountryList'] as List;
          final List<CountryModel> countryModels = countryListJson
              .map((json) => CountryModel.fromJson(json))
              .toList();

          print('Successfully fetched ${countryModels.length} countries');

          return DataSuccess(countryModels);
        } else {
          print('API returned error status: $status');
          return  DataFailed(
            DioException(
              requestOptions: RequestOptions(path: ''),
              error: 'API returned error status',
              type: DioExceptionType.badResponse,
              response: Response(
                statusCode: 400,
                requestOptions: RequestOptions(path: ''),
              ),
            ),
          );
        }
      } else {
        print('Unexpected status code: ${response.statusCode}');
        return  DataFailed(
          DioException(
            requestOptions: RequestOptions(path: ''),
            error: 'Unexpected status code',
            type: DioExceptionType.badResponse,
            response: Response(
              statusCode: 500,
              requestOptions: RequestOptions(path: ''),
            ),
          ),
        );
      }
    } on DioException catch (e) {
      print('DioException in CountryRepository: ${e.message}');
      return DataFailed(e);
    } catch (e) {
      print('Unknown error in CountryRepository: $e');
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