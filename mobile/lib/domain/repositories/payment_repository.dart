import '../../data/models/ticket_model.dart';
import '../../data/models/tukang_model.dart';
import '../../data/models/wallet_model.dart';

abstract class PaymentRepository {
  Future<Map<String, dynamic>> createDokuInvoice({
    required String ticketId,
    required double amount,
    required String paymentChannel, // 'VA_BCA', 'VA_MANDIRI', 'VA_BRI', 'QRIS', 'CASH'
  });

  Future<TicketModel> processPaymentSuccess({
    required String ticketId,
    required String paymentMethod,
  });

  Future<WalletModel> getTukangWallet(String tukangId);

  Future<WithdrawalRequest> requestWithdrawal({
    required String tukangId,
    required String tukangName,
    required double amount,
    required PayoutAccount payoutAccount,
  });
}
