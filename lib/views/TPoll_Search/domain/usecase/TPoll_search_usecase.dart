import '../../../../core/error/data_state.dart';
import '../entities/TPollSearchEntity.dart';
import '../repository/TPoll_Search_repository.dart';

class TpollSearchUseCase {
  final TpollSearchRepository repository;

  TpollSearchUseCase(this.repository);

  Future<DataState<TpollSearchEntity>> call(String searchId) {
    return repository.pollSearchResults(searchId);
  }
}