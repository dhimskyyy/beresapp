import 'tukang_model.dart';

class WalletModel {
  final String tukangId;
  final double balance;
  final List<WalletTransaction> transactions;

  WalletModel({
    required this.tukangId,
    required this.balance,
    required this.transactions,
  });

  factory WalletModel.fromMap(Map<String, dynamic> map) {
    return WalletModel(
      tukangId: map['tukangId'] ?? '',
      balance: (map['balance'] ?? 0).toDouble(),
      transactions: (map['transactions'] as List<dynamic>?)
              ?.map((x) => WalletTransaction.fromMap(x))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tukangId': tukangId,
      'balance': balance,
      'transactions': transactions.map((x) => x.toMap()).toList(),
    };
  }
}

class WalletTransaction {
  final String id;
  final String type; // 'income' (job payment) or 'withdrawal'
  final double amount;
  final double adminFee; // Rp 2500 for withdrawal
  final double netAmount;
  final String title;
  final String status; // 'completed', 'pending', 'rejected'
  final DateTime createdAt;

  WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    this.adminFee = 0,
    required this.netAmount,
    required this.title,
    required this.status,
    required this.createdAt,
  });

  factory WalletTransaction.fromMap(Map<String, dynamic> map) {
    return WalletTransaction(
      id: map['id'] ?? '',
      type: map['type'] ?? 'income',
      amount: (map['amount'] ?? 0).toDouble(),
      adminFee: (map['adminFee'] ?? 0).toDouble(),
      netAmount: (map['netAmount'] ?? 0).toDouble(),
      title: map['title'] ?? '',
      status: map['status'] ?? 'completed',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'adminFee': adminFee,
      'netAmount': netAmount,
      'title': title,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class WithdrawalRequest {
  final String id;
  final String tukangId;
  final String tukangName;
  final double amount; // gross amount requested (e.g. 200000)
  final double adminFee; // Rp 2500
  final double netAmount; // net amount transferred (e.g. 197500)
  final PayoutAccount payoutAccount;
  final String status; // 'pending', 'approved', 'rejected'
  final String? adminNote;
  final DateTime createdAt;
  final DateTime? processedAt;

  WithdrawalRequest({
    required this.id,
    required this.tukangId,
    required this.tukangName,
    required this.amount,
    this.adminFee = 2500,
    required this.netAmount,
    required this.payoutAccount,
    required this.status,
    this.adminNote,
    required this.createdAt,
    this.processedAt,
  });

  factory WithdrawalRequest.fromMap(Map<String, dynamic> map, String id) {
    final payoutTargetMap = map['payoutTarget'] as Map<String, dynamic>? ?? {};
    return WithdrawalRequest(
      id: id,
      tukangId: map['tukangId'] ?? '',
      tukangName: map['tukangName'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      adminFee: (map['adminFee'] ?? 2500).toDouble(),
      netAmount: (map['netAmount'] ?? 0).toDouble(),
      payoutAccount: PayoutAccount.fromMap(payoutTargetMap),
      status: map['status'] ?? 'pending',
      adminNote: map['adminNote'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      processedAt: map['processedAt'] != null
          ? DateTime.tryParse(map['processedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tukangId': tukangId,
      'tukangName': tukangName,
      'amount': amount,
      'adminFee': adminFee,
      'netAmount': netAmount,
      'payoutTarget': payoutAccount.toMap(),
      'status': status,
      'adminNote': adminNote,
      'createdAt': createdAt.toIso8601String(),
      'processedAt': processedAt?.toIso8601String(),
    };
  }
}
