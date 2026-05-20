import '../../../../core/error/data_state.dart';
import '../entities/footer_setting_entity.dart';
import '../repository/footer_setting_repository.dart';

class GetFooterSettingsUseCase {
  final FooterSettingsRepository repository;

  GetFooterSettingsUseCase(this.repository);

  Future<DataState<FooterSettingsEntity>> call({required String domain}) {
    return repository.getFooterSettings(domain: domain);
  }
}