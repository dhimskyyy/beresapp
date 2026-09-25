import 'package:equatable/equatable.dart';
import '../../../data/models/ticket_model.dart';

abstract class PaymentState extends Equatable {
  const PaymentState();
  @override
  List<Object?> get props => [];
}

class PaymentInitialState extends PaymentState {}

class PaymentLoadingState extends PaymentState {}

class PaymentCompletedSuccessState extends PaymentState {
  final TicketModel paidTicket;
  TicketModel get ticket => paidTicket;
  const PaymentCompletedSuccessState(this.paidTicket);
  @override
  List<Object?> get props => [paidTicket];
}

class PaymentFailureState extends PaymentState {
  final String message;
  const PaymentFailureState(this.message);
  @override
  List<Object?> get props => [message];
}
