import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entities/trending_routes_entity.dart';
import '../../domain/usecase/get_trending_routes_usecase.dart';
import 'trending_routes_event.dart';
import 'trending_routes_state.dart';

class TrendingRoutesBloc
    extends Bloc<TrendingRoutesEvent, TrendingRoutesState> {
  final GetTrendingRoutesUseCase getTrendingRoutesUseCase;

  TrendingRoutesBloc({required this.getTrendingRoutesUseCase})
      : super(const TrendingRoutesInitial()) {
    on<LoadTrendingRoutes>(_onLoadTrendingRoutes);
    on<RefreshTrendingRoutes>(_onRefreshTrendingRoutes);
  }

  Future<void> _onLoadTrendingRoutes(
      LoadTrendingRoutes event,
      Emitter<TrendingRoutesState> emit,
      ) async {
    print('BLoC: Loading trending routes...');
    emit(const TrendingRoutesLoading());

    final result = await getTrendingRoutesUseCase(domain: event.domain);

    if (result is DataSuccess<List<TrendingRouteEntity>>) {
      print('BLoC: Successfully loaded ${result.data!.length} routes');
      emit(TrendingRoutesLoaded(result.data!));
    } else if (result is DataFailed<List<TrendingRouteEntity>>) {
      final errorMessage = _getErrorMessage(result.error);
      print('BLoC: Error loading routes - $errorMessage');
      emit(TrendingRoutesError(errorMessage));
    }
  }

  Future<void> _onRefreshTrendingRoutes(
      RefreshTrendingRoutes event,
      Emitter<TrendingRoutesState> emit,
      ) async {
    print('BLoC: Refreshing trending routes...');

    // Don't emit loading state if we already have data (for pull-to-refresh)
    final currentState = state;
    if (currentState is! TrendingRoutesLoading) {
      // Keep current state while refreshing
    }

    final result = await getTrendingRoutesUseCase(domain: event.domain);

    if (result is DataSuccess<List<TrendingRouteEntity>>) {
      print('BLoC: Successfully refreshed ${result.data!.length} routes');
      emit(TrendingRoutesLoaded(result.data!));
    } else if (result is DataFailed<List<TrendingRouteEntity>>) {
      final errorMessage = _getErrorMessage(result.error);
      print('BLoC: Error refreshing routes - $errorMessage');
      // If we have existing data, keep it and just show error
      if (currentState is TrendingRoutesLoaded) {
        emit(TrendingRoutesError(errorMessage));
      } else {
        emit(TrendingRoutesError(errorMessage));
      }
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error == null) {
      return 'An unknown error occurred';
    }

    // more specific error handling here
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please check your internet.';
      case DioExceptionType.sendTimeout:
        return 'Send timeout. Please try again.';
      case DioExceptionType.receiveTimeout:
        return 'Receive timeout. Please try again.';
      case DioExceptionType.badResponse:
        return 'Server error: ${error.response?.statusCode}';
      case DioExceptionType.cancel:
        return 'Request cancelled';
      case DioExceptionType.connectionError:
        return 'No internet connection';
      case DioExceptionType.unknown:
      default:
        return error.message ?? 'An unknown error occurred';
    }
  }
}