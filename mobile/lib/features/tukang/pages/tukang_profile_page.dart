import 'package:flutter/material.dart';
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
  late List<PayoutAccount> _payoutAccounts;
  late double _workRadiusKm;

  @override
  void initState() {
    super.initState();
    _services = List<String>.from(widget.tukang.services);
    _payoutAccounts = List<PayoutAccount>.from(widget.tukang.payoutAccounts);
    _workRadiusKm = widget.tukang.workRadiusKm;
  }

  void _showEditServicesModal() {
    final availableCategories = ServiceCategories.all;
    final tempSelected = List<String>.from(_services);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Edit Keahlian Layanan',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(modalCtx),
                      ),
                    ],
                  ),
                  const Text(
                    'Pilih kategori pekerjaan yang dapat Anda kerjakan:',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 12),

                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: availableCategories.length,
                      itemBuilder: (context, idx) {
                        final cat = availableCategories[idx];
                        final isSelected = tempSelected.contains(cat.id);

                        return CheckboxListTile(
                          activeColor: AppColors.textDark,
                          secondary: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: cat.backgroundColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(cat.icon, color: AppColors.primary, size: 20),
                          ),
                          title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          value: isSelected,
                          onChanged: (val) {
                            setModalState(() {
                              if (val == true) {
                                tempSelected.add(cat.id);
                              } else {
                                if (tempSelected.length > 1) {
                                  tempSelected.remove(cat.id);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Minimal pilih 1 kategori keahlian.')),
                                  );
                                }
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _services = tempSelected;
                        });
                        Navigator.pop(modalCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Keahlian layanan berhasil diperbarui!'),
                            backgroundColor: AppColors.successGreen,
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.textDark,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Simpan Perubahan Keahlian', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  void _showEditPayoutAccountModal() {
    final currentAccount = _payoutAccounts.isNotEmpty
        ? _payoutAccounts.first
        : PayoutAccount(type: 'bank', provider: 'BCA', accountNumber: '2102198765', accountName: widget.tukang.name);

    final providerCtrl = TextEditingController(text: currentAccount.provider);
    final numberCtrl = TextEditingController(text: currentAccount.accountNumber);
    final nameCtrl = TextEditingController(text: currentAccount.accountName);
    String type = currentAccount.type;

    final providers = ['BCA', 'Mandiri', 'BRI', 'BNI', 'GoPay', 'OVO', 'DANA', 'ShopeePay'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Edit Rekening Payout & E-Wallet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Rekening ini digunakan untuk pencairan saldo hasil kerja Anda.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: providers.contains(providerCtrl.text) ? providerCtrl.text : 'BCA',
                    decoration: const InputDecoration(
                      labelText: 'Bank / E-Wallet Provider',
                      border: OutlineInputBorder(),
                    ),
                    items: providers.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        providerCtrl.text = val;
                        setModalState(() {
                          type = ['GoPay', 'OVO', 'DANA', 'ShopeePay'].contains(val) ? 'ewallet' : 'bank';
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: numberCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: type == 'bank' ? 'Nomor Rekening Bank' : 'Nomor HP E-Wallet',
                      hintText: type == 'bank' ? 'Contoh: 8820192831' : 'Contoh: 081234567890',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nama Pemilik Rekening / Akun',
                      hintText: 'Contoh: Ahmad Subarjo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (numberCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap lengkapi semua bidang.')));
                          return;
                        }

                        final updatedAcc = PayoutAccount(
                          type: type,
                          provider: providerCtrl.text,
                          accountNumber: numberCtrl.text.trim(),
                          accountName: nameCtrl.text.trim(),
                        );

                        setState(() {
                          _payoutAccounts = [updatedAcc];
                        });

                        Navigator.pop(modalCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Rekening pencairan berhasil diperbarui!'), backgroundColor: AppColors.successGreen),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.textDark,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Simpan Rekening Payout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  void _showKtpViewerModal() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.verified, color: AppColors.successGreen),
            SizedBox(width: 8),
            Text('Dokumen KTP Resmi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.tukang.ktpUrl.isNotEmpty
                    ? widget.tukang.ktpUrl
                    : 'https://images.unsplash.com/photo-1557804506-669a67965ba0?w=800',
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 180,
                  color: AppColors.border,
                  child: const Center(child: Icon(Icons.badge, size: 48, color: AppColors.textMuted)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('Nama KTP: ${widget.tukang.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 2),
            Text('Status: ${widget.tukang.verificationStatus.toUpperCase()}', style: const TextStyle(color: AppColors.successGreen, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Tutup')),
        ],
      ),
    );
  }

  void _showCustomerSupportModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bantuan & Dukungan 24/7', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Tim Support Beres siap membantu kendala operasional Anda.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 16),

            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFDCFCE7), child: Icon(Icons.chat, color: AppColors.successGreen)),
              title: const Text('Chat WhatsApp CS', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('+62 852-5669-4929 (WA 24/7)', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Membuka chat CS WhatsApp...')));
              },
            ),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFEFF6FF), child: Icon(Icons.phone, color: AppColors.primary)),
              title: const Text('Call Center Beres', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('+62 852-5669-4929', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Memanggil Call Center Beres...')));
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPayout = _payoutAccounts.isNotEmpty ? _payoutAccounts.first : null;

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
                        Text('KTP TERVERIFIKASI ADMIN', style: TextStyle(color: AppColors.successGreen, fontSize: 11, fontWeight: FontWeight.bold)),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Keahlian & Kategori Layanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
                            TextButton.icon(
                              onPressed: _showEditServicesModal,
                              icon: const Icon(Icons.edit, size: 14, color: AppColors.primary),
                              label: const Text('Edit Keahlian', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _services.map((cat) {
                            return Chip(
                              avatar: const Icon(Icons.check_circle, size: 16, color: AppColors.primary),
                              label: Text(cat.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              backgroundColor: AppColors.bgAC,
                              side: BorderSide.none,
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Options List
                  _buildProfileTile(
                    icon: Icons.account_balance_rounded,
                    iconBg: const Color(0xFFECFDF5),
                    iconColor: AppColors.successGreen,
                    title: 'Rekening Payout & Pencairan',
                    subtitle: currentPayout != null
                        ? '${currentPayout.provider} • ${currentPayout.accountNumber} (a.n ${currentPayout.accountName})'
                        : 'Belum diatur • Klik untuk tambah',
                    onTap: _showEditPayoutAccountModal,
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
                    icon: Icons.badge_outlined,
                    iconBg: const Color(0xFFFEF3C7),
                    iconColor: AppColors.safetyAmber,
                    title: 'Dokumen KTP & Identitas',
                    subtitle: 'Terverifikasi • Lihat Dokumen KTP',
                    onTap: _showKtpViewerModal,
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
    required VoidCallback onTap,
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
          trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
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
