import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/usecase/verify_otp_usecase.dart';
import 'verify_otp_event.dart';
import 'verify_otp_state.dart';

class VerifyOtpBloc extends Bloc<VerifyOtpEvent, VerifyOtpState> {
  final VerifyOtpUseCase verifyOtpUseCase;

  VerifyOtpBloc({required this.verifyOtpUseCase}) : super(const VerifyOtpInitial()) {
    on<VerifyOtpRequested>(_onVerifyOtpRequested);
    on<VerifyOtpReset>(_onVerifyOtpReset);
  }

  Future<void> _onVerifyOtpRequested(
      VerifyOtpRequested event,
      Emitter<VerifyOtpState> emit,
      ) async {
    emit(const VerifyOtpLoading());

    final result = await verifyOtpUseCase(
      contact: event.contact,
      type: event.type,
      otp: event.otp,
    );

    if (result is DataSuccess) {
      emit(VerifyOtpSuccess(result.data!));
    } else if (result is DataFailed) {
      emit(VerifyOtpFailed(result));
    }
  }

  void _onVerifyOtpReset(
      VerifyOtpReset event,
      Emitter<VerifyOtpState> emit,
      ) {
    emit(const VerifyOtpInitial());
  }
}