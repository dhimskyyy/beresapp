import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/ticket_model.dart';
import '../../../data/models/tukang_model.dart';
import '../../../domain/entities/ticket_status.dart';
import '../../ticket/bloc/ticket_bloc.dart';
import '../../ticket/bloc/ticket_event.dart';
import '../../ticket/bloc/ticket_state.dart';

class MitraActiveJobPage extends StatefulWidget {
  final TicketModel ticket;
  final TukangModel tukang;

  const MitraActiveJobPage({super.key, required this.ticket, required this.tukang});

  @override
  State<MitraActiveJobPage> createState() => _MitraActiveJobPageState();
}

class _MitraActiveJobPageState extends State<MitraActiveJobPage> {
  final ImagePicker _picker = ImagePicker();
  final _itemTitleController = TextEditingController();
  final _itemAmountController = TextEditingController();
  final List<BillItem> _billItems = [];

  @override
  void dispose() {
    _itemTitleController.dispose();
    _itemAmountController.dispose();
    super.dispose();
  }

  void _showAddBillItemDialog() {
    showDialog(
      context: context,
      builder: (diagCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Input Rincian Tagihan Final'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _itemTitleController,
              decoration: const InputDecoration(labelText: 'Nama Tindakan / Sparepart', hintText: 'Contoh: Cuci AC / Ganti Freon'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _itemAmountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Biaya (Rp)', hintText: 'Contoh: 75000'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(diagCtx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(_itemAmountController.text.trim()) ?? 0;
              if (_itemTitleController.text.isEmpty || amount <= 0) return;
              setState(() {
                _billItems.add(BillItem(title: _itemTitleController.text.trim(), amount: amount));
              });
              _itemTitleController.clear();
              _itemAmountController.clear();
              Navigator.pop(diagCtx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.textDark),
            child: const Text('Tambah Item', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _takeWorkPhoto(bool isBefore) async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
      if (picked != null) {
        if (!mounted) return;
        context.read<TicketBloc>().add(
          UploadWorkPhotosRequestedEvent(
            ticketId: widget.ticket.id,
            isBefore: isBefore,
            photoPaths: [picked.path],
          ),
        );
        if (!isBefore) {
          context.read<TicketBloc>().add(
            UpdateTicketStatusRequestedEvent(
              ticketId: widget.ticket.id,
              newStatus: TicketStatus.workCompleted,
            ),
          );
        } else {
          context.read<TicketBloc>().add(
            UpdateTicketStatusRequestedEvent(
              ticketId: widget.ticket.id,
              newStatus: TicketStatus.inProgress,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengambil foto: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Pengerjaan #${widget.ticket.id}'),
        backgroundColor: AppColors.textDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocConsumer<TicketBloc, TicketState>(
        listener: (context, state) {
          if (state is TukangLockedSuccessState) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tahapan pengerjaan berhasil diperbarui!'), backgroundColor: AppColors.successGreen),
            );
          }
        },
        builder: (context, state) {
          final t = widget.ticket;
          final status = t.status;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Ticket Detail Header Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Chip(label: Text(t.category.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.white)), backgroundColor: AppColors.textDark),
                          Text(status.label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ],
                      ),
                      Text(t.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('Pelanggan: ${t.userName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('📍 ${t.address}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Step-by-step Workflow Single Clear Action Button
                const Text('Langkah Alur Kerja Pengerjaan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 12),

                // STEP 1: Mulai Berangkat
                if (status == TicketStatus.locked) ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<TicketBloc>().add(
                        UpdateTicketStatusRequestedEvent(
                          ticketId: t.id,
                          newStatus: TicketStatus.onTheWay,
                        ),
                      );
                    },
                    icon: const Icon(Icons.two_wheeler, color: Colors.white),
                    label: const Text('Mulai Berangkat (Menuju Lokasi)', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('⚠️ Mengaktifkan transmisi lokasi GPS ke peta aplikasi pelanggan.', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],

                // STEP 2: Tiba di Lokasi
                if (status == TicketStatus.onTheWay) ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<TicketBloc>().add(
                        UpdateTicketStatusRequestedEvent(
                          ticketId: t.id,
                          newStatus: TicketStatus.arrived,
                        ),
                      );
                    },
                    icon: const Icon(Icons.pin_drop, color: Colors.white),
                    label: const Text('Saya Sudah Tiba di Lokasi User', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.safetyAmber,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],

                // STEP 3: Diagnosa & Input Tagihan Final
                if (status == TicketStatus.arrived) ...[
                  const Text('1. Diagnosa & Input Tagihan Final:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _showAddBillItemDialog,
                    icon: const Icon(Icons.add_task),
                    label: const Text('Tambah Item Tagihan (Jasa / Sparepart)'),
                  ),
                  const SizedBox(height: 8),
                  if (_billItems.isNotEmpty) ...[
                    ..._billItems.map((item) => Card(
                          child: ListTile(
                            dense: true,
                            title: Text(item.title),
                            trailing: Text('Rp ${item.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        )),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        context.read<TicketBloc>().add(
                          SubmitFinalBillRequestedEvent(
                            ticketId: t.id,
                            items: _billItems,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.textDark),
                      child: const Text('Kirim Tagihan ke User', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // STEP 4: Foto Sebelum Pengerjaan
                  const Text('2. Foto Sebelum Pengerjaan (Before):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _takeWorkPhoto(true),
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    label: const Text('Foto Sebelum & Mulai Kerja', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],

                // STEP 5: Foto Setelah Pengerjaan
                if (status == TicketStatus.inProgress) ...[
                  const Text('3. Foto Setelah Pengerjaan (After):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _takeWorkPhoto(false),
                    icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                    label: const Text('Foto Setelah Kerja & Selesaikan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.successGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],

                if (status == TicketStatus.workCompleted) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.successGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('✓ Pekerjaan Fisik Telah Tuntas. Menunggu Pembayaran User.', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.successGreen)),
                  )
                ]
              ],
            ),
          );
        },
      ),
    );
  }
}
