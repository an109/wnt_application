import 'package:dio/dio.dart';

import '../../../../../core/error/data_state.dart';
import '../../../../VisaApplication/domain/entity/visaEntity.dart';
import '../../domain/repository/VRepository.dart';
import '../data_source/V_api_service.dart';
import '../models/VApplicationModel.dart';


class VRepositoryImpl implements VRepository {
  final VApiService apiService;

  VRepositoryImpl(this.apiService);

  @override
  Future<DataState<List<VisaApplicationEntity>>> getVisaApplications({String? userEmail}) async {
    try {
      final response = await apiService.getVisaApplications(userEmail: userEmail);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;

        if (data is Map<String, dynamic> && data['success'] == true) {
          final List<dynamic> applicationsJson = data['applications'] ?? [];

          List<VisaApplicationModel> applications = applicationsJson
              .map((json) => VisaApplicationModel.fromJson(json))
              .toList();

          print('Successfully fetched ${applications.length} visa applications');
          return DataSuccess(applications);
        } else {
          print('API returned success: false');
          return  DataFailed(
            DioException(
              requestOptions: RequestOptions(path: ''),
              error: 'API returned unsuccessful response',
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
      print('DioException in repository: ${e.message}');
      return DataFailed(e);
    } catch (e) {
      print('Unknown error in repository: $e');
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