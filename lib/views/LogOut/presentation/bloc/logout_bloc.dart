import 'package:bloc/bloc.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/logout_entity.dart';
import '../../domain/usecase/logout_usecase.dart';
import 'logout_event.dart';
import 'logout_state.dart';

class LogoutBloc extends Bloc<LogoutEvent, LogoutState> {
  final LogoutUseCase logoutUseCase;

  LogoutBloc({required this.logoutUseCase}) : super(LogoutInitial()) {
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onLogoutRequested(
      LogoutRequested event,
      Emitter<LogoutState> emit,
      ) async {
    emit(LogoutLoading());

    final result = await logoutUseCase();

    if (result is DataSuccess<LogoutEntity>) {
      emit(LogoutSuccess(result.data!));
    } else if (result is DataFailed<LogoutEntity>) {
      emit(LogoutFailed(result.error!));
    }
  }
}