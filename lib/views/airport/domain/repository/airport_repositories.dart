import '../../../../core/error/data_state.dart';
import '../entities/airport_entities.dart';

abstract class AirportRepository {
  Future<DataState<List<AirportEntity>>> getAirports({String? country, String? searchQuery});
}