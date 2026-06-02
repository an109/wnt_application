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
          print("Results count: ${model.search.results.length}");
          for (int i = 0; i < model.search.results.length; i++) {
            print("Result $i -> steps count: ${model.search.results[i].steps.length}");
          }

          // 1. Safely find the main step. If the list is empty, mainStep will be null.
          final StepModel? mainStep = result.steps.isEmpty
              ? null
              : result.steps.firstWhere(
                (step) => step.main,
            orElse: () => result.steps.first,
          );

          // 2. Provide safe fallback defaults if mainStep is null (e.g., during early polling)
          final vehicle = mainStep?.details.vehicle ??
              VehicleModel(
                image: '',
                make: '',
                model: '',
                vehicleType: VehicleTypeModel(key: 0, name: 'Unknown'),
                maxBags: 0,
                maxPassengers: 0,
                category: VehicleCategoryModel(id: 0, name: 'Unknown'),
              );

          // 3. Safely map amenities, defaulting to an empty list if mainStep is null
          final amenities = mainStep?.details.amenities.map((amenityModel) {
            return AmenityEntity(
              key: amenityModel.key,
              name: amenityModel.name,
              description: amenityModel.description,
              included: amenityModel.included,
              chargeable: amenityModel.chargeable,
              price: amenityModel.price != null
                  ? PriceInfoEntity(
                value: amenityModel.price!.value,
                display: amenityModel.price!.display,
                compact: amenityModel.price!.compact,
                currency: amenityModel.price!.currency,
              )
                  : null,
            );
          }).toList() ?? [];

          return SearchResultEntity(
            resultId: result.resultId,
            vehicleId: result.vehicleId,
            providerName: result.providerName,
            vehicleType: result.vehicleType,
            vehicleName: result.vehicleName,
            totalPriceAmount: result.totalPriceAmount,
            totalPriceCurrency: result.totalPriceCurrency,
            bookable: result.bookable,
            vehicleImageUrl: vehicle.image,
            maxPassengers: vehicle.maxPassengers,
            maxBags: vehicle.maxBags,
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