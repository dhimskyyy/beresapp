import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/service_categories.dart';
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

  /// 1-Click Instant Bidding (Tanpa Modal Input Harga / Pesan)
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

  @override
  Widget build(BuildContext context) {
    final isSuspended = widget.tukang.isCurrentlySuspended;
    final tukangLat = widget.tukang.currentLocation?.lat ?? -6.2088;
    final tukangLng = widget.tukang.currentLocation?.lng ?? 106.8456;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: true,
        child: Column(
          children: [
            // Modern Header Dashboard Card (Slate Dark Theme)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.textDark, Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Row
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
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                          onPressed: _fetchRadar,
                          tooltip: 'Segarkan Radar Job',
                        ),
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
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

                                // Action Button: 1-Click Bid or Disabled Once Bid
                                ElevatedButton.icon(
                                  onPressed: (isSuspended || hasAlreadyBid) ? null : () => _submitDirect1ClickBid(ticket),
                                  icon: Icon(
                                    hasAlreadyBid ? Icons.check_circle_rounded : Icons.touch_app_rounded,
                                    color: hasAlreadyBid ? AppColors.textMuted : Colors.white,
                                    size: 18,
                                  ),
                                  label: Text(
                                    hasAlreadyBid ? '✓ Anda Sudah Bid' : 'Ajukan Penawaran (1-Click Bid)',
                                    style: TextStyle(
                                      color: hasAlreadyBid ? AppColors.textMuted : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.textDark,
                                    disabledBackgroundColor: Colors.grey.shade300,
                                    disabledForegroundColor: AppColors.textMuted,
                                    minimumSize: const Size.fromHeight(44),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
