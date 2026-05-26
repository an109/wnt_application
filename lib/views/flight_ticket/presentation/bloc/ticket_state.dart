import 'package:equatable/equatable.dart';
import '../../domain/entities/ticket_entity.dart';

abstract class TicketState extends Equatable {
  const TicketState();
  @override
  List<Object?> get props => [];
}

class TicketInitial extends TicketState {}

class TicketLoading extends TicketState {}

class TicketSuccess extends TicketState {
  final TicketEntity ticket;
  const TicketSuccess(this.ticket);
  @override
  List<Object?> get props => [ticket];
}

class TicketPending extends TicketState {
  final TicketEntity ticket;
  const TicketPending(this.ticket);
  @override
  List<Object?> get props => [ticket];
}

class TicketError extends TicketState {
  final String message;
  const TicketError(this.message);
  @override
  List<Object?> get props => [message];
}
