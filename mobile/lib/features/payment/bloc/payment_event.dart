import 'package:equatable/equatable.dart';
import '../../../data/models/tukang_model.dart';

abstract class PaymentEvent extends Equatable {
  const PaymentEvent();
  @override
  List<Object?> get props => [];
}

class CreateDokuInvoiceRequestedEvent extends PaymentEvent {
  final String ticketId;
  final double amount;
  final String paymentChannel;

  const CreateDokuInvoiceRequestedEvent({
    required this.ticketId,
    required this.amount,
    required this.paymentChannel,
  });

  @override
  List<Object?> get props => [ticketId, amount, paymentChannel];
}

class ConfirmPaymentSuccessRequestedEvent extends PaymentEvent {
  final String ticketId;
  final String paymentMethod;

  const ConfirmPaymentSuccessRequestedEvent({
    required this.ticketId,
    required this.paymentMethod,
  });

  @override
  List<Object?> get props => [ticketId, paymentMethod];
}

class FetchTukangWalletRequestedEvent extends PaymentEvent {
  final String tukangId;
  const FetchTukangWalletRequestedEvent(this.tukangId);
  @override
  List<Object?> get props => [tukangId];
}

class RequestWithdrawalRequestedEvent extends PaymentEvent {
  final String tukangId;
  final String tukangName;
  final double amount;
  final PayoutAccount payoutAccount;

  const RequestWithdrawalRequestedEvent({
    required this.tukangId,
    required this.tukangName,
    required this.amount,
    required this.payoutAccount,
  });

  @override
  List<Object?> get props => [tukangId, tukangName, amount, payoutAccount];
}
