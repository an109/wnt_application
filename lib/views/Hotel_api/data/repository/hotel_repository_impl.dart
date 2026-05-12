import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entities/hotel_entity.dart';
import '../../domain/repository/hotel_repository.dart';
import '../data_source/hotel_api_service.dart';
import '../models/hotel_model.dart';

class HotelRepositoryImpl implements HotelRepository {
  final HotelApiService apiService;

  HotelRepositoryImpl(this.apiService);

  @override
  Future<DataState<List<HotelEntity>>> getHotelsByCity({
    required String cityCode,
    required String checkIn,
    required String checkOut,
    required String guestNationality,
    required int page,
    required int pageSize,
    Map<String, dynamic>? filters,
    List<Map<String, dynamic>>? paxRooms,
  }) async {
    try {
      final response = await apiService.getHotelsByCity(
        cityCode: cityCode,
        checkIn: checkIn,
        checkOut: checkOut,
        guestNationality: guestNationality,
        page: page,
        pageSize: pageSize,
        filters: filters,
        paxRooms: paxRooms,
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final results = data['results'] as List;

        final List<HotelModel> hotelModels = results
            .map((json) => HotelModel.fromJson(json))
            .toList();

        final List<HotelEntity> hotelEntities = hotelModels
            .map((model) => HotelEntity.fromModel(model))
            .toList();

        print('Successfully fetched ${hotelEntities.length} hotels');
        return DataSuccess(hotelEntities);
      } else {
        print('Failed to fetch hotels: ${response.statusCode}');
        return  DataFailed(
          DioException(
            requestOptions: RequestOptions(path: ''),
            error: 'Failed to fetch hotels',
            type: DioExceptionType.badResponse,
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