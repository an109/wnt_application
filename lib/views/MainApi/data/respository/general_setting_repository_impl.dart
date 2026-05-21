import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entities/general_setting_entity.dart';
import '../../domain/entities/section_heros_entity.dart';
import '../../domain/repository/general_setting_repository.dart';
import '../data_source/general_setting_api_service.dart';
import '../models/pd_response_model.dart';

class GeneralSettingsRepositoryImpl implements GeneralSettingsRepository {
  final GeneralSettingsApiService apiService;

  GeneralSettingsRepositoryImpl(this.apiService);

  @override
  Future<DataState<GeneralSettingsEntity>> getGeneralSettings({String? domain}) async {
    try {
      final response = await apiService.getPopularDestinationsData(domain: domain ?? 'thewandernova.com');

      if (response.statusCode == 200) {
        final responseData = PopularDestinationsResponseModel.fromJson(response.data);
        return DataSuccess(responseData.generalSettings.toEntity()); // Convert to Entity
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: response.requestOptions.path),
            response: response,
            type: DioExceptionType.badResponse,
          ),
        );
      }
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: 'flights-popular-destinations'),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  @override
  Future<DataState<SectionHeroesEntity>> getSectionHeroes({String? domain}) async {
    try {
      final response = await apiService.getPopularDestinationsData(domain: domain ?? 'thewandernova.com');

      if (response.statusCode == 200) {
        final responseData = PopularDestinationsResponseModel.fromJson(response.data);
        return DataSuccess(responseData.sectionHeroes.toEntity()); // Convert to Entity
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: response.requestOptions.path),
            response: response,
            type: DioExceptionType.badResponse,
          ),
        );
      }
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: 'flights-popular-destinations'),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  @override
  Future<DataState<List<FaqEntity>>> getFaqList({String? domain}) async {
    try {
      final response = await apiService.getPopularDestinationsData(domain: domain ?? 'thewandernova.com');

      if (response.statusCode == 200) {
        final responseData = PopularDestinationsResponseModel.fromJson(response.data);
        return DataSuccess(responseData.faqList.map((e) => e.toEntity()).toList()); // Convert to Entity
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: response.requestOptions.path),
            response: response,
            type: DioExceptionType.badResponse,
          ),
        );
      }
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: 'flights-popular-destinations'),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}