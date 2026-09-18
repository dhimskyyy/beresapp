import 'package:equatable/equatable.dart';
import '../../../data/models/ticket_model.dart';

abstract class TicketState extends Equatable {
  const TicketState();
  @override
  List<Object?> get props => [];
}

class TicketInitialState extends TicketState {}

class TicketLoadingState extends TicketState {}

class TicketCreatedSuccessState extends TicketState {
  final TicketModel ticket;
  const TicketCreatedSuccessState(this.ticket);
  @override
  List<Object?> get props => [ticket];
}

class TicketListLoadedState extends TicketState {
  final List<TicketModel> tickets;
  const TicketListLoadedState(this.tickets);
  @override
  List<Object?> get props => [tickets];
}

class BidSubmittedSuccessState extends TicketState {
  final TicketModel updatedTicket;
  const BidSubmittedSuccessState(this.updatedTicket);
  @override
  List<Object?> get props => [updatedTicket];
}

class TukangLockedSuccessState extends TicketState {
  final TicketModel lockedTicket;
  const TukangLockedSuccessState(this.lockedTicket);
  @override
  List<Object?> get props => [lockedTicket];
}

class TicketOperationFailureState extends TicketState {
  final String message;
  const TicketOperationFailureState(this.message);
  @override
  List<Object?> get props => [message];
}
