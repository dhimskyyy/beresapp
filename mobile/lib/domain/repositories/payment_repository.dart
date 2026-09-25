import '../../data/models/ticket_model.dart';

abstract class PaymentRepository {
  Future<TicketModel> processPaymentSuccess({
    required String ticketId,
    required String paymentMethod,
  });
}
