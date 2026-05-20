import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/views/VisaDestination/presentation/bloc/visaDestin_event.dart';
import 'package:wander_nova/views/VisaDestination/presentation/bloc/visaDestin_state.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/visaDestin_Entity.dart';
import '../../domain/usecase/get_visaDestin_usecase.dart';

class VisaDestinationBloc extends Bloc<VisaDestinationEvent, VisaDestinationState> {
  final GetVisaDestinationsUseCase getVisaDestinationsUseCase;

  VisaDestinationBloc({required this.getVisaDestinationsUseCase})
      : super(VisaDestinationInitial()) {
    on<LoadVisaDestinations>(_onLoadVisaDestinations);
    on<RefreshVisaDestinations>(_onRefreshVisaDestinations);
  }

  Future<void> _onLoadVisaDestinations(
      LoadVisaDestinations event,
      Emitter<VisaDestinationState> emit,
      ) async {
    emit(VisaDestinationLoading());

    final result = await getVisaDestinationsUseCase(domain: event.domain);

    if (result is DataSuccess<List<VisaDestinationEntity>>) {
      emit(VisaDestinationLoaded(result.data!));
    } else if (result is DataFailed<List<VisaDestinationEntity>>) {
      final errorMessage = _handleDioError(result.error);
      emit(VisaDestinationError(errorMessage));
    }
  }

  Future<void> _onRefreshVisaDestinations(
      RefreshVisaDestinations event,
      Emitter<VisaDestinationState> emit,
      ) async {
    // Keep current state while refreshing
    if (state is VisaDestinationLoaded) {
      emit(state);
    }

    final result = await getVisaDestinationsUseCase(domain: event.domain);

    if (result is DataSuccess<List<VisaDestinationEntity>>) {
      emit(VisaDestinationLoaded(result.data!));
    } else if (result is DataFailed<List<VisaDestinationEntity>>) {
      final errorMessage = _handleDioError(result.error);
      emit(VisaDestinationError(errorMessage));
    }
  }

  String _handleDioError(dynamic error) {
    if (error == null) {
      return 'An unknown error occurred';
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.badResponse:
        return 'Server error: ${error.response?.statusCode}';
      case DioExceptionType.cancel:
        return 'Request cancelled';
      case DioExceptionType.connectionError:
        return 'No internet connection';
      case DioExceptionType.badCertificate:
        return 'Certificate error';
      case DioExceptionType.unknown:
      default:
        return error.message ?? 'An error occurred while loading destinations';
    }
  }
}