import '../../../../core/error/data_state.dart';
import '../entities/general_setting_entity.dart';
import '../repository/general_setting_repository.dart';

class GetFaqListUsecase {
  final GeneralSettingsRepository repository;

  GetFaqListUsecase(this.repository);

  Future<DataState<List<FaqEntity>>> call({String? domain}) {
    return repository.getFaqList(domain: domain);
  }
}