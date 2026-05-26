import 'package:equatable/equatable.dart';
import '../../data/models/ticket_request_model.dart';

abstract class TicketEvent extends Equatable {
  const TicketEvent();
  @override
  List<Object?> get props => [];
}

class IssueTicketEvent extends TicketEvent {
  final TicketRequestModel request;
  const IssueTicketEvent(this.request);
  @override
  List<Object?> get props => [request];
}
