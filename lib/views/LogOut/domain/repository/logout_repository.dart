import '../../../../core/error/data_state.dart';
import '../entity/logout_entity.dart';

abstract class LogoutRepository {
  Future<DataState<LogoutEntity>> logout();
}