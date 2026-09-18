import '../../domain/entities/ticket_status.dart';
import '../../domain/repositories/payment_repository.dart';
import '../models/ticket_model.dart';
import '../models/tukang_model.dart';
import '../models/wallet_model.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  static final Map<String, WalletModel> _wallets = {
    'TKG-001': WalletModel(
      tukangId: 'TKG-001',
      balance: 350000,
      transactions: [
        WalletTransaction(
          id: 'trx_1',
          type: 'income',
          amount: 150000,
          adminFee: 0,
          netAmount: 150000,
          title: 'Pendapatan Tiket #TCK-801 (AC Bocor)',
          status: 'completed',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        WalletTransaction(
          id: 'trx_2',
          type: 'income',
          amount: 200000,
          adminFee: 0,
          netAmount: 200000,
          title: 'Pendapatan Tiket #TCK-789 (Servis Pompa)',
          status: 'completed',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ],
    ),
  };

  static final List<WithdrawalRequest> _withdrawalRequests = [];

  @override
  Future<Map<String, dynamic>> createDokuInvoice({
    required String ticketId,
    required double amount,
    required String paymentChannel,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final String vaNumber = '8801${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    final String qrisUrl = 'https://images.unsplash.com/photo-1595079672139-cee25825d0d0?w=400';

    return {
      'invoiceId': 'INV-DOKU-${DateTime.now().millisecondsSinceEpoch}',
      'paymentChannel': paymentChannel,
      'amount': amount,
      'vaNumber': vaNumber,
      'qrisUrl': qrisUrl,
      'expiredAt': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
    };
  }

  @override
  Future<TicketModel> processPaymentSuccess({
    required String ticketId,
    required String paymentMethod,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    // Update wallet balance for tukang
    final wallet = await getTukangWallet('TKG-001');
    final incomeTx = WalletTransaction(
      id: 'trx_${DateTime.now().millisecondsSinceEpoch}',
      type: 'income',
      amount: 125000,
      adminFee: 0,
      netAmount: 125000,
      title: 'Pendapatan Tiket #$ticketId',
      status: 'completed',
      createdAt: DateTime.now(),
    );

    _wallets['TKG-001'] = WalletModel(
      tukangId: 'TKG-001',
      balance: wallet.balance + 125000,
      transactions: [incomeTx, ...wallet.transactions],
    );

    // Return dummy paid ticket
    return TicketModel(
      id: ticketId,
      userId: 'USR-001',
      userName: 'Siti Rahmawati',
      category: 'ac',
      title: 'Pekerjaan AC Tuntas',
      description: 'Air AC sudah jernih kembali.',
      photoUrls: [],
      address: 'Jl. Wijaya II No. 18, Kebayoran Baru',
      lat: -6.2382,
      lng: 106.8123,
      status: TicketStatus.completed,
      selectedTukangId: 'TKG-001',
      selectedTukangName: 'Ahmad Subarjo',
      bids: [],
      paymentMethod: paymentMethod,
      paymentStatus: 'paid',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<WalletModel> getTukangWallet(String tukangId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (!_wallets.containsKey(tukangId)) {
      _wallets[tukangId] = WalletModel(tukangId: tukangId, balance: 0, transactions: []);
    }
    return _wallets[tukangId]!;
  }

  @override
  Future<WithdrawalRequest> requestWithdrawal({
    required String tukangId,
    required String tukangName,
    required double amount,
    required PayoutAccount payoutAccount,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    final wallet = await getTukangWallet(tukangId);

    if (amount < 20000) {
      throw Exception('Minimal penarikan saldo adalah Rp 20.000');
    }

    if (wallet.balance < amount) {
      throw Exception('Saldo dompet digital Anda tidak mencukupi untuk penarikan sebesar Rp ${amount.toStringAsFixed(0)}');
    }

    const double adminFee = 2500;
    final double netAmount = amount - adminFee;

    final request = WithdrawalRequest(
      id: 'WD-${DateTime.now().millisecondsSinceEpoch}',
      tukangId: tukangId,
      tukangName: tukangName,
      amount: amount,
      adminFee: adminFee,
      netAmount: netAmount,
      payoutAccount: payoutAccount,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    // Deduct amount from wallet balance
    final wdTx = WalletTransaction(
      id: 'trx_wd_${DateTime.now().millisecondsSinceEpoch}',
      type: 'withdrawal',
      amount: amount,
      adminFee: adminFee,
      netAmount: netAmount,
      title: 'Penarikan Saldo (${payoutAccount.provider} - ${payoutAccount.accountNumber})',
      status: 'pending',
      createdAt: DateTime.now(),
    );

    _wallets[tukangId] = WalletModel(
      tukangId: tukangId,
      balance: wallet.balance - amount,
      transactions: [wdTx, ...wallet.transactions],
    );

    _withdrawalRequests.add(request);
    return request;
  }
}
