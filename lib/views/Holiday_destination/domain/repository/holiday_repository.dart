import '../../../../core/error/data_state.dart';
import '../entities/holiday_destination_entity.dart';

abstract class HolidayRepository {
  Future<DataState<List<HolidayDestinationEntity>>> getPopularDestinations({String? domain});
}