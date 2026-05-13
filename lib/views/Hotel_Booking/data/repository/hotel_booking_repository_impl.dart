import 'package:dio/dio.dart';

import '../../../../core/error/data_state.dart';
import '../../data/data_source/hotel_booking_api_service.dart';
import '../../domain/entities/hotel_booking_entity.dart';
import '../../domain/repository/hotel_booking_repository.dart';
import '../models/hotel_booking_models.dart';

class HotelBookingRepositoryImpl implements HotelBookingRepository {
  final HotelBookingApiService apiService;

  HotelBookingRepositoryImpl(this.apiService);

  @override
  Future<DataState<HotelBookingEntity>> getHotelBookingDetails({
    required String bookingCode,
    required String paymentMode,
  }) async {
    try {
      final response = await apiService.getHotelBookingDetails(
        bookingCode: bookingCode,
        paymentMode: paymentMode,
      );

      if (response.statusCode == 200) {
        final hotelBookingModel = HotelBookingModel.fromJson(response.data);
        final hotelBookingEntity = _mapToEntity(hotelBookingModel);
        return DataSuccess(hotelBookingEntity);
      } else {
        return  DataFailed(
          DioException(
            requestOptions: RequestOptions(path: ''),
            error: 'Failed to fetch hotel booking details',
            type: DioExceptionType.badResponse,
          ),
        );
      }
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  HotelBookingEntity _mapToEntity(HotelBookingModel model) {
    return HotelBookingEntity(
      status: StatusEntity(
        code: model.status.code,
        description: model.status.description,
      ),
      hotelResult: model.hotelResult.map((hotel) {
        return HotelResultEntity(
          hotelCode: hotel.hotelCode,
          currency: hotel.currency,
          rooms: hotel.rooms.map((room) {
            return RoomEntity(
              name: room.name,
              bookingCode: room.bookingCode,
              inclusion: room.inclusion,
              totalFare: room.totalFare,
              totalTax: room.totalTax,
              recommendedSellingRate: room.recommendedSellingRate,
              roomPromotion: room.roomPromotion,
              cancelPolicies: room.cancelPolicies.map((policy) {
                return CancelPolicyEntity(
                  fromDate: policy.fromDate,
                  chargeType: policy.chargeType,
                  cancellationCharge: policy.cancellationCharge,
                );
              }).toList(),
              mealType: room.mealType,
              isRefundable: room.isRefundable,
              amenities: room.amenities,
            );
          }).toList(),
          rateConditions: hotel.rateConditions,
        );
      }).toList(),
    );
  }
}