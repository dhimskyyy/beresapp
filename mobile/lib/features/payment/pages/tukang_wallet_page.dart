import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/tukang_model.dart';
import '../../../data/models/wallet_model.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';
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
  final _currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

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

  LinearGradient _getProviderGradient(String provider) {
    switch (provider.toUpperCase()) {
      case 'BCA':
        return const LinearGradient(
          colors: [Color(0xFF003D79), Color(0xFF0066CC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'MANDIRI':
        return const LinearGradient(
          colors: [Color(0xFF002D62), Color(0xFF0B4E9E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'BRI':
        return const LinearGradient(
          colors: [Color(0xFF00529C), Color(0xFF007AE6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'BNI':
        return const LinearGradient(
          colors: [Color(0xFF005E6A), Color(0xFF00899B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'GOPAY':
        return const LinearGradient(
          colors: [Color(0xFF006C84), Color(0xFF00AA13)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'OVO':
        return const LinearGradient(
          colors: [Color(0xFF4C2A86), Color(0xFF7A42C4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'DANA':
        return const LinearGradient(
          colors: [Color(0xFF108EE9), Color(0xFF1677FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'SHOPEEPAY':
        return const LinearGradient(
          colors: [Color(0xFFEE4D2D), Color(0xFFFF6433)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  Color _getProviderShadowColor(String provider) {
    switch (provider.toUpperCase()) {
      case 'BCA':
      case 'MANDIRI':
      case 'BRI':
      case 'BNI':
        return const Color(0xFF00529C);
      case 'GOPAY':
        return const Color(0xFF00AA13);
      case 'OVO':
        return const Color(0xFF6B3BA7);
      case 'DANA':
        return const Color(0xFF108EE9);
      case 'SHOPEEPAY':
        return const Color(0xFFEE4D2D);
      default:
        return const Color(0xFF1E293B);
    }
  }

  String _formatAccountNumber(String raw, String type) {
    final clean = raw.replaceAll(RegExp(r'\s+'), '');
    if (clean.isEmpty) return '•••• •••• •••• ••••';
    if (type == 'bank') {
      final buffer = StringBuffer();
      for (int i = 0; i < clean.length; i++) {
        if (i > 0 && i % 4 == 0) buffer.write(' ');
        buffer.write(clean[i]);
      }
      return buffer.toString();
    } else {
      if (clean.length > 8) {
        return '${clean.substring(0, 4)} ${clean.substring(4, 8)} ${clean.substring(8)}';
      } else if (clean.length > 4) {
        return '${clean.substring(0, 4)} ${clean.substring(4)}';
      }
      return clean;
    }
  }

  /// Modal Penarikan Saldo Modern (Tarik Dana)
  void _showWithdrawalModal(double currentBalance, List<PayoutAccount> payoutAccounts, TukangModel currentTukang) {
    if (payoutAccounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tambahkan rekening bank/e-wallet pencairan terlebih dahulu.'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
      _showQuickPayoutModal(currentTukang);
      return;
    }

    int selectedAccountIndex = 0;
    double requestedAmount = currentBalance >= 100000 ? 100000 : (currentBalance >= 20000 ? currentBalance : 20000);
    _amountController.text = requestedAmount.toInt().toString();
    const double adminFee = 2500;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final selectedAccount = payoutAccounts[selectedAccountIndex];
          final double net = (requestedAmount - adminFee) > 0 ? (requestedAmount - adminFee) : 0;
          final bool isValidAmount = requestedAmount >= 20000 && requestedAmount <= currentBalance;

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              top: 12,
              left: 20,
              right: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                    ),
                  ),

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.arrow_downward_rounded, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Tarik Saldo BeresPay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                              Text('Pencairan instan ke rekening Anda', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(modalCtx),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Saldo Tersedia Pill
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Saldo Tersedia di Dompet:', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        Text(_currencyFormat.format(currentBalance), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Rekening Tujuan Pilihan Card (Virtual Style)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Rekening Tujuan Pencairan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(modalCtx);
                          _showQuickPayoutModal(currentTukang);
                        },
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
                        child: const Text('Ganti / Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: _getProviderGradient(selectedAccount.provider),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _getProviderShadowColor(selectedAccount.provider).withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            selectedAccount.provider.toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatAccountNumber(selectedAccount.accountNumber, selectedAccount.type),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'a.n ${selectedAccount.accountName}',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.successGreen,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('UTAMA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Input Nominal & Fast Chips
                  const Text('Nominal Penarikan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                  const SizedBox(height: 8),

                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      prefixStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      hintText: '200000',
                      hintStyle: const TextStyle(fontSize: 16, color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.textDark, width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _amountController.clear();
                          setModalState(() => requestedAmount = 0);
                        },
                      ),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        requestedAmount = double.tryParse(val) ?? 0;
                      });
                    },
                  ),

                  const SizedBox(height: 10),

                  // Fast Nominal Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFastAmountChip('50rb', 50000, setModalState, (val) => requestedAmount = val),
                        const SizedBox(width: 6),
                        _buildFastAmountChip('100rb', 100000, setModalState, (val) => requestedAmount = val),
                        const SizedBox(width: 6),
                        _buildFastAmountChip('200rb', 200000, setModalState, (val) => requestedAmount = val),
                        const SizedBox(width: 6),
                        _buildFastAmountChip('500rb', 500000, setModalState, (val) => requestedAmount = val),
                        const SizedBox(width: 6),
                        ActionChip(
                          label: const Text('Tarik Semua', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          side: const BorderSide(color: AppColors.primary),
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            setModalState(() {
                              requestedAmount = currentBalance;
                              _amountController.text = currentBalance.toInt().toString();
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  if (requestedAmount < 20000 && _amountController.text.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text('⚠️ Minimal penarikan saldo adalah Rp 20.000', style: TextStyle(color: AppColors.dangerRed, fontSize: 11)),
                    ),

                  if (requestedAmount > currentBalance)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text('⚠️ Saldo Anda tidak mencukupi untuk nominal ini', style: TextStyle(color: AppColors.dangerRed, fontSize: 11)),
                    ),

                  const SizedBox(height: 16),

                  // Rincian Biaya Transfer Transparan
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Nominal Penarikan', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                            Text(_currencyFormat.format(requestedAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textDark)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Biaya Transfer Antar Bank / E-Wallet', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                            Text('- Rp 2.500', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.dangerRed)),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Uang Bersih Diterima', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                            Text(
                              _currencyFormat.format(net),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.successGreen),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Row(
                          children: [
                            Icon(Icons.bolt_rounded, size: 14, color: AppColors.safetyAmber),
                            SizedBox(width: 4),
                            Text('Pencairan Instan (< 15 menit langsung ke rekening)', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tombol Konfirmasi Tarik Dana
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: (!isValidAmount)
                          ? null
                          : () {
                              Navigator.pop(modalCtx);
                              context.read<PaymentBloc>().add(
                                RequestWithdrawalRequestedEvent(
                                  tukangId: currentTukang.id,
                                  tukangName: currentTukang.name,
                                  amount: requestedAmount,
                                  payoutAccount: selectedAccount,
                                ),
                              );
                            },
                      icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
                      label: const Text('Konfirmasi & Tarik Saldo Sekarang', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.textDark,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFastAmountChip(String label, double amount, StateSetter setModalState, Function(double) onSelected) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textDark)),
      backgroundColor: Colors.white,
      side: const BorderSide(color: AppColors.border),
      padding: EdgeInsets.zero,
      onPressed: () {
        setModalState(() {
          onSelected(amount);
          _amountController.text = amount.toInt().toString();
        });
      },
    );
  }

  /// Dialog Bukti Konfirmasi Instan (Receipt Modal)
  void _showWithdrawalReceiptDialog(BuildContext context, WithdrawalRequest req) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.successGreen.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'Permohonan Penarikan Berhasil!',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textDark),
            ),
            const SizedBox(height: 4),
            const Text(
              'Dana sedang diproses transfer ke rekening tujuan Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),

            // Receipt Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildReceiptRow('ID Penarikan', req.id),
                  const Divider(height: 14),
                  _buildReceiptRow('Nominal Penarikan', _currencyFormat.format(req.amount)),
                  const SizedBox(height: 4),
                  _buildReceiptRow('Biaya Admin', '- ${_currencyFormat.format(req.adminFee)}'),
                  const Divider(height: 14),
                  _buildReceiptRow(
                    'Uang Bersih Diterima',
                    _currencyFormat.format(req.netAmount),
                    valueColor: AppColors.successGreen,
                    isBold: true,
                  ),
                  const Divider(height: 14),
                  _buildReceiptRow('Rekening Tujuan', '${req.payoutAccount.provider} • ${req.payoutAccount.accountNumber}'),
                  const SizedBox(height: 4),
                  _buildReceiptRow('Atas Nama', req.payoutAccount.accountName),
                  const SizedBox(height: 4),
                  _buildReceiptRow('Status', 'Diproses Instan', valueColor: AppColors.primary, isBold: true),
                ],
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Selesai & Cek Mutasi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? AppColors.textDark,
          ),
        ),
      ],
    );
  }

  /// Quick Payout Account Editor Modal (Synchronized with AuthBloc)
  void _showQuickPayoutModal(TukangModel currentTukang) {
    final currentAccount = currentTukang.payoutAccounts.isNotEmpty
        ? currentTukang.payoutAccounts.first
        : PayoutAccount(type: 'bank', provider: 'BCA', accountNumber: '', accountName: currentTukang.name);

    String type = currentAccount.type;
    final providerCtrl = TextEditingController(text: currentAccount.provider);
    final numberCtrl = TextEditingController(text: currentAccount.accountNumber);
    final nameCtrl = TextEditingController(text: currentAccount.accountName);

    final bankProviders = ['BCA', 'Mandiri', 'BRI', 'BNI'];
    final ewalletProviders = ['GoPay', 'OVO', 'DANA', 'ShopeePay'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final activeTab = type == 'bank' ? 0 : 1;
            final currentProviderList = activeTab == 0 ? bankProviders : ewalletProviders;

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Rekening Payout & E-Wallet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                        IconButton(onPressed: () => Navigator.pop(modalCtx), icon: const Icon(Icons.close_rounded)),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Virtual Card Preview
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: _getProviderGradient(providerCtrl.text),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      providerCtrl.text.toUpperCase(),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(4)),
                                      child: Text(type == 'bank' ? 'BANK' : 'E-WALLET', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _formatAccountNumber(numberCtrl.text, type),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  nameCtrl.text.isEmpty ? 'NAMA PEMILIK REKENING' : nameCtrl.text.toUpperCase(),
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Type Toggle (Bank vs E-Wallet)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setModalState(() {
                                      type = 'bank';
                                      if (!bankProviders.contains(providerCtrl.text)) providerCtrl.text = bankProviders.first;
                                    }),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: type == 'bank' ? Colors.white : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: type == 'bank' ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : null,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text('Transfer Bank', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: type == 'bank' ? AppColors.textDark : AppColors.textMuted)),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setModalState(() {
                                      type = 'ewallet';
                                      if (!ewalletProviders.contains(providerCtrl.text)) providerCtrl.text = ewalletProviders.first;
                                    }),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: type == 'ewallet' ? Colors.white : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: type == 'ewallet' ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : null,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text('Dompet E-Wallet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: type == 'ewallet' ? AppColors.textDark : AppColors.textMuted)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Provider Chips
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: currentProviderList.map((p) {
                              final isSelected = providerCtrl.text.toUpperCase() == p.toUpperCase();
                              return ChoiceChip(
                                label: Text(p),
                                selected: isSelected,
                                onSelected: (sel) {
                                  if (sel) setModalState(() => providerCtrl.text = p);
                                },
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 16),

                          // Input Fields
                          TextField(
                            controller: numberCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: type == 'bank' ? 'Nomor Rekening Bank' : 'Nomor Handphone E-Wallet',
                              border: const OutlineInputBorder(),
                            ),
                            onChanged: (_) => setModalState(() {}),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: nameCtrl,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Nama Lengkap Pemilik Rekening / Akun',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => setModalState(() {}),
                          ),
                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () {
                                if (numberCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Harap lengkapi nomor dan nama pemilik.')),
                                  );
                                  return;
                                }

                                final updatedAcc = PayoutAccount(
                                  type: type,
                                  provider: providerCtrl.text,
                                  accountNumber: numberCtrl.text.trim(),
                                  accountName: nameCtrl.text.trim(),
                                );

                                final updatedTukang = currentTukang.copyWith(payoutAccounts: [updatedAcc]);
                                context.read<AuthBloc>().add(TukangProfileUpdatedEvent(updatedTukang));

                                Navigator.pop(modalCtx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Rekening payout ${updatedAcc.provider} berhasil disimpan & disinkronkan!'),
                                    backgroundColor: AppColors.successGreen,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.textDark),
                              child: const Text('Simpan Rekening Payout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Read synchronized tukang from AuthBloc
    final authState = context.watch<AuthBloc>().state;
    final currentTukang = authState is TukangAuthenticatedState ? authState.tukang : widget.tukang;
    final payoutAccounts = currentTukang.payoutAccounts;
    final activePayout = payoutAccounts.isNotEmpty ? payoutAccounts.first : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dompet BeresPay Mitra', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: AppColors.textDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan Saldo',
            onPressed: () => context.read<PaymentBloc>().add(FetchTukangWalletRequestedEvent(currentTukang.id)),
          ),
        ],
      ),
      body: BlocConsumer<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state is WithdrawalSubmittedSuccessState) {
            _showWithdrawalReceiptDialog(context, state.request);
            context.read<PaymentBloc>().add(FetchTukangWalletRequestedEvent(currentTukang.id));
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

            return RefreshIndicator(
              color: AppColors.textDark,
              onRefresh: () async {
                context.read<PaymentBloc>().add(FetchTukangWalletRequestedEvent(currentTukang.id));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Balance Header Card (BeresPay Mitra)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.textDark, Color(0xFF1E293B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.safetyAmber, size: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Saldo Siap Ditarik', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.successGreen,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('0% Komisi Mitra', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _currencyFormat.format(wallet.balance),
                            style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                          ),
                          const SizedBox(height: 16),

                          // Tombol Tarik Saldo
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton.icon(
                              onPressed: () => _showWithdrawalModal(wallet.balance, payoutAccounts, currentTukang),
                              icon: const Icon(Icons.arrow_downward_rounded, color: AppColors.textDark, size: 18),
                              label: const Text('Tarik Saldo ke Rekening', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 13)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 2. Kartu Rekening Pencairan Aktif (Integrated with Profile)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Rekening Pencairan Aktif', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                        TextButton(
                          onPressed: () => _showQuickPayoutModal(currentTukang),
                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
                          child: Text(activePayout != null ? 'Ubah' : '+ Tambah', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    if (activePayout != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: _getProviderGradient(activePayout.provider),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                activePayout.provider.toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '${activePayout.provider} • ${_formatAccountNumber(activePayout.accountNumber, activePayout.type)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'a.n ${activePayout.accountName}',
                                    style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.successGreen.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_rounded, size: 12, color: AppColors.successGreen),
                                  SizedBox(width: 4),
                                  Text('Siap', style: TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.bold, fontSize: 10)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      GestureDetector(
                        onTap: () => _showQuickPayoutModal(currentTukang),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.safetyAmber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.safetyAmber.withValues(alpha: 0.5)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline_rounded, color: AppColors.safetyAmber, size: 24),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Rekening Pencairan Belum Diatur', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                                    SizedBox(height: 2),
                                    Text('Klik untuk menambahkan rekening bank atau e-wallet agar dapat mencairkan saldo.', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // 3. Riwayat Mutasi Saldo & Penarikan
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Riwayat Transaksi & Penarikan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                        Text('${wallet.transactions.length} Transaksi', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (wallet.transactions.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.receipt_long_rounded, size: 48, color: AppColors.textMuted),
                            SizedBox(height: 8),
                            Text('Belum Ada Mutasi Saldo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            SizedBox(height: 4),
                            Text('Hasil dari tiket yang selesai akan otomatis masuk ke sini.', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: wallet.transactions.length,
                        itemBuilder: (context, idx) {
                          final tx = wallet.transactions[idx];
                          final isIncome = tx.type == 'income';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundColor: isIncome
                                    ? AppColors.successGreen.withValues(alpha: 0.12)
                                    : AppColors.dangerRed.withValues(alpha: 0.12),
                                child: Icon(
                                  isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                  color: isIncome ? AppColors.successGreen : AppColors.dangerRed,
                                  size: 18,
                                ),
                              ),
                              title: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppColors.textDark)),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 6,
                                  runSpacing: 3,
                                  children: [
                                    Text(
                                      '${tx.createdAt.day}/${tx.createdAt.month}/${tx.createdAt.year}',
                                      style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: (tx.status.toLowerCase() == 'approved' || tx.status.toLowerCase() == 'completed')
                                            ? AppColors.successGreen.withValues(alpha: 0.12)
                                            : tx.status.toLowerCase() == 'rejected'
                                                ? AppColors.dangerRed.withValues(alpha: 0.12)
                                                : AppColors.safetyAmber.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        (tx.status.toLowerCase() == 'approved' || tx.status.toLowerCase() == 'completed')
                                            ? 'BERHASIL'
                                            : tx.status.toLowerCase() == 'rejected'
                                                ? 'DITOLAK'
                                                : 'MENUNGGU',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: (tx.status.toLowerCase() == 'approved' || tx.status.toLowerCase() == 'completed')
                                              ? AppColors.successGreen
                                              : tx.status.toLowerCase() == 'rejected'
                                                  ? AppColors.dangerRed
                                                  : const Color(0xFFB45309),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${isIncome ? '+' : '-'} ${_currencyFormat.format(tx.amount)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isIncome ? AppColors.successGreen : AppColors.dangerRed,
                                    ),
                                  ),
                                  if (!isIncome && tx.adminFee > 0)
                                    Text('(Admin: -${_currencyFormat.format(tx.adminFee)})', style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 20),

                    // 4. Catatan Kebijakan Penarikan
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.shield_outlined, size: 14, color: AppColors.textMuted),
                              SizedBox(width: 6),
                              Text('Ketentuan Pencairan Saldo BeresPay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textDark)),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            '• Minimal penarikan saldo adalah Rp 20.000.\n• Biaya admin transfer antar bank/e-wallet flat Rp 2.500 per transaksi.\n• Pencairan diproses secara instan otomatis 24 jam nonstop.',
                            style: TextStyle(fontSize: 10.5, color: AppColors.textMuted, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }
}
