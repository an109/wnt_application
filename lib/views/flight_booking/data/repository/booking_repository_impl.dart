import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/repository/booking_repository.dart';
import '../data_source/booking_api_service.dart';
import '../models/booking_request_model.dart';

class BookingRepositoryImpl implements BookingRepository {
  final BookingApiService apiService;

  BookingRepositoryImpl(this.apiService);

  @override
  Future<DataState<BookingEntity>> bookFlight(BookingRequestModel request) async {
    try {
      final response = await apiService.bookFlight(request);
      final data = response.response;

      final entity = BookingEntity(
        responseStatus: data?.responseStatus,
        errorCode: data?.error?.errorCode,
        errorMessage: data?.error?.errorMessage,
        traceId: data?.traceId,
        pnr: data?.pnr,
        bookingId: data?.bookingId,
        isPriceChanged: data?.isPriceChanged,
        status: data?.status,
      );

      return DataSuccess(entity);
    } on DioException catch (e) {
      return DataFailed(e);
    }
  }
}
