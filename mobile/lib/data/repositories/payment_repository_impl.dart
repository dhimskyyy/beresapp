import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/ticket_status.dart';
import '../../domain/repositories/payment_repository.dart';
import '../models/ticket_model.dart';
import '../models/tukang_model.dart';
import '../models/wallet_model.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    await Future.delayed(const Duration(milliseconds: 600));

    // 1. Fetch current ticket from Firestore if available
    TicketModel? existingTicket;
    try {
      final doc = await _firestore.collection('tickets').doc(ticketId).get();
      if (doc.exists && doc.data() != null) {
        existingTicket = TicketModel.fromMap(doc.data()!, doc.id);
      }
    } catch (_) {}

    final String tukangId = existingTicket?.selectedTukangId ?? 'TKG-001';
    final double earnedAmount = existingTicket?.finalBill?.totalAmount ?? 125000.0;

    // 2. Update local wallet (safeguard: balance never negative)
    final wallet = await getTukangWallet(tukangId);
    final currentBal = wallet.balance < 0 ? 0.0 : wallet.balance;
    final double newBalance = currentBal + earnedAmount;

    final incomeTx = WalletTransaction(
      id: 'trx_${DateTime.now().millisecondsSinceEpoch}',
      type: 'income',
      amount: earnedAmount,
      adminFee: 0,
      netAmount: earnedAmount,
      title: 'Pendapatan Tiket #$ticketId (${existingTicket?.title ?? "Pekerjaan Tuntas"})',
      status: 'completed',
      createdAt: DateTime.now(),
    );

    _wallets[tukangId] = WalletModel(
      tukangId: tukangId,
      balance: newBalance,
      transactions: [incomeTx, ...wallet.transactions],
    );

    // 3. Construct updated ticket model
    final updatedTicket = TicketModel(
      id: existingTicket?.id ?? ticketId,
      userId: existingTicket?.userId ?? 'USR-001',
      userName: existingTicket?.userName ?? 'Siti Rahmawati',
      category: existingTicket?.category ?? 'ac',
      title: existingTicket?.title ?? 'Pekerjaan AC Tuntas',
      description: existingTicket?.description ?? 'Pekerjaan telah selesai dan lunas.',
      photoUrls: existingTicket?.photoUrls ?? [],
      address: existingTicket?.address ?? 'Jl. Wijaya II No. 18, Kebayoran Baru',
      lat: existingTicket?.lat ?? -6.2382,
      lng: existingTicket?.lng ?? 106.8123,
      status: TicketStatus.completed,
      selectedTukangId: tukangId,
      selectedTukangName: existingTicket?.selectedTukangName ?? 'Ahmad Subarjo',
      bids: existingTicket?.bids ?? [],
      finalBill: existingTicket?.finalBill,
      beforePhotos: existingTicket?.beforePhotos ?? [],
      afterPhotos: existingTicket?.afterPhotos ?? [],
      paymentMethod: paymentMethod,
      paymentStatus: 'paid',
      dokuInvoiceId: existingTicket?.dokuInvoiceId,
      ratingStars: existingTicket?.ratingStars,
      ratingReview: existingTicket?.ratingReview,
      cancelReason: existingTicket?.cancelReason,
      createdAt: existingTicket?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // 4. Sync ticket status & tukang wallet balance to Cloud Firestore
    try {
      debugPrint('[PaymentRepo] Mengirim status pembayaran lunas tiket $ticketId ke Cloud Firestore...');
      await _firestore.collection('tickets').doc(ticketId).set(
        updatedTicket.toMap(),
        SetOptions(merge: true),
      );

      await _firestore.collection('tukang').doc(tukangId).set({
        'walletBalance': newBalance,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
      debugPrint('[PaymentRepo] SUKSES: Pembayaran tiket & saldo tukang tersimpan di Cloud Firestore! Saldo baru: $newBalance');
    } catch (e) {
      debugPrint('[PaymentRepo] GAGAL menyimpan pembayaran ke Firestore: $e');
    }

    return updatedTicket;
  }

  @override
  Future<WalletModel> getTukangWallet(String tukangId) async {
    // 1. Check Cloud Firestore for live wallet balance
    double liveBalance = 0;
    bool hasCloudBalance = false;
    try {
      final doc = await _firestore.collection('tukang').doc(tukangId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data.containsKey('walletBalance')) {
          liveBalance = (data['walletBalance'] as num).toDouble();
          // Auto-heal negative balance: never allow below 0!
          if (liveBalance < 0) {
            liveBalance = 0.0;
            try {
              await _firestore.collection('tukang').doc(tukangId).set({
                'walletBalance': 0.0,
                'updatedAt': DateTime.now().toIso8601String(),
              }, SetOptions(merge: true));
            } catch (_) {}
          }
          hasCloudBalance = true;
        }
      }
    } catch (e) {
      debugPrint('[PaymentRepo] Error reading tukang balance: $e');
    }

    // 2. Query Cloud Firestore for all withdrawals of this tukang (to sync approved/rejected status!)
    final Map<String, Map<String, dynamic>> cloudWdMap = {};
    try {
      final wdSnap = await _firestore
          .collection('withdrawals')
          .where('tukangId', isEqualTo: tukangId)
          .get();

      for (final doc in wdSnap.docs) {
        cloudWdMap[doc.id] = doc.data();
      }
    } catch (e) {
      debugPrint('[PaymentRepo] Error reading withdrawals: $e');
    }

    // 3. Merge transactions: update local transactions with Firestore live status
    final List<WalletTransaction> currentTx = _wallets[tukangId]?.transactions ?? <WalletTransaction>[];
    final List<WalletTransaction> mergedTxList = [];
    final Set<String> processedWdIds = {};

    for (final tx in currentTx) {
      if (tx.type == 'withdrawal') {
        final cleanId = tx.id.replaceAll('trx_', '');
        final cloudDoc = cloudWdMap[cleanId] ?? cloudWdMap[tx.id];

        if (cloudDoc != null) {
          processedWdIds.add(cleanId);
          processedWdIds.add(tx.id);
          mergedTxList.add(WalletTransaction(
            id: tx.id,
            type: 'withdrawal',
            amount: tx.amount,
            adminFee: tx.adminFee,
            netAmount: tx.netAmount,
            title: tx.title,
            status: cloudDoc['status'] ?? tx.status,
            createdAt: tx.createdAt,
          ));
          continue;
        }
      }
      mergedTxList.add(tx);
    }

    // 4. Add any cloud withdrawals that are not in local memory yet
    for (final entry in cloudWdMap.entries) {
      final docId = entry.key;
      if (!processedWdIds.contains(docId) && !processedWdIds.contains('trx_$docId')) {
        final w = entry.value;
        final payoutTarget = w['payoutTarget'] as Map<String, dynamic>? ?? {};
        final provider = payoutTarget['provider'] ?? 'Bank/E-Wallet';
        final accNo = payoutTarget['accountNumber'] ?? '';
        final amount = (w['amount'] as num?)?.toDouble() ?? 0.0;
        final adminFee = (w['adminFee'] as num?)?.toDouble() ?? 2500.0;
        final netAmount = (w['netAmount'] as num?)?.toDouble() ?? (amount - adminFee);
        final createdAt = w['createdAt'] != null
            ? DateTime.tryParse(w['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now();

        mergedTxList.add(WalletTransaction(
          id: docId,
          type: 'withdrawal',
          amount: amount,
          adminFee: adminFee,
          netAmount: netAmount,
          title: 'Penarikan Saldo ($provider - $accNo)',
          status: w['status'] ?? 'pending',
          createdAt: createdAt,
        ));
      }
    }

    // Sort descending by date
    mergedTxList.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final initialDefault = (_wallets[tukangId]?.balance != null && _wallets[tukangId]!.balance >= 0)
        ? _wallets[tukangId]!.balance
        : 350000.0;

    double finalBalance = hasCloudBalance ? liveBalance : initialDefault;
    if (finalBalance < 0) finalBalance = 0.0;

    final updatedWallet = WalletModel(
      tukangId: tukangId,
      balance: finalBalance,
      transactions: mergedTxList,
    );

    _wallets[tukangId] = updatedWallet;
    return updatedWallet;
  }

  @override
  Future<WithdrawalRequest> requestWithdrawal({
    required String tukangId,
    required String tukangName,
    required double amount,
    required PayoutAccount payoutAccount,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final wallet = await getTukangWallet(tukangId);

    if (amount < 20000) {
      throw Exception('Minimal penarikan saldo adalah Rp 20.000');
    }

    if (wallet.balance < amount) {
      throw Exception('Saldo tidak mencukupi untuk penarikan sebesar Rp ${amount.toInt()}. Saldo Anda saat ini Rp ${wallet.balance.toInt()}');
    }

    const double adminFee = 2500;
    final double netAmount = amount - adminFee;

    // Calculate exact remaining balance (never negative)
    final double newBalance = (wallet.balance - amount <= 0) ? 0.0 : (wallet.balance - amount);

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

    // Deduct amount from wallet balance locally
    final wdTx = WalletTransaction(
      id: request.id,
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
      balance: newBalance,
      transactions: [wdTx, ...wallet.transactions],
    );

    _withdrawalRequests.add(request);

    // Sync to Cloud Firestore:
    // 1. Create document in 'withdrawals' collection (read by Admin Dashboard in real time)
    // 2. Set exact non-negative balance in 'tukang/{tukangId}'
    try {
      debugPrint('[PaymentRepo] Mengirim permohonan penarikan ${request.id} ke Cloud Firestore...');
      await _firestore.collection('withdrawals').doc(request.id).set({
        'id': request.id,
        'tukangId': request.tukangId,
        'tukangName': request.tukangName,
        'amount': request.amount,
        'adminFee': request.adminFee,
        'netAmount': request.netAmount,
        'payoutTarget': {
          'type': request.payoutAccount.type,
          'provider': request.payoutAccount.provider,
          'accountNumber': request.payoutAccount.accountNumber,
          'accountName': request.payoutAccount.accountName,
        },
        'status': 'pending',
        'adminNote': null,
        'createdAt': request.createdAt.toIso8601String(),
        'processedAt': null,
      });

      await _firestore.collection('tukang').doc(tukangId).set({
        'walletBalance': newBalance, // Set exact non-negative balance!
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
      debugPrint('[PaymentRepo] SUKSES: Penarikan ${request.id} berhasil tersimpan di Cloud Firestore! Saldo baru: Rp $newBalance');
    } catch (e) {
      debugPrint('[PaymentRepo] GAGAL menyimpan ke Firestore: $e');
    }

    return request;
  }
}
