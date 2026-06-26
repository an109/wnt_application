
import '../../../../../core/error/data_state.dart';
import '../entities/FlightBookEntity.dart';

abstract class FlightBookRepository {
  Future<DataState<List<FlightBookEntity>>> getBookings({int? userId});
}