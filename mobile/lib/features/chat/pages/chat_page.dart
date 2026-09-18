import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/ticket_model.dart';
import '../../../domain/entities/ticket_status.dart';
import '../../ticket/bloc/ticket_bloc.dart';
import '../../ticket/bloc/ticket_event.dart';
import '../../ticket/bloc/ticket_state.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';

class ChatPage extends StatefulWidget {
  final TicketModel ticket;
  final String currentUserId;
  final String currentUserRole; // 'user' or 'tukang'

  const ChatPage({
    super.key,
    required this.ticket,
    required this.currentUserId,
    required this.currentUserRole,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  late TicketModel _currentTicket;

  @override
  void initState() {
    super.initState();
    _currentTicket = widget.ticket;
    context.read<ChatBloc>().add(StartChatStreamEvent(widget.ticket.id));
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        setState(() => _selectedImage = picked);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengambil gambar: $e')));
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty && _selectedImage == null) return;

    context.read<ChatBloc>().add(
      SendChatMessageRequestedEvent(
        ticketId: _currentTicket.id,
        senderId: widget.currentUserId,
        senderRole: widget.currentUserRole,
        text: text.isNotEmpty ? text : null,
        imagePath: _selectedImage?.path,
      ),
    );

    _messageController.clear();
    setState(() => _selectedImage = null);
  }

  /// Dialog untuk Tukang membuat dan mengirim Invoice / Nota resmi
  void _showCreateInvoiceDialog() {
    final itemTitleCtrl = TextEditingController(text: 'Jasa ${_currentTicket.category.toUpperCase()}');
    final amountCtrl = TextEditingController(text: '100000');

    showDialog(
      context: context,
      builder: (diagCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.receipt_long, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Buat Invoice / Nota Jasa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Masukkan kesepakatan rincian biaya yang telah dibahas bersama Pelanggan di obrolan:', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 12),
              TextField(
                controller: itemTitleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi Item Jasa',
                  hintText: 'Contoh: Jasa Benerin Motor / AC',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Total Nominal Kesepakatan (Rp)',
                  hintText: 'Contoh: 100000',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(diagCtx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
                if (amount <= 0 || itemTitleCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nominal & item tidak boleh kosong')));
                  return;
                }
                Navigator.pop(diagCtx);

                final items = [
                  BillItem(title: itemTitleCtrl.text.trim(), amount: amount),
                ];

                context.read<TicketBloc>().add(
                  SubmitFinalBillRequestedEvent(
                    ticketId: _currentTicket.id,
                    items: items,
                  ),
                );

                // Send chat callout message
                context.read<ChatBloc>().add(
                  SendChatMessageRequestedEvent(
                    ticketId: _currentTicket.id,
                    senderId: widget.currentUserId,
                    senderRole: widget.currentUserRole,
                    text: '🧾 Saya telah membuat Nota/Invoice sebesar Rp ${amount.toStringAsFixed(0)}. Silakan periksa dan klik "Setujui Invoice" di bagian atas obrolan.',
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Kirim Invoice', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final oppositeName = widget.currentUserRole == 'user'
        ? (_currentTicket.selectedTukangName ?? 'Mitra Tukang')
        : _currentTicket.userName;

    final isTukang = widget.currentUserRole == 'tukang';

    return BlocListener<TicketBloc, TicketState>(
      listener: (context, state) {
        if (state is TukangLockedSuccessState) {
          setState(() {});
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(oppositeName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('Tiket #${_currentTicket.id} • ${_currentTicket.category.toUpperCase()}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textDark,
          elevation: 1,
          actions: [
            if (isTukang)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: TextButton.icon(
                  onPressed: _showCreateInvoiceDialog,
                  icon: const Icon(Icons.receipt_long_rounded, size: 16, color: AppColors.primary),
                  label: const Text('Buat Invoice', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            // Interactive In-Chat Invoice Banner Card
            if (_currentTicket.finalBill != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.receipt_rounded, color: AppColors.primary, size: 20),
                            SizedBox(width: 6),
                            Text('Invoice Nota Jasa Kesepakatan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _currentTicket.finalBill!.approvedByUser ? AppColors.successGreen : AppColors.safetyAmber,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _currentTicket.finalBill!.approvedByUser ? 'DISETUJUI' : 'MENUNGGU ACC',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),

                    // Items list
                    ..._currentTicket.finalBill!.items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(item.title, style: const TextStyle(fontSize: 13)),
                              Text('Rp ${item.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        )),
                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Tagihan Kesepakatan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(
                          'Rp ${_currentTicket.finalBill!.totalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // User Action Button: Setujui Invoice
                    if (!isTukang && !_currentTicket.finalBill!.approvedByUser)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            context.read<TicketBloc>().add(ApproveFinalBillRequestedEvent(_currentTicket.id));
                            context.read<TicketBloc>().add(
                              UpdateTicketStatusRequestedEvent(
                                ticketId: _currentTicket.id,
                                newStatus: TicketStatus.onTheWay,
                              ),
                            );

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Invoice disetujui! Pekerjaan resmi dimulai.'),
                                backgroundColor: AppColors.successGreen,
                              ),
                            );
                          },
                          icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                          label: const Text('Setujui Invoice & Mulai Pekerjaan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.successGreen,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),

                    if (_currentTicket.finalBill!.approvedByUser)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.successGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: AppColors.successGreen, size: 16),
                            SizedBox(width: 6),
                            Text('Persetujuan Selesai • Pekerjaan Berlangsung', style: TextStyle(color: AppColors.successGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

            // Chat Stream Messages List
            Expanded(
              child: BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  if (state is ChatLoadingState) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  }

                  if (state is ChatLoadedState) {
                    final messages = state.messages;
                    if (messages.isEmpty) {
                      return const Center(
                        child: Text('Belum ada obrolan. Diskusi rincian & nominal harga di sini.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg.senderRole == widget.currentUserRole;

                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isMe ? AppColors.primary : AppColors.textDark,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                                bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                if (msg.imageUrl != null) ...[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: msg.imageUrl!.startsWith('http')
                                        ? Image.network(msg.imageUrl!, height: 160, width: double.infinity, fit: BoxFit.cover)
                                        : Image.file(File(msg.imageUrl!), height: 160, width: double.infinity, fit: BoxFit.cover),
                                  ),
                                  const SizedBox(height: 6),
                                ],
                                if (msg.text != null && msg.text!.isNotEmpty)
                                  Text(
                                    msg.text!,
                                    style: const TextStyle(color: Colors.white, fontSize: 14),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 10),
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

            // Selected Image Preview Bar
            if (_selectedImage != null)
              Container(
                color: Colors.grey.shade200,
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(_selectedImage!.path), height: 50, width: 50, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Foto siap terlampir', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.dangerRed),
                      onPressed: () => setState(() => _selectedImage = null),
                    ),
                  ],
                ),
              ),

            // Bottom Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.photo_camera, color: AppColors.primary),
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                  IconButton(
                    icon: const Icon(Icons.photo_library, color: AppColors.primary),
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Ketik pesan obrolan...',
                        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _sendMessage,
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
