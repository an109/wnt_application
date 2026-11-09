import '../../../../../core/error/data_state.dart';
import '../entity/InsuranceBookingEntity.dart';

abstract class InsuranceBookingRepository {
  Future<DataState<List<InsuranceBookingEntity>>> getInsuranceBookings();
}
