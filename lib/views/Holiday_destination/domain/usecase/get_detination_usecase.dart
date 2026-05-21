import '../../../../core/error/data_state.dart';
import '../entities/holiday_destination_entity.dart';
import '../repository/holiday_repository.dart';

class GetDestinationsUseCase {
  final HolidayRepository repository;

  GetDestinationsUseCase(this.repository);

  Future<DataState<List<HolidayDestinationEntity>>> call({String? domain}) async {
    return await repository.getPopularDestinations(domain: domain);
  }
}