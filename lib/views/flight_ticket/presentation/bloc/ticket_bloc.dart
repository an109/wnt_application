import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/usecase/issue_ticket_usecase.dart';
import 'ticket_event.dart';
import 'ticket_state.dart';

class TicketBloc extends Bloc<TicketEvent, TicketState> {
  final IssueTicketUsecase issueTicketUsecase;

  TicketBloc({required this.issueTicketUsecase}) : super(TicketInitial()) {
    on<IssueTicketEvent>(_onIssueTicket);
  }

  Future<void> _onIssueTicket(
    IssueTicketEvent event,
    Emitter<TicketState> emit,
  ) async {
    emit(TicketLoading());
    final result = await issueTicketUsecase(event.request);
    if (result is DataSuccess) {
      final ticket = result.data!;
      if (ticket.isPending) {
        emit(TicketPending(ticket));
      } else if (ticket.isSuccess) {
        emit(TicketSuccess(ticket));
      } else {
        emit(TicketError(ticket.errorMessage ?? 'Ticket issuance failed'));
      }
    } else if (result is DataFailed) {
      emit(TicketError(result.error?.message ?? 'Ticket issuance failed'));
    }
  }
}
