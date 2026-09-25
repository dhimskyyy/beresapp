import 'package:equatable/equatable.dart';

abstract class PaymentEvent extends Equatable {
  const PaymentEvent();
  @override
  List<Object?> get props => [];
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
