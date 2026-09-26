import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/service_categories.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../core/widgets/gps_requirement_dialog.dart';
import '../../../data/models/ticket_model.dart';
import '../../../data/models/tukang_model.dart';
import '../../../domain/entities/ticket_status.dart';
import '../../chat/pages/chat_page.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
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
  StreamSubscription? _radarWatcherSub;

  @override
  void initState() {
    super.initState();
    _isOnline = widget.tukang.isOnline;
    _fetchRadar();
    _radarWatcherSub = FirebaseFirestore.instance
        .collection('tickets')
        .where('status', whereIn: ['OPEN', 'BIDDING'])
        .snapshots()
        .listen(
      (_) {
        if (mounted) _fetchRadar();
      },
      onError: (e) {
        debugPrint('Radar stream watcher note: $e');
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GpsRequirementDialog.checkAndShow(context, isTukang: true);
    });
  }

  @override
  void dispose() {
    _radarWatcherSub?.cancel();
    super.dispose();
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
    final a = 0.5 - math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) * math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) / 2;
    final dist = 12742 * math.asin(math.sqrt(a));
    return dist < 0.5 ? 1.2 : dist;
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mnt lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  /// 1-Click Instant Bidding with feedback
  void _submitDirect1ClickBid(TicketModel ticket) {
    if (widget.tukang.isCurrentlySuspended) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akun Anda sedang disuspend. Tidak dapat mengajukan penawaran.'),
          backgroundColor: AppColors.dangerRed,
        ),
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

  /// Helper safe image builder
  Widget _buildSafeImage(String path, {double width = 64, double height = 64, double radius = 8}) {
    Widget img;
    if (path.startsWith('data:image')) {
      try {
        final base64String = path.split(',').last;
        final bytes = base64Decode(base64String);
        img = Image.memory(
          bytes,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _fallbackImage(width, height),
        );
      } catch (_) {
        img = _fallbackImage(width, height);
      }
    } else if (path.startsWith('http')) {
      img = Image.network(
        path,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallbackImage(width, height),
      );
    } else if (path.startsWith('/')) {
      final file = File(path);
      if (file.existsSync()) {
        img = Image.file(
          file,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _fallbackImage(width, height),
        );
      } else {
        img = _fallbackImage(width, height);
      }
    } else {
      img = Image.asset(
        path,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallbackImage(width, height),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: img,
    );
  }

  Widget _fallbackImage(double w, double h) {
    return Container(
      width: w,
      height: h,
      color: Colors.grey.shade200,
      child: const Icon(Icons.image_outlined, size: 22, color: AppColors.textMuted),
    );
  }

  /// Fullscreen Image Viewer Modal
  void _showImageViewer(BuildContext context, String path) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: _buildSafeImage(path, width: double.infinity, height: 400, radius: 12),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
          ],
        ),
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
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Material(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    clipBehavior: Clip.antiAlias,
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: AppColors.textDark.withValues(alpha: 0.1),
                                        child: Icon(ServiceCategories.getIconForCategory(t.category), color: AppColors.textDark, size: 20),
                                      ),
                                      title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      subtitle: Text('📍 ${t.address} • ${_formatTimeAgo(t.createdAt)}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted), maxLines: 1),
                                      trailing: ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          _showJobDetailBottomSheet(context, t, 2.4);
                                        },
                                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.textDark, minimumSize: const Size(60, 32)),
                                        child: const Text('Detail', style: TextStyle(color: Colors.white, fontSize: 11)),
                                      ),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
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
      ),
    );
  }

  /// Modernized Job Detail Bottom Sheet with Mini Map & Photo Gallery
  void _showJobDetailBottomSheet(BuildContext context, TicketModel ticket, double distance) {
    final isLockedByMe = ticket.status == TicketStatus.locked ||
        ticket.status == TicketStatus.onTheWay ||
        ticket.status == TicketStatus.arrived ||
        ticket.status == TicketStatus.inProgress ||
        ticket.status == TicketStatus.workCompleted;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.88,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Top drag bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
              ),

              // Header bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.bgAC,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(ServiceCategories.getIconForCategory(ticket.category), size: 14, color: AppColors.primary),
                          const SizedBox(width: 5),
                          Text(ticket.category.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primary)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ticket.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      const SizedBox(height: 6),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.successGreen.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on, size: 12, color: AppColors.successGreen),
                                const SizedBox(width: 3),
                                Text('📍 ${distance.toStringAsFixed(1)} km (~${(distance * 3).clamp(3, 60).round()} mnt)',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.successGreen)),
                              ],
                            ),
                          ),
                          Text('• Diposting ${_formatTimeAgo(ticket.createdAt)}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                      const Divider(height: 24),

                      // Deskripsi Pekerjaan
                      const Text('Deskripsi Kendala Konsumen:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMuted)),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(ticket.description, style: const TextStyle(fontSize: 13, color: AppColors.textDark, height: 1.4)),
                      ),
                      const SizedBox(height: 16),

                      // Foto Kendala Konsumen (Jika Ada)
                      if (ticket.photoUrls.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Foto Kendala (${ticket.photoUrls.length}):', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMuted)),
                            const Text('Ketuk untuk perbesar', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 90,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: ticket.photoUrls.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 8),
                            itemBuilder: (context, idx) {
                              final imgPath = ticket.photoUrls[idx];
                              return GestureDetector(
                                onTap: () => _showImageViewer(context, imgPath),
                                child: _buildSafeImage(imgPath, width: 90, height: 90, radius: 10),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Informasi Pelanggan & Alamat
                      const Text('Detail Pelanggan & Lokasi:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMuted)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppColors.primary,
                                  child: Text(
                                    ticket.userName.isNotEmpty ? ticket.userName[0].toUpperCase() : 'U',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(ticket.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      const Row(
                                        children: [
                                          Icon(Icons.verified, size: 12, color: AppColors.primary),
                                          SizedBox(width: 3),
                                          Text('Konsumen Terverifikasi Beres App', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.place_rounded, color: AppColors.dangerRed, size: 18),
                                const SizedBox(width: 6),
                                Expanded(child: Text(ticket.address, style: const TextStyle(fontSize: 12, color: AppColors.textDark))),
                                IconButton(
                                  icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.textMuted),
                                  tooltip: 'Salin Alamat',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: ticket.address));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Alamat berhasil disalin!'), duration: Duration(seconds: 1)),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Mini Map Lokasi Pelanggan
                      if (ticket.lat != 0.0 && ticket.lng != 0.0) ...[
                        const Text('Peta Titik Lokasi Rumah:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMuted)),
                        const SizedBox(height: 6),
                        Container(
                          height: 140,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(ticket.lat, ticket.lng),
                              initialZoom: 15.0,
                              interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.beres.beresapp',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(ticket.lat, ticket.lng),
                                    width: 40,
                                    height: 40,
                                    child: const Icon(Icons.location_on, color: AppColors.dangerRed, size: 36),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Status Stepper Progress Job
                      const Text('Progress Status Pekerjaan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMuted)),
                      const SizedBox(height: 8),
                      _buildProgressStepper(ticket.status),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Action Buttons: Chat & Mulai Pekerjaan
              Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                              isLockedByMe ? 'Buka Pengerjaan' : 'Mulai',
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
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          '🔒 Tombol "Buka Pengerjaan" aktif setelah User menyetujui Nota/Invoice Jasa di Room Chat.',
                          style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
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
      case TicketStatus.arrived:
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
              // Modern Floating Box Header (Kartu Profil Tukang)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
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
                    // Profile Row & Notifikasi
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
                        // Refresh & Notifikasi Row
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                                onPressed: _fetchRadar,
                                tooltip: 'Segarkan Radar',
                              ),
                            ),
                            const SizedBox(width: 6),
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
                                        icon: const Icon(Icons.notifications_active_rounded, color: AppColors.safetyAmber, size: 20),
                                        onPressed: () => _showNotificationBottomSheet(context, radarTickets),
                                        tooltip: 'Notifikasi Chat & Radar Job',
                                      ),
                                    ),
                                    Positioned(
                                      right: 4,
                                      top: 4,
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
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Quick Stats Cards Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickStatTile(
                            icon: Icons.star_rounded,
                            iconColor: AppColors.safetyAmber,
                            title: '${widget.tukang.rating}',
                            subtitle: 'Rating Mitra',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildQuickStatTile(
                            icon: Icons.radar_rounded,
                            iconColor: AppColors.primaryLight,
                            title: '${widget.tukang.workRadiusKm.toInt()} km',
                            subtitle: 'Radius Pantau',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildQuickStatTile(
                            icon: Icons.handyman_rounded,
                            iconColor: AppColors.primary,
                            title: '${widget.tukang.services.length}',
                            subtitle: 'Keahlian Aktif',
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          width: 12,
                          height: 12,
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
                              _isOnline ? 'RADAR AKTIF • ONLINE' : 'RADAR MATI • OFFLINE',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: _isOnline ? AppColors.successGreen : AppColors.textMuted,
                              ),
                            ),
                            Text(
                              _isOnline
                                  ? 'Memindai tiket radius ≤ ${widget.tukang.workRadiusKm.toInt()} km & ${widget.tukang.services.length} keahlian'
                                  : 'Aktifkan untuk menerima notifikasi order terdekat',
                              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Switch(
                      value: _isOnline,
                      activeThumbColor: AppColors.successGreen,
                      activeTrackColor: AppColors.successGreen.withValues(alpha: 0.4),
                      onChanged: (val) {
                        setState(() => _isOnline = val);
                        final updatedTukang = widget.tukang.copyWith(isOnline: val);
                        context.read<AuthBloc>().add(TukangProfileUpdatedEvent(updatedTukang));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(val ? 'Radar pekerjaan kembali ONLINE' : 'Radar pekerjaan kini OFFLINE')),
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

              const SizedBox(height: 6),

              // Synchronized Category Filter Bar (Chips with Category Count Badges)
              BlocBuilder<TicketBloc, TicketState>(
                builder: (context, state) {
                  final allTickets = state is TicketListLoadedState ? state.tickets : <TicketModel>[];
                  final tukangServices = widget.tukang.services;

                  // Categories matching tukang's active skills
                  final relevantCategories = ServiceCategories.all
                      .where((cat) => tukangServices.contains(cat.id))
                      .toList();

                  final totalOpenCount = allTickets.length;

                  return Container(
                    height: 42,
                    margin: const EdgeInsets.only(left: 16, right: 16, bottom: 6),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildFilterChip(
                          'all',
                          'Semua Kategori',
                          Icons.dashboard_rounded,
                          count: totalOpenCount,
                        ),
                        ...relevantCategories.map((cat) {
                          final countInCat = allTickets.where((t) => t.category == cat.id).length;
                          return _buildFilterChip(
                            cat.id,
                            cat.name,
                            cat.icon,
                            count: countInCat,
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),

              // Job Radar Feed List with RefreshIndicator
              Expanded(
                child: BlocConsumer<TicketBloc, TicketState>(
                  listener: (context, state) {
                    if (state is BidSubmittedSuccessState) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✓ Penawaran (Bid) Anda berhasil terkirim ke Pelanggan!'),
                          backgroundColor: AppColors.successGreen,
                        ),
                      );
                      _fetchRadar();
                    }
                  },
                  builder: (context, state) {
                    if (state is TicketLoadingState) {
                      return const AppLoadingView(message: 'Memindai radar tiket pekerjaan...');
                    }

                    if (state is TicketOperationFailureState) {
                      return AppErrorView(
                        title: 'Radar Gagal Memuat',
                        message: state.message,
                        retryLabel: 'Pindai Ulang Radar',
                        onRetry: _fetchRadar,
                      );
                    }

                    if (state is TicketListLoadedState) {
                      final allTickets = state.tickets;
                      final filteredTickets = _selectedCategoryFilter == 'all'
                          ? allTickets
                          : allTickets.where((t) => t.category == _selectedCategoryFilter).toList();

                      if (filteredTickets.isEmpty) {
                        return RefreshIndicator(
                          color: AppColors.textDark,
                          onRefresh: () async => _fetchRadar(),
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Container(
                              height: 380,
                              alignment: Alignment.center,
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.radar_rounded, size: 40, color: AppColors.primary),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text('Belum Ada Tiket di Radar Saat Ini', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
                                  const SizedBox(height: 6),
                                  Text(
                                    _selectedCategoryFilter == 'all'
                                        ? 'Radar memantau dalam radius ${widget.tukang.workRadiusKm.toInt()} km sesuai ${widget.tukang.services.length} keahlian aktif Anda. Tarik ke bawah untuk memindai ulang.'
                                        : 'Tidak ada tiket kategori ini di sekitar lokasi Anda.',
                                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  OutlinedButton.icon(
                                    onPressed: _fetchRadar,
                                    icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.textDark),
                                    label: const Text('Pindai Ulang Radar', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      return RefreshIndicator(
                        color: AppColors.textDark,
                        onRefresh: () async => _fetchRadar(),
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          itemCount: filteredTickets.length,
                          itemBuilder: (context, index) {
                            final ticket = filteredTickets[index];
                            final hasAlreadyBid = ticket.bids.any((b) => b.tukangId == widget.tukang.id);
                            final distance = _calculateDistanceInKm(tukangLat, tukangLng, ticket.lat, ticket.lng);
                            final categoryIcon = ServiceCategories.getIconForCategory(ticket.category);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
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
                                    // Row 1: Category Pill + Time Ago + Distance Pill
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                              decoration: BoxDecoration(
                                                color: AppColors.bgAC,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(categoryIcon, size: 14, color: AppColors.primary),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    ticket.category.toUpperCase(),
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primary),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.access_time_rounded, size: 12, color: Colors.grey.shade700),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    _formatTimeAgo(ticket.createdAt),
                                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.successGreen.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.3)),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.near_me_rounded, size: 12, color: AppColors.successGreen),
                                              const SizedBox(width: 3),
                                              Text(
                                                '${distance.toStringAsFixed(1)} km',
                                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.successGreen),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 12),
                                    Text(ticket.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                                    const SizedBox(height: 4),
                                    Text(
                                      ticket.description,
                                      style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.3),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),

                                    // Ticket Photo Preview Strip (if customer uploaded photos)
                                    if (ticket.photoUrls.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      SizedBox(
                                        height: 60,
                                        child: ListView.separated(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: ticket.photoUrls.length > 4 ? 4 : ticket.photoUrls.length,
                                          separatorBuilder: (context, index) => const SizedBox(width: 8),
                                          itemBuilder: (context, imgIdx) {
                                            final isLast = imgIdx == 3 && ticket.photoUrls.length > 4;
                                            final imgPath = ticket.photoUrls[imgIdx];
                                            return GestureDetector(
                                              onTap: () => _showImageViewer(context, imgPath),
                                              child: Stack(
                                                children: [
                                                  _buildSafeImage(imgPath, width: 60, height: 60, radius: 8),
                                                  if (isLast)
                                                    Container(
                                                      width: 60,
                                                      height: 60,
                                                      decoration: BoxDecoration(
                                                        color: Colors.black54,
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      alignment: Alignment.center,
                                                      child: Text(
                                                        '+${ticket.photoUrls.length - 3}',
                                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],

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
                                                backgroundColor: AppColors.primary,
                                                child: Text(
                                                  ticket.userName.isNotEmpty ? ticket.userName[0].toUpperCase() : 'U',
                                                  style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(ticket.userName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                                              const Spacer(),
                                              const Text('Pelanggan', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.place_outlined, size: 14, color: AppColors.textMuted),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  ticket.address,
                                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 14),

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
                                              hasAlreadyBid ? '✓ Penawaran Terkirim' : 'Kirim Penawaran (1-Klik)',
                                              style: TextStyle(
                                                color: hasAlreadyBid ? AppColors.textMuted : Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.textDark,
                                              disabledBackgroundColor: Colors.grey.shade200,
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
                        ),
                      );
                    }

                    return AppErrorView(
                      title: 'Radar Gagal Memuat',
                      message: 'Tidak dapat memperbarui radar tiket pekerjaan saat ini.',
                      retryLabel: 'Pindai Ulang Radar',
                      onRetry: _fetchRadar,
                    );
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

  Widget _buildFilterChip(String id, String label, IconData icon, {int count = 0}) {
    final isSelected = _selectedCategoryFilter == id;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategoryFilter = id;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8, top: 2, bottom: 2),
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
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.25) : AppColors.safetyAmber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppColors.textDark,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
