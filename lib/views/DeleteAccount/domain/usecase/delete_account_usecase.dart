import '../../../../core/error/data_state.dart';
import '../entity/delete_account_entity.dart';
import '../repository/delete_account_repository.dart';

class DeleteAccountUseCase {
  final DeleteAccountRepository repository;

  DeleteAccountUseCase(this.repository);

  Future<DataState<DeleteAccountEntity>> call() async {
    return await repository.deleteAccount();
  }
}
