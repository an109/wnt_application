import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entities/TPollSearchEntity.dart';
import '../../domain/repository/TPoll_Search_repository.dart';
import '../data_source/TPoll_Search_api-service.dart';
import '../models/TPoll_SearchModel.dart';

class TpollSearchRepositoryImpl implements TpollSearchRepository {
  final TpollSearchApiService apiService;

  TpollSearchRepositoryImpl(this.apiService);

  @override
  Future<DataState<TpollSearchEntity>> pollSearchResults(String searchId) async {
    try {
      final response = await apiService.pollSearchResults(searchId);
      final tpollSearchModel = TpollSearchModel.fromJson(response.data);

      final entity = _mapToEntity(tpollSearchModel);
      return DataSuccess<TpollSearchEntity>(entity);
    } on DioException catch (e) {
      print('API Error in pollSearchResults: ${e.message}');
      return DataFailed<TpollSearchEntity>(e);
    } catch (e) {
      print('Unknown Error in pollSearchResults: $e');
      return DataFailed<TpollSearchEntity>(
        DioException(
          requestOptions: RequestOptions(path: Urls.tpollSearch(searchId)),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  TpollSearchEntity _mapToEntity(TpollSearchModel model) {
    return TpollSearchEntity(
      success: model.success,
      search: SearchDataEntity(
        numPassengers: model.search.numPassengers,
        pickupDatetime: model.search.pickupDatetime,
        flightDatetime: model.search.flightDatetime,
        searchId: model.search.searchId,
        results: model.search.results.map((result) {
          // Extract vehicle data from first step (main step)
          final mainStep = result.steps.firstWhere(
                (step) => step.main,
            orElse: () => result.steps.isNotEmpty ? result.steps.first : result.steps[0],
          );
          final vehicle = mainStep.details.vehicle;
          final amenities = mainStep.details.amenities.map((amenityModel) {
            return AmenityEntity(
              key: amenityModel.key,
              name: amenityModel.name,
              included: amenityModel.included,
              chargeable: amenityModel.chargeable,
            );
          }).toList();

          return SearchResultEntity(
            resultId: result.resultId,
            vehicleId: result.vehicleId,
            providerName: result.providerName,
            vehicleType: result.vehicleType,
            vehicleName: result.vehicleName,
            totalPriceAmount: result.totalPrice.totalPrice.value,
            totalPriceCurrency: result.totalPrice.totalPrice.currency,
            bookable: result.bookable,
            // Mapped from vehicle model
            vehicleImageUrl: vehicle.image,
            maxPassengers: vehicle.maxPassengers,
            maxBags: vehicle.maxBags,
            // Mapped amenities list
            amenities: amenities,
          );
        }).toList(),
        startLocation: LocationInfoEntity(
          fullAddress: model.search.startLocation.fullAddress,
          city: model.search.startLocation.city,
          iataCode: model.search.startLocation.iataCode,
        ),
        endLocation: LocationInfoEntity(
          fullAddress: model.search.endLocation.fullAddress,
          city: model.search.endLocation.city,
          iataCode: model.search.endLocation.iataCode,
        ),
        currencyInfo: CurrencyInfoEntity(
          code: model.search.currencyInfo.code,
          prefixSymbol: model.search.currencyInfo.prefixSymbol,
        ),
        expiresIn: model.search.expiresIn,
        moreComing: model.search.moreComing,
      ),
    );
  }
}