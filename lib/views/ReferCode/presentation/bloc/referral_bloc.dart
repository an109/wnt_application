import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/referral_entity.dart';
import '../../domain/usecase/get_referral_usecase.dart';
import 'referral_event.dart';
import 'referral_state.dart';

class ReferralBloc extends Bloc<ReferralEvent, ReferralState> {
  final GetReferralUseCase _getReferralUseCase;

  ReferralBloc(this._getReferralUseCase) : super(const ReferralInitial()) {
    on<FetchReferralEvent>(_onFetchReferral);
  }

  Future<void> _onFetchReferral(FetchReferralEvent event,
      Emitter<ReferralState> emit,) async {
    emit(const ReferralLoading());

    final dataState = await _getReferralUseCase();

    // Map the DataState returned by the UseCase to our specific ReferralStates
    if (dataState is DataSuccess<ReferralEntity>) {
      emit(ReferralSuccess(dataState.data!));
    } else if (dataState is DataFailed<ReferralEntity>) {
      emit(ReferralFailed(dataState.error!));
    }
  }
}
