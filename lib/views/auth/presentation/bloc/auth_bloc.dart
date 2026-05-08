import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/usecase/google_auth_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GoogleLoginUseCase googleLoginUseCase;

  AuthBloc({required this.googleLoginUseCase}) : super(const AuthInitial()) {
    on<GoogleLoginRequested>(_onGoogleLoginRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthTokenRefreshRequested>(_onAuthTokenRefreshRequested);
  }

  Future<void> _onGoogleLoginRequested(
      GoogleLoginRequested event,
      Emitter<AuthState> emit,
      ) async {
    print(' Bloc: Processing GoogleLoginRequested');
    emit(const AuthLoading());

    final result = await googleLoginUseCase(event.idToken);

    if (result is DataSuccess) {
      print(' Bloc: Emitting AuthAuthenticated');
      emit(AuthAuthenticated(result.data!));
    } else if (result is DataFailed) {
      final errorMessage = result.error?.message ?? 'Authentication failed';
      print(' Bloc: Emitting AuthError - $errorMessage');
      emit(AuthError(errorMessage));
    }
  }

  Future<void> _onAuthLogoutRequested(
      AuthLogoutRequested event,
      Emitter<AuthState> emit,
      ) async {
    print(' Bloc: Processing logout');
    // TODO: Clear stored tokens via PreferencesManager if needed
    emit(const AuthUnauthenticated());
  }

  Future<void> _onAuthTokenRefreshRequested(
      AuthTokenRefreshRequested event,
      Emitter<AuthState> emit,
      ) async {
    // TODO: Implement token refresh logic if your API supports it
    print(' Bloc: Token refresh requested (not implemented yet)');
  }
}