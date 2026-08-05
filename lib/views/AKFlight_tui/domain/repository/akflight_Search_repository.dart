import '../../../../core/error/data_state.dart';
import '../entity/akflight_search_entity.dart';

abstract class AkFlightSearchRepository {
  Future<DataState<AkFlightSearchEntity>> searchFlights(FlightSearchRequestEntity request);
}