import '../../../../core/error/data_state.dart';
import '../entities/ticket_entity.dart';
import '../repository/ticket_repository.dart';
import '../../data/models/ticket_request_model.dart';

class IssueTicketUsecase {
  final TicketRepository repository;

  IssueTicketUsecase(this.repository);

  Future<DataState<TicketEntity>> call(TicketRequestModel request) {
    return repository.issueTicket(request);
  }
}
