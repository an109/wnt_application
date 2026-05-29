import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/usecase/send_otp_usecase.dart';
import 'send_otp_event.dart';
import 'send_otp_state.dart';

class SendOtpBloc extends Bloc<SendOtpEvent, SendOtpState> {
  final SendOtpUseCase sendOtpUseCase;

  SendOtpBloc({required this.sendOtpUseCase}) : super(const SendOtpInitial()) {
    on<SendOtpRequested>(_onSendOtpRequested);
    on<SendOtpReset>(_onSendOtpReset);
  }

  Future<void> _onSendOtpRequested(
      SendOtpRequested event,
      Emitter<SendOtpState> emit,
      ) async {
    emit(const SendOtpLoading());

    final result = await sendOtpUseCase(
      contact: event.contact,
      type: event.type,
      purpose: event.purpose,
    );

    if (result is DataSuccess) {
      emit(SendOtpSuccess(result.data!));
    } else if (result is DataFailed) {
      emit(SendOtpFailed(result));
    }
  }

  void _onSendOtpReset(
      SendOtpReset event,
      Emitter<SendOtpState> emit,
      ) {
    emit(const SendOtpInitial());
  }
}