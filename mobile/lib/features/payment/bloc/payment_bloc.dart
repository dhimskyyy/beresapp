import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/payment_repository.dart';
import 'payment_event.dart';
import 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentRepository paymentRepository;

  PaymentBloc({required this.paymentRepository}) : super(PaymentInitialState()) {
    on<CreateDokuInvoiceRequestedEvent>(_onCreateInvoice);
    on<ConfirmPaymentSuccessRequestedEvent>(_onConfirmPayment);
    on<FetchTukangWalletRequestedEvent>(_onFetchWallet);
    on<RequestWithdrawalRequestedEvent>(_onRequestWithdrawal);
  }

  Future<void> _onCreateInvoice(CreateDokuInvoiceRequestedEvent event, Emitter<PaymentState> emit) async {
    emit(PaymentLoadingState());
    try {
      final invoice = await paymentRepository.createDokuInvoice(
        ticketId: event.ticketId,
        amount: event.amount,
        paymentChannel: event.paymentChannel,
      );
      emit(DokuInvoiceCreatedState(invoice));
    } catch (e) {
      emit(PaymentFailureState('Gagal membuat tagihan DOKU: ${e.toString()}'));
    }
  }

  Future<void> _onConfirmPayment(ConfirmPaymentSuccessRequestedEvent event, Emitter<PaymentState> emit) async {
    emit(PaymentLoadingState());
    try {
      final paidTicket = await paymentRepository.processPaymentSuccess(
        ticketId: event.ticketId,
        paymentMethod: event.paymentMethod,
      );
      emit(PaymentCompletedSuccessState(paidTicket));
    } catch (e) {
      emit(PaymentFailureState('Gagal memproses pembayaran: ${e.toString()}'));
    }
  }

  Future<void> _onFetchWallet(FetchTukangWalletRequestedEvent event, Emitter<PaymentState> emit) async {
    emit(PaymentLoadingState());
    try {
      final wallet = await paymentRepository.getTukangWallet(event.tukangId);
      emit(WalletLoadedState(wallet));
    } catch (e) {
      emit(PaymentFailureState('Gagal memuat saldo dompet: ${e.toString()}'));
    }
  }

  Future<void> _onRequestWithdrawal(RequestWithdrawalRequestedEvent event, Emitter<PaymentState> emit) async {
    emit(PaymentLoadingState());
    try {
      final wd = await paymentRepository.requestWithdrawal(
        tukangId: event.tukangId,
        tukangName: event.tukangName,
        amount: event.amount,
        payoutAccount: event.payoutAccount,
      );
      emit(WithdrawalSubmittedSuccessState(wd));
    } catch (e) {
      emit(PaymentFailureState(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
