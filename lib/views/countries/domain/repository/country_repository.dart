import '../../../../core/error/data_state.dart';
import '../entities/country_entity.dart';

abstract class CountryRepository {
  Future<DataState<List<CountryEntity>>> getCountryList();
}