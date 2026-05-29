import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/login_entity.dart';
import '../../domain/usecase/login_usecase.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final LoginUseCase loginUseCase;

  LoginBloc({required this.loginUseCase}) : super(LoginInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
    on<LoginReset>(_onLoginReset);
  }

  Future<void> _onLoginSubmitted(
      LoginSubmitted event,
      Emitter<LoginState> emit,
      ) async {
    print('LoginBloc: Processing login for ${event.contactType}: ${event.contactValue}');

    // Validate input
    if (event.contactValue.trim().isEmpty) {
      print('LoginBloc: Validation failed - contact value is empty');
      emit(LoginValidationError(
        event.contactType,
        '${event.contactType == 'email' ? 'Email' : 'Phone'} is required',
      ));
      return;
    }

    if (event.password.length < 6) {
      print('LoginBloc: Validation failed - password too short');
      emit(const LoginValidationError(
        'password',
        'Password must be at least 6 characters',
      ));
      return;
    }

    emit(LoginLoading());
    print('LoginBloc: Emitting Loading state');

    try {
      final result = await loginUseCase(
        contactValue: event.contactValue.trim(),
        password: event.password,
        contactType: event.contactType,
      );

      print('LoginBloc: UseCase result type: ${result.runtimeType}');

      if (result is DataSuccess<LoginEntity>) {
        print('LoginBloc: Login successful');
        emit(LoginSuccess(result.data!));
      } else if (result is DataFailed<LoginEntity>) {
        final error = result.error;
        print('LoginBloc: Login failed - ${error?.message}');

        String errorMessage = 'Login failed. Please try again.';

        if (error != null) {
          if (error.type == DioExceptionType.badResponse) {
            final responseData = error.response?.data;
            if (responseData is Map<String, dynamic>) {
              errorMessage = responseData['message'] ??
                  responseData['error'] ??
                  errorMessage;
            } else if (responseData is String) {
              errorMessage = responseData;
            }
          } else if (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout) {
            errorMessage = 'Connection timeout. Please check your network.';
          } else if (error.type == DioExceptionType.connectionError) {
            errorMessage = 'Unable to connect to server. Please check your connection.';
          } else {
            errorMessage = error.message ?? errorMessage;
          }
        }

        emit(LoginFailure(errorMessage, dioError: error));
      }
    } catch (e, stackTrace) {
      print('LoginBloc: Unexpected error: $e');
      print('Stack trace: $stackTrace');
      emit(const LoginFailure('An unexpected error occurred. Please try again.'));
    }
  }

  void _onLoginReset(LoginReset event, Emitter<LoginState> emit) {
    print('LoginBloc: Resetting login state');
    emit(LoginInitial());
  }
}