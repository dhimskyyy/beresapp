import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class UserWalletPage extends StatefulWidget {
  final double currentBalance;
  final Function(double newBalance) onBalanceUpdated;

  const UserWalletPage({
    super.key,
    required this.currentBalance,
    required this.onBalanceUpdated,
  });

  @override
  State<UserWalletPage> createState() => _UserWalletPageState();
}

class _UserWalletPageState extends State<UserWalletPage> {
  late double _balance;

  final List<Map<String, dynamic>> _transactions = [
    {
      'title': 'Top Up Saldomu via BCA VA',
      'date': 'Hari ini, 14:20',
      'amount': '+ Rp 100.000',
      'isIncome': true,
    },
    {
      'title': 'Pembayaran Servis AC #BRS-8912',
      'date': 'Kemarin, 16:45',
      'amount': '- Rp 150.000',
      'isIncome': false,
    },
    {
      'title': 'Pembayaran Perbaikan Pompa Air',
      'date': '12 Sep 2026',
      'amount': '- Rp 200.000',
      'isIncome': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _balance = widget.currentBalance;
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  void _showTopUpSheet() {
    final topUpCtrl = TextEditingController(text: '100000');
    String selectedMethod = 'QRIS Instan (Bebas Biaya)';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Top Up Saldomu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  const SizedBox(height: 4),
                  const Text('Pilih nominal pengisian saldo instan e-wallet Beres.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 16),

                  // Quick chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [50000, 100000, 200000, 500000].map((amt) {
                      final isSel = topUpCtrl.text == amt.toString();
                      return ChoiceChip(
                        label: Text('Rp ${_formatCurrency(amt.toDouble())}'),
                        selected: isSel,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSel ? Colors.white : AppColors.textDark,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: isSel ? AppColors.primary : AppColors.border),
                        ),
                        onSelected: (val) {
                          if (val) {
                            setSheetState(() => topUpCtrl.text = amt.toString());
                          }
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),
                  TextField(
                    controller: topUpCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      labelText: 'Nominal Isi Saldo',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text('Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                  const SizedBox(height: 8),

                  DropdownButtonFormField<String>(
                    value: selectedMethod,
                    items: const [
                      DropdownMenuItem(value: 'QRIS Instan (Bebas Biaya)', child: Text('QRIS Instan (Bebas Biaya)')),
                      DropdownMenuItem(value: 'BCA Virtual Account', child: Text('BCA Virtual Account')),
                      DropdownMenuItem(value: 'Mandiri Virtual Account', child: Text('Mandiri Virtual Account')),
                      DropdownMenuItem(value: 'BRI Virtual Account', child: Text('BRI Virtual Account')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setSheetState(() => selectedMethod = val);
                      }
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final added = double.tryParse(topUpCtrl.text) ?? 0;
                        if (added <= 0) return;

                        setState(() {
                          _balance += added;
                          _transactions.insert(0, {
                            'title': 'Top Up Saldomu via $selectedMethod',
                            'date': 'Baru saja',
                            'amount': '+ Rp ${_formatCurrency(added)}',
                            'isIncome': true,
                          });
                        });
                        widget.onBalanceUpdated(_balance);
                        Navigator.pop(sheetCtx);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Top Up Rp ${_formatCurrency(added)} berhasil! Saldo telah bertambah.'),
                            backgroundColor: AppColors.successGreen,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Bayar & Konfirmasi Top Up', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Dompet & Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saldomu Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.bolt_rounded, color: AppColors.safetyAmber, size: 20),
                          SizedBox(width: 6),
                          Text('Saldomu / BeresPay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.successGreen.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.4)),
                        ),
                        child: const Text('Aktif & Terproteksi', style: TextStyle(color: AppColors.successGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Total Saldo Tersedia', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${_formatCurrency(_balance)}',
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showTopUpSheet,
                      icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 20),
                      label: const Text('Isi Saldo (Top Up)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section: Saved Payment Methods
            const Text('Metode Pembayaran Tersimpan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark)),
            const SizedBox(height: 12),

            _buildPaymentTile(
              icon: Icons.qr_code_2_rounded,
              iconBg: const Color(0xFFEFF6FF),
              iconColor: AppColors.primary,
              title: 'QRIS Instan (Bebas Biaya)',
              subtitle: 'GoPay, OVO, DANA, ShopeePay & BCA Mobile',
              badge: 'Rekomendasi',
            ),
            _buildPaymentTile(
              icon: Icons.account_balance_rounded,
              iconBg: const Color(0xFFF0FDF4),
              iconColor: AppColors.successGreen,
              title: 'BCA Virtual Account',
              subtitle: '80123 081234567890 (Otomatis Verifikasi)',
            ),
            _buildPaymentTile(
              icon: Icons.account_balance_rounded,
              iconBg: const Color(0xFFF1F5F9),
              iconColor: AppColors.textDark,
              title: 'Mandiri / BNI / BRI VA',
              subtitle: 'Bayar via transfer ATM / Mobile Banking',
            ),
            _buildPaymentTile(
              icon: Icons.payments_outlined,
              iconBg: const Color(0xFFFEF3C7),
              iconColor: AppColors.safetyAmber,
              title: 'Tunai di Tempat (Cash COD)',
              subtitle: 'Bayar langsung ke tukang setelah pengerjaan selesai',
            ),

            const SizedBox(height: 8),

            // Add New Method Button
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pilihan kartu debit / rekening bank baru tersedia saat checkout.')),
                );
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tambah Rekening / Kartu Baru', style: TextStyle(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                minimumSize: const Size(double.infinity, 48),
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 28),

            // Section: Recent Transactions
            const Text('Riwayat Transaksi Dompet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark)),
            const SizedBox(height: 12),

            Material(
              color: Colors.white,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _transactions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final tx = _transactions[index];
                  final isIncome = tx['isIncome'] as bool;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isIncome ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF),
                      child: Icon(
                        isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                        color: isIncome ? AppColors.successGreen : AppColors.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(tx['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text(tx['date'] as String, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    trailing: Text(
                      tx['amount'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isIncome ? AppColors.successGreen : AppColors.textDark,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? badge,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          leading: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Metode pembayaran $title aktif.'), duration: const Duration(seconds: 1)),
            );
          },
        ),
      ),
    );
  }
}
