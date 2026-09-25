import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/ticket_model.dart';
import '../../../domain/entities/ticket_status.dart';
import '../../ticket/bloc/ticket_bloc.dart';
import '../../ticket/bloc/ticket_event.dart';
import '../../ticket/bloc/ticket_state.dart';

enum BidSortOption {
  cheapest('Termurah', Icons.arrow_downward),
  highestRating('Rating Tertinggi', Icons.star),
  newest('Terbaru', Icons.access_time);

  final String label;
  final IconData icon;
  const BidSortOption(this.label, this.icon);
}

class TicketBidsPage extends StatefulWidget {
  final TicketModel ticket;
  const TicketBidsPage({super.key, required this.ticket});

  @override
  State<TicketBidsPage> createState() => _TicketBidsPageState();
}

class _TicketBidsPageState extends State<TicketBidsPage> {
  BidSortOption _selectedSort = BidSortOption.cheapest;
  final _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _ticketSub;
  late TicketModel _liveTicket;

  @override
  void initState() {
    super.initState();
    _liveTicket = widget.ticket;
    _ticketSub = FirebaseFirestore.instance
        .collection('tickets')
        .doc(widget.ticket.id)
        .snapshots()
        .listen((snap) {
      if (snap.exists && snap.data() != null && mounted) {
        setState(() {
          _liveTicket = TicketModel.fromMap(snap.data()!, snap.id);
        });
      }
    });
  }

  @override
  void dispose() {
    _ticketSub?.cancel();
    super.dispose();
  }

  List<BidModel> _getSortedBids(List<BidModel> bids) {
    final list = List<BidModel>.from(bids);
    switch (_selectedSort) {
      case BidSortOption.cheapest:
        list.sort((a, b) => a.estimatedPrice.compareTo(b.estimatedPrice));
        break;
      case BidSortOption.highestRating:
        list.sort((a, b) => b.tukangRating.compareTo(a.tukangRating));
        break;
      case BidSortOption.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
    return list;
  }

  void _showLockConfirmation(BuildContext context, BidModel bid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (diagCtx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.handshake, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Konfirmasi Kunci Tukang',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textDark),
                      ),
                      Text(
                        'Pilihan Anda akan mengunci penawaran mitra',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Profile Card preview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: NetworkImage(
                          bid.tukangPhoto ?? 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bid.tukangName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star, color: AppColors.safetyAmber, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '${bid.tukangRating.toStringAsFixed(1)} (Mitra Terverifikasi)',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Estimasi Biaya:',
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                      Text(
                        _currencyFormat.format(bid.estimatedPrice),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Policy Guarantee Notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, color: Colors.amber, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Garansi Bebas Biaya Batal jika tukang belum berangkat. Setelah tukang mengupdate status "Menuju Lokasi", pembatalan sepihak via tombol di-lock demi keadilan mitra.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF78350F), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(diagCtx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: const Text('Batal', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(diagCtx);
                      context.read<TicketBloc>().add(
                        LockTukangRequestedEvent(
                          ticketId: widget.ticket.id,
                          selectedTukangId: bid.tukangId,
                          selectedTukangName: bid.tukangName,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Ya, Kunci Tukang Ini',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Bandingkan Penawaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0.5,
      ),
      body: BlocConsumer<TicketBloc, TicketState>(
        listener: (context, state) {
          if (state is TukangLockedSuccessState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Tukang ${state.lockedTicket.selectedTukangName} berhasil dipilih & dikunci!')),
                  ],
                ),
                backgroundColor: AppColors.successGreen,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
            Navigator.pop(context);
          }
        },
        builder: (context, state) {
          // Use current ticket from state if available
          final currentTicket = (state is TicketListLoadedState)
              ? state.tickets.firstWhere((t) => t.id == widget.ticket.id, orElse: () => _liveTicket)
              : _liveTicket;

          final isLocked = currentTicket.status != TicketStatus.open && currentTicket.status != TicketStatus.bidding;
          final sortedBids = _getSortedBids(currentTicket.bids);

          return Column(
            children: [
              // Ticket Summary Hero Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                currentTicket.category.toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primary),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '#TCK-${currentTicket.id.length > 5 ? currentTicket.id.substring(0, 5).toUpperCase() : currentTicket.id}',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isLocked ? AppColors.successGreen.withValues(alpha: 0.1) : AppColors.safetyAmber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isLocked ? AppColors.successGreen.withValues(alpha: 0.3) : AppColors.safetyAmber.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            currentTicket.status.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isLocked ? AppColors.successGreen : AppColors.safetyAmber,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      currentTicket.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    if (currentTicket.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        currentTicket.description,
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: AppColors.dangerRed),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            currentTicket.address,
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Filter & Counter Row
              if (currentTicket.bids.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Text(
                        '${currentTicket.bids.length} Penawaran Masuk',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      const Spacer(),
                      PopupMenuButton<BidSortOption>(
                        initialValue: _selectedSort,
                        onSelected: (option) => setState(() => _selectedSort = option),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_selectedSort.icon, size: 14, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                _selectedSort.label,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
                              ),
                              const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textMuted),
                            ],
                          ),
                        ),
                        itemBuilder: (context) => BidSortOption.values.map((opt) {
                          return PopupMenuItem(
                            value: opt,
                            child: Row(
                              children: [
                                Icon(opt.icon, size: 16, color: opt == _selectedSort ? AppColors.primary : AppColors.textMuted),
                                const SizedBox(width: 8),
                                Text(
                                  opt.label,
                                  style: TextStyle(
                                    fontWeight: opt == _selectedSort ? FontWeight.bold : FontWeight.normal,
                                    color: opt == _selectedSort ? AppColors.primary : AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

              // Bids List
              Expanded(
                child: currentTicket.bids.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.radar, size: 40, color: AppColors.primary),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Mencari Penawaran Mitra...',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Permintaan Anda telah dibroadcast ke tukang terverifikasi di area sekitar. Penawaran biasanya masuk dalam 2-5 menit.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: sortedBids.length,
                        itemBuilder: (context, index) {
                          final bid = sortedBids[index];
                          final isThisSelected = currentTicket.selectedTukangId == bid.tukangId;
                          final simulatedDistance = (1.2 + (index * 0.7)).toStringAsFixed(1);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isThisSelected
                                    ? AppColors.successGreen
                                    : (index == 0 && !isLocked ? AppColors.primary.withValues(alpha: 0.5) : AppColors.border),
                                width: isThisSelected ? 2 : (index == 0 && !isLocked ? 1.5 : 1),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Best Price Banner
                                if (index == 0 && _selectedSort == BidSortOption.cheapest && !isLocked)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.verified, size: 14, color: AppColors.primary),
                                        SizedBox(width: 6),
                                        Text(
                                          'Rekomendasi Penawaran Paling Ekonomis',
                                          style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),

                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Tukang Row
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Stack(
                                            children: [
                                              CircleAvatar(
                                                radius: 26,
                                                backgroundImage: NetworkImage(
                                                  bid.tukangPhoto ?? 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
                                                ),
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
                                              )
                                            ],
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  bid.tukangName,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.safetyAmber.withValues(alpha: 0.15),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          const Icon(Icons.star, color: AppColors.safetyAmber, size: 12),
                                                          const SizedBox(width: 3),
                                                          Text(
                                                            bid.tukangRating.toStringAsFixed(1),
                                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Row(
                                                      children: [
                                                        const Icon(Icons.near_me, size: 12, color: AppColors.textMuted),
                                                        const SizedBox(width: 2),
                                                        Text('~$simulatedDistance km', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Price Badge
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              const Text('Estimasi', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                              Text(
                                                _currencyFormat.format(bid.estimatedPrice),
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),

                                      // Equipment & Readiness Note
                                      if (bid.note.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: const Color(0xFFE2E8F0)),
                                          ),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Icon(Icons.handyman_outlined, size: 16, color: AppColors.textMuted),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  bid.note,
                                                  style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.3),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],

                                      const SizedBox(height: 14),

                                      // Action Button
                                      if (!isLocked)
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: () => _showLockConfirmation(context, bid),
                                            icon: const Icon(Icons.check_circle_outline, size: 18),
                                            label: const Text('Pilih & Kunci Tukang Ini', style: TextStyle(fontWeight: FontWeight.bold)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primary,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                          ),
                                        )
                                      else if (isThisSelected)
                                        Container(
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: AppColors.successGreen.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.4)),
                                          ),
                                          child: const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.verified, size: 16, color: AppColors.successGreen),
                                              SizedBox(width: 6),
                                              Text(
                                                'Tukang Terpilih untuk Pesanan Ini',
                                                style: TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
