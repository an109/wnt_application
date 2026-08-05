import '../../../../core/error/data_state.dart';
import '../entity/AKHotelStartPay_entity.dart';
import '../repository/AKHotelStartPay_repository.dart';

class AkHotelStartPayUseCase {
  final AkHotelStartPayRepository repository;

  AkHotelStartPayUseCase(this.repository);

  Future<DataState<AkHotelStartPayEntity>> call(AkHotelStartPayRequestEntity request) async {
    return await repository.startPay(request);
  }
}
