import '../../../../core/error/data_state.dart';
import '../entities/ticket_entity.dart';
import '../../data/models/ticket_request_model.dart';

abstract class TicketRepository {
  Future<DataState<TicketEntity>> issueTicket(TicketRequestModel request);
}
