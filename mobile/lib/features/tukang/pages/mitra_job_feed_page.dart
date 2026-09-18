import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/ticket_model.dart';
import '../../../data/models/tukang_model.dart';
import '../../ticket/bloc/ticket_bloc.dart';
import '../../ticket/bloc/ticket_event.dart';
import '../../ticket/bloc/ticket_state.dart';

class MitraJobFeedPage extends StatefulWidget {
  final TukangModel tukang;
  const MitraJobFeedPage({super.key, required this.tukang});

  @override
  State<MitraJobFeedPage> createState() => _MitraJobFeedPageState();
}

class _MitraJobFeedPageState extends State<MitraJobFeedPage> {
  final _estimatedPriceController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchRadar();
  }

  void _fetchRadar() {
    context.read<TicketBloc>().add(
      FetchTukangRadarTicketsEvent(
        services: widget.tukang.services,
        lat: widget.tukang.currentLocation?.lat ?? -6.2088,
        lng: widget.tukang.currentLocation?.lng ?? 106.8456,
      ),
    );
  }

  @override
  void dispose() {
    _estimatedPriceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _showBidDialog(TicketModel ticket) {
    if (widget.tukang.isCurrentlySuspended) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Akun Anda sedang disuspend. Tidak dapat mengajukan penawaran.'), backgroundColor: AppColors.dangerRed),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (diagCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Penawaran #${ticket.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ticket.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: _estimatedPriceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Estimasi Biaya (Rp)',
                hintText: 'Contoh: 150000',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Pesan untuk Pelanggan',
                hintText: 'Siap datang 20 menit, bawa steam AC...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(diagCtx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              final price = double.tryParse(_estimatedPriceController.text.trim()) ?? 0;
              if (price <= 0) return;
              Navigator.pop(diagCtx);
              context.read<TicketBloc>().add(
                SubmitBidRequestedEvent(
                  ticketId: ticket.id,
                  tukangId: widget.tukang.id,
                  tukangName: widget.tukang.name,
                  tukangPhoto: widget.tukang.photoUrl,
                  tukangRating: widget.tukang.rating,
                  estimatedPrice: price,
                  note: _noteController.text.trim(),
                ),
              );
              _estimatedPriceController.clear();
              _noteController.clear();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.textDark),
            child: const Text('Kirim Bid', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSuspended = widget.tukang.isCurrentlySuspended;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Radar Job Tiket Mitra'),
        backgroundColor: AppColors.textDark,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchRadar),
        ],
      ),
      body: Column(
        children: [
          // Suspend Banner Alert
          if (isSuspended)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: AppColors.dangerRed.withValues(alpha: 0.15),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.dangerRed, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('AKUN ANDA DENGAN SANKSI SUSPEND (3 HARI)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.dangerRed, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text('Alasan: ${widget.tukang.suspendReason ?? 'Pelanggaran ketentuan'}', style: const TextStyle(fontSize: 11, color: AppColors.textDark)),
                        const SizedBox(height: 2),
                        const Text('Fitur bidding & terima order dinonaktifkan sementara.', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Job Radar Feed List
          Expanded(
            child: BlocConsumer<TicketBloc, TicketState>(
              listener: (context, state) {
                if (state is BidSubmittedSuccessState) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Penawaran Anda berhasil terkirim ke pelanggan!'), backgroundColor: AppColors.successGreen),
                  );
                  _fetchRadar();
                }
              },
              builder: (context, state) {
                if (state is TicketLoadingState) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.textDark));
                }

                if (state is TicketListLoadedState) {
                  final tickets = state.tickets;
                  if (tickets.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.radar_sharp, size: 48, color: AppColors.textMuted),
                          SizedBox(height: 12),
                          Text('Belum Ada Tiket Pekerjaan di Radar', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('Radar otomatis memantau tiket keluhan di radius terdekat Anda', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: tickets.length,
                    itemBuilder: (context, index) {
                      final ticket = tickets[index];
                      final hasAlreadyBid = ticket.bids.any((b) => b.tukangId == widget.tukang.id);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Chip(
                                    label: Text(ticket.category.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.white)),
                                    backgroundColor: AppColors.textDark,
                                  ),
                                  const Text('📍 2.4 km dari lokasi Anda', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                ],
                              ),
                              Text(ticket.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(ticket.description, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.person, size: 14, color: AppColors.textMuted),
                                  const SizedBox(width: 4),
                                  Text(ticket.userName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 14, color: AppColors.dangerRed),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(ticket.address, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                              const SizedBox(height: 16),

                              ElevatedButton(
                                onPressed: isSuspended ? null : () => _showBidDialog(ticket),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: hasAlreadyBid ? AppColors.successGreen : AppColors.textDark,
                                  minimumSize: const Size.fromHeight(42),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: Text(
                                  hasAlreadyBid ? '✓ Penawaran Terkirim (Update Bid)' : 'Ajukan Penawaran (Bid)',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }

                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }
}
