import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/payment_repository.dart';
import 'payment_event.dart';
import 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentRepository paymentRepository;

  PaymentBloc({required this.paymentRepository}) : super(PaymentInitialState()) {
    on<ConfirmPaymentSuccessRequestedEvent>(_onConfirmPayment);
  }

  Future<void> _onConfirmPayment(
    ConfirmPaymentSuccessRequestedEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoadingState());
    try {
      final paidTicket = await paymentRepository.processPaymentSuccess(
        ticketId: event.ticketId,
        paymentMethod: event.paymentMethod,
      );
      emit(PaymentCompletedSuccessState(paidTicket));
    } catch (e) {
      emit(PaymentFailureState('Gagal memproses pembayaran tunai: ${e.toString()}'));
    }
  }
}
