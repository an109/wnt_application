import 'package:wander_nova/core/error/data_state.dart';
import '../entity/HotelBookingEntity.dart';


abstract class HotelListRepository {
  Future<DataState<List<HotelBookingListEntity>>> getHotelBookings();
}