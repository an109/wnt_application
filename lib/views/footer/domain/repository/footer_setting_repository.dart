import '../../../../core/error/data_state.dart';
import '../entities/footer_setting_entity.dart';

abstract class FooterSettingsRepository {
  Future<DataState<FooterSettingsEntity>> getFooterSettings({required String domain});
}