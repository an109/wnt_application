import '../../../../core/error/data_state.dart';
import '../entity/AKFlights_entity.dart';
import '../repository/AKFlights_repository.dart';

class GetAkflightsUseCase {
  final AkflightsRepository repository;

  GetAkflightsUseCase(this.repository);

  Future<DataState<AkflightsSearchEntity>> call({required String tui}) async {
    return await repository.getExpSearch(tui: tui);
  }
}