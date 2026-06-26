
import '../../../../../core/error/data_state.dart';
import '../entities/FlightBookEntity.dart';
import '../repository/FlightBookRepository.dart';

class GetBookUseCase {
  final FlightBookRepository repository;

  GetBookUseCase(this.repository);

  Future<DataState<List<FlightBookEntity>>> call({int? userId}) async {
    return await repository.getBookings(userId: userId);
  }
}