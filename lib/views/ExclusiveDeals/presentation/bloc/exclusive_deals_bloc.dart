import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/usecase/get_exclusive_deals_usecase.dart';
import '../../domain/entities/exclusive_deal_entity.dart';
import 'exclusive_deals_event.dart';
import 'exclusive_deals_state.dart';

class ExclusiveDealsBloc extends Bloc<ExclusiveDealsEvent, ExclusiveDealsState> {
  final GetExclusiveDealsUseCase getExclusiveDealsUseCase;

  ExclusiveDealsBloc({required this.getExclusiveDealsUseCase})
      : super(const ExclusiveDealsInitial()) {
    on<LoadExclusiveDeals>(_onLoadExclusiveDeals);
    on<RefreshExclusiveDeals>(_onRefreshExclusiveDeals);
  }

  Future<void> _onLoadExclusiveDeals(
      LoadExclusiveDeals event,
      Emitter<ExclusiveDealsState> emit,
      ) async {
    emit(const ExclusiveDealsLoading());

    final result = await getExclusiveDealsUseCase(domain: event.domain);

    // Handle DataState using type checking (no 'when' method)
    if (result is DataSuccess<List<ExclusiveDealEntity>>) {
      final deals = result.data;
      if (deals != null) {
        print('Successfully loaded ${deals.length} exclusive deals');
        emit(ExclusiveDealsLoaded(deals));
      } else {
        emit(const ExclusiveDealsError('No deals found'));
      }
    } else if (result is DataFailed<List<ExclusiveDealEntity>>) {
      final error = result.error;
      final message = _handleDioError(error);
      print('Failed to load exclusive deals: $message');
      emit(ExclusiveDealsError(message));
    }
  }

  Future<void> _onRefreshExclusiveDeals(
      RefreshExclusiveDeals event,
      Emitter<ExclusiveDealsState> emit,
      ) async {
    // Only refresh if not already loading
    if (state is ExclusiveDealsLoading) return;

    final result = await getExclusiveDealsUseCase(domain: event.domain);

    if (result is DataSuccess<List<ExclusiveDealEntity>>) {
      final deals = result.data;
      if (deals != null) {
        print('Successfully refreshed ${deals.length} exclusive deals');
        emit(ExclusiveDealsLoaded(deals));
      }
    } else if (result is DataFailed<List<ExclusiveDealEntity>>) {
      final error = result.error;
      final message = _handleDioError(error);
      print('Failed to refresh exclusive deals: $message');
      // Keep the old state but log the error
      if (state is ExclusiveDealsLoaded) {
        print('Error during refresh: $message');
      }
    }
  }

  String _handleDioError(DioException? error) {
    if (error == null) {
      return 'An unknown error occurred';
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) {
          return 'Unauthorized. Please login again.';
        } else if (statusCode == 403) {
          return 'Access forbidden.';
        } else if (statusCode == 404) {
          return 'Resource not found.';
        } else if (statusCode != null && statusCode >= 500) {
          return 'Server error. Please try again later.';
        }
        return 'Failed to load data. Status: $statusCode';
      case DioExceptionType.cancel:
        return 'Request cancelled.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network.';
      case DioExceptionType.badCertificate:
        return 'Certificate validation failed.';
      case DioExceptionType.unknown:
      default:
        return error.message ?? 'An unknown error occurred';
    }
  }
}