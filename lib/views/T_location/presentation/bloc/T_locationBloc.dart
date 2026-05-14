import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/usecase/get_location_usecase.dart';
import 'T_locationEvent.dart';
import 'T_locationState.dart';

class T_locationBloc extends Bloc<T_locationEvent, T_locationState> {
  final GetT_locationsUseCase getT_locationsUseCase;

  T_locationBloc({required this.getT_locationsUseCase}) : super(const T_locationInitial()) {
    on<LoadT_locationsEvent>(_onLoadT_locations);
    on<SearchT_locationsEvent>(_onSearchT_locations);
    on<ClearT_locationsEvent>(_onClearT_locations);
  }

  Future<void> _onLoadT_locations(
      LoadT_locationsEvent event,
      Emitter<T_locationState> emit,
      ) async {
    emit(const T_locationsLoading());

    final result = await getT_locationsUseCase.execute(
      country: event.country,
      searchQuery: null,
    );

    if (result is DataSuccess) {
      final response = result.data;
      if (response != null) {
        emit(T_locationsLoaded(
          locations: response.locations,
          count: response.count,
          sources: response.sources,
        ));
      } else {
        emit(const T_locationsError(message: 'No data received'));
      }
    } else if (result is DataFailed) {
      final error = result.error;
      String errorMessage = 'Failed to load locations';

      if (error != null) {
        if (error.type == DioExceptionType.connectionTimeout) {
          errorMessage = 'Connection timeout. Please check your internet.';
        } else if (error.type == DioExceptionType.receiveTimeout) {
          errorMessage = 'Receive timeout. Server is taking too long.';
        } else if (error.type == DioExceptionType.badResponse) {
          errorMessage = 'Server error: ${error.response?.statusCode}';
        } else if (error.type == DioExceptionType.connectionError) {
          errorMessage = 'Connection error. Please check your network.';
        } else {
          errorMessage = error.message ?? 'Unknown error';
        }
      }

      emit(T_locationsError(message: errorMessage));
    }
  }

  Future<void> _onSearchT_locations(
      SearchT_locationsEvent event,
      Emitter<T_locationState> emit,
      ) async {
    if (event.searchQuery.trim().isEmpty) {
      emit(const T_locationsError(message: 'Search query cannot be empty'));
      return;
    }

    emit(const T_locationsSearchLoading());

    final result = await getT_locationsUseCase.execute(
      country: null,
      searchQuery: event.searchQuery,
    );

    if (result is DataSuccess) {
      final response = result.data;
      if (response != null) {
        emit(T_locationsSearchLoaded(
          locations: response.locations,
          count: response.count,
          sources: response.sources,
        ));
      } else {
        emit(const T_locationsError(message: 'No data received'));
      }
    } else if (result is DataFailed) {
      final error = result.error;
      String errorMessage = 'Search failed';

      if (error != null) {
        if (error.type == DioExceptionType.connectionTimeout) {
          errorMessage = 'Connection timeout. Please check your internet.';
        } else if (error.type == DioExceptionType.receiveTimeout) {
          errorMessage = 'Receive timeout. Server is taking too long.';
        } else if (error.type == DioExceptionType.badResponse) {
          errorMessage = 'Server error: ${error.response?.statusCode}';
        } else if (error.type == DioExceptionType.connectionError) {
          errorMessage = 'Connection error. Please check your network.';
        } else {
          errorMessage = error.message ?? 'Unknown error';
        }
      }

      emit(T_locationsError(message: errorMessage));
    }
  }

  void _onClearT_locations(
      ClearT_locationsEvent event,
      Emitter<T_locationState> emit,
      ) {
    emit(const T_locationInitial());
  }
}