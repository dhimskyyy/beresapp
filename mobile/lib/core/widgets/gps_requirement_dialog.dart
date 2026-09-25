import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Modal dialog untuk memastikan GPS dan izin lokasi aktif saat pengguna membuka aplikasi
class GpsRequirementDialog extends StatelessWidget {
  final VoidCallback onAccepted;
  final bool isTukang;

  const GpsRequirementDialog({
    super.key,
    required this.onAccepted,
    this.isTukang = false,
  });

  static Future<void> checkAndShow(BuildContext context, {bool isTukang = false}) async {
    // Tampilkan modal edukasi GPS & izin lokasi wajib di awal
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => GpsRequirementDialog(
        isTukang: isTukang,
        onAccepted: () => Navigator.pop(ctx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  size: 34,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Aktivasi GPS & Izin Lokasi Wajib',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isTukang
                    ? 'Aplikasi Beres Mitra membutuhkan GPS aktif setiap saat untuk mendeteksi posisi Anda di radar pekerjaan terdekat dan mengarahkan navigasi ke alamat konsumen.'
                    : 'Aplikasi Beres membutuhkan GPS aktif untuk mendeteksi alamat kedatangan secara presisi dan menghubungkan Anda dengan teknisi terbaik di sekitar Anda.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pastikan saklar Lokasi (GPS) di Pengaturan perangkat Anda dalam posisi AKTIF.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF92400E), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: onAccepted,
                  icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  label: const Text(
                    'Saya Mengerti & Sudah Aktifkan GPS',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
