import '../../../../core/error/data_state.dart';
import '../entities/TPollSearchEntity.dart';

abstract class TpollSearchRepository {
  Future<DataState<TpollSearchEntity>> pollSearchResults(String searchId);
}