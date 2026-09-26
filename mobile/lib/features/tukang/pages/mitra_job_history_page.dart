import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/service_categories.dart';
import '../../../data/models/ticket_model.dart';
import '../../../data/models/tukang_model.dart';
import '../../../domain/entities/ticket_status.dart';
import '../../ticket/bloc/ticket_bloc.dart';
import '../../ticket/bloc/ticket_event.dart';
import '../../ticket/bloc/ticket_state.dart';

class MitraJobHistoryPage extends StatefulWidget {
  final TukangModel tukang;
  const MitraJobHistoryPage({super.key, required this.tukang});

  @override
  State<MitraJobHistoryPage> createState() => _MitraJobHistoryPageState();
}

class _MitraJobHistoryPageState extends State<MitraJobHistoryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<TicketBloc>().add(FetchTukangActiveTicketsEvent(widget.tukang.id));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showJobDetailModal(BuildContext context, TicketModel ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#TCK-${ticket.id.length > 6 ? ticket.id.substring(0, 6).toUpperCase() : ticket.id}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ticket.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ticket.status == TicketStatus.completed
                        ? AppColors.successGreen.withValues(alpha: 0.12)
                        : AppColors.dangerRed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    ticket.status.label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: ticket.status == TicketStatus.completed ? AppColors.successGreen : AppColors.dangerRed,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Consumer Details
                    const Text('Informasi Konsumen', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person, size: 16, color: AppColors.textMuted),
                              const SizedBox(width: 8),
                              Text(ticket.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on, size: 16, color: AppColors.dangerRed),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(ticket.address, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Bill Breakdown
                    if (ticket.finalBill != null) ...[
                      const Text('Rincian Nota & Pendapatan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            ...ticket.finalBill!.items.map(
                              (i) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(i.title, style: const TextStyle(fontSize: 13)),
                                    Text(_currencyFormat.format(i.amount), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  ],
                                ),
                              ),
                            ),
                            const Divider(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Diterima Mitra', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                Text(
                                  _currencyFormat.format(ticket.finalBill!.totalAmount),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.successGreen),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Rating & Review Section
                    if (ticket.ratingStars != null) ...[
                      const Text('Ulasan & Penilaian Konsumen', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: List.generate(5, (index) {
                                return Icon(
                                  index < (ticket.ratingStars ?? 0) ? Icons.star : Icons.star_border,
                                  color: AppColors.safetyAmber,
                                  size: 20,
                                );
                              }),
                            ),
                            if (ticket.ratingReview != null && ticket.ratingReview!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                '"${ticket.ratingReview}"',
                                style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Color(0xFF78350F)),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Photos (Before & After)
                    if (ticket.beforePhotos.isNotEmpty || ticket.afterPhotos.isNotEmpty) ...[
                      const Text('Dokumentasi Foto Pengerjaan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (ticket.beforePhotos.isNotEmpty)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Sebelum', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(ticket.beforePhotos[0], height: 90, width: double.infinity, fit: BoxFit.cover),
                                  ),
                                ],
                              ),
                            ),
                          if (ticket.beforePhotos.isNotEmpty && ticket.afterPhotos.isNotEmpty)
                            const SizedBox(width: 12),
                          if (ticket.afterPhotos.isNotEmpty)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Sesudah', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(ticket.afterPhotos[0], height: 90, width: double.infinity, fit: BoxFit.cover),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textDark,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Tutup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildJobCard(TicketModel ticket) {
    final isCompleted = ticket.status == TicketStatus.completed;
    final categoryMeta = ServiceCategories.findById(ticket.category);
    final totalEarnings = ticket.finalBill?.totalAmount ?? (ticket.bids.isNotEmpty ? ticket.bids.first.estimatedPrice : 0.0);
    String dateStr;
    try {
      dateStr = DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(ticket.updatedAt);
    } catch (_) {
      dateStr = DateFormat('d MMM yyyy, HH:mm').format(ticket.updatedAt);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showJobDetailModal(context, ticket),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.textDark.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            (categoryMeta?.name ?? ticket.category).toUpperCase(),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '#TCK-${ticket.id.length > 6 ? ticket.id.substring(0, 6).toUpperCase() : ticket.id}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    Text(dateStr, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 10),

                // Title & Address
                Text(
                  ticket.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(ticket.userName, style: const TextStyle(fontSize: 12, color: AppColors.textDark)),
                    const SizedBox(width: 8),
                    const Text('•', style: TextStyle(color: AppColors.textMuted)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ticket.address,
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),

                // Bottom Earnings & Rating Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (isCompleted)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Pendapatan Bersih', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                          Text(
                            _currencyFormat.format(totalEarnings),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.successGreen),
                          ),
                        ],
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.dangerRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Dibatalkan',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.dangerRed),
                        ),
                      ),

                    // Customer Review preview or detail arrow
                    if (ticket.ratingStars != null)
                      Row(
                        children: [
                          const Icon(Icons.star, color: AppColors.safetyAmber, size: 16),
                          const SizedBox(width: 3),
                          Text(
                            '${ticket.ratingStars}.0',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
                        ],
                      )
                    else
                      const Row(
                        children: [
                          Text('Lihat Rincian', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Riwayat Pekerjaan Mitra', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.textDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocBuilder<TicketBloc, TicketState>(
        builder: (context, state) {
          List<TicketModel> allTickets = [];
          if (state is TicketListLoadedState) {
            allTickets = state.tickets;
          }

          // Completed & Canceled tickets
          final completedTickets = allTickets.where((t) => t.status == TicketStatus.completed).toList();
          final canceledTickets = allTickets.where((t) => t.status == TicketStatus.canceled).toList();
          final historyTickets = allTickets.where((t) => t.status == TicketStatus.completed || t.status == TicketStatus.canceled).toList();

          // Calculate summary metrics
          double totalEarnings = 0;
          int totalReviews = 0;
          double starSum = 0;

          for (final t in completedTickets) {
            totalEarnings += t.finalBill?.totalAmount ?? (t.bids.isNotEmpty ? t.bids.first.estimatedPrice : 0.0);
            if (t.ratingStars != null) {
              starSum += t.ratingStars!;
              totalReviews++;
            }
          }

          final avgRating = totalReviews > 0 ? (starSum / totalReviews).toStringAsFixed(1) : '5.0';

          return Column(
            children: [
              // Summary Metrics Header
              Container(
                color: AppColors.textDark,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Row(
                  children: [
                    _buildSummaryCard(
                      title: 'Selesai',
                      value: '${completedTickets.length}',
                      icon: Icons.task_alt,
                      color: AppColors.successGreen,
                    ),
                    const SizedBox(width: 10),
                    _buildSummaryCard(
                      title: 'Total Pendapatan',
                      value: _currencyFormat.format(totalEarnings),
                      icon: Icons.monetization_on_outlined,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    _buildSummaryCard(
                      title: 'Kepuasan',
                      value: '$avgRating ★',
                      icon: Icons.star_outline,
                      color: AppColors.safetyAmber,
                    ),
                  ],
                ),
              ),

              // Filter Tabs
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppColors.textDark,
                  unselectedLabelColor: AppColors.textMuted,
                  indicatorColor: AppColors.textDark,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: [
                    Tab(text: 'Semua (${historyTickets.length})'),
                    Tab(text: 'Selesai (${completedTickets.length})'),
                    Tab(text: 'Dibatalkan (${canceledTickets.length})'),
                  ],
                ),
              ),

              // TabBarView Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTicketList(historyTickets, 'Belum ada riwayat pekerjaan.'),
                    _buildTicketList(completedTickets, 'Belum ada pekerjaan yang selesai.'),
                    _buildTicketList(canceledTickets, 'Tidak ada pekerjaan yang dibatalkan.'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTicketList(List<TicketModel> tickets, String emptyMsg) {
    if (tickets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.history_toggle_off, size: 54, color: AppColors.textMuted),
              const SizedBox(height: 14),
              Text(
                emptyMsg,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
              ),
              const SizedBox(height: 6),
              const Text(
                'Pekerjaan yang telah rampung akan tercatat otomatis di sini beserta review dari konsumen.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tickets.length,
      itemBuilder: (context, index) => _buildJobCard(tickets[index]),
    );
  }
}
