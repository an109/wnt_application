import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/usecase/reset_password_usecase.dart';
import 'reset_password_event.dart';
import 'reset_password_state.dart';

class ResetPasswordBloc extends Bloc<ResetPasswordEvent, ResetPasswordState> {
  final ResetPasswordUseCase resetPasswordUseCase;

  ResetPasswordBloc({required this.resetPasswordUseCase}) : super(const ResetPasswordInitial()) {
    on<ResetPasswordRequested>(_onResetPasswordRequested);
    on<ResetPasswordReset>(_onResetPasswordReset);
  }

  Future<void> _onResetPasswordRequested(
      ResetPasswordRequested event,
      Emitter<ResetPasswordState> emit,
      ) async {
    emit(const ResetPasswordLoading());

    final result = await resetPasswordUseCase(
      email: event.email,
      otp: event.otp,
      newPassword: event.newPassword,
    );

    if (result is DataSuccess) {
      emit(ResetPasswordSuccess(result.data!));
    } else if (result is DataFailed) {
      emit(ResetPasswordFailed(result));
    }
  }

  void _onResetPasswordReset(
      ResetPasswordReset event,
      Emitter<ResetPasswordState> emit,
      ) {
    emit(const ResetPasswordInitial());
  }
}
