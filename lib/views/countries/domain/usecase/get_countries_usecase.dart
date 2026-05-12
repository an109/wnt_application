import '../../../../core/error/data_state.dart';
import '../entities/country_entity.dart';
import '../repository/country_repository.dart';

class GetCountriesUseCase {
  final CountryRepository repository;

  GetCountriesUseCase(this.repository);

  Future<DataState<List<CountryEntity>>> call() async {
    return await repository.getCountryList();
  }
}