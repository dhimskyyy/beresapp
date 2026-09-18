import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/ticket_model.dart';
import '../bloc/payment_bloc.dart';
import '../bloc/payment_event.dart';
import '../bloc/payment_state.dart';

class UserPaymentModal extends StatefulWidget {
  final TicketModel ticket;
  const UserPaymentModal({super.key, required this.ticket});

  @override
  State<UserPaymentModal> createState() => _UserPaymentModalState();
}

class _UserPaymentModalState extends State<UserPaymentModal> {
  String _selectedChannel = 'VA_BCA';

  @override
  Widget build(BuildContext context) {
    final double totalAmount = widget.ticket.finalBill?.totalAmount ?? 150000;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: BlocConsumer<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state is PaymentCompletedSuccessState) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pembayaran Berhasil! Tiket lunas.'), backgroundColor: AppColors.successGreen),
            );
            Navigator.pop(context);
          } else if (state is PaymentFailureState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.dangerRed),
            );
          }
        },
        builder: (context, state) {
          if (state is DokuInvoiceCreatedState) {
            final inv = state.invoiceData;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.qr_code_2, size: 54, color: AppColors.primary),
                const SizedBox(height: 12),
                Text('Invoice DOKU Sandbox #${inv['invoiceId']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text('Total: Rp ${totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                const SizedBox(height: 16),

                if (inv['paymentChannel'].toString().startsWith('VA_')) ...[
                  const Text('Nomor Virtual Account DOKU:', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  const SizedBox(height: 4),
                  SelectableText(
                    inv['vaNumber'],
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2),
                  ),
                ] else if (inv['paymentChannel'] == 'QRIS') ...[
                  Container(
                    height: 140,
                    width: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                      image: DecorationImage(image: NetworkImage(inv['qrisUrl']), fit: BoxFit.cover),
                    ),
                  ),
                ] else ...[
                  const Text('Bayar Tunai Langsung ke Tukang saat pengerjaan selesai.'),
                ],
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: () {
                    context.read<PaymentBloc>().add(
                      ConfirmPaymentSuccessRequestedEvent(
                        ticketId: widget.ticket.id,
                        paymentMethod: inv['paymentChannel'],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.successGreen,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Simulasi Webhook Pembayaran Lunas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Pilih Metode Pembayaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 8),
              Text('Total Tagihan Final: Rp ${totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
              const SizedBox(height: 16),

              // ignore: deprecated_member_use
              RadioListTile<String>(
                value: 'VA_BCA',
                // ignore: deprecated_member_use
                groupValue: _selectedChannel,
                title: const Text('Virtual Account BCA (DOKU)'),
                secondary: const Icon(Icons.account_balance, color: AppColors.primary),
                // ignore: deprecated_member_use
                onChanged: (v) => setState(() => _selectedChannel = v!),
              ),
              // ignore: deprecated_member_use
              RadioListTile<String>(
                value: 'VA_MANDIRI',
                // ignore: deprecated_member_use
                groupValue: _selectedChannel,
                title: const Text('Virtual Account Mandiri (DOKU)'),
                secondary: const Icon(Icons.account_balance, color: AppColors.primary),
                // ignore: deprecated_member_use
                onChanged: (v) => setState(() => _selectedChannel = v!),
              ),
              // ignore: deprecated_member_use
              RadioListTile<String>(
                value: 'QRIS',
                // ignore: deprecated_member_use
                groupValue: _selectedChannel,
                title: const Text('QRIS Instant (GoPay/DANA/OVO/ShopeePay)'),
                secondary: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
                // ignore: deprecated_member_use
                onChanged: (v) => setState(() => _selectedChannel = v!),
              ),
              // ignore: deprecated_member_use
              RadioListTile<String>(
                value: 'CASH',
                // ignore: deprecated_member_use
                groupValue: _selectedChannel,
                title: const Text('Tunai / Cash di Tempat'),
                secondary: const Icon(Icons.payments, color: AppColors.successGreen),
                // ignore: deprecated_member_use
                onChanged: (v) => setState(() => _selectedChannel = v!),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  context.read<PaymentBloc>().add(
                    CreateDokuInvoiceRequestedEvent(
                      ticketId: widget.ticket.id,
                      amount: totalAmount,
                      paymentChannel: _selectedChannel,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Lanjut Pembayaran DOKU', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }
}
