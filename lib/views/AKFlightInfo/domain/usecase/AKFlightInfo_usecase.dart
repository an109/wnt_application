import '../../../../core/error/data_state.dart';
import '../entity/AKFlightInfo_entity.dart';
import '../repository/AKFlightInfo_repository.dart';

class AkFlightInfoUseCase {
  final AkFlightInfoRepository repository;

  AkFlightInfoUseCase(this.repository);

  Future<DataState<AkFlightInfoEntity>> call(
      AkFlightInfoRequestEntity request) async {
    return await repository.getFlightInfo(request);
  }
}
