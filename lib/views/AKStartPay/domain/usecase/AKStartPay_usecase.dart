import '../../../../core/error/data_state.dart';
import '../entity/AKStartPay_entity.dart';
import '../repository/AKStartPay_repository.dart';

class AkStartPayUseCase {
  final AkStartPayRepository repository;

  AkStartPayUseCase(this.repository);

  Future<DataState<AkStartPayEntity>> call(AkStartPayRequestEntity request) async {
    return await repository.startPay(request);
  }
}
