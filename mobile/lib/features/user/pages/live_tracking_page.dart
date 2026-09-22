import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/ticket_model.dart';
import '../../../domain/entities/ticket_status.dart';
import '../../chat/pages/chat_page.dart';
import '../../payment/pages/user_payment_modal.dart';
import '../../payment/pages/user_rating_modal.dart';
import '../../ticket/bloc/ticket_bloc.dart';
import '../../ticket/bloc/ticket_event.dart';
import '../../ticket/bloc/ticket_state.dart';

class LiveTrackingPage extends StatefulWidget {
  final TicketModel ticket;
  const LiveTrackingPage({super.key, required this.ticket});

  @override
  State<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> {
  final _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  int _getStepIndex(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
      case TicketStatus.bidding:
      case TicketStatus.locked:
        return 0;
      case TicketStatus.onTheWay:
        return 1;
      case TicketStatus.arrived:
        return 2;
      case TicketStatus.inProgress:
        return 3;
      case TicketStatus.workCompleted:
      case TicketStatus.paymentPending:
      case TicketStatus.completed:
        return 4;
      case TicketStatus.canceled:
        return -1;
    }
  }

  void _showContactModal(BuildContext context, String title, String phone, IconData icon, Color color) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textDark)),
            const SizedBox(height: 6),
            Text(phone, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary)),
            const SizedBox(height: 12),
            const Text(
              'Silakan hubungi kontak mitra langsung untuk koordinasi rute atau detail kendala lokasi.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: phone));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Nomor $phone berhasil disalin ke clipboard!'),
                          backgroundColor: AppColors.successGreen,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Salin Nomor'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Menghubungi $phone...'),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.call, size: 16, color: Colors.white),
                    label: const Text('Panggil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _cancelOrder(BuildContext context, TicketModel ticket) {
    if (!ticket.status.canUserCancelDirectly) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.lock, color: AppColors.safetyAmber, size: 24),
              SizedBox(width: 10),
              Text('Pembatalan Terkunci'),
            ],
          ),
          content: const Text(
            'Tukang telah mengonfirmasi status "Menuju Lokasi". Tombol batal otomatis dikunci untuk menghargai ongkos bensin dan waktu perjalanan mitra.\n\nJika pembatalan mendesak diperlukan, koordinasikan langsung saat mitra tiba atau hubungi CS Beres 24/7.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Saya Mengerti', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (diagCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Batalkan Pesanan Ini?'),
        content: const Text(
          'Mitra tukang belum berangkat menuju lokasi Anda. Pembatalan pada tahap ini 100% BEBAS BIAYA.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(diagCtx),
            child: const Text('Kembali', style: TextStyle(color: AppColors.textMuted)),
          ),
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
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dangerRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Ya, Batalkan Pesanan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required int stepNumber,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isCompleted,
    required bool isActive,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.successGreen
                    : (isActive ? AppColors.primary : Colors.white),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted || isActive ? Colors.transparent : const Color(0xFFCBD5E1),
                  width: 2,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : null,
              ),
              child: Icon(
                isCompleted ? Icons.check : icon,
                color: isCompleted || isActive ? Colors.white : const Color(0xFF94A3B8),
                size: 18,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 38,
                color: isCompleted ? AppColors.successGreen : const Color(0xFFE2E8F0),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isActive || isCompleted ? AppColors.textDark : const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isActive ? AppColors.primary : AppColors.textMuted,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TicketBloc, TicketState>(
      listener: (context, state) {
        if (state is TukangLockedSuccessState) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Status pesanan berhasil diperbarui!'),
              backgroundColor: AppColors.successGreen,
            ),
          );
        }
      },
      builder: (context, state) {
        final currentTicket = (state is TicketListLoadedState)
            ? state.tickets.firstWhere((t) => t.id == widget.ticket.id, orElse: () => widget.ticket)
            : widget.ticket;

        final userLocation = LatLng(currentTicket.lat, currentTicket.lng);
        final tukangLocation = LatLng(currentTicket.lat - 0.0035, currentTicket.lng - 0.0028);
        final canCancelDirectly = currentTicket.status.canUserCancelDirectly;
        final currentStep = _getStepIndex(currentTicket.status);

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: Text(
              'Lacak #${currentTicket.id.length > 6 ? currentTicket.id.substring(0, 6).toUpperCase() : currentTicket.id}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textDark,
            elevation: 0.5,
            actions: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
                tooltip: 'Chat dengan Tukang',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatPage(
                        ticket: currentTicket,
                        currentUserId: currentTicket.userId,
                        currentUserRole: 'user',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Stack(
            children: [
              // OpenStreetMap Full Map
              Positioned.fill(
                bottom: 220, // Keep map visible beneath sheet
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: userLocation,
                    initialZoom: 14.8,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.beres.beresapp',
                    ),
                    MarkerLayer(
                      markers: [
                        // User Home Pin (Red Marker)
                        Marker(
                          point: userLocation,
                          width: 50,
                          height: 50,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                ),
                                child: const Text('Lokasi Anda', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                              const Icon(Icons.location_on, color: AppColors.dangerRed, size: 28),
                            ],
                          ),
                        ),
                        // Tukang Live Pin (Motor / Technician icon)
                        if (currentTicket.status == TicketStatus.onTheWay)
                          Marker(
                            point: tukangLocation,
                            width: 50,
                            height: 50,
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                  ),
                                  child: const Text('Mitra OTW', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                                  ),
                                  child: const Icon(Icons.two_wheeler, color: Colors.white, size: 18),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Draggable / Floating Control Sheet
              DraggableScrollableSheet(
                initialChildSize: 0.52,
                minChildSize: 0.28,
                maxChildSize: 0.90,
                builder: (context, scrollController) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -6)),
                      ],
                    ),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sheet Handle
                          Center(
                            child: Container(
                              width: 44,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Status Header & Quick Cancel
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.radar, size: 14, color: AppColors.primary),
                                    const SizedBox(width: 6),
                                    Text(
                                      currentTicket.status.label,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              if (currentTicket.status.isActive)
                                TextButton.icon(
                                  onPressed: () => _cancelOrder(context, currentTicket),
                                  icon: Icon(canCancelDirectly ? Icons.close : Icons.lock_outline, size: 14, color: canCancelDirectly ? AppColors.dangerRed : AppColors.textMuted),
                                  label: Text(
                                    canCancelDirectly ? 'Batal' : 'Batal Terkunci',
                                    style: TextStyle(
                                      color: canCancelDirectly ? AppColors.dangerRed : AppColors.textMuted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Tukang Profile Card with Quick Contact Buttons
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Stack(
                                      children: [
                                        const CircleAvatar(
                                          backgroundImage: NetworkImage('https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150'),
                                          radius: 26,
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: const BoxDecoration(
                                              color: AppColors.successGreen,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.check, size: 10, color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            currentTicket.selectedTukangName ?? 'Tukang Mitra Beres',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                                          ),
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              const Icon(Icons.star, color: AppColors.safetyAmber, size: 14),
                                              const SizedBox(width: 3),
                                              const Text('4.9', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                                              const SizedBox(width: 4),
                                              Text('• ${currentTicket.category.toUpperCase()} Specialist', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                                // Contact Action Bar
                                Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: () => _showContactModal(
                                          context,
                                          'Telepon Mitra',
                                          '0812-3456-7890',
                                          Icons.phone,
                                          AppColors.primary,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: AppColors.border),
                                          ),
                                          child: const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.phone, size: 16, color: AppColors.primary),
                                              SizedBox(width: 6),
                                              Text('Telepon', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: InkWell(
                                        onTap: () => _showContactModal(
                                          context,
                                          'WhatsApp Mitra',
                                          '0812-3456-7890',
                                          Icons.chat,
                                          const Color(0xFF25D366),
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: AppColors.border),
                                          ),
                                          child: const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.chat, size: 16, color: Color(0xFF25D366)),
                                              SizedBox(width: 6),
                                              Text('WhatsApp', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ChatPage(
                                                ticket: currentTicket,
                                                currentUserId: currentTicket.userId,
                                                currentUserRole: 'user',
                                              ),
                                            ),
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.forum, size: 16, color: Colors.white),
                                              SizedBox(width: 6),
                                              Text('Chat App', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // 4-Step Progress Stepper
                          const Text(
                            'Status Pengerjaan',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              children: [
                                _buildStepItem(
                                  stepNumber: 1,
                                  title: '1. Menuju Lokasi',
                                  subtitle: currentStep >= 1 ? 'Mitra sedang dalam perjalanan ke alamat Anda' : 'Menunggu mitra mulai berangkat',
                                  icon: Icons.two_wheeler,
                                  isCompleted: currentStep > 1,
                                  isActive: currentStep == 1,
                                  isLast: false,
                                ),
                                _buildStepItem(
                                  stepNumber: 2,
                                  title: '2. Tiba di Lokasi',
                                  subtitle: currentStep >= 2 ? 'Mitra telah sampai dan mengecek kendala' : 'Estimasi tiba ~15 menit',
                                  icon: Icons.pin_drop,
                                  isCompleted: currentStep > 2,
                                  isActive: currentStep == 2,
                                  isLast: false,
                                ),
                                _buildStepItem(
                                  stepNumber: 3,
                                  title: '3. Sedang Bekerja',
                                  subtitle: currentStep >= 3 ? 'Perbaikan sedang dilaksanakan sesuai estimasi' : 'Pengerjaan fisik oleh teknisi',
                                  icon: Icons.build_circle_outlined,
                                  isCompleted: currentStep > 3,
                                  isActive: currentStep == 3,
                                  isLast: false,
                                ),
                                _buildStepItem(
                                  stepNumber: 4,
                                  title: '4. Pembayaran & Selesai',
                                  subtitle: currentStep >= 4 ? 'Tagihan diverifikasi & pekerjaan tuntas' : 'Verifikasi nota dan pembayaran aman',
                                  icon: Icons.verified,
                                  isCompleted: currentTicket.status == TicketStatus.completed,
                                  isActive: currentStep == 4 && currentTicket.status != TicketStatus.completed,
                                  isLast: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Final Bill Presentation Section
                          if (currentTicket.finalBill != null) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Rincian Tagihan Nota Final',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                                ),
                                if (currentTicket.finalBill!.approvedByUser)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.successGreen.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('Disetujui', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.successGreen)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                children: [
                                  ...currentTicket.finalBill!.items.map(
                                    (item) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(item.title, style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
                                          Text(
                                            _currencyFormat.format(item.amount),
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Divider(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Total Biaya Final', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      Text(
                                        _currencyFormat.format(currentTicket.finalBill!.totalAmount),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.primary),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Payment Action Buttons
                            if (!currentTicket.finalBill!.approvedByUser)
                              ElevatedButton.icon(
                                onPressed: () {
                                  context.read<TicketBloc>().add(ApproveFinalBillRequestedEvent(currentTicket.id));
                                },
                                icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                                label: const Text('Setujui Nota Tagihan Ini', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.successGreen,
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              )
                            else if (currentTicket.status != TicketStatus.completed)
                              ElevatedButton.icon(
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                                    builder: (_) => UserPaymentModal(ticket: currentTicket),
                                  );
                                },
                                icon: const Icon(Icons.payment, color: Colors.white),
                                label: const Text('Bayar Tagihan Sekarang (DOKU)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              )
                            else ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.successGreen.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.3)),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle, color: AppColors.successGreen, size: 18),
                                    SizedBox(width: 8),
                                    Text('LUNAS — Pembayaran Terverifikasi', style: TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: () => UserRatingModal.show(context, currentTicket),
                                icon: const Icon(Icons.star, color: AppColors.safetyAmber, size: 18),
                                label: Text(
                                  currentTicket.ratingStars != null ? 'Ubah Ulasan (${currentTicket.ratingStars}★)' : 'Beri Ulasan Tukang',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
                                ),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(44),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  side: const BorderSide(color: AppColors.border),
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                          ],

                          // Work Photos Documentation
                          const Text(
                            'Dokumentasi Foto Pekerjaan',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Sebelum Pengerjaan', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                    const SizedBox(height: 6),
                                    Container(
                                      height: 100,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppColors.border),
                                      ),
                                      child: currentTicket.beforePhotos.isNotEmpty
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(11),
                                              child: Image.network(currentTicket.beforePhotos[0], fit: BoxFit.cover),
                                            )
                                          : const Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.photo_camera_back, color: AppColors.textMuted, size: 28),
                                                  SizedBox(height: 4),
                                                  Text('Belum ada foto', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                                ],
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Hasil Akhir', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                    const SizedBox(height: 6),
                                    Container(
                                      height: 100,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppColors.border),
                                      ),
                                      child: currentTicket.afterPhotos.isNotEmpty
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(11),
                                              child: Image.network(currentTicket.afterPhotos[0], fit: BoxFit.cover),
                                            )
                                          : const Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.task_alt, color: AppColors.textMuted, size: 28),
                                                  SizedBox(height: 4),
                                                  Text('Belum selesai', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                                ],
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
