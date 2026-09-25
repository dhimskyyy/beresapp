import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/service_categories.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../data/models/tukang_model.dart';
import '../../../domain/entities/ticket_status.dart';
import '../../chat/pages/chat_page.dart';
import '../../ticket/bloc/ticket_bloc.dart';
import '../../ticket/bloc/ticket_event.dart';
import '../../ticket/bloc/ticket_state.dart';

class MitraChatListPage extends StatefulWidget {
  final TukangModel tukang;
  const MitraChatListPage({super.key, required this.tukang});

  @override
  State<MitraChatListPage> createState() => _MitraChatListPageState();
}

class _MitraChatListPageState extends State<MitraChatListPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<TicketBloc>().add(FetchTukangActiveTicketsEvent(widget.tukang.id));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Kotak Masuk Chat Konsumen', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.textDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocBuilder<TicketBloc, TicketState>(
        builder: (context, state) {
          if (state is TicketLoadingState) {
            return const AppLoadingView(message: 'Memuat pesan konsumen...');
          }

          if (state is TicketOperationFailureState) {
            return AppErrorView(
              message: state.message,
              onRetry: () => context.read<TicketBloc>().add(FetchTukangActiveTicketsEvent(widget.tukang.id)),
            );
          }

          if (state is TicketListLoadedState) {
            if (state.tickets.isEmpty) {
              return const AppEmptyView(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Belum Ada Percakapan',
                subtitle: 'Percakapan dengan konsumen akan muncul di sini setelah Anda terpilih / mengunci orderan pada radar pekerjaan.',
              );
            }

            var tickets = state.tickets;
          if (_searchQuery.isNotEmpty) {
            tickets = tickets.where((t) {
              final user = t.userName;
              final title = t.title;
              return user.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  title.toLowerCase().contains(_searchQuery.toLowerCase());
            }).toList();
          }

          return Column(
            children: [
              // Search Header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'Cari nama konsumen atau jenis pekerjaan...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              // Chat Items
              Expanded(
                child: tickets.isEmpty
                    ? Center(
                        child: Text(
                          'Tidak ada percakapan yang cocok dengan "$_searchQuery"',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        itemCount: tickets.length,
                        itemBuilder: (context, idx) {
                          final ticket = tickets[idx];
                          final categoryMeta = ServiceCategories.findById(ticket.category);
                          final consumerName = ticket.userName.isNotEmpty ? ticket.userName : 'Konsumen Beres';

                          final lastMsg = ticket.status == TicketStatus.completed
                              ? '✅ Pekerjaan tuntas & pembayaran lunas.'
                              : (ticket.status == TicketStatus.inProgress
                                  ? '🛠️ Anda sedang mengerjakan perbaikan ini'
                                  : (ticket.status == TicketStatus.onTheWay
                                      ? '🛵 Anda sedang menuju lokasi konsumen'
                                      : '📋 Permintaan: ${ticket.title}'));

                          final timeStr = DateFormat('HH:mm').format(ticket.updatedAt);
                          final isActive = ticket.status.isActive;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
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
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      // Avatar with category icon badge
                                      Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          CircleAvatar(
                                            radius: 26,
                                            backgroundColor: AppColors.textDark,
                                            child: Text(
                                              consumerName.isNotEmpty ? consumerName[0].toUpperCase() : 'K',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: -2,
                                            right: -2,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: isActive ? AppColors.safetyAmber : Colors.grey.shade400,
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.white, width: 2),
                                              ),
                                              child: Icon(categoryMeta?.icon ?? Icons.build_rounded, size: 10, color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 14),

                                      // Chat Snippet
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    consumerName,
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Text(timeStr, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                              ],
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              ticket.title,
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    lastMsg,
                                                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (isActive)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.successGreen.withValues(alpha: 0.12),
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    child: Text(
                                                      ticket.status.label,
                                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.successGreen),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        }

        return AppErrorView(
          message: 'Terjadi kesalahan saat memuat obrolan konsumen.',
          onRetry: () => context.read<TicketBloc>().add(FetchTukangActiveTicketsEvent(widget.tukang.id)),
        );
      },
    ),
  );
}
}
