import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/referral_entity.dart';

// We extend your provided DataState to maintain consistency
abstract class ReferralState extends DataState<ReferralEntity> {
  const ReferralState({super.data, super.error});
}

class ReferralInitial extends ReferralState {
  const ReferralInitial();
}

class ReferralLoading extends ReferralState {
  const ReferralLoading();
}

class ReferralSuccess extends ReferralState {
  const ReferralSuccess(ReferralEntity data) : super(data: data);
}

class ReferralFailed extends ReferralState {
  const ReferralFailed(DioException error) : super(error: error);
}