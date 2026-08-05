import '../../../../core/error/data_state.dart';
import '../entity/AKFlights_entity.dart';

abstract class AkflightsRepository {
  Future<DataState<AkflightsSearchEntity>> getExpSearch({required String tui});
}