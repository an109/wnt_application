import '../../../../core/error/data_state.dart';
import '../entities/general_setting_entity.dart';
import '../repository/general_setting_repository.dart';

class GetPromoCodesUsecase {
  final GeneralSettingsRepository repository;

  GetPromoCodesUsecase(this.repository);

  Future<DataState<List<PromoCodeEntity>>> call({String? domain}) {
    return repository.getPromoCodes(domain: domain);
  }
}