import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/ticket_model.dart';
import '../../../domain/entities/ticket_status.dart';
import '../../chat/pages/chat_page.dart';
import '../../ticket/bloc/ticket_bloc.dart';
import '../../ticket/bloc/ticket_event.dart';
import '../../ticket/bloc/ticket_state.dart';

class LiveTrackingPage extends StatelessWidget {
  final TicketModel ticket;
  const LiveTrackingPage({super.key, required this.ticket});

  void _cancelOrder(BuildContext context) {
    if (!ticket.status.canUserCancelDirectly) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Pembatalan Terkunci'),
          content: const Text(
            'Tukang sudah mengupdate status "Menuju Lokasi". Tombol batal otomatis dikunci untuk melindungi tukang yang sudah di jalan.\n\nJika tetap batal saat tukang tiba, pembatalan harus disepakati langsung di tempat dan User membayar uang bensin/transport secara tunai.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mengerti')),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (diagCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Batalkan Pesanan Ini?'),
        content: const Text('Tukang belum berangkat ke lokasi Anda. Pembatalan saat ini GRATIS.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(diagCtx), child: const Text('Tidak')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(diagCtx);
              context.read<TicketBloc>().add(
                UpdateTicketStatusRequestedEvent(
                  ticketId: ticket.id,
                  newStatus: TicketStatus.canceled,
                  cancelReason: 'Dibatalkan oleh User sebelum berangkat',
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.dangerRed),
            child: const Text('Ya, Batalkan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userLocation = LatLng(ticket.lat, ticket.lng);
    // Simulating moving tukang location (e.g. 500m away towards user)
    final tukangLocation = LatLng(ticket.lat - 0.004, ticket.lng - 0.003);

    final canCancelDirectly = ticket.status.canUserCancelDirectly;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Tracking & Progress #${ticket.id}'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat, color: AppColors.primary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatPage(
                    ticket: ticket,
                    currentUserId: ticket.userId,
                    currentUserRole: 'user',
                  ),
                ),
              );
            },
          )
        ],
      ),
      body: BlocConsumer<TicketBloc, TicketState>(
        listener: (context, state) {
          if (state is TukangLockedSuccessState) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Status pekerjaan berhasil diperbarui!'), backgroundColor: AppColors.successGreen),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              // OpenStreetMap Full Map Preview
              Expanded(
                flex: 5,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: userLocation,
                    initialZoom: 14.5,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.beres.beresapp',
                    ),
                    MarkerLayer(
                      markers: [
                        // User Pin (Red)
                        Marker(
                          point: userLocation,
                          width: 45,
                          height: 45,
                          child: const Icon(Icons.pin_drop, color: AppColors.dangerRed, size: 40),
                        ),
                        // Tukang Live Pin (Blue Motor/Wrench)
                        if (ticket.status == TicketStatus.onTheWay)
                          Marker(
                            point: tukangLocation,
                            width: 45,
                            height: 45,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                              ),
                              child: const Icon(Icons.two_wheeler, color: Colors.white, size: 24),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Bottom Control Panel & Status Sheet
              Expanded(
                flex: 6,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20.0),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, -4))],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Badge & Tukang Info
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                ticket.status.label,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _cancelOrder(context),
                              icon: Icon(canCancelDirectly ? Icons.close : Icons.lock, size: 16),
                              label: Text(canCancelDirectly ? 'Batal Pesanan' : 'Batal Terkunci'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: canCancelDirectly ? AppColors.dangerRed : Colors.grey,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Tukang Info Card
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                backgroundImage: NetworkImage('https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150'),
                                radius: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(ticket.selectedTukangName ?? 'Tukang Mitra', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    const SizedBox(height: 2),
                                    const Text('⭐ 4.9 (Mitra Terverifikasi)', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Final Bill Section (if submitted by Tukang)
                        if (ticket.finalBill != null) ...[
                          const Text('Rincian Tagihan Final (Diinput Tukang):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              children: [
                                ...ticket.finalBill!.items.map((item) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(item.title, style: const TextStyle(fontSize: 13)),
                                          Text('Rp ${item.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        ],
                                      ),
                                    )),
                                const Divider(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Total Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text('Rp ${ticket.finalBill!.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (!ticket.finalBill!.approvedByUser)
                            ElevatedButton(
                              onPressed: () {
                                context.read<TicketBloc>().add(ApproveFinalBillRequestedEvent(ticket.id));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.successGreen,
                                minimumSize: const Size.fromHeight(44),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('✓ Setujui Rincian Biaya Ini', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.all(10),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.successGreen.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('✓ Rincian Biaya Telah Disetujui User', style: TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          const SizedBox(height: 16),
                        ],

                        // Work Photos Inspection (Before & After)
                        const Text('Foto Dokumentasi Pengerjaan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 100,
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: ticket.beforePhotos.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(11),
                                        child: Image.network(ticket.beforePhotos[0], fit: BoxFit.cover),
                                      )
                                    : const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.camera_alt, color: AppColors.textMuted),
                                          SizedBox(height: 4),
                                          Text('Foto Sebelum', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                height: 100,
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: ticket.afterPhotos.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(11),
                                        child: Image.network(ticket.afterPhotos[0], fit: BoxFit.cover),
                                      )
                                    : const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.camera_alt, color: AppColors.textMuted),
                                          SizedBox(height: 4),
                                          Text('Foto Sesudah', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
