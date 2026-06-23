import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/visaEntity.dart';
import '../../domain/repository/visaRepository.dart';
import '../data_source/visa_api_service.dart';
import '../models/visaModel.dart';

class VisaApplicationRepositoryImpl implements VisaApplicationRepository {
  final VisaApplicationApiService _apiService;

  VisaApplicationRepositoryImpl(this._apiService);

  @override
  Future<DataState<List<VisaApplicationEntity>>> getAllVisaApplications() async {
    try {
      final response = await _apiService.getAllVisaApplications();

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data is List
            ? response.data
            : (response.data['applications'] ?? response.data['results'] ?? []);

        final applications = data
            .map((json) => VisaApplicationModel.fromJson(json as Map<String, dynamic>))
            .toList();

        return DataSuccess(applications);
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: 'visa-applications'),
            error: 'Failed to fetch visa applications',
            type: DioExceptionType.badResponse,
            response: response,
          ),
        );
      }
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: 'visa-applications'),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  @override
  Future<DataState<VisaApplicationEntity>> getVisaApplicationById(int id) async {
    try {
      final response = await _apiService.getVisaApplicationById(id);

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> data = response.data;
        final applicationData = data['application'] ?? data;
        final application = VisaApplicationModel.fromJson(
            applicationData as Map<String, dynamic>);

        return DataSuccess(application);
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: 'visa-applications/$id'),
            error: 'Failed to fetch visa application',
            type: DioExceptionType.badResponse,
            response: response,
          ),
        );
      }
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: 'visa-applications/$id'),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  @override
  Future<DataState<VisaApplicationEntity>> createVisaApplication(
      VisaApplicationEntity application) async {
    try {
      final model = VisaApplicationModel.fromEntity(application);
      final requestBody = model.toJson();

      final response = await _apiService.createVisaApplication(requestBody);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        final Map<String, dynamic> data = response.data;
        final applicationData = data['application'] ?? data;
        final createdApplication = VisaApplicationModel.fromJson(
            applicationData as Map<String, dynamic>);

        return DataSuccess(createdApplication);
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: 'visa-applications'),
            error: 'Failed to create visa application',
            type: DioExceptionType.badResponse,
            response: response,
          ),
        );
      }
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: 'visa-applications'),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}