import 'package:bloc/bloc.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/delete_account_entity.dart';
import '../../domain/usecase/delete_account_usecase.dart';
import 'delete_account_event.dart';
import 'delete_account_state.dart';

class DeleteAccountBloc extends Bloc<DeleteAccountEvent, DeleteAccountState> {
  final DeleteAccountUseCase deleteAccountUseCase;

  DeleteAccountBloc({required this.deleteAccountUseCase}) : super(DeleteAccountInitial()) {
    on<DeleteAccountRequested>(_onDeleteAccountRequested);
  }

  Future<void> _onDeleteAccountRequested(
      DeleteAccountRequested event,
      Emitter<DeleteAccountState> emit,
      ) async {
    emit(DeleteAccountLoading());

    final result = await deleteAccountUseCase();

    if (result is DataSuccess<DeleteAccountEntity>) {
      emit(DeleteAccountSuccess(result.data!));
    } else if (result is DataFailed<DeleteAccountEntity>) {
      emit(DeleteAccountFailed(result.error!));
    }
  }
}
