import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entities/Popular_destination_entity.dart';
import '../../domain/repository/destination_repository.dart';
import '../data_source/destination_api_service.dart';
import '../model/destination_model.dart';

class PopularDestinationRepositoryImpl implements PopularDestinationRepository {
  final PopularDestinationApiService apiService;

  PopularDestinationRepositoryImpl(this.apiService);

  @override
  Future<DataState<List<DestinationEntity>>> getPopularDestinations() async {
    try {
      final response = await apiService.getPopularDestinations();

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> destinationsJson = response.data['destinations'];
        final destinations = destinationsJson
            .map((json) => DestinationModel.fromJson(json))
            .toList();

        return DataSuccess(destinations);
      } else {
        return  DataFailed(
          DioException(
            requestOptions: RequestOptions(path: ''),
            error: 'Failed to fetch destinations',
            type: DioExceptionType.badResponse,
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