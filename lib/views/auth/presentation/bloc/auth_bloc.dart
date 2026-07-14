import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/data_state.dart';
import '../../../../core/utils/storage/shared_preference.dart';
import '../../domain/entity/user_entity.dart';
import '../../domain/usecase/apple_auth_usecase.dart';
import '../../domain/usecase/google_auth_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GoogleLoginUseCase googleLoginUseCase;
  final AppleLoginUseCase appleLoginUseCase;
  final PreferencesManager preferencesManager;

  AuthBloc({
    required this.googleLoginUseCase,
    required this.appleLoginUseCase,
    required this.preferencesManager,
  }) : super(const AuthInitial()) {
    on<GoogleLoginRequested>(_onGoogleLoginRequested);
    on<AppleLoginRequested>(_onAppleLoginRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthTokenRefreshRequested>(_onAuthTokenRefreshRequested);
    on<AuthCheckStatusRequested>(_onAuthCheckStatusRequested);

    add(const AuthCheckStatusRequested());
  }

  Future<void> _persistAndEmit(
    UserEntity user,
    Emitter<AuthState> emit,
  ) async {
    await preferencesManager.saveUserData(user.toJson());
    await preferencesManager.saveIsSocialLogin(true);
    await preferencesManager.clearUserPassword();
    if (user.accessToken != null) {
      await preferencesManager.saveToken(user.accessToken!);
    }
    if (user.refreshToken != null) {
      await preferencesManager.saveRefreshToken(user.refreshToken!);
    }
    await preferencesManager.saveUserType(int.tryParse(user.userType ?? '0') ?? 0);
    emit(AuthAuthenticated(user));
  }

  Future<void> _onAuthCheckStatusRequested(
      AuthCheckStatusRequested event,
      Emitter<AuthState> emit,
      ) async {
    print('🔍 Checking saved login status...');

    final isLoggedIn = preferencesManager.isLoggedIn();
    final userData = preferencesManager.getUserData();
    final token = preferencesManager.getToken();

    if (isLoggedIn && userData != null && token != null) {
      print('User found in local storage');
      final user = UserEntity.fromJson(userData);
      emit(AuthAuthenticated(user));
    } else {
      print(' No saved user found');
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onGoogleLoginRequested(
      GoogleLoginRequested event,
      Emitter<AuthState> emit,
      ) async {
    print(' Bloc: Processing GoogleLoginRequested');
    emit(const AuthLoading());

    final result = await googleLoginUseCase(event.idToken);

    if (result is DataSuccess) {
      print(' Bloc: Emitting AuthAuthenticated (google)');
      await _persistAndEmit(result.data!, emit);
    } else if (result is DataFailed) {
      final errorMessage = result.error?.message ?? 'Authentication failed';
      print(' Bloc: Emitting AuthError - $errorMessage');
      emit(AuthError(errorMessage));
    }
  }

  Future<void> _onAppleLoginRequested(
      AppleLoginRequested event,
      Emitter<AuthState> emit,
      ) async {
    print(' Bloc: Processing AppleLoginRequested');
    emit(const AuthLoading());

    final result = await appleLoginUseCase(
      token: event.token,
      firstName: event.firstName,
      lastName: event.lastName,
      email: event.email,
    );

    if (result is DataSuccess) {
      print(' Bloc: Emitting AuthAuthenticated (apple)');
      await _persistAndEmit(result.data!, emit);
    } else if (result is DataFailed) {
      final errorMessage = result.error?.message ?? 'Apple authentication failed';
      print(' Bloc: Emitting AuthError - $errorMessage');
      emit(AuthError(errorMessage));
    }
  }

  Future<void> _onAuthLogoutRequested(
      AuthLogoutRequested event,
      Emitter<AuthState> emit,
      ) async {
    print(' Bloc: Processing logout');
    await preferencesManager.clearUserData();
    await preferencesManager.clearToken();
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