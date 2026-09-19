import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_saved_address.dart';

class UserAddEditAddressPage extends StatefulWidget {
  final UserSavedAddress? initialAddress;
  final String defaultRecipientName;
  final String defaultPhone;

  const UserAddEditAddressPage({
    super.key,
    this.initialAddress,
    required this.defaultRecipientName,
    required this.defaultPhone,
  });

  @override
  State<UserAddEditAddressPage> createState() => _UserAddEditAddressPageState();
}

class _UserAddEditAddressPageState extends State<UserAddEditAddressPage> {
  final _formKey = GlobalKey<FormState>();
  final MapController _mapController = MapController();

  late String _selectedLabel;
  late TextEditingController _recipientNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _noteController;
  late bool _isPrimary;
  late LatLng _currentMarkerPoint;

  final List<String> _labelOptions = ['Rumah', 'Kantor', 'Apartemen', 'Kos', 'Lainnya'];

  // Simulated location lookup dictionary for Jakarta & major areas
  final Map<String, LatLng> _knownAreaPoints = {
    'ceria': const LatLng(-6.2255, 106.8123),
    'wijaya': const LatLng(-6.2425, 106.7978),
    'sudirman': const LatLng(-6.2150, 106.8220),
    'thamrin': const LatLng(-6.1920, 106.8235),
    'kebayoran': const LatLng(-6.2450, 106.7900),
    'tebet': const LatLng(-6.2300, 106.8500),
    'senayan': const LatLng(-6.2210, 106.8000),
    'kemang': const LatLng(-6.2600, 106.8150),
    'bandung': const LatLng(-6.9175, 107.6191),
    'surabaya': const LatLng(-7.2575, 112.7521),
  };

  @override
  void initState() {
    super.initState();
    final addr = widget.initialAddress;
    _selectedLabel = addr != null ? addr.label.replaceAll(RegExp(r'\s*\(Utama\)'), '') : 'Rumah';
    if (!_labelOptions.contains(_selectedLabel)) {
      _selectedLabel = 'Lainnya';
    }

    _recipientNameController = TextEditingController(text: addr?.recipientName ?? widget.defaultRecipientName);
    _phoneController = TextEditingController(text: addr?.phone ?? widget.defaultPhone);
    _addressController = TextEditingController(
      text: addr?.fullAddress ?? 'Jl. Wijaya II No. 18, RT 05 / RW 02, Kebayoran Baru, Jakarta Selatan',
    );
    _noteController = TextEditingController(text: addr?.note ?? '');
    _isPrimary = addr?.isPrimary ?? false;

    _currentMarkerPoint = addr != null
        ? LatLng(addr.latitude, addr.longitude)
        : const LatLng(-6.2425, 106.7978);
  }

  @override
  void dispose() {
    _recipientNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // Reverse Geocoding Simulation based on marker coordinates
  void _updateAddressFromCoordinates(LatLng point) {
    setState(() {
      _currentMarkerPoint = point;
    });

    // Create realistic address title and description based on coordinate range
    final lat = point.latitude;
    final lng = point.longitude;

    String areaName = 'Jakarta Selatan';
    String streetName = 'Jl. Ceria Indah';
    int streetNo = (point.latitude.abs() * 1000 % 80).toInt() + 1;

    if (lat < -6.24) {
      areaName = 'Kebayoran Baru, Jakarta Selatan';
      streetName = 'Jl. Wijaya Timur';
    } else if (lat < -6.21) {
      areaName = 'Karet Semanggi, Jakarta Selatan';
      streetName = 'Jl. Jend. Sudirman Kav.';
    } else if (lat < -6.19) {
      areaName = 'Menteng, Jakarta Pusat';
      streetName = 'Jl. M.H. Thamrin';
    }

    final newAddr = '$streetName No. $streetNo, RT 04 / RW 03, $areaName (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})';
    _addressController.text = newAddr;
  }

  // User types an address -> Auto-focus and move map to location
  void _onAddressInputChanged(String text) {
    if (text.trim().isEmpty) return;
    final lower = text.toLowerCase();

    for (final entry in _knownAreaPoints.entries) {
      if (lower.contains(entry.key)) {
        setState(() {
          _currentMarkerPoint = entry.value;
        });
        _mapController.move(entry.value, 15.5);
        return;
      }
    }

    // Dynamic shift based on hash of the text
    final pseudoOffset = (text.length % 10) * 0.002;
    final shifted = LatLng(
      -6.2088 + pseudoOffset,
      106.8456 + pseudoOffset,
    );
    setState(() {
      _currentMarkerPoint = shifted;
    });
    _mapController.move(shifted, 15.0);
  }

  void _useCurrentGPSLocation() {
    // Current GPS position (Jakarta Central / User Hub)
    final gpsPoint = LatLng(
      -6.2425 + (Random().nextDouble() - 0.5) * 0.005,
      106.7978 + (Random().nextDouble() - 0.5) * 0.005,
    );
    _mapController.move(gpsPoint, 16.0);
    _updateAddressFromCoordinates(gpsPoint);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lokasi GPS berhasil diperbarui! Pin telah difokuskan.'),
        backgroundColor: AppColors.successGreen,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _saveAddress() {
    if (!_formKey.currentState!.validate()) return;

    final updated = UserSavedAddress(
      id: widget.initialAddress?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      label: _isPrimary ? '$_selectedLabel (Utama)' : _selectedLabel,
      recipientName: _recipientNameController.text.trim(),
      phone: _phoneController.text.trim(),
      fullAddress: _addressController.text.trim(),
      note: _noteController.text.trim(),
      isPrimary: _isPrimary,
      latitude: _currentMarkerPoint.latitude,
      longitude: _currentMarkerPoint.longitude,
    );

    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialAddress != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          isEditing ? 'Ubah Alamat' : 'Tambah Alamat Baru',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // -------------------------------------------------------------
              // 1. INTERACTIVE OPENSTREETMAP SECTION
              // -------------------------------------------------------------
              Container(
                width: double.infinity,
                height: 260,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _currentMarkerPoint,
                        initialZoom: 15.0,
                        onTap: (tapPosition, point) {
                          _updateAddressFromCoordinates(point);
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.beres.beresapp',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _currentMarkerPoint,
                              width: 50,
                              height: 50,
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(6),
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4),
                                      ],
                                    ),
                                    child: const Text('Lokasi', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                  const Icon(Icons.location_on, color: AppColors.dangerRed, size: 32),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Instruction Banner on top of map
                    Positioned(
                      top: 12,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.touch_app_rounded, color: Colors.white, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Ketuk peta untuk memindahkan pin lokasi rumah Anda secara presisi.',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // GPS Button to locate current position
                    Positioned(
                      bottom: 12,
                      right: 16,
                      child: FloatingActionButton.small(
                        heroTag: 'gps_button',
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        elevation: 3,
                        onPressed: _useCurrentGPSLocation,
                        tooltip: 'Gunakan Lokasi GPS Saya',
                        child: const Icon(Icons.my_location_rounded, size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              // -------------------------------------------------------------
              // 2. FORM FIELDS SECTION
              // -------------------------------------------------------------
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label Selector
                    const Text('Label Alamat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _labelOptions.map((label) {
                        final isSelected = _selectedLabel == label;
                        return ChoiceChip(
                          label: Text(label),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textDark,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedLabel = label);
                            }
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 18),

                    // Nama Penerima
                    const Text('Nama Penerima / Kontak', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _recipientNameController,
                      decoration: InputDecoration(
                        hintText: 'Nama lengkap Anda / penghuni rumah',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                        prefixIcon: const Icon(Icons.person_outline, size: 20),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Nama penerima wajib diisi' : null,
                    ),

                    const SizedBox(height: 14),

                    // Nomor Telepon / WA
                    const Text('No. WhatsApp / Telepon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: '0812-xxxx-xxxx',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                        prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Nomor telepon wajib diisi' : null,
                    ),

                    const SizedBox(height: 14),

                    // Alamat Lengkap (Two-way map sync)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Alamat Lengkap & Jalan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                        Text('(Otomatis terhubung ke peta)', style: TextStyle(fontSize: 11, color: AppColors.primary.withValues(alpha: 0.8))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _addressController,
                      maxLines: 3,
                      onChanged: _onAddressInputChanged,
                      decoration: InputDecoration(
                        hintText: 'Nama jalan, nomor rumah, RT/RW, kelurahan, kecamatan',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Alamat lengkap wajib diisi' : null,
                    ),

                    const SizedBox(height: 14),

                    // Catatan Patokan
                    const Text('Catatan / Patokan Lokasi (Opsional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        hintText: 'Cth: Pagar hitam depan pos satpam, seberang masjid',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                        prefixIcon: const Icon(Icons.info_outline, size: 20),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Switch Alamat Utama
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Jadikan Alamat Utama', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                              Text('Alamat default setiap pemesanan tukang', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ),
                          Switch(
                            value: _isPrimary,
                            activeColor: AppColors.primary,
                            onChanged: (val) => setState(() => _isPrimary = val),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Tombol Simpan
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveAddress,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        child: Text(
                          isEditing ? 'Simpan Perubahan Alamat' : 'Simpan Alamat Baru',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
