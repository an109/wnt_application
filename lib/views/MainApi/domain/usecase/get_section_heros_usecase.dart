import '../../../../core/error/data_state.dart';
import '../entities/section_heros_entity.dart';
import '../repository/general_setting_repository.dart';

class GetSectionHeroesUsecase {
  final GeneralSettingsRepository repository;

  GetSectionHeroesUsecase(this.repository);

  Future<DataState<SectionHeroesEntity>> call({String? domain}) {
    return repository.getSectionHeroes(domain: domain);
  }
}