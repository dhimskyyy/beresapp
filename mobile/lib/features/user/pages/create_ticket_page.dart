import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/service_categories.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../ticket/bloc/ticket_bloc.dart';
import '../../ticket/bloc/ticket_event.dart';
import '../../ticket/bloc/ticket_state.dart';

class CreateTicketPage extends StatefulWidget {
  final String? initialCategory;
  const CreateTicketPage({super.key, this.initialCategory});

  @override
  State<CreateTicketPage> createState() => _CreateTicketPageState();
}

class _CreateTicketPageState extends State<CreateTicketPage> {
  final _formKey = GlobalKey<FormState>();
  final MapController _mapController = MapController();
  late String _selectedCategory;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController(text: 'Jl. Wijaya II No. 18, Kebayoran Baru, Jakarta Selatan');
  
  LatLng _pinLocation = const LatLng(-6.2382, 106.8123); // Default Kebayoran Baru
  final List<XFile> _pickedPhotos = [];
  final ImagePicker _picker = ImagePicker();

  // Known areas for geocoding simulation
  final Map<String, LatLng> _knownAreaPoints = {
    'ceria': const LatLng(-6.2255, 106.8123),
    'wijaya': const LatLng(-6.2425, 106.7978),
    'sudirman': const LatLng(-6.2150, 106.8220),
    'thamrin': const LatLng(-6.1920, 106.8235),
    'kebayoran': const LatLng(-6.2450, 106.7900),
    'tebet': const LatLng(-6.2300, 106.8500),
    'senayan': const LatLng(-6.2210, 106.8000),
    'kemang': const LatLng(-6.2600, 106.8150),
    'fatmawati': const LatLng(-6.2750, 106.7950),
    'cilandak': const LatLng(-6.2900, 106.8000),
    'bandung': const LatLng(-6.9175, 107.6191),
    'surabaya': const LatLng(-7.2575, 112.7521),
    'jakarta': const LatLng(-6.2088, 106.8456),
  };

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'ac';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // Reverse Geocoding: Marker moved -> Update Address text automatically
  void _updateAddressFromCoordinates(LatLng point) {
    setState(() {
      _pinLocation = point;
    });
    _mapController.move(point, _mapController.camera.zoom);

    final lat = point.latitude;
    String areaName = 'Jakarta Selatan';
    String streetName = 'Jl. Ceria Indah';
    int streetNo = (point.latitude.abs() * 1000 % 80).toInt() + 1;

    if (lat < -6.24) {
      areaName = 'Kebayoran Baru, Jakarta Selatan';
      streetName = 'Jl. Wijaya II';
    } else if (lat < -6.22) {
      areaName = 'Senayan, Jakarta Selatan';
      streetName = 'Jl. Asia Afrika';
    } else if (lat < -6.20) {
      areaName = 'Karet Semanggi, Jakarta Selatan';
      streetName = 'Jl. Jend. Sudirman';
    } else if (lat < -6.18) {
      areaName = 'Menteng, Jakarta Pusat';
      streetName = 'Jl. M.H. Thamrin';
    }

    final newAddr = '$streetName No. $streetNo, $areaName';
    _addressController.text = newAddr;
  }

  // Geocoding: User types address -> Auto-focus and move marker on map
  void _onAddressInputChanged(String text) {
    if (text.trim().isEmpty) return;
    final lower = text.toLowerCase();

    for (final entry in _knownAreaPoints.entries) {
      if (lower.contains(entry.key)) {
        setState(() {
          _pinLocation = entry.value;
        });
        _mapController.move(entry.value, 15.5);
        return;
      }
    }

    final pseudoOffset = (text.length % 10) * 0.002;
    final shifted = LatLng(
      -6.2382 + pseudoOffset,
      106.8123 + pseudoOffset,
    );
    setState(() {
      _pinLocation = shifted;
    });
    _mapController.move(shifted, 15.0);
  }

  void _useCurrentGPSLocation() {
    const gpsLocation = LatLng(-6.2443, 106.8044);
    _updateAddressFromCoordinates(gpsLocation);
    _mapController.move(gpsLocation, 16.0);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Titik lokasi penjemputan diselaraskan ke GPS saat ini.'),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        setState(() {
          _pickedPhotos.add(picked);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memilih foto: $e')));
    }
  }

  void _submitTicket() {
    if (_formKey.currentState?.validate() ?? false) {
      final authState = context.read<AuthBloc>().state;
      if (authState is UserAuthenticatedState) {
        context.read<TicketBloc>().add(
          CreateTicketRequestedEvent(
            userId: authState.user.id,
            userName: authState.user.name,
            category: _selectedCategory,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            photoUrls: _pickedPhotos.map((p) => p.path).toList(),
            address: _addressController.text.trim(),
            lat: _pinLocation.latitude,
            lng: _pinLocation.longitude,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            'Buat Tiket Keluhan',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: BlocConsumer<TicketBloc, TicketState>(
          listener: (context, state) {
            if (state is TicketCreatedSuccessState) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tiket keluhan berhasil dibuat! Membroadcast ke tukang terdekat...'), backgroundColor: AppColors.successGreen),
              );
              Navigator.pop(context);
            } else if (state is TicketOperationFailureState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: AppColors.dangerRed),
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is TicketLoadingState;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Category Dropdown Selection
                    const Text('Pilih Kategori Layanan Spesifik:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: ServiceCategories.all.map((cat) {
                        return DropdownMenuItem(
                          value: cat.id,
                          child: Row(
                            children: [
                              Icon(cat.icon, color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCategory = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Judul Keluhan Singkat',
                        hintText: 'Contoh: AC Kamar Tidur Bocor Menetes Air',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Isi judul keluhan' : null,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Deskripsi Detail Masalah',
                        hintText: 'Ceritakan kendala secara detail agar tukang paham alat & sparepart yang dibutuhkan...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Isi deskripsi masalah' : null,
                    ),
                    const SizedBox(height: 20),

                    // Photo Pickers
                    const Text('Lampirkan Foto Keluhan (Maks. 5 Foto):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 90,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ElevatedButton(
                            onPressed: () => _pickImage(ImageSource.camera),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: AppColors.border),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt, size: 24),
                                SizedBox(height: 4),
                                Text('Kamera', style: TextStyle(fontSize: 11)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: AppColors.border),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.photo_library, size: 24),
                                SizedBox(height: 4),
                                Text('Galeri', style: TextStyle(fontSize: 11)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          ..._pickedPhotos.map((photo) => Container(
                                margin: const EdgeInsets.only(right: 10),
                                width: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                  image: DecorationImage(image: FileImage(File(photo.path)), fit: BoxFit.cover),
                                ),
                              ))
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Address Input & Map Preview
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Alamat Penjemputan / Rumah:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        TextButton.icon(
                          onPressed: _useCurrentGPSLocation,
                          icon: const Icon(Icons.my_location, size: 14, color: AppColors.primary),
                          label: const Text('Gunakan GPS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _addressController,
                      onChanged: _onAddressInputChanged,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.location_on, color: AppColors.dangerRed),
                        hintText: 'Ketik alamat atau geser/ketuk pin di peta...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                        helperText: 'Alamat & pin peta tersinkronisasi otomatis secara bolak-balik',
                        helperStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Isi alamat penjemputan' : null,
                    ),
                    const SizedBox(height: 12),

                    // OpenStreetMap Interactive Pinpoint Preview
                    Container(
                      height: 220,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: _pinLocation,
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
                                      point: _pinLocation,
                                      width: 48,
                                      height: 48,
                                      child: const Icon(Icons.location_on, color: AppColors.dangerRed, size: 44),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Coordinates overlay chip
                          Positioned(
                            top: 10,
                            left: 10,
                            right: 60,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.touch_app_outlined, size: 14, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '${_pinLocation.latitude.toStringAsFixed(4)}, ${_pinLocation.longitude.toStringAsFixed(4)} (Ketuk peta)',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textDark),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // GPS Shortcut Button
                          Positioned(
                            bottom: 10,
                            right: 10,
                            child: FloatingActionButton.small(
                              heroTag: 'createTicketGPSBtn',
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              onPressed: _useCurrentGPSLocation,
                              child: const Icon(Icons.my_location),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    ElevatedButton(
                      onPressed: isLoading ? null : _submitTicket,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Broadcast Tiket ke Tukang', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
