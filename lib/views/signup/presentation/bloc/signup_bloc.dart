import 'package:bloc/bloc.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/signup_entity.dart';
import '../../domain/usecase/signup_usecase.dart';
import 'signup_event.dart';
import 'signup_state.dart';

class SignupBloc extends Bloc<SignupEvent, SignupState> {
  final SignupUseCase signupUseCase;

  SignupBloc({required this.signupUseCase}) : super(SignupInitial()) {
    on<SignupSubmitted>(_onSignupSubmitted);
    on<SignupReset>(_onSignupReset);
  }

  Future<void> _onSignupSubmitted(
      SignupSubmitted event,
      Emitter<SignupState> emit,
      ) async {
    emit(SignupLoading());

    final result = await signupUseCase(
      firstname: event.firstname,
      lastname: event.lastname,
      password: event.password,
      email: event.email,
      phone: event.phone,
      phoneCode: event.phoneCode,
    );

    if (result is DataSuccess<SignupEntity>) {
      emit(SignupSuccess(result.data!));
    } else if (result is DataFailed<SignupEntity>) {
      final errorMessage = _handleError(result.error);
      emit(SignupFailed(errorMessage));
    }
  }

  void _onSignupReset(SignupReset event, Emitter<SignupState> emit) {
    emit(SignupInitial());
  }

  String _handleError(dynamic error) {
    if (error == null) return 'An unknown error occurred';

    if (error is String) return error;

    // Handle DioException
    if (error.toString().contains('DioException')) {
      if (error.response?.statusCode == 400) {
        return error.response?.data['message'] ?? 'Invalid input data';
      } else if (error.response?.statusCode == 409) {
        return 'User already exists with this phone number';
      } else if (error.response?.statusCode == 500) {
        return 'Server error. Please try again later';
      }
      return error.message ?? 'Network error. Please check your connection';
    }

    return error.toString();
  }
}