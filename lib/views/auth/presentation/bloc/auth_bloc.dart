import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/data_state.dart';
import '../../../../core/utils/storage/shared_preference.dart';
import '../../domain/entity/user_entity.dart';
import '../../domain/usecase/google_auth_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GoogleLoginUseCase googleLoginUseCase;
  final PreferencesManager preferencesManager;

  AuthBloc({
    required this.googleLoginUseCase,
    required this.preferencesManager,
  }) : super(const AuthInitial()) {
    on<GoogleLoginRequested>(_onGoogleLoginRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthTokenRefreshRequested>(_onAuthTokenRefreshRequested);
    on<AuthCheckStatusRequested>(_onAuthCheckStatusRequested);

    add(const AuthCheckStatusRequested());
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
      print(' Bloc: Emitting AuthAuthenticated');
      // Save user data to local storage
      final user = result.data!;
      await preferencesManager.saveUserData(user.toJson()); // Add toJson method
      if (user.accessToken != null) {
        await preferencesManager.saveToken(user.accessToken!);
      }
      if (user.refreshToken != null) {
        await preferencesManager.saveRefreshToken(user.refreshToken!);
      }
      await preferencesManager.saveUserType(int.tryParse(user.userType ?? '0') ?? 0);

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