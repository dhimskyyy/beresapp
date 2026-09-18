import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/ticket_model.dart';
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

  @override
  void initState() {
    super.initState();
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
        ticketId: widget.ticket.id,
        senderId: widget.currentUserId,
        senderRole: widget.currentUserRole,
        text: text.isNotEmpty ? text : null,
        imagePath: _selectedImage?.path,
      ),
    );

    _messageController.clear();
    setState(() => _selectedImage = null);
  }

  @override
  Widget build(BuildContext context) {
    final oppositeName = widget.currentUserRole == 'user'
        ? (widget.ticket.selectedTukangName ?? 'Mitra Tukang')
        : widget.ticket.userName;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(oppositeName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Tiket #${widget.ticket.id} • ${widget.ticket.category.toUpperCase()}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 1,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.successGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.successGreen),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, size: 14, color: AppColors.successGreen),
                SizedBox(width: 4),
                Text('Privasi Terjaga', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.successGreen)),
              ],
            ),
          )
        ],
      ),
      body: Column(
        children: [
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
                      child: Text('Belum ada obrolan. Mulai tanyakan kejelasan lokasi atau keluhan.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
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
    );
  }
}
