import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entities/flight_entity.dart';
import '../../domain/entities/flight_search_request_entity.dart';
import '../../domain/repository/flight_repository.dart';
import '../data_source/flight_api_service.dart';
import '../model/flight_search_request_model.dart';

class FlightRepositoryImpl implements FlightRepository {
  final FlightApiService _flightApiService;

  FlightRepositoryImpl(this._flightApiService);

  @override
  Future<DataState<List<FlightEntity>>> searchFlights(
      FlightSearchRequestEntity request) async {
    try {
      final requestModel = FlightSearchRequestModel.fromEntity(request);
      final response = await _flightApiService.searchFlights(requestModel);

      return DataSuccess(response.flights);
    } on DioException catch (e) {
      return DataFailed(e);
    }
  }
}