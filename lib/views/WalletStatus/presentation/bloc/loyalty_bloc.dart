import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecase/get_loyality_usecase.dart';
import 'loyalty_event.dart';
import 'loyalty_state.dart';

class LoyaltyBloc extends Bloc<LoyaltyEvent, LoyaltyState> {
  final GetUserLoyaltyUseCase _getUserLoyaltyUseCase;

  LoyaltyBloc(this._getUserLoyaltyUseCase) : super(LoyaltyInitial()) {
    on<FetchUserLoyalty>(_onFetchUserLoyalty);
  }

  Future<void> _onFetchUserLoyalty(
      FetchUserLoyalty event,
      Emitter<LoyaltyState> emit,
      ) async {
    emit(LoyaltyLoading());
    final dataState = await _getUserLoyaltyUseCase();
    emit(LoyaltyLoaded(dataState));
  }
}