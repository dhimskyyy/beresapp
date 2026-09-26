import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/ticket_model.dart';
import 'user_rating_modal.dart';
import '../bloc/payment_bloc.dart';
import '../bloc/payment_event.dart';
import '../bloc/payment_state.dart';

class UserPaymentModal extends StatelessWidget {
  final TicketModel ticket;
  const UserPaymentModal({super.key, required this.ticket});

  static void show(BuildContext context, TicketModel ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => UserPaymentModal(ticket: ticket),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final double totalAmount = ticket.finalBill?.totalAmount ?? 0;
    final items = ticket.finalBill?.items ?? [];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: BlocConsumer<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state is PaymentCompletedSuccessState) {
            Navigator.pop(context);
            UserRatingModal.show(context, widgetOrTicket(state.ticket));
          } else if (state is PaymentFailureState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.dangerRed),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is PaymentLoadingState;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.payments_rounded, color: AppColors.successGreen, size: 22),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Pembayaran Tunai di Tempat',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Total Amount Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Tagihan Nota:',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          currencyFormat.format(totalAmount),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                      ],
                    ),
                    if (items.isNotEmpty) ...[
                      const Divider(height: 18),
                      ...items.map((it) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              it.title,
                              style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                            ),
                            Text(
                              currencyFormat.format(it.amount),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Instruksi Pembayaran Tunai
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 20, color: Color(0xFF2563EB)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Silakan serahkan uang tunai sejumlah ${currencyFormat.format(totalAmount)} langsung kepada teknisi (${ticket.selectedTukangName ?? "Mitra Beres"}) di tempat.',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF1E40AF), height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Tombol Konfirmasi Pembayaran Tunai
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () {
                          context.read<PaymentBloc>().add(
                            ConfirmPaymentSuccessRequestedEvent(
                              ticketId: ticket.id,
                              paymentMethod: 'CASH',
                            ),
                          );
                        },
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_rounded, color: Colors.white),
                  label: Text(
                    isLoading ? 'Memproses...' : 'Saya Sudah Bayar Tunai ke Mitra',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.successGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          );
        },
      ),
    );
  }

  TicketModel widgetOrTicket(TicketModel updated) => updated;
}
