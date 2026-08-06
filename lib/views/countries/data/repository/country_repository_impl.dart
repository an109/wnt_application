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
        final responseData = response.data as Map<String, dynamic>;
        final countryListJson = responseData['CountryList'] as List?;

        if (countryListJson != null) {
          final List<CountryModel> countryModels = countryListJson
              .map((json) => CountryModel.fromJson(json as Map<String, dynamic>))
              .toList();

          return DataSuccess(countryModels);
        } else {
          return DataFailed(
            DioException(
              requestOptions: RequestOptions(path: ''),
              error: 'API returned no CountryList',
              type: DioExceptionType.badResponse,
              response: Response(
                statusCode: 400,
                requestOptions: RequestOptions(path: ''),
              ),
            ),
          );
        }
      } else {
        return DataFailed(
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