import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/service_categories.dart';
import '../../../data/models/ticket_model.dart';
import '../../../data/models/tukang_model.dart';
import '../../../domain/entities/ticket_status.dart';
import '../../chat/pages/chat_page.dart';
import '../../ticket/bloc/ticket_bloc.dart';
import '../../ticket/bloc/ticket_event.dart';
import '../../ticket/bloc/ticket_state.dart';
import 'mitra_active_job_page.dart';

class MitraJobFeedPage extends StatefulWidget {
  final TukangModel tukang;
  const MitraJobFeedPage({super.key, required this.tukang});

  @override
  State<MitraJobFeedPage> createState() => _MitraJobFeedPageState();
}

class _MitraJobFeedPageState extends State<MitraJobFeedPage> {
  late bool _isOnline;
  String _selectedCategoryFilter = 'all';

  @override
  void initState() {
    super.initState();
    _isOnline = widget.tukang.isOnline;
    _fetchRadar();
  }

  void _fetchRadar() {
    context.read<TicketBloc>().add(
      FetchTukangRadarTicketsEvent(
        services: widget.tukang.services,
        lat: widget.tukang.currentLocation?.lat ?? -6.2088,
        lng: widget.tukang.currentLocation?.lng ?? 106.8456,
        radiusKm: widget.tukang.workRadiusKm,
        tukangId: widget.tukang.id,
      ),
    );
  }

  double _calculateDistanceInKm(double lat1, double lon1, double lat2, double lon2) {
    if (lat1 == 0.0 && lon1 == 0.0) return 2.4;
    const p = 0.017453292519943295;
    final a = 0.5 - math.cos((lat2 - lat1) * p)/2 + 
            math.cos(lat1 * p) * math.cos(lat2 * p) * 
            (1 - math.cos((lon2 - lon1) * p))/2;
    final dist = 12742 * math.asin(math.sqrt(a));
    return dist < 0.5 ? 1.2 : dist;
  }

  /// 1-Click Instant Bidding
  void _submitDirect1ClickBid(TicketModel ticket) {
    if (widget.tukang.isCurrentlySuspended) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Akun Anda sedang disuspend. Tidak dapat mengajukan penawaran.'), backgroundColor: AppColors.dangerRed),
      );
      return;
    }

    context.read<TicketBloc>().add(
      SubmitBidRequestedEvent(
        ticketId: ticket.id,
        tukangId: widget.tukang.id,
        tukangName: widget.tukang.name,
        tukangPhoto: widget.tukang.photoUrl,
        tukangRating: widget.tukang.rating,
        estimatedPrice: 0,
        note: 'Siap datang dan mengerjakan tiket ${ticket.category.toUpperCase()} Anda.',
      ),
    );
  }

  /// Modal Bottom Sheet Notifikasi Chat & Radar Job
  void _showNotificationBottomSheet(BuildContext context, List<TicketModel> radarTickets) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return DefaultTabController(
          length: 2,
          child: Container(
            height: MediaQuery.of(ctx).size.height * 0.75,
            padding: const EdgeInsets.all(20),
            child: Column(
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
                Row(
                  children: [
                    const Icon(Icons.notifications_active_rounded, color: AppColors.safetyAmber, size: 24),
                    const SizedBox(width: 8),
                    const Text('Pusat Notifikasi Mitra', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textDark)),
                    const Spacer(),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 10),
                TabBar(
                  labelColor: AppColors.textDark,
                  unselectedLabelColor: AppColors.textMuted,
                  indicatorColor: AppColors.textDark,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: const [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 16),
                          SizedBox(width: 6),
                          Text('Pesan Chat (2)'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.radar_rounded, size: 16),
                          SizedBox(width: 6),
                          Text('Radar Order'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TabBarView(
                    children: [
                      // TAB 1: Chat Notifications List
                      ListView(
                        children: [
                          _buildNotificationChatItem(
                            name: 'Budi Santoso (AC Servis)',
                            message: 'Mas, kapan perkiraan bisa sampai ke rumah?',
                            time: '10:42',
                            unreadCount: 1,
                            onTap: () {
                              Navigator.pop(ctx);
                              if (radarTickets.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatPage(
                                      ticket: radarTickets.first,
                                      currentUserId: widget.tukang.id,
                                      currentUserRole: 'tukang',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                          _buildNotificationChatItem(
                            name: 'Siti Aminah (Pipa Mampet)',
                            message: 'Nota jasa perbaikan sudah saya setujui ya mas.',
                            time: 'Kemarin',
                            unreadCount: 0,
                            onTap: () {
                              Navigator.pop(ctx);
                              if (radarTickets.length > 1) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatPage(
                                      ticket: radarTickets[1],
                                      currentUserId: widget.tukang.id,
                                      currentUserRole: 'tukang',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      // TAB 2: Recent Radar Job List
                      radarTickets.isEmpty
                          ? const Center(child: Text('Belum ada tiket baru di sekitar Anda.'))
                          : ListView.builder(
                              itemCount: radarTickets.length,
                              itemBuilder: (context, index) {
                                final t = radarTickets[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: AppColors.textDark.withValues(alpha: 0.1),
                                      child: Icon(ServiceCategories.getIconForCategory(t.category), color: AppColors.textDark, size: 20),
                                    ),
                                    title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    subtitle: Text('📍 ${t.address}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted), maxLines: 1),
                                    trailing: ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        _showJobDetailBottomSheet(context, t, 2.4);
                                      },
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.textDark, minimumSize: const Size(60, 32)),
                                      child: const Text('Detail', style: TextStyle(color: Colors.white, fontSize: 11)),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationChatItem({
    required String name,
    required String message,
    required String time,
    required int unreadCount,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.safetyAmber,
          child: Text(name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(message, style: const TextStyle(fontSize: 12, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(time, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
            if (unreadCount > 0) ...[
              const SizedBox(height: 4),
              CircleAvatar(
                radius: 8,
                backgroundColor: AppColors.dangerRed,
                child: Text('$unreadCount', style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ]
          ],
        ),
      ),
    );
  }

  /// Modal Bottom Sheet Detail Pekerjaan
  void _showJobDetailBottomSheet(BuildContext context, TicketModel ticket, double distance) {
    final isLockedByMe = ticket.status == TicketStatus.locked ||
        ticket.status == TicketStatus.onTheWay ||
        ticket.status == TicketStatus.inProgress ||
        ticket.status == TicketStatus.workCompleted;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.85,
          padding: const EdgeInsets.all(20),
          child: Column(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.bgAC,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(ServiceCategories.getIconForCategory(ticket.category), size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(ticket.category.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primary)),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 8),
              Text(ticket.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 4),
              Text('📍 ${distance.toStringAsFixed(1)} km dari lokasi Anda', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.successGreen)),
              const Divider(height: 24),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Deskripsi Pekerjaan
                      const Text('Deskripsi Permintaan User:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMuted)),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(ticket.description, style: const TextStyle(fontSize: 13, color: AppColors.textDark, height: 1.4)),
                      ),
                      const SizedBox(height: 16),

                      // Informasi Pelanggan & Alamat
                      const Text('Detail Pelanggan & Lokasi:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMuted)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppColors.textDark,
                                  child: Text(
                                    ticket.userName.isNotEmpty ? ticket.userName[0].toUpperCase() : 'U',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(ticket.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    const Text('Pelanggan Beres App', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.place, color: AppColors.dangerRed, size: 18),
                                const SizedBox(width: 6),
                                Expanded(child: Text(ticket.address, style: const TextStyle(fontSize: 12, color: AppColors.textDark))),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Status Stepper Progress Job
                      const Text('Progress Status Pekerjaan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMuted)),
                      const SizedBox(height: 8),
                      _buildProgressStepper(ticket.status),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),
              // Action Buttons: Chat & Mulai Pekerjaan
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatPage(
                              ticket: ticket,
                              currentUserId: widget.tukang.id,
                              currentUserRole: 'tukang',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: AppColors.textDark),
                      label: const Text('Chat User', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.textDark, width: 1.5),
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isLockedByMe
                          ? () {
                              Navigator.pop(ctx);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MitraActiveJobPage(ticket: ticket, tukang: widget.tukang),
                                ),
                              );
                            }
                          : null,
                      icon: Icon(
                        isLockedByMe ? Icons.play_arrow_rounded : Icons.lock_rounded,
                        color: isLockedByMe ? Colors.white : AppColors.textMuted,
                      ),
                      label: Text(
                        isLockedByMe ? 'Mulai Pekerjaan' : 'Mulai (Terkunci)',
                        style: TextStyle(
                          color: isLockedByMe ? Colors.white : AppColors.textMuted,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.successGreen,
                        disabledBackgroundColor: Colors.grey.shade300,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              if (!isLockedByMe)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Center(
                    child: Text(
                      '🔒 Tombol "Mulai Pekerjaan" terbuka setelah User menyetujui Nota/Invoice Jasa di Room Chat.',
                      style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressStepper(TicketStatus status) {
    final stepIndex = _getStepIndex(status);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStepItem(step: 1, label: 'Terkirim', isActive: stepIndex >= 1, isCompleted: stepIndex > 1),
          _buildStepLine(isActive: stepIndex >= 2),
          _buildStepItem(step: 2, label: 'Disetujui', isActive: stepIndex >= 2, isCompleted: stepIndex > 2),
          _buildStepLine(isActive: stepIndex >= 3),
          _buildStepItem(step: 3, label: 'Dikerjakan', isActive: stepIndex >= 3, isCompleted: stepIndex > 3),
          _buildStepLine(isActive: stepIndex >= 4),
          _buildStepItem(step: 4, label: 'Selesai', isActive: stepIndex >= 4, isCompleted: stepIndex >= 4),
        ],
      ),
    );
  }

  int _getStepIndex(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
      case TicketStatus.bidding:
        return 1;
      case TicketStatus.locked:
        return 2;
      case TicketStatus.onTheWay:
      case TicketStatus.inProgress:
      case TicketStatus.workCompleted:
        return 3;
      case TicketStatus.paymentPending:
      case TicketStatus.completed:
        return 4;
      default:
        return 1;
    }
  }

  Widget _buildStepItem({required int step, required String label, required bool isActive, required bool isCompleted}) {
    return Column(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: isActive ? (isCompleted ? AppColors.successGreen : AppColors.textDark) : Colors.grey.shade300,
          child: isCompleted
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : Text('$step', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isActive ? Colors.white : AppColors.textMuted)),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? AppColors.textDark : AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine({required bool isActive}) {
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? AppColors.successGreen : Colors.grey.shade300,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSuspended = widget.tukang.isCurrentlySuspended;
    final tukangLat = widget.tukang.currentLocation?.lat ?? -6.2088;
    final tukangLng = widget.tukang.currentLocation?.lng ?? 106.8456;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          top: true,
          child: Column(
            children: [
              // Modern Floating Box Header (Kartu Profil Tukang Terpisah)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.textDark, Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Row & Icon Notifikasi
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColors.safetyAmber,
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.white,
                                child: Text(
                                  widget.tukang.name.isNotEmpty ? widget.tukang.name[0].toUpperCase() : 'T',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textDark),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Halo, ${widget.tukang.name} 👷‍♂️',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                                ),
                                const SizedBox(height: 2),
                                const Row(
                                  children: [
                                    Icon(Icons.verified_user, color: AppColors.successGreen, size: 12),
                                    SizedBox(width: 4),
                                    Text('Mitra Terverifikasi Admin', style: TextStyle(color: AppColors.successGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Icon Notifikasi dengan Badge Red Dot
                        BlocBuilder<TicketBloc, TicketState>(
                          builder: (context, state) {
                            final radarTickets = state is TicketListLoadedState ? state.tickets : <TicketModel>[];
                            return Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.notifications_active_rounded, color: AppColors.safetyAmber),
                                    onPressed: () => _showNotificationBottomSheet(context, radarTickets),
                                    tooltip: 'Notifikasi Chat & Radar Job',
                                  ),
                                ),
                                Positioned(
                                  right: 6,
                                  top: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppColors.dangerRed,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Text('2', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Quick Stats Cards Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickStatTile(
                            icon: Icons.star_rounded,
                            iconColor: AppColors.safetyAmber,
                            title: '${widget.tukang.rating}',
                            subtitle: 'Rating Sempurna',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildQuickStatTile(
                            icon: Icons.radar_rounded,
                            iconColor: AppColors.primaryLight,
                            title: '${widget.tukang.workRadiusKm.toInt()} km',
                            subtitle: 'Radius GPS',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildQuickStatTile(
                            icon: Icons.account_balance_wallet_rounded,
                            iconColor: AppColors.successGreen,
                            title: 'Rp ${(widget.tukang.walletBalance / 1000).toStringAsFixed(0)}rb',
                            subtitle: 'Saldo Dompet',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Online / Offline Status Switch Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                  border: Border.all(
                    color: _isOnline ? AppColors.successGreen.withValues(alpha: 0.4) : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: _isOnline ? AppColors.successGreen : AppColors.textMuted,
                            shape: BoxShape.circle,
                            boxShadow: _isOnline
                                ? [BoxShadow(color: AppColors.successGreen.withValues(alpha: 0.6), blurRadius: 8, spreadRadius: 2)]
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isOnline ? 'STATUS: ONLINE (SIAP TERIMA JOB)' : 'STATUS: OFFLINE (ISTIRAHAT)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: _isOnline ? AppColors.successGreen : AppColors.textMuted,
                              ),
                            ),
                            Text(
                              _isOnline ? 'Radar memantau tiket di radius <= ${widget.tukang.workRadiusKm.toInt()} km' : 'Aktifkan untuk menerima notifikasi order terdekat',
                              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Switch(
                      value: _isOnline,
                      activeColor: AppColors.successGreen,
                      onChanged: (val) {
                        setState(() => _isOnline = val);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(val ? 'Status Mitra: ONLINE (Aktif Memantau Job)' : 'Status Mitra: OFFLINE')),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Suspend Alert (If applicable)
              if (isSuspended)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.dangerRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.dangerRed),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.dangerRed, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('AKUN DALAM SANKSI SUSPEND (3 HARI)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.dangerRed, fontSize: 12)),
                            Text('Alasan: ${widget.tukang.suspendReason ?? 'Pelanggaran ketentuan'}', style: const TextStyle(fontSize: 11, color: AppColors.textDark)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 8),
              // Category Filter Bar (Horizontal Chips)
              Container(
                height: 40,
                margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFilterChip('all', 'Semua Kategori', Icons.grid_view_rounded),
                    ...ServiceCategories.all.map((cat) => _buildFilterChip(cat.id, cat.name, cat.icon)),
                  ],
                ),
              ),

              // Job Radar Feed List
              Expanded(
                child: BlocConsumer<TicketBloc, TicketState>(
                  listener: (context, state) {
                    if (state is BidSubmittedSuccessState) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Penawaran (Bid) Anda berhasil terkirim ke Pelanggan!'), backgroundColor: AppColors.successGreen),
                      );
                      _fetchRadar();
                    }
                  },
                  builder: (context, state) {
                    if (state is TicketLoadingState) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.textDark));
                    }

                    if (state is TicketListLoadedState) {
                      final allTickets = state.tickets;
                      final filteredTickets = _selectedCategoryFilter == 'all'
                          ? allTickets
                          : allTickets.where((t) => t.category == _selectedCategoryFilter).toList();

                      if (filteredTickets.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.radar_rounded, size: 56, color: AppColors.textMuted),
                                const SizedBox(height: 12),
                                const Text('Belum Ada Tiket Pekerjaan di Radar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Text(
                                  _selectedCategoryFilter == 'all'
                                      ? 'Tidak ada tiket terbuka dalam radius jangkauan ${widget.tukang.workRadiusKm.toInt()} km. Jika pelanggan telah melock tukang lain, job akan otomatis hilang dari radar.'
                                      : 'Tidak ada tiket kategori ini di sekitar lokasi Anda.',
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filteredTickets.length,
                        itemBuilder: (context, index) {
                          final ticket = filteredTickets[index];
                          final hasAlreadyBid = ticket.bids.any((b) => b.tukangId == widget.tukang.id);
                          final distance = _calculateDistanceInKm(tukangLat, tukangLng, ticket.lat, ticket.lng);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top Badge Row (Category + Distance Pill)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.bgAC,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(ServiceCategories.getIconForCategory(ticket.category), size: 14, color: AppColors.primary),
                                            const SizedBox(width: 4),
                                            Text(
                                              ticket.category.toUpperCase(),
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primary),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.successGreen.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.3)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.location_on, size: 12, color: AppColors.successGreen),
                                            const SizedBox(width: 2),
                                            Text(
                                              '📍 ${distance.toStringAsFixed(1)} km dari lokasi Anda',
                                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.successGreen),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),
                                  Text(ticket.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                                  const SizedBox(height: 4),
                                  Text(ticket.description, style: const TextStyle(fontSize: 13, color: AppColors.textMuted), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 12),

                                  // Customer & Address Info Card
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 12,
                                              backgroundColor: AppColors.primaryLight,
                                              child: Text(
                                                ticket.userName.isNotEmpty ? ticket.userName[0].toUpperCase() : 'U',
                                                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(ticket.userName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.place_outlined, size: 14, color: AppColors.textMuted),
                                            const SizedBox(width: 4),
                                            Expanded(child: Text(ticket.address, style: const TextStyle(fontSize: 11, color: AppColors.textMuted), overflow: TextOverflow.ellipsis)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Action Buttons: 1-Click Bid + Tombol Detail
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: ElevatedButton.icon(
                                          onPressed: (isSuspended || hasAlreadyBid) ? null : () => _submitDirect1ClickBid(ticket),
                                          icon: Icon(
                                            hasAlreadyBid ? Icons.check_circle_rounded : Icons.touch_app_rounded,
                                            color: hasAlreadyBid ? AppColors.textMuted : Colors.white,
                                            size: 16,
                                          ),
                                          label: Text(
                                            hasAlreadyBid ? '✓ Anda Sudah Bid' : 'Ajukan Bid (1-Click)',
                                            style: TextStyle(
                                              color: hasAlreadyBid ? AppColors.textMuted : Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.textDark,
                                            disabledBackgroundColor: Colors.grey.shade300,
                                            disabledForegroundColor: AppColors.textMuted,
                                            minimumSize: const Size.fromHeight(42),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        flex: 2,
                                        child: OutlinedButton.icon(
                                          onPressed: () => _showJobDetailBottomSheet(context, ticket, distance),
                                          icon: const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textDark),
                                          label: const Text(
                                            'Detail',
                                            style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: AppColors.textDark, width: 1.5),
                                            minimumSize: const Size.fromHeight(42),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        ),
                                      ),
                                    ],
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
        ),
      ),
    );
  }

  Widget _buildQuickStatTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 9), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String id, String label, IconData icon) {
    final isSelected = _selectedCategoryFilter == id;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategoryFilter = id;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.textDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.textDark : AppColors.border),
          boxShadow: [
            if (isSelected)
              BoxShadow(color: AppColors.textDark.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : AppColors.textDark),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
