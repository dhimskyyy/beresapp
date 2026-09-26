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
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/service_categories.dart';
import '../../../data/models/ticket_model.dart';
import '../../../data/models/tukang_model.dart';
import '../../../domain/entities/ticket_status.dart';
import '../../chat/pages/chat_page.dart';
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
  
  late TicketModel _currentTicket;
  List<BillItem> _billItems = [];

  final _currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _ticketSub;

  @override
  void initState() {
    super.initState();
    _currentTicket = widget.ticket;
    if (_currentTicket.finalBill != null) {
      _billItems = List.from(_currentTicket.finalBill!.items);
    }
    _ticketSub = FirebaseFirestore.instance
        .collection('tickets')
        .doc(widget.ticket.id)
        .snapshots()
        .listen((snap) {
      if (snap.exists && snap.data() != null && mounted) {
        setState(() {
          _currentTicket = TicketModel.fromMap(snap.data()!, snap.id);
          if (_currentTicket.finalBill != null) {
            _billItems = List.from(_currentTicket.finalBill!.items);
          }
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant MitraActiveJobPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ticket.id != widget.ticket.id ||
        oldWidget.ticket.status != widget.ticket.status ||
        oldWidget.ticket.updatedAt != widget.ticket.updatedAt ||
        oldWidget.ticket.finalBill != widget.ticket.finalBill) {
      setState(() {
        _currentTicket = widget.ticket;
        if (_currentTicket.finalBill != null) {
          _billItems = List.from(_currentTicket.finalBill!.items);
        } else {
          _billItems = [];
        }
      });
    }
  }

  @override
  void dispose() {
    _ticketSub?.cancel();
    super.dispose();
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

  /// Safe Image Widget
  Widget _buildSafeImage(String path, {double width = 72, double height = 72, double radius = 10}) {
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
      child: const Icon(Icons.image_outlined, size: 24, color: AppColors.textMuted),
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

  /// Choice modal: Camera or Gallery
  void _showImageSourceDialog(bool isBefore) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (bctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isBefore ? 'Unggah Foto Sebelum Kerja (Before)' : 'Unggah Foto Hasil Kerja (After)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
            ),
            const SizedBox(height: 6),
            Text(
              isBefore
                  ? 'Foto kondisi awal unit/kendala sebelum dibongkar atau diperbaiki.'
                  : 'Foto bukti fisik unit setelah perbaikan selesai dan berfungsi normal.',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(bctx);
                      _pickAndUploadWorkPhoto(isBefore, ImageSource.camera);
                    },
                    icon: const Icon(Icons.camera_alt_rounded, color: Colors.white),
                    label: const Text('Kamera', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(bctx);
                      _pickAndUploadWorkPhoto(isBefore, ImageSource.gallery);
                    },
                    icon: const Icon(Icons.photo_library_rounded, color: AppColors.textDark),
                    label: const Text('Galeri', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.textDark),
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
  }

  Future<void> _pickAndUploadWorkPhoto(bool isBefore, ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        if (!mounted) return;
        context.read<TicketBloc>().add(
          UploadWorkPhotosRequestedEvent(
            ticketId: _currentTicket.id,
            isBefore: isBefore,
            photoPaths: [picked.path],
          ),
        );

        if (!isBefore) {
          context.read<TicketBloc>().add(
            UpdateTicketStatusRequestedEvent(
              ticketId: _currentTicket.id,
              newStatus: TicketStatus.workCompleted,
            ),
          );
        } else if (_currentTicket.status == TicketStatus.arrived) {
          final bill = _currentTicket.finalBill;
          if (bill == null || !bill.approvedByUser) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Nota jasa wajib dibuat dan disetujui konsumen di room chat sebelum memulai pengerjaan!'),
                backgroundColor: AppColors.dangerRed,
              ),
            );
            return;
          }
          context.read<TicketBloc>().add(
            UpdateTicketStatusRequestedEvent(
              ticketId: _currentTicket.id,
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

  /// Interactive GPS Navigation Modal Bottom Sheet
  void _showGpsNavigationModal(BuildContext context, double tukangLat, double tukangLng) {
    final distKm = _calculateDistanceInKm(tukangLat, tukangLng, _currentTicket.lat, _currentTicket.lng);
    final etaMin = (distKm * 3).clamp(3, 90).round();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
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
                          child: const Icon(Icons.navigation_rounded, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Navigasi Rute Mitra', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
                            Text('Panduan arah GPS ke rumah konsumen', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          ],
                        ),
                      ],
                    ),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded)),
                  ],
                ),
              ),

              // Interactive OpenStreetMap with 2 Markers
              Expanded(
                child: Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng((tukangLat + _currentTicket.lat) / 2, (tukangLng + _currentTicket.lng) / 2),
                        initialZoom: 13.5,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.beres.beresapp',
                        ),
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: [
                                LatLng(tukangLat, tukangLng),
                                LatLng(_currentTicket.lat, _currentTicket.lng),
                              ],
                              color: AppColors.primary,
                              strokeWidth: 4.0,
                            ),
                          ],
                        ),
                        MarkerLayer(
                          markers: [
                            // Mitra Pin (Motorcycle)
                            Marker(
                              point: LatLng(tukangLat, tukangLng),
                              width: 45,
                              height: 45,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.textDark,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                                ),
                                child: const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 22),
                              ),
                            ),
                            // Konsumen Pin (House)
                            Marker(
                              point: LatLng(_currentTicket.lat, _currentTicket.lng),
                              width: 45,
                              height: 45,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.dangerRed,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                                ),
                                child: const Icon(Icons.home_rounded, color: Colors.white, size: 22),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Floating Distance Banner on Map
                    Positioned(
                      top: 12,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.directions_bike_rounded, color: AppColors.primary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Jarak: ${distKm.toStringAsFixed(1)} km',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.timer_rounded, color: AppColors.successGreen, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  '~$etaMin mnt',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.successGreen),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Destination Details
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            _currentTicket.userName.isNotEmpty ? _currentTicket.userName[0].toUpperCase() : 'U',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('Tujuan: ${_currentTicket.userName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.successGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Lokasi Akurat GPS', style: TextStyle(color: AppColors.successGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.place_rounded, color: AppColors.dangerRed, size: 18),
                        const SizedBox(width: 6),
                        Expanded(child: Text(_currentTicket.address, style: const TextStyle(fontSize: 12, color: AppColors.textDark))),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _currentTicket.address));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Alamat berhasil disalin ke clipboard!'), duration: Duration(seconds: 1)),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.textDark),
                            label: const Text('Salin Alamat', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.border),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                            label: const Text('Tutup Peta', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.textDark,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
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

  /// Emergency CS 24/7 Bottom Sheet
  void _showEmergencySupportBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (bctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.dangerRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.support_agent_rounded, color: AppColors.dangerRed, size: 24),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bantuan Darurat Mitra 24/7', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
                    Text('Pusat Bantuan & Kendala Saat Pengerjaan', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Jika terjadi kendala seperti konsumen tidak di rumah, alamat tidak ditemukan, atau butuh bantuan admin darurat:',
              style: TextStyle(fontSize: 12, color: AppColors.textDark, height: 1.4),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: AppColors.successGreen,
                child: Icon(Icons.chat_rounded, color: Colors.white, size: 20),
              ),
              title: const Text('WhatsApp Hotline CS Mitra', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: const Text('0812-3456-7890 (Respon Cepat)', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.pop(bctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Menghubungkan ke WhatsApp CS Beres...')),
                );
              },
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Icon(Icons.phone_rounded, color: Colors.white, size: 20),
              ),
              title: const Text('Call Center Beres App 24 Jam', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: const Text('1500-BERES (Bebas Pulsa)', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.pop(bctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Memanggil Call Center 1500-BERES...')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tukangLat = widget.tukang.currentLocation?.lat ?? -6.2088;
    final tukangLng = widget.tukang.currentLocation?.lng ?? 106.8456;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Pengerjaan #${_currentTicket.id.length > 8 ? _currentTicket.id.substring(0, 8) : _currentTicket.id}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: AppColors.textDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.support_agent_rounded, color: AppColors.safetyAmber),
            tooltip: 'Bantuan Darurat 24/7',
            onPressed: _showEmergencySupportBottomSheet,
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white),
            tooltip: 'Chat Konsumen',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatPage(
                    ticket: _currentTicket,
                    currentUserId: widget.tukang.id,
                    currentUserRole: 'tukang',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<TicketBloc, TicketState>(
        listener: (context, state) {
          if (state is TukangLockedSuccessState && state.ticket.id == _currentTicket.id) {
            setState(() {
              _currentTicket = state.ticket;
              if (_currentTicket.finalBill != null) {
                _billItems = List.from(_currentTicket.finalBill!.items);
              }
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tahapan pengerjaan berhasil diperbarui!'), backgroundColor: AppColors.successGreen),
            );
          } else if (state is TicketOperationFailureState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.dangerRed),
            );
          }
        },
        builder: (context, state) {
          final t = _currentTicket;
          final status = t.status;
          final double totalBill = _billItems.fold(0, (prev, i) => prev + i.amount);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. SOP 5-Step Stepper Card
                _buildSopStepperCard(status),

                const SizedBox(height: 14),

                // 2. Info Detail Pekerjaan & Konsumen
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                                Icon(ServiceCategories.getIconForCategory(t.category), size: 14, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(t.category.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primary)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status.label,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(t.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      const SizedBox(height: 4),
                      Text(t.description, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.3)),
                      const Divider(height: 20),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.primary,
                            child: Text(
                              t.userName.isNotEmpty ? t.userName[0].toUpperCase() : 'U',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                                const Text('Konsumen Pemesan', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatPage(
                                    ticket: t,
                                    currentUserId: widget.tukang.id,
                                    currentUserRole: 'tukang',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppColors.textDark),
                            label: const Text('Chat', style: TextStyle(fontSize: 12, color: AppColors.textDark, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.place_rounded, color: AppColors.dangerRed, size: 16),
                          const SizedBox(width: 6),
                          Expanded(child: Text(t.address, style: const TextStyle(fontSize: 11.5, color: AppColors.textDark))),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // 3. Tombol Navigasi Peta GPS ke Rumah Konsumen
                _buildGpsNavigationCard(tukangLat, tukangLng),

                const SizedBox(height: 14),

                // 4. Foto Bukti Kerja SOP (Before & After)
                _buildWorkPhotosSection(status),

                const SizedBox(height: 14),

                // 5. Rincian Nota Material & Jasa
                _buildFinalBillSection(totalBill),

                const SizedBox(height: 20),

                // 6. Tombol Aksi Utama Alur SOP
                _buildDynamicWorkflowButton(status, t),

                // 7. Info Perayaan jika pekerjaan selesai
                if (status == TicketStatus.workCompleted || status == TicketStatus.completed) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.successGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 24),
                            SizedBox(width: 8),
                            Text('Pekerjaan Fisik Selesai! 🎉', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.successGreen)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total nota tagihan: ${_currencyFormat.format(totalBill)}. Pembayaran dilakukan secara tunai (Pure Cash) langsung oleh konsumen di lokasi pengerjaan.',
                          style: const TextStyle(fontSize: 12, color: AppColors.textDark, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  /// 1. SOP 5-Step Stepper Card
  Widget _buildSopStepperCard(TicketStatus status) {
    final step = _getStepNumber(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Alur SOP Pengerjaan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
              Text('Tahap $step dari 5', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStepBubble(stepNum: 1, label: 'Terkunci', isActive: step >= 1, isCompleted: step > 1),
              _buildStepLineConnector(isActive: step >= 2),
              _buildStepBubble(stepNum: 2, label: 'Di Jalan', isActive: step >= 2, isCompleted: step > 2),
              _buildStepLineConnector(isActive: step >= 3),
              _buildStepBubble(stepNum: 3, label: 'Tiba', isActive: step >= 3, isCompleted: step > 3),
              _buildStepLineConnector(isActive: step >= 4),
              _buildStepBubble(stepNum: 4, label: 'Kerja', isActive: step >= 4, isCompleted: step > 4),
              _buildStepLineConnector(isActive: step >= 5),
              _buildStepBubble(stepNum: 5, label: 'Selesai', isActive: step >= 5, isCompleted: step >= 5),
            ],
          ),
        ],
      ),
    );
  }

  int _getStepNumber(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
      case TicketStatus.bidding:
      case TicketStatus.locked:
        return 1;
      case TicketStatus.onTheWay:
        return 2;
      case TicketStatus.arrived:
        return 3;
      case TicketStatus.inProgress:
        return 4;
      case TicketStatus.workCompleted:
      case TicketStatus.paymentPending:
      case TicketStatus.completed:
        return 5;
      default:
        return 1;
    }
  }

  Widget _buildStepBubble({required int stepNum, required String label, required bool isActive, required bool isCompleted}) {
    return Column(
      children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: isActive
              ? (isCompleted ? AppColors.successGreen : AppColors.textDark)
              : Colors.grey.shade200,
          child: isCompleted
              ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
              : Text(
                  '$stepNum',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.white : AppColors.textMuted,
                  ),
                ),
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

  Widget _buildStepLineConnector({required bool isActive}) {
    return Expanded(
      child: Container(
        height: 2.5,
        margin: const EdgeInsets.only(bottom: 14),
        color: isActive ? AppColors.successGreen : Colors.grey.shade200,
      ),
    );
  }

  /// 2. Tombol Navigasi Peta GPS ke Rumah Konsumen
  Widget _buildGpsNavigationCard(double tukangLat, double tukangLng) {
    final distKm = _calculateDistanceInKm(tukangLat, tukangLng, _currentTicket.lat, _currentTicket.lng);
    final etaMin = (distKm * 3).clamp(3, 90).round();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showGpsNavigationModal(context, tukangLat, tukangLng),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.navigation_rounded, color: AppColors.primary, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Navigasi Peta GPS ke Konsumen',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text('📍 ${distKm.toStringAsFixed(1)} km', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                          const SizedBox(width: 6),
                          Text('• Estimasi ~$etaMin menit', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.textDark,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.map_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text('Buka Peta', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 3. Foto Bukti Kerja SOP (Before & After)
  Widget _buildWorkPhotosSection(TicketStatus status) {
    final beforePhotos = _currentTicket.beforePhotos;
    final afterPhotos = _currentTicket.afterPhotos;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.photo_camera_rounded, color: AppColors.textDark, size: 18),
              SizedBox(width: 8),
              Text('Bukti Foto Pengerjaan (SOP)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Wajib mengunggah bukti foto kondisi awal dan sesudah selesai perbaikan.', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const Divider(height: 20),

          // Foto Sebelum (Before)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('1. Foto Sebelum (Before)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppColors.textDark)),
                  const SizedBox(width: 6),
                  if (beforePhotos.isNotEmpty)
                    const Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 16),
                ],
              ),
              TextButton.icon(
                onPressed: () => _showImageSourceDialog(true),
                icon: const Icon(Icons.add_a_photo_rounded, size: 14),
                label: Text(beforePhotos.isEmpty ? 'Upload Foto' : '+ Tambah', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
            ],
          ),
          if (beforePhotos.isNotEmpty) ...[
            const SizedBox(height: 6),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: beforePhotos.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  return GestureDetector(
                    onTap: () => _showImageViewer(beforePhotos[idx]),
                    child: _buildSafeImage(beforePhotos[idx], width: 72, height: 72, radius: 10),
                  );
                },
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border, style: BorderStyle.solid),
              ),
              child: const Center(
                child: Text('Belum ada foto kondisi awal (Before)', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic)),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Foto Sesudah (After)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('2. Foto Sesudah (After)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppColors.textDark)),
                  const SizedBox(width: 6),
                  if (afterPhotos.isNotEmpty)
                    const Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 16),
                ],
              ),
              TextButton.icon(
                onPressed: () => _showImageSourceDialog(false),
                icon: const Icon(Icons.add_a_photo_rounded, size: 14),
                label: Text(afterPhotos.isEmpty ? 'Upload Foto' : '+ Tambah', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
            ],
          ),
          if (afterPhotos.isNotEmpty) ...[
            const SizedBox(height: 6),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: afterPhotos.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  return GestureDetector(
                    onTap: () => _showImageViewer(afterPhotos[idx]),
                    child: _buildSafeImage(afterPhotos[idx], width: 72, height: 72, radius: 10),
                  );
                },
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border, style: BorderStyle.solid),
              ),
              child: const Center(
                child: Text('Belum ada foto hasil perbaikan (After)', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 4. Rincian Nota Material & Jasa
  Widget _buildFinalBillSection(double totalBill) {
    final finalBill = _currentTicket.finalBill;
    final isApproved = finalBill?.approvedByUser ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isApproved ? AppColors.successGreen.withValues(alpha: 0.5) : AppColors.border.withValues(alpha: 0.8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.receipt_long_rounded, color: AppColors.textDark, size: 18),
                  SizedBox(width: 8),
                  Text('Rincian Nota Material & Jasa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isApproved
                      ? AppColors.successGreen.withValues(alpha: 0.12)
                      : (finalBill != null ? AppColors.safetyAmber.withValues(alpha: 0.15) : Colors.grey.shade100),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isApproved ? Icons.check_circle_rounded : (finalBill != null ? Icons.hourglass_top_rounded : Icons.pending_outlined),
                      size: 12,
                      color: isApproved ? AppColors.successGreen : (finalBill != null ? AppColors.safetyAmber : AppColors.textMuted),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      isApproved ? 'Telah Disetujui' : (finalBill != null ? 'Menunggu Persetujuan' : 'Belum Dibuat'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isApproved ? AppColors.successGreen : (finalBill != null ? const Color(0xFFB45309) : AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isApproved
                ? 'Nota telah disetujui konsumen melalui Chat room.'
                : 'Nota biaya jasa ditulis, ditetapkan, dan disetujui melalui Chat room bersama konsumen.',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),

          if (finalBill == null || finalBill.items.isEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  const Icon(Icons.chat_outlined, size: 28, color: AppColors.textMuted),
                  const SizedBox(height: 8),
                  const Text(
                    'Nota belum dibuat',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Silakan buka room Chat untuk menentukan rincian dan harga bersama konsumen.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            ticket: _currentTicket,
                            currentUserId: widget.tukang.id,
                            currentUserRole: 'tukang',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_rounded, color: Colors.white, size: 16),
                    label: const Text('Buka Chat & Buat Nota', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ...finalBill.items.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      child: Text('${idx + 1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item.title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textDark))),
                    Text(_currencyFormat.format(item.amount), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  ],
                ),
              );
            }),
            const Divider(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Kesepakatan Nota:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                Text(
                  _currencyFormat.format(finalBill.totalAmount),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatPage(
                      ticket: _currentTicket,
                      currentUserId: widget.tukang.id,
                      currentUserRole: 'tukang',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.chat_rounded, size: 16, color: AppColors.textDark),
              label: Text(
                isApproved ? 'Lihat Nota di Room Chat' : 'Buka Chat Room (Edit / Cek Persetujuan)',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                minimumSize: const Size.fromHeight(40),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 5. Tombol Aksi Utama Alur SOP Dinamis
  Widget _buildDynamicWorkflowButton(TicketStatus status, TicketModel t) {
    if (status == TicketStatus.locked) {
      return ElevatedButton.icon(
        onPressed: () {
          context.read<TicketBloc>().add(
            UpdateTicketStatusRequestedEvent(
              ticketId: t.id,
              newStatus: TicketStatus.onTheWay,
            ),
          );
        },
        icon: const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 22),
        label: const Text('🛵 Mulai Berangkat Menuju Lokasi Konsumen', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 2,
        ),
      );
    }

    if (status == TicketStatus.onTheWay) {
      return ElevatedButton.icon(
        onPressed: () {
          context.read<TicketBloc>().add(
            UpdateTicketStatusRequestedEvent(
              ticketId: t.id,
              newStatus: TicketStatus.arrived,
            ),
          );
        },
        icon: const Icon(Icons.pin_drop_rounded, color: Colors.white, size: 22),
        label: const Text('📍 Saya Sudah Tiba di Lokasi Konsumen', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.safetyAmber,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 2,
        ),
      );
    }

    if (status == TicketStatus.arrived) {
      final bill = t.finalBill;
      final isBillApproved = bill != null && bill.approvedByUser;

      if (!isBillApproved) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    bill == null ? Icons.lock_clock_rounded : Icons.hourglass_top_rounded,
                    color: const Color(0xFFD97706),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      bill == null
                          ? 'Wajib Sepakati Nota Jasa Dahulu'
                          : 'Menunggu Persetujuan Nota (${_currencyFormat.format(bill.totalAmount)})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                bill == null
                    ? 'Anda telah tiba di lokasi konsumen. Silakan buka room chat untuk menetapkan rincian nota jasa bersama konsumen sebelum memulai pengerjaan.'
                    : 'Nota jasa telah dikirim ke room chat. Konsumen harus menekan tombol "Setujui Nota" di room chat sebelum Anda dapat memulai pengerjaan.',
                style: const TextStyle(fontSize: 12, color: Color(0xFFB45309), height: 1.4),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        ticket: t,
                        currentUserId: widget.tukang.id,
                        currentUserRole: 'tukang',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.chat_rounded, color: Colors.white, size: 18),
                label: Text(
                  bill == null ? 'Buka Chat & Tetapkan Nota' : 'Buka Chat Room (Cek Persetujuan)',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),
            ],
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Nota disetujui konsumen (${_currencyFormat.format(bill.totalAmount)}). Silakan mulai pengerjaan.',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.successGreen),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _showImageSourceDialog(true),
            icon: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 22),
            label: const Text('📸 Ambil Foto Before & Mulai Pengerjaan', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
          ),
        ],
      );
    }

    if (status == TicketStatus.inProgress) {
      return ElevatedButton.icon(
        onPressed: () => _showImageSourceDialog(false),
        icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
        label: const Text('✅ Ambil Foto After & Tuntaskan Pekerjaan', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.successGreen,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 2,
        ),
      );
    }

    if (status == TicketStatus.paymentPending) {
      final total = t.finalBill?.totalAmount ?? 0;
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.payments_rounded, color: AppColors.successGreen, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pembayaran Tunai di Tempat',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Nota disetujui konsumen. Silakan terima uang tunai sejumlah ${_currencyFormat.format(total)} dari konsumen.',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _showConfirmCashPaymentDialog(context, t),
            icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
            label: Text(
              '💵 Konfirmasi Uang Tunai Diterima (${_currencyFormat.format(total)})',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.successGreen,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
          ),
        ],
      );
    }

    if (status == TicketStatus.completed) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_rounded, color: AppColors.successGreen, size: 22),
                SizedBox(width: 8),
                Text(
                  'Pekerjaan Selesai & Lunas Tunai',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.successGreen),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  context.read<TicketBloc>().add(FetchTukangActiveTicketsEvent(widget.tukang.id));
                }
              },
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textDark),
              label: const Text('Kembali ke Radar Pekerjaan', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.textDark, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: () => Navigator.pop(context),
      icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textDark),
      label: const Text('Kembali ke Radar Pekerjaan', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.textDark, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showConfirmCashPaymentDialog(BuildContext context, TicketModel t) {
    final total = t.finalBill?.totalAmount ?? 0;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.payments_rounded, color: AppColors.successGreen),
            SizedBox(width: 10),
            Text('Konfirmasi Tunai', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Apakah Anda sudah menerima uang tunai langsung dari konsumen sebesar:'),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _currencyFormat.format(total),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Pastikan uang tunai sudah Anda terima di tempat sebelum menyelesaikan pesanan ini.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<TicketBloc>().add(
                UpdateTicketStatusRequestedEvent(
                  ticketId: t.id,
                  newStatus: TicketStatus.completed,
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pembayaran tunai berhasil dikonfirmasi! Tiket selesai.'),
                  backgroundColor: AppColors.successGreen,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.successGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Ya, Uang Diterima', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
