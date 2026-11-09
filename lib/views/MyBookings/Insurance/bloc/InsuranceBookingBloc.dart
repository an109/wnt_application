import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/data_state.dart';
import '../domain/entity/InsuranceBookingEntity.dart';
import '../domain/usecase/GetInsuranceBookingsUseCase.dart';
import 'InsuranceBookingEvent.dart';
import 'InsuranceBookingState.dart';

class InsuranceBookingBloc extends Bloc<InsuranceBookingEvent, InsuranceBookingState> {
  final GetInsuranceBookingsUseCase _getInsuranceBookingsUseCase;

  InsuranceBookingBloc(this._getInsuranceBookingsUseCase) : super(InsuranceBookingInitial()) {
    on<FetchInsuranceBookings>(_onFetchInsuranceBookings);
  }

  Future<void> _onFetchInsuranceBookings(
    FetchInsuranceBookings event,
    Emitter<InsuranceBookingState> emit,
  ) async {
    emit(InsuranceBookingLoading());
    final result = await _getInsuranceBookingsUseCase.call();
    if (result is DataSuccess<List<InsuranceBookingEntity>>) {
      emit(InsuranceBookingLoaded(result.data ?? []));
    } else if (result is DataFailed) {
      emit(InsuranceBookingError(result.error?.message ?? 'Failed to fetch insurance bookings'));
    }
  }
}
