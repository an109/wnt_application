import '../../../../core/error/data_state.dart';
import '../entity/referral_entity.dart';

abstract class ReferralRepository {
  Future<DataState<ReferralEntity>> getUserReferral();
}