import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/service_categories.dart';
import '../../../data/models/tukang_model.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../ticket/bloc/ticket_bloc.dart';
import '../../ticket/bloc/ticket_event.dart';

class TukangProfilePage extends StatefulWidget {
  final TukangModel tukang;
  final ValueChanged<double>? onRadiusChanged;

  const TukangProfilePage({
    super.key,
    required this.tukang,
    this.onRadiusChanged,
  });

  @override
  State<TukangProfilePage> createState() => _TukangProfilePageState();
}

class _TukangProfilePageState extends State<TukangProfilePage> {
  late List<String> _services;
  late double _workRadiusKm;
  late bool _isOnline;

  @override
  void initState() {
    super.initState();
    _services = List<String>.from(widget.tukang.services);
    _workRadiusKm = widget.tukang.workRadiusKm;
    _isOnline = widget.tukang.isOnline;
  }

  void _showEditServicesModal() {
    final availableCategories = ServiceCategories.all;
    final tempSelected = List<String>.from(_services);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.handyman_rounded, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Kelola Keahlian Layanan',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Pilih bidang pekerjaan Anda untuk menerima order tiket.',
                                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textMuted),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                  ),

                  // Counter & Fast Selection Actions Bar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${tempSelected.length}/${availableCategories.length} Kategori Aktif',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () {
                                setModalState(() {
                                  tempSelected.clear();
                                  tempSelected.addAll(availableCategories.map((c) => c.id));
                                });
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                child: Text(
                                  'Pilih Semua',
                                  style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
                            InkWell(
                              onTap: () {
                                if (tempSelected.length > 1) {
                                  setModalState(() {
                                    final first = tempSelected.first;
                                    tempSelected.clear();
                                    tempSelected.add(first);
                                  });
                                }
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                child: Text(
                                  'Sisakan 1',
                                  style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 12),

                  // Category Cards List
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      itemCount: availableCategories.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, idx) {
                        final cat = availableCategories[idx];
                        final isSelected = tempSelected.contains(cat.id);

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              setModalState(() {
                                if (isSelected) {
                                  if (tempSelected.length > 1) {
                                    tempSelected.remove(cat.id);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Minimal harus memilih 1 kategori keahlian aktif.'),
                                        backgroundColor: AppColors.dangerRed,
                                      ),
                                    );
                                  }
                                } else {
                                  tempSelected.add(cat.id);
                                }
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected ? cat.backgroundColor.withValues(alpha: 0.6) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.border,
                                  width: isSelected ? 1.8 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.08),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: cat.backgroundColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected ? AppColors.primary.withValues(alpha: 0.3) : Colors.transparent,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Icon(cat.icon, color: AppColors.primary, size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              cat.name,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: isSelected ? AppColors.textDark : AppColors.textMuted,
                                              ),
                                            ),
                                            if (isSelected) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: AppColors.successGreen.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Text(
                                                  'AKTIF',
                                                  style: TextStyle(color: AppColors.successGreen, fontSize: 9, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          cat.description,
                                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected ? AppColors.primary : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected ? AppColors.primary : Colors.grey.shade400,
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Bottom Action
                  Container(
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 14,
                      bottom: MediaQuery.of(modalCtx).padding.bottom + 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Colors.grey.shade200)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -3)),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.info_outline, size: 14, color: AppColors.primary),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Radar tiket order otomatis menyesuaikan keahlian terpilih.',
                                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _services = tempSelected;
                              });
                              final updatedTukang = widget.tukang.copyWith(services: tempSelected);
                              context.read<AuthBloc>().add(TukangProfileUpdatedEvent(updatedTukang));
                              Navigator.pop(modalCtx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: Colors.white),
                                      const SizedBox(width: 8),
                                      Text('${tempSelected.length} Keahlian layanan berhasil diperbarui!'),
                                    ],
                                  ),
                                  backgroundColor: AppColors.successGreen,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                              // Refresh radar with updated services
                              context.read<TicketBloc>().add(
                                    FetchTukangRadarTicketsEvent(
                                      services: _services,
                                      lat: widget.tukang.currentLocation?.lat ?? -6.2088,
                                      lng: widget.tukang.currentLocation?.lng ?? 106.8456,
                                      radiusKm: _workRadiusKm,
                                    ),
                                  );
                            },
                            icon: const Icon(Icons.check_rounded, color: Colors.white),
                            label: Text(
                              'Simpan Perubahan (${tempSelected.length} Keahlian)',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.textDark,
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
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
      },
    );
  }

  void _showEditRadiusModal() {
    double selectedRadius = _workRadiusKm;
    final tukangLat = widget.tukang.currentLocation?.lat ?? -6.2088;
    final tukangLng = widget.tukang.currentLocation?.lng ?? 106.8456;
    final MapController mapController = MapController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            double zoom = 14.0 - (selectedRadius / 12.0);
            if (zoom < 6.0) zoom = 6.0;
            if (zoom > 15.0) zoom = 15.0;

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Radius Jangkauan (Peta GPS)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(modalCtx),
                      )
                    ],
                  ),
                  const Text(
                    'Geser slider dari 0 km hingga 100 km. Lingkaran pada peta akan beranimasi menyesuaikan radius pekerjaan yang Anda tentukan.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 12),

                  // Interactive OpenStreetMap Canvas
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          FlutterMap(
                            mapController: mapController,
                            options: MapOptions(
                              initialCenter: LatLng(tukangLat, tukangLng),
                              initialZoom: zoom,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.beres.app',
                              ),
                              CircleLayer(
                                circles: [
                                  CircleMarker(
                                    point: LatLng(tukangLat, tukangLng),
                                    color: AppColors.primary.withValues(alpha: 0.2),
                                    borderColor: AppColors.primary,
                                    borderStrokeWidth: 3.0,
                                    useRadiusInMeter: true,
                                    radius: selectedRadius * 1000,
                                  ),
                                ],
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(tukangLat, tukangLng),
                                    width: 44,
                                    height: 44,
                                    child: const Icon(Icons.person_pin_circle_rounded, color: AppColors.dangerRed, size: 44),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.textDark,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6),
                                ],
                              ),
                              child: Text(
                                'Radius: ${selectedRadius.toStringAsFixed(1)} km',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Radius Slider (0 km - 100 km)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('0 km', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMuted)),
                      Text('${selectedRadius.toStringAsFixed(1)} km', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primary)),
                      const Text('100 km', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                  Slider(
                    value: selectedRadius,
                    min: 0.0,
                    max: 100.0,
                    divisions: 100,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.border,
                    label: '${selectedRadius.toStringAsFixed(1)} km',
                    onChanged: (val) {
                      setModalState(() {
                        selectedRadius = val;
                      });
                    },
                  ),

                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _workRadiusKm = selectedRadius;
                        });
                        final updatedTukang = widget.tukang.copyWith(workRadiusKm: selectedRadius);
                        context.read<AuthBloc>().add(TukangProfileUpdatedEvent(updatedTukang));
                        Navigator.pop(modalCtx);
                        widget.onRadiusChanged?.call(selectedRadius);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Radius pekerjaan berhasil diatur ke ${selectedRadius.toStringAsFixed(1)} km! Radar langsung diperbarui.'),
                            backgroundColor: AppColors.successGreen,
                          ),
                        );

                        // Trigger REAL distance radar re-fetch
                        context.read<TicketBloc>().add(
                              FetchTukangRadarTicketsEvent(
                                services: _services,
                                lat: tukangLat,
                                lng: tukangLng,
                                radiusKm: selectedRadius,
                              ),
                            );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.textDark,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Simpan Radius Pekerjaan Baru', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  void _showSopModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sopCtx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.78,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.menu_book_rounded, color: AppColors.safetyAmber, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('SOP & Pedoman Mitra Beres', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                          SizedBox(height: 2),
                          Text('Standar operasional wajib teknisi lapangan Beres', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted),
                      onPressed: () => Navigator.pop(sopCtx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 12),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  children: [
                    _buildSopItem(
                      number: '01',
                      title: 'Keselamatan Kerja (K3)',
                      desc: 'Wajib mengenakan alas kaki pelindung, sarung tangan isolator, dan perlengkapan standar saat menangani perbaikan listrik, ketinggian, atau atap.',
                      icon: Icons.health_and_safety_rounded,
                      color: AppColors.safetyAmber,
                    ),
                    _buildSopItem(
                      number: '02',
                      title: 'Foto Bukti Before & After',
                      desc: 'Ambil foto kondisi kerusakan sebelum dikerjakan dan foto hasil perbaikan setelah selesai sebagai bukti penyelesaian klaim pembayaran.',
                      icon: Icons.camera_alt_rounded,
                      color: AppColors.primaryLight,
                    ),
                    _buildSopItem(
                      number: '03',
                      title: 'Transparansi Biaya & Material',
                      desc: 'Bila dibutuhkan penggantian suku cadang atau material baru, selalu diskusikan dan minta persetujuan pemilik tiket sebelum membeli atau memasang.',
                      icon: Icons.receipt_long_rounded,
                      color: AppColors.successGreen,
                    ),
                    _buildSopItem(
                      number: '04',
                      title: 'Jaminan Garansi Kerja 14 Hari',
                      desc: 'Setiap pekerjaan bergaransi 14 hari. Apabila terjadi kendala pasca-pengerjaan, mitra didampingi tim Beres Care untuk penanganan tepat sasaran.',
                      icon: Icons.verified_user_rounded,
                      color: AppColors.primary,
                    ),
                    _buildSopItem(
                      number: '05',
                      title: 'Etika Ramah & Komunikasi Sopan',
                      desc: 'Beri penjelasan yang jelas kepada customer mengenai akar permasalahan dan cara perawatan agar menjaga reputasi rating bintang 5 Anda.',
                      icon: Icons.sentiment_very_satisfied_rounded,
                      color: Colors.purple,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 8,
                  bottom: MediaQuery.of(sopCtx).padding.bottom + 16,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(sopCtx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.textDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Saya Paham SOP Kerja', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSopItem({
    required String number,
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(icon, color: color, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$number. ',
                      style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 13),
                    ),
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomerSupportModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalCtx).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.headset_mic_rounded, color: Colors.blueAccent, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bantuan & CS Beres 24/7',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF86EFAC)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.successGreen,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Text(
                                  'ONLINE 24/7 • Respons < 3 Menit',
                                  style: TextStyle(color: Color(0xFF15803D), fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted),
                      onPressed: () => Navigator.pop(modalCtx),
                    ),
                  ],
                ),
              ),

              const Divider(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: const Text(
                  'Layanan bantuan prioritas khusus Mitra Teknisi Beres untuk kendala tiket, pembayaran, atau asistensi teknis lapangan.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.3),
                ),
              ),

              const SizedBox(height: 12),

              // Channel 1: WhatsApp Priority
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.successGreen,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.chat_rounded, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'WhatsApp CS Prioritas',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '+62 852-5669-4929 (Chat Siaga 24 Jam)',
                                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Tercepat',
                              style: TextStyle(color: Color(0xFF15803D), fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Clipboard.setData(const ClipboardData(text: '+6285256694929'));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Nomor WhatsApp CS berhasil disalin ke clipboard!'),
                                    backgroundColor: AppColors.successGreen,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy_rounded, size: 14, color: AppColors.successGreen),
                              label: const Text('Salin Nomor', style: TextStyle(color: AppColors.successGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF86EFAC)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(modalCtx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: const [
                                        Icon(Icons.open_in_new, color: Colors.white, size: 16),
                                        SizedBox(width: 8),
                                        Text('Menghubungkan ke Chat WhatsApp CS Beres...'),
                                      ],
                                    ),
                                    backgroundColor: AppColors.successGreen,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
                              label: const Text('Buka Chat WA', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.successGreen,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Channel 2: Hotline Call Center Darurat
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Hotline Darurat Operasional',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '+62 852-5669-4929 (Bebas Pulsa)',
                                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDBEAFE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Darurat K3',
                              style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Clipboard.setData(const ClipboardData(text: '+6285256694929'));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Nomor Hotline Darurat berhasil disalin!'),
                                    backgroundColor: AppColors.primary,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy_rounded, size: 14, color: AppColors.primary),
                              label: const Text('Salin Nomor', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF93C5FD)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(modalCtx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: const [
                                        Icon(Icons.call, color: Colors.white, size: 16),
                                        SizedBox(width: 8),
                                        Text('Memanggil Saluran Hotline Darurat Beres...'),
                                      ],
                                    ),
                                    backgroundColor: AppColors.primary,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.phone, size: 14, color: Colors.white),
                              label: const Text('Panggil CS', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Channel 3: Panduan & SOP Lapangan
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.safetyAmber,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Pedoman SOP & Garansi 14 Hari',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Panduan kerja, foto bukti & klaim material',
                              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(modalCtx);
                          _showSopModal();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          backgroundColor: AppColors.safetyAmber.withValues(alpha: 0.15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text(
                          'Buka SOP',
                          style: TextStyle(color: Color(0xFFB45309), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Security Trust Note
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.verified_user_outlined, size: 14, color: AppColors.textMuted),
                    SizedBox(width: 6),
                    Text(
                      'Dilindungi oleh Beres Mitra Safety Network • Bebas Biaya',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w500),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.textDark,
      appBar: AppBar(
        title: const Text('Profil Mitra Tukang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.textDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Tukang Profile Header
            Container(
              width: double.infinity,
              color: AppColors.textDark,
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 24, top: 8),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: AppColors.safetyAmber,
                        child: CircleAvatar(
                          radius: 41,
                          backgroundColor: Colors.white,
                          child: Text(
                            widget.tukang.name.isNotEmpty ? widget.tukang.name[0].toUpperCase() : 'T',
                            style: const TextStyle(fontSize: 36, color: AppColors.textDark, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.successGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified, color: Colors.white, size: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.tukang.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.successGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.successGreen),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_user, color: AppColors.successGreen, size: 14),
                        SizedBox(width: 4),
                        Text('MITRA TERVERIFIKASI RESMI', style: TextStyle(color: AppColors.successGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Rating & Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatBadge(Icons.star_rounded, '${widget.tukang.rating}', 'Rating Sempurna', AppColors.safetyAmber),
                      const SizedBox(width: 16),
                      _buildStatBadge(Icons.build_circle_rounded, '38+', 'Pekerjaan Selesai', AppColors.primaryLight),
                    ],
                  ),
                ],
              ),
            ),

            // Profile Sections (Rounded top light container)
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Services / Skill Categories Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.handyman_rounded, color: AppColors.primary, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 6,
                                    runSpacing: 3,
                                    children: [
                                      const Text(
                                        'Keahlian Layanan',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${_services.length} Kategori',
                                          style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Pekerjaan yang Anda terima di radar tiket',
                                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: _showEditServicesModal,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.tune_rounded, size: 14, color: AppColors.primary),
                                    SizedBox(width: 4),
                                    Text('Kelola', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _services.map((serviceId) {
                            final catItem = ServiceCategories.findById(serviceId.toLowerCase());
                            final displayName = catItem?.name ?? serviceId.toUpperCase();
                            final icon = catItem?.icon ?? Icons.build_rounded;
                            final bg = catItem?.backgroundColor ?? AppColors.bgAC;

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: bg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(icon, size: 15, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    displayName,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const Icon(Icons.check_circle_rounded, size: 12, color: AppColors.successGreen),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Options List
                  _buildProfileTile(
                    icon: Icons.wifi_tethering_rounded,
                    iconBg: _isOnline ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                    iconColor: _isOnline ? AppColors.successGreen : AppColors.textMuted,
                    title: 'Status Penerimaan Pesanan (Radar)',
                    subtitle: _isOnline ? 'Online • Siap menerima order pekerjaan' : 'Offline • Istirahat / Order nonaktif',
                    trailing: Switch(
                      value: _isOnline,
                      activeThumbColor: AppColors.successGreen,
                      onChanged: (val) {
                        setState(() => _isOnline = val);
                        final updatedTukang = widget.tukang.copyWith(isOnline: val);
                        context.read<AuthBloc>().add(TukangProfileUpdatedEvent(updatedTukang));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(val ? 'Status Mitra kini ONLINE' : 'Status Mitra kini OFFLINE'),
                            backgroundColor: val ? AppColors.successGreen : AppColors.textDark,
                          ),
                        );
                      },
                    ),
                  ),

                  _buildProfileTile(
                    icon: Icons.map_outlined,
                    iconBg: const Color(0xFFEFF6FF),
                    iconColor: AppColors.primary,
                    title: 'Radius Pekerjaan & Lokasi (Peta GPS)',
                    subtitle: 'Radius ${_workRadiusKm.toStringAsFixed(1)} km dari lokasi HP Anda',
                    onTap: _showEditRadiusModal,
                  ),

                  _buildProfileTile(
                    icon: Icons.headset_mic_outlined,
                    iconBg: const Color(0xFFE0F2FE),
                    iconColor: Colors.blueAccent,
                    title: 'Bantuan Mitra & CS Beres 24/7',
                    subtitle: 'Hubungi Support WA & Call Center',
                    onTap: _showCustomerSupportModal,
                  ),

                  const SizedBox(height: 20),

                  // Logout Button
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 24),
                    child: OutlinedButton.icon(
                      onPressed: () => _showLogoutDialog(context),
                      icon: const Icon(Icons.logout, color: AppColors.dangerRed),
                      label: const Text('Keluar dari Akun Mitra', style: TextStyle(color: AppColors.dangerRed, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.dangerRed, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          trailing: trailing ?? const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
          onTap: onTap,
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Konfirmasi Keluar Mitra', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Apakah Anda yakin ingin keluar dari Akun Mitra Beres?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                context.read<AuthBloc>().add(SignOutRequestedEvent());
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.dangerRed),
              child: const Text('Keluar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
