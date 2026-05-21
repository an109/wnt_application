import '../../../../core/error/data_state.dart';
import '../entities/general_setting_entity.dart';
import '../repository/general_setting_repository.dart';

class GetGeneralSettingsUsecase {
  final GeneralSettingsRepository repository;

  GetGeneralSettingsUsecase(this.repository);

  Future<DataState<GeneralSettingsEntity>> call({String? domain}) {
    return repository.getGeneralSettings(domain: domain);
  }
}