

import 'package:dio/dio.dart';
import 'package:wander_nova/views/MyBookings/Flights/domain/repository/FlightBookRepository.dart';

import '../../../../../core/error/data_state.dart';
import '../../domain/entities/FlightBookEntity.dart';
import '../data_source/FlightBookApiService.dart';
import '../models/FlightBookModel.dart';

class FlightBookRepositoryImpl implements FlightBookRepository {
  final FlightBookApiService bookingApiService;

  FlightBookRepositoryImpl(this.bookingApiService);

  @override
  Future<DataState<List<FlightBookEntity>>> getBookings({int? userId}) async {
    try {
      final response = await bookingApiService.getBookings(userId: userId);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;

        if (data['success'] == true && data['bookings'] != null) {
          final List<dynamic> bookingsJson = data['bookings'];
          final List<FlightBookEntity> bookings = bookingsJson
              .map((json) => BookingModel.fromJson(json))
              .toList();

          print('SUCCESS: Retrieved ${bookings.length} bookings');
          return DataSuccess(bookings);
        } else {
          print('ERROR: API returned success=false or no bookings');
          return  DataFailed(
            DioException(
              requestOptions: RequestOptions(path: ''),
              error: 'No bookings found',
              type: DioExceptionType.badResponse,
              response: Response(
                statusCode: 200,
                requestOptions: RequestOptions(path: ''),
              ),
            ),
          );
        }
      } else {
        print('ERROR: Invalid response status code: ${response.statusCode}');
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: ''),
            error: 'Invalid response',
            type: DioExceptionType.badResponse,
            response: response,
          ),
        );
      }
    } on DioException catch (e) {
      print('DioException in repository: ${e.message}');
      return DataFailed(e);
    } catch (e) {
      print('Unknown exception in repository: $e');
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}