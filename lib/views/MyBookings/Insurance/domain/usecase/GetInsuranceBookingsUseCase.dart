import '../../../../../core/error/data_state.dart';
import '../entity/InsuranceBookingEntity.dart';
import '../repository/InsuranceBookingRepository.dart';

class GetInsuranceBookingsUseCase {
  final InsuranceBookingRepository _repository;

  GetInsuranceBookingsUseCase(this._repository);

  Future<DataState<List<InsuranceBookingEntity>>> call() async {
    return await _repository.getInsuranceBookings();
  }
}
