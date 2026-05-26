import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';

abstract class HotelBookingApiService {
  Future<Response> getHotelBookingDetails({
    required String bookingCode,
    required String paymentMode,
  });

  Future<Response> bookHotel({required Map<String, dynamic> payload});

  Future<Response> getBookingDetail({
    required String bookingReferenceId,
    String paymentMode = 'Limit',
  });

  Future<Response> getHcnStatus({
    required String bookingReferenceId,
    required String bookingCreatedAt,
    required String checkInDate,
    String paymentMode = 'Limit',
    int retryCount = 0,
  });

  Future<Response> saveBooking({required Map<String, dynamic> payload});

  Future<Response> cancelBooking({required String confirmationNumber});
}

class HotelBookingApiServiceImpl implements HotelBookingApiService {
  final Dio dio;

  HotelBookingApiServiceImpl(this.dio);

  @override
  Future<Response> getHotelBookingDetails({
    required String bookingCode,
    required String paymentMode,
  }) async {
    try {
      final response = await dio.post(
        Urls.hotelPrebook,
        data: {'BookingCode': bookingCode, 'PaymentMode': paymentMode},
      );
      return response;
    } on DioException catch (e) {
      print('PreBook error: ${e.message}');
      rethrow;
    }
  }

  @override
  Future<Response> bookHotel({required Map<String, dynamic> payload}) async {
    try {
      final response = await dio.post(Urls.hotelBook, data: payload);
      return response;
    } on DioException catch (e) {
      print('Book hotel error: ${e.message}');
      rethrow;
    }
  }

  @override
  Future<Response> getBookingDetail({
    required String bookingReferenceId,
    String paymentMode = 'Limit',
  }) async {
    try {
      final response = await dio.post(
        Urls.hotelBookingDetail,
        data: {'BookingReferenceId': bookingReferenceId, 'PaymentMode': paymentMode},
      );
      return response;
    } on DioException catch (e) {
      print('BookingDetail error: ${e.message}');
      rethrow;
    }
  }

  @override
  Future<Response> getHcnStatus({
    required String bookingReferenceId,
    required String bookingCreatedAt,
    required String checkInDate,
    String paymentMode = 'Limit',
    int retryCount = 0,
  }) async {
    try {
      final response = await dio.post(
        Urls.hotelHcnStatus,
        data: {
          'BookingReferenceId': bookingReferenceId,
          'PaymentMode': paymentMode,
          'BookingCreatedAt': bookingCreatedAt,
          'CheckInDate': checkInDate,
          'RetryCount': retryCount,
        },
      );
      return response;
    } on DioException catch (e) {
      print('HCN status error: ${e.message}');
      rethrow;
    }
  }

  @override
  Future<Response> saveBooking({required Map<String, dynamic> payload}) async {
    try {
      final response = await dio.post(Urls.hotelBookings, data: payload);
      return response;
    } on DioException catch (e) {
      print('Save booking error: ${e.message}');
      rethrow;
    }
  }

  @override
  Future<Response> cancelBooking({required String confirmationNumber}) async {
    try {
      final response = await dio.post(
        Urls.hotelCancel,
        data: {'ConfirmationNumber': confirmationNumber},
      );
      return response;
    } on DioException catch (e) {
      print('Cancel booking error: ${e.message}');
      rethrow;
    }
  }
}