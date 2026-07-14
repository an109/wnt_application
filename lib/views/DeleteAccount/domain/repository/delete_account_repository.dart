import '../../../../core/error/data_state.dart';
import '../entity/delete_account_entity.dart';

abstract class DeleteAccountRepository {
  Future<DataState<DeleteAccountEntity>> deleteAccount();
}
