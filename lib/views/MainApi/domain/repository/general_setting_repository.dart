import '../../../../core/error/data_state.dart';
import '../entities/general_setting_entity.dart';
import '../entities/section_heros_entity.dart';

abstract class GeneralSettingsRepository {
  Future<DataState<GeneralSettingsEntity>> getGeneralSettings({String? domain});
  Future<DataState<SectionHeroesEntity>> getSectionHeroes({String? domain});
  Future<DataState<List<FaqEntity>>> getFaqList({String? domain});
}