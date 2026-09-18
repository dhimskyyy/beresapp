import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/tukang_model.dart';
import '../bloc/payment_bloc.dart';
import '../bloc/payment_event.dart';
import '../bloc/payment_state.dart';

class TukangWalletPage extends StatefulWidget {
  final TukangModel tukang;
  const TukangWalletPage({super.key, required this.tukang});

  @override
  State<TukangWalletPage> createState() => _TukangWalletPageState();
}

class _TukangWalletPageState extends State<TukangWalletPage> {
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<PaymentBloc>().add(FetchTukangWalletRequestedEvent(widget.tukang.id));
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _showWithdrawalModal(double currentBalance) {
    if (widget.tukang.payoutAccounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan rekening bank/e-wallet pencairan terlebih dahulu di profil Anda.')),
      );
      return;
    }

    final selectedAccount = widget.tukang.payoutAccounts.first;
    double requestedAmount = 200000;
    const double adminFee = 2500;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final double net = (requestedAmount - adminFee) > 0 ? (requestedAmount - adminFee) : 0;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              top: 24,
              left: 24,
              right: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tarik Saldo ke Rekening', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Saldo Tersedia: Rp ${currentBalance.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 16),

                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Nominal Penarikan (Rp)',
                    hintText: 'Contoh: 200000',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    setModalState(() {
                      requestedAmount = double.tryParse(val) ?? 0;
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Account Target Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_wallet, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${selectedAccount.provider} - ${selectedAccount.accountNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('a.n ${selectedAccount.accountName}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Fee Breakdown Card (Rp 2.500 Flat Fee Rule)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.safetyAmber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.safetyAmber),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Nominal Penarikan', style: TextStyle(fontSize: 12)),
                          Text('Rp ${requestedAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text('Biaya Admin Transfer Bank', style: TextStyle(fontSize: 12, color: AppColors.dangerRed)),
                          Text('- Rp 2.500', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.dangerRed)),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Uang Bersih yang Diterima', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('Rp ${net.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.successGreen)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () {
                    if (requestedAmount < 50000) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Minimal penarikan adalah Rp 50.000')));
                      return;
                    }
                    Navigator.pop(ctx);
                    context.read<PaymentBloc>().add(
                      RequestWithdrawalRequestedEvent(
                        tukangId: widget.tukang.id,
                        tukangName: widget.tukang.name,
                        amount: requestedAmount,
                        payoutAccount: selectedAccount,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textDark,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Kirim Permohonan Penarikan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dompet Mitra'),
        backgroundColor: AppColors.textDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocConsumer<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state is WithdrawalSubmittedSuccessState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Permohonan penarikan Rp ${state.request.amount.toStringAsFixed(0)} berhasil diajukan! (Uang bersih Rp ${state.request.netAmount.toStringAsFixed(0)})'), backgroundColor: AppColors.successGreen),
            );
            context.read<PaymentBloc>().add(FetchTukangWalletRequestedEvent(widget.tukang.id));
          } else if (state is PaymentFailureState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.dangerRed),
            );
          }
        },
        builder: (context, state) {
          if (state is PaymentLoadingState) {
            return const Center(child: CircularProgressIndicator(color: AppColors.textDark));
          }

          if (state is WalletLoadedState) {
            final wallet = state.wallet;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Balance Header Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.textDark,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: AppColors.textDark.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Saldo Dompet Mitra', style: TextStyle(color: Colors.white70, fontSize: 13)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.successGreen,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('0% Komisi Launching', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Rp ${wallet.balance.toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showWithdrawalModal(wallet.balance),
                          icon: const Icon(Icons.arrow_downward, color: AppColors.textDark),
                          label: const Text('Tarik Saldo Uang', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(42),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Transaction History Ledger
                  const Text('Riwayat Transaksi & Penarikan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  const SizedBox(height: 12),

                  if (wallet.transactions.isEmpty)
                    const Center(child: Text('Belum ada transaksi di dompet Anda.', style: TextStyle(color: AppColors.textMuted)))
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: wallet.transactions.length,
                      itemBuilder: (context, idx) {
                        final tx = wallet.transactions[idx];
                        final isIncome = tx.type == 'income';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isIncome ? AppColors.successGreen.withValues(alpha: 0.1) : AppColors.dangerRed.withValues(alpha: 0.1),
                              child: Icon(
                                isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                                color: isIncome ? AppColors.successGreen : AppColors.dangerRed,
                              ),
                            ),
                            title: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: Text('${tx.createdAt.day}/${tx.createdAt.month}/${tx.createdAt.year} • Status: ${tx.status.toUpperCase()}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${isIncome ? '+' : '-'} Rp ${tx.amount.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isIncome ? AppColors.successGreen : AppColors.dangerRed,
                                  ),
                                ),
                                if (!isIncome && tx.adminFee > 0)
                                  Text('(Admin Fee: -Rp ${tx.adminFee.toStringAsFixed(0)})', style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }
}
