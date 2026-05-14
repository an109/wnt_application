import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../data_source/exclusive_deals_api_service.dart';
import '../models/exclusive_deal_model.dart';
import '../../domain/entities/exclusive_deal_entity.dart';
import '../../domain/repository/exclusive_deals_repository.dart';

class ExclusiveDealsRepositoryImpl implements ExclusiveDealsRepository {
  final ExclusiveDealsApiService apiService;

  ExclusiveDealsRepositoryImpl(this.apiService);

  @override
  Future<DataState<List<ExclusiveDealEntity>>> getExclusiveDeals({String? domain}) async {
    try {
      final response = await apiService.getExclusiveDeals(domain: domain);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['success'] == true && data['deals'] != null) {
          final List<dynamic> dealsJson = data['deals'];
          final List<ExclusiveDealEntity> deals = dealsJson
              .map((json) => ExclusiveDealModel.fromJson(json))
              .toList();

          return DataSuccess(deals);
        } else {
          return  DataFailed(
            DioException(
              requestOptions: RequestOptions(path: ''),
              error: 'Invalid response format',
              type: DioExceptionType.badResponse,
              response: Response(requestOptions: RequestOptions(path: '')),
            ),
          );
        }
      } else {
        return  DataFailed(
          DioException(
            requestOptions: RequestOptions(path: ''),
            error: 'Failed to fetch exclusive deals',
            type: DioExceptionType.badResponse,
            response: Response(requestOptions: RequestOptions(path: '')),
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