import '../../../../core/error/data_state.dart';
import '../entity/referral_entity.dart';
import '../repository/referral_repository.dart';

class GetReferralUseCase {
  final ReferralRepository repository;

  GetReferralUseCase(this.repository);

  Future<DataState<ReferralEntity>> call() async {
    return await repository.getUserReferral();
  }
}