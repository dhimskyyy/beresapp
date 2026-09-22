import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/chat_message_model.dart';
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
  final _currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  XFile? _selectedImage;
  late TicketModel _currentTicket;
  bool _showQuickActions = true;

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

  void _sendMessage({String? customText}) {
    final text = customText ?? _messageController.text.trim();
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

    if (customText == null) {
      _messageController.clear();
      setState(() => _selectedImage = null);
    }
  }

  /// Safe Image Builder
  Widget _buildSafeImage(String path, {double? width, double height = 180, double radius = 12}) {
    Widget img;
    if (path.startsWith('http')) {
      img = Image.network(
        path,
        width: width ?? double.infinity,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _imageFallback(width, height),
      );
    } else if (path.startsWith('/')) {
      final file = File(path);
      if (file.existsSync()) {
        img = Image.file(
          file,
          width: width ?? double.infinity,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _imageFallback(width, height),
        );
      } else {
        img = _imageFallback(width, height);
      }
    } else {
      img = Image.asset(
        path,
        width: width ?? double.infinity,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _imageFallback(width, height),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: img,
    );
  }

  Widget _imageFallback(double? w, double h) {
    return Container(
      width: w ?? double.infinity,
      height: h,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image_rounded, color: AppColors.textMuted, size: 28),
    );
  }

  /// Fullscreen Image Viewer Modal
  void _showImageViewer(String path) {
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
              child: _buildSafeImage(path, width: double.infinity, height: 420, radius: 12),
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

  /// Dialog untuk Tukang membuat dan mengirim Invoice / Nota resmi
  void _showCreateInvoiceDialog() {
    final List<BillItem> items = _currentTicket.finalBill != null
        ? List.from(_currentTicket.finalBill!.items)
        : [
            BillItem(title: 'Jasa Pengerjaan ${_currentTicket.category.toUpperCase()}', amount: 100000),
          ];

    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (diagCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final double total = items.fold(0, (sum, i) => sum + i.amount);

            return Container(
              height: MediaQuery.of(context).size.height * 0.82,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                top: 12,
                left: 20,
                right: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Invoice / Nota Kesepakatan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
                              Text('Kirim rincian biaya resmi ke room chat', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ),
                        ],
                      ),
                      IconButton(onPressed: () => Navigator.pop(diagCtx), icon: const Icon(Icons.close_rounded)),
                    ],
                  ),
                  const Divider(height: 16),

                  // Quick Suggestion Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildInvoiceQuickChip('+ Cuci Standar (75rb)', 'Cuci Unit Standar', 75000, items, setDialogState),
                        const SizedBox(width: 6),
                        _buildInvoiceQuickChip('+ Tambah Freon (150rb)', 'Tambah Freon R32', 150000, items, setDialogState),
                        const SizedBox(width: 6),
                        _buildInvoiceQuickChip('+ Ganti Pipa (85rb)', 'Ganti Pipa & Selang', 85000, items, setDialogState),
                        const SizedBox(width: 6),
                        _buildInvoiceQuickChip('+ Jasa Bongkar (50rb)', 'Biaya Bongkar Pasang', 50000, items, setDialogState),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Input Item Baru
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: titleCtrl,
                          decoration: InputDecoration(
                            hintText: 'Nama item / jasa...',
                            hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: amountCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            prefixText: 'Rp ',
                            hintText: '50000',
                            hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.textDark,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.add, color: Colors.white, size: 20),
                        onPressed: () {
                          final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
                          if (titleCtrl.text.trim().isEmpty || amount <= 0) return;
                          setDialogState(() {
                            items.add(BillItem(title: titleCtrl.text.trim(), amount: amount));
                            titleCtrl.clear();
                            amountCtrl.clear();
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Daftar Item
                  Expanded(
                    child: items.isEmpty
                        ? const Center(child: Text('Belum ada item tagihan.', style: TextStyle(color: AppColors.textMuted)))
                        : ListView.separated(
                            itemCount: items.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 6),
                            itemBuilder: (context, idx) {
                              final item = items[idx];
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 9,
                                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                      child: Text('${idx + 1}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(item.title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
                                    Text(_currencyFormat.format(item.amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () {
                                        setDialogState(() => items.removeAt(idx));
                                      },
                                      child: const Icon(Icons.remove_circle_outline, color: AppColors.dangerRed, size: 18),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  const Divider(height: 16),

                  // Total Row & Tombol Kirim
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Nota Kesepakatan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(
                        _currencyFormat.format(total),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: items.isEmpty
                          ? null
                          : () {
                              Navigator.pop(diagCtx);

                              context.read<TicketBloc>().add(
                                SubmitFinalBillRequestedEvent(
                                  ticketId: _currentTicket.id,
                                  items: items,
                                ),
                              );

                              // Send chat announcement
                              _sendMessage(
                                customText: '🧾 Saya telah membuat Nota Tagihan baru sebesar ${_currencyFormat.format(total)}. Silakan periksa rincian pada kartu nota di atas obrolan.',
                              );
                            },
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                      label: const Text('Kirim Nota Resmi ke Chat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.textDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInvoiceQuickChip(String label, String title, double amount, List<BillItem> items, StateSetter setDialogState) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textDark)),
      backgroundColor: AppColors.background,
      side: const BorderSide(color: AppColors.border),
      padding: EdgeInsets.zero,
      onPressed: () {
        setDialogState(() {
          items.add(BillItem(title: title, amount: amount));
        });
      },
    );
  }

  /// Modal Kontak & Telepon Darurat
  void _showContactModal(BuildContext context, String name, String phone) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primary,
                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'C', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
                      Text(phone, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: AppColors.successGreen,
                child: Icon(Icons.chat_rounded, color: Colors.white, size: 20),
              ),
              title: const Text('Chat WhatsApp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Buka WhatsApp untuk respon cepat', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Membuka WhatsApp...')),
                );
              },
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: AppColors.textDark,
                child: Icon(Icons.call_rounded, color: Colors.white, size: 20),
              ),
              title: const Text('Panggil Nomor Telepon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(phone, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.pop(ctx);
                Clipboard.setData(ClipboardData(text: phone));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nomor telepon disalin ke clipboard!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Dialog Nego / Minta Revisi Nota
  void _showNegotiateDialog() {
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (diagCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.edit_note_rounded, color: AppColors.safetyAmber),
            SizedBox(width: 8),
            Text('Nego / Minta Revisi Nota', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tuliskan penawaran atau alasan Anda jika merasa nominal nota belum sesuai:',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.3),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Contoh: Mas, bisakah harganya jadi 80rb untuk cuci AC saja tanpa tambah freon?',
                hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(diagCtx), child: const Text('Batal', style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            onPressed: () {
              final text = noteCtrl.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(diagCtx);
              _sendMessage(customText: '💬 [Pengajuan Nego]: $text');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.textDark),
            child: const Text('Kirim ke Chat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTukang = widget.currentUserRole == 'tukang';
    final oppositeName = isTukang ? _currentTicket.userName : (_currentTicket.selectedTukangName ?? 'Mitra Tukang');
    final oppositePhone = isTukang ? '0812-3456-7890' : '0813-9988-7766';

    return BlocListener<TicketBloc, TicketState>(
      listener: (context, state) {
        if (state is TukangLockedSuccessState && state.ticket.id == _currentTicket.id) {
          setState(() {
            _currentTicket = state.ticket;
          });
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          titleSpacing: 0,
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: isTukang ? AppColors.primary : AppColors.safetyAmber,
                child: Text(
                  oppositeName.isNotEmpty ? oppositeName[0].toUpperCase() : 'P',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      oppositeName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: AppColors.successGreen, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_currentTicket.category.toUpperCase()} • ${_currentTicket.status.label}',
                          style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textDark,
          elevation: 1,
          actions: [
            IconButton(
              icon: const Icon(Icons.call_outlined, color: AppColors.textDark, size: 22),
              tooltip: 'Panggil Kontak',
              onPressed: () => _showContactModal(context, oppositeName, oppositePhone),
            ),
            if (isTukang)
              IconButton(
                icon: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 22),
                tooltip: 'Buat / Edit Nota Tagihan',
                onPressed: _showCreateInvoiceDialog,
              ),
          ],
        ),
        body: Column(
          children: [
            // 1. Interactive In-Chat Invoice Banner Card
            if (_currentTicket.finalBill != null) _buildInteractiveInvoiceBanner(isTukang),

            // 2. Chat Stream Messages List
            Expanded(
              child: BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  if (state is ChatLoadingState) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  }

                  if (state is ChatLoadedState) {
                    final messages = state.messages;
                    if (messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
                              child: const Icon(Icons.chat_bubble_outline_rounded, size: 36, color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 12),
                            const Text('Mulai Obrolan Pekerjaan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark)),
                            const SizedBox(height: 4),
                            const Text('Bicarakan rincian kendala, estimasi waktu, dan kesepakatan nota.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg.senderRole == widget.currentUserRole;

                        return _buildModernChatBubble(msg, isMe);
                      },
                    );
                  }

                  return const SizedBox();
                },
              ),
            ),

            // 3. Selected Image Preview Bar
            if (_selectedImage != null)
              Container(
                color: Colors.grey.shade100,
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(_selectedImage!.path), height: 48, width: 48, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Foto siap dilampirkan ke obrolan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.dangerRed),
                      onPressed: () => setState(() => _selectedImage = null),
                    ),
                  ],
                ),
              ),

            // 4. Quick Action Bar (Di atas Text Field)
            if (_showQuickActions)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildQuickActionChip(
                        icon: Icons.camera_alt_rounded,
                        label: 'Kamera',
                        onTap: () => _pickImage(ImageSource.camera),
                      ),
                      const SizedBox(width: 6),
                      _buildQuickActionChip(
                        icon: Icons.photo_library_rounded,
                        label: 'Galeri',
                        onTap: () => _pickImage(ImageSource.gallery),
                      ),
                      const SizedBox(width: 6),
                      _buildQuickActionChip(
                        icon: Icons.place_rounded,
                        label: 'Kirim Alamat',
                        onTap: () {
                          _sendMessage(customText: '📍 Alamat Lokasi Pekerjaan: ${_currentTicket.address}');
                        },
                      ),
                      if (isTukang) ...[
                        const SizedBox(width: 6),
                        _buildQuickActionChip(
                          icon: Icons.receipt_long_rounded,
                          label: 'Buat Invoice',
                          color: AppColors.primary,
                          onTap: _showCreateInvoiceDialog,
                        ),
                      ],
                      const SizedBox(width: 6),
                      _buildQuickActionChip(
                        icon: Icons.support_agent_rounded,
                        label: 'Bantuan CS',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Menghubungkan ke Admin CS Beres App 24/7...')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

            // 5. Modern Bottom Input Bar
            Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.6))),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _showQuickActions ? Icons.keyboard_arrow_down_rounded : Icons.add_circle_outline_rounded,
                        color: AppColors.textDark,
                      ),
                      tooltip: 'Menu Tambahan',
                      onPressed: () => setState(() => _showQuickActions = !_showQuickActions),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        maxLines: 4,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Ketik pesan obrolan...',
                          hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: const BoxDecoration(color: AppColors.textDark, shape: BoxShape.circle),
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                        onPressed: () => _sendMessage(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionChip({required IconData icon, required String label, required VoidCallback onTap, Color? color}) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: (color ?? AppColors.textDark).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: (color ?? AppColors.textDark).withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color ?? AppColors.textDark),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color ?? AppColors.textDark),
            ),
          ],
        ),
      ),
    );
  }

  /// 1. Interactive In-Chat Invoice Banner Card
  Widget _buildInteractiveInvoiceBanner(bool isTukang) {
    final bill = _currentTicket.finalBill!;
    final isApproved = bill.approvedByUser;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isApproved ? AppColors.successGreen.withValues(alpha: 0.5) : AppColors.primary.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isApproved ? AppColors.successGreen.withValues(alpha: 0.12) : AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.receipt_long_rounded, color: isApproved ? AppColors.successGreen : AppColors.primary, size: 18),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Nota Kesepakatan',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.textDark),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isApproved ? AppColors.successGreen.withValues(alpha: 0.12) : AppColors.safetyAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isApproved ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
                        size: 12, color: isApproved ? AppColors.successGreen : AppColors.safetyAmber),
                    const SizedBox(width: 4),
                    Text(
                      isApproved ? 'DISETUJUI' : 'MENUNGGU ACC',
                      style: TextStyle(
                        color: isApproved ? AppColors.successGreen : const Color(0xFFB45309),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 18),

          // Items List
          ...bill.items.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.5),
              child: Row(
                children: [
                  Text('${idx + 1}. ', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  Expanded(child: Text(item.title, style: const TextStyle(fontSize: 12.5, color: AppColors.textDark))),
                  Text(_currencyFormat.format(item.amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppColors.textDark)),
                ],
              ),
            );
          }),

          const Divider(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text('Total Kesepakatan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
              ),
              Text(
                _currencyFormat.format(bill.totalAmount),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.primary),
              ),
            ],
          ),

          // User Action Buttons (Approve / Nego)
          if (!isTukang && !isApproved) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    onPressed: _showNegotiateDialog,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Nego / Revisi', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.read<TicketBloc>().add(ApproveFinalBillRequestedEvent(_currentTicket.id));
                      context.read<TicketBloc>().add(
                        UpdateTicketStatusRequestedEvent(
                          ticketId: _currentTicket.id,
                          newStatus: TicketStatus.onTheWay,
                        ),
                      );

                      _sendMessage(
                        customText: '✅ Saya telah menyetujui Nota/Invoice sebesar ${_currencyFormat.format(bill.totalAmount)}. Pekerjaan resmi dimulai!',
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✓ Invoice disetujui! Pekerjaan resmi dimulai.'),
                          backgroundColor: AppColors.successGreen,
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                    label: const Text('Setujui & Mulai', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.successGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Tukang Action (Edit Nota if not yet approved)
          if (isTukang && !isApproved) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text('Menunggu persetujuan konsumen di room chat.', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ),
                TextButton(
                  onPressed: _showCreateInvoiceDialog,
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                  child: const Text('Edit Nota', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                ),
              ],
            ),
          ],

          // Approved Banner Note
          if (isApproved) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.successGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user_rounded, color: AppColors.successGreen, size: 14),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Persetujuan nota tuntas • Pengerjaan dilindungi Beres Guarantee',
                      style: TextStyle(color: AppColors.successGreen, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 2. Modern Chat Bubble
  Widget _buildModernChatBubble(ChatMessageModel msg, bool isMe) {
    final timeStr = '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}';
    final isSystemCallout = (msg.text ?? '').startsWith('🧾') || (msg.text ?? '').startsWith('✅');

    if (isSystemCallout) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          child: Text(
            msg.text ?? '',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark, height: 1.3),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.76),
        decoration: BoxDecoration(
          color: isMe ? AppColors.textDark : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
          ),
          border: isMe ? null : Border.all(color: AppColors.border.withValues(alpha: 0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Image Attachment (if exists)
            if (msg.imageUrl != null) ...[
              GestureDetector(
                onTap: () => _showImageViewer(msg.imageUrl!),
                child: _buildSafeImage(msg.imageUrl!, height: 160, radius: 12),
              ),
              const SizedBox(height: 6),
            ],

            // Text Message
            if (msg.text != null && msg.text!.isNotEmpty)
              Text(
                msg.text!,
                style: TextStyle(
                  color: isMe ? Colors.white : AppColors.textDark,
                  fontSize: 13.5,
                  height: 1.35,
                ),
              ),

            const SizedBox(height: 4),

            // Time & Double Check Status
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    color: isMe ? Colors.white70 : AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    msg.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                    size: 14,
                    color: msg.isRead ? AppColors.safetyAmber : Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
