import 'package:equatable/equatable.dart';
import '../../../data/models/ticket_model.dart';
import '../../../data/models/wallet_model.dart';

abstract class PaymentState extends Equatable {
  const PaymentState();
  @override
  List<Object?> get props => [];
}

class PaymentInitialState extends PaymentState {}

class PaymentLoadingState extends PaymentState {}

class DokuInvoiceCreatedState extends PaymentState {
  final Map<String, dynamic> invoiceData;
  const DokuInvoiceCreatedState(this.invoiceData);
  @override
  List<Object?> get props => [invoiceData];
}

class PaymentCompletedSuccessState extends PaymentState {
  final TicketModel paidTicket;
  const PaymentCompletedSuccessState(this.paidTicket);
  @override
  List<Object?> get props => [paidTicket];
}

class WalletLoadedState extends PaymentState {
  final WalletModel wallet;
  const WalletLoadedState(this.wallet);
  @override
  List<Object?> get props => [wallet];
}

class WithdrawalSubmittedSuccessState extends PaymentState {
  final WithdrawalRequest request;
  const WithdrawalSubmittedSuccessState(this.request);
  @override
  List<Object?> get props => [request];
}

class PaymentFailureState extends PaymentState {
  final String message;
  const PaymentFailureState(this.message);
  @override
  List<Object?> get props => [message];
}
