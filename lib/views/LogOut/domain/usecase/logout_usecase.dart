import '../../../../core/error/data_state.dart';
import '../entity/logout_entity.dart';
import '../repository/logout_repository.dart';

class LogoutUseCase {
  final LogoutRepository repository;

  LogoutUseCase(this.repository);

  Future<DataState<LogoutEntity>> call() async {
    return await repository.logout();
  }
}