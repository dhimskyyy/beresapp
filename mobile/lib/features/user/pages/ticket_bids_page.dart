import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/ticket_model.dart';
import '../../../domain/entities/ticket_status.dart';
import '../../ticket/bloc/ticket_bloc.dart';
import '../../ticket/bloc/ticket_event.dart';
import '../../ticket/bloc/ticket_state.dart';

class TicketBidsPage extends StatelessWidget {
  final TicketModel ticket;
  const TicketBidsPage({super.key, required this.ticket});

  void _showLockConfirmation(BuildContext context, BidModel bid) {
    showDialog(
      context: context,
      builder: (diagCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Kunci & Pilih Tukang Ini?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Anda akan mengunci ${bid.tukangName} untuk pekerjaan ini.'),
            const SizedBox(height: 8),
            Text('Estimasi Biaya: Rp ${bid.estimatedPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 12),
            const Text(
              '⚠️ Catatan Pembatalan:\nSetelah tukang mengupdate status "Menuju Lokasi", pembatalan sepihak via tombol di-lock. Jika batal di tempat, ongkos bensin disepakati langsung.',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(diagCtx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(diagCtx);
              context.read<TicketBloc>().add(
                LockTukangRequestedEvent(
                  ticketId: ticket.id,
                  selectedTukangId: bid.tukangId,
                  selectedTukangName: bid.tukangName,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Ya, Lock Tukang', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Penawaran Tiket #${ticket.id}'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: BlocConsumer<TicketBloc, TicketState>(
        listener: (context, state) {
          if (state is TukangLockedSuccessState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Tukang ${state.lockedTicket.selectedTukangName} berhasil di-lock!'), backgroundColor: AppColors.successGreen),
            );
            Navigator.pop(context);
          }
        },
        builder: (context, state) {
          final isLocked = ticket.status != TicketStatus.open && ticket.status != TicketStatus.bidding;

          return Column(
            children: [
              // Ticket Header Info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Chip(
                          label: Text(ticket.category.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                          backgroundColor: AppColors.bgAC,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isLocked ? AppColors.successGreen.withValues(alpha: 0.1) : AppColors.safetyAmber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isLocked ? AppColors.successGreen : AppColors.safetyAmber),
                          ),
                          child: Text(
                            ticket.status.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isLocked ? AppColors.successGreen : AppColors.safetyAmber,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(ticket.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(ticket.description, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: AppColors.dangerRed),
                        const SizedBox(width: 4),
                        Expanded(child: Text(ticket.address, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                      ],
                    )
                  ],
                ),
              ),
              const Divider(height: 1),

              // Bids Section
              Expanded(
                child: ticket.bids.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.radar, size: 48, color: AppColors.textMuted),
                            SizedBox(height: 12),
                            Text('Mencari Penawaran Tukang Terdekat...', style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text('Notifikasi telah dibroadcast ke mitra tukang terverifikasi', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: ticket.bids.length,
                        itemBuilder: (context, index) {
                          final bid = ticket.bids[index];
                          final isThisSelected = ticket.selectedTukangId == bid.tukangId;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isThisSelected ? AppColors.successGreen : AppColors.border,
                                width: isThisSelected ? 2 : 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundImage: NetworkImage(bid.tukangPhoto ?? 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150'),
                                        radius: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(bid.tukangName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                            Row(
                                              children: [
                                                const Icon(Icons.star, color: AppColors.safetyAmber, size: 14),
                                                const SizedBox(width: 2),
                                                Text('${bid.tukangRating.toStringAsFixed(1)} (Mitra Terverifikasi)', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        'Rp ${bid.estimatedPrice.toStringAsFixed(0)}',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                                      ),
                                    ],
                                  ),
                                  if (bid.note.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.background,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text('"${bid.note}"', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  if (!isLocked)
                                    ElevatedButton(
                                      onPressed: () => _showLockConfirmation(context, bid),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        minimumSize: const Size.fromHeight(40),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      child: const Text('Lock Tukang Ini', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    )
                                  else if (isThisSelected)
                                    Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: AppColors.successGreen.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text('✓ Tukang Terpilih', style: TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.bold)),
                                    )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              )
            ],
          );
        },
      ),
    );
  }
}
