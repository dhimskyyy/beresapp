import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';

class UserProfilePage extends StatelessWidget {
  final UserModel user;

  const UserProfilePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pengaturan aplikasi')),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User Info Header Card
            Container(
              width: double.infinity,
              color: AppColors.primary,
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 24, top: 8),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 41,
                          backgroundColor: AppColors.primaryLight,
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                            style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.successGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.phone,
                    style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Main Menu Options List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  _buildProfileTile(
                    icon: Icons.location_on_outlined,
                    iconBg: const Color(0xFFEFF6FF),
                    iconColor: AppColors.primary,
                    title: 'Alamat Tersimpan',
                    subtitle: 'Jl. Wijaya II No. 18, Kebayoran Baru (Utama)',
                    onTap: () {
                      _showAddressModal(context);
                    },
                  ),
                  _buildProfileTile(
                    icon: Icons.account_balance_wallet_outlined,
                    iconBg: const Color(0xFFECFDF5),
                    iconColor: AppColors.successGreen,
                    title: 'Metode Pembayaran & E-Wallet',
                    subtitle: 'Saldomu / QRIS / Transfer Bank',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Manajemen Pembayaran User')),
                      );
                    },
                  ),
                  _buildProfileTile(
                    icon: Icons.history_rounded,
                    iconBg: const Color(0xFFF5F3FF),
                    iconColor: Colors.purple,
                    title: 'Riwayat Pesanan',
                    subtitle: 'Daftar tiket pekerjaan yang selesai',
                    onTap: () {},
                  ),
                  _buildProfileTile(
                    icon: Icons.shield_outlined,
                    iconBg: const Color(0xFFFEF3C7),
                    iconColor: AppColors.safetyAmber,
                    title: 'Garansi & Perlindungan Layanan',
                    subtitle: 'Garansi 7 hari untuk setiap perbaikan',
                    onTap: () {},
                  ),
                  _buildProfileTile(
                    icon: Icons.help_outline_rounded,
                    iconBg: const Color(0xFFE0F2FE),
                    iconColor: Colors.blueAccent,
                    title: 'Pusat Bantuan & Customer Service',
                    subtitle: 'FAQ / Hubungi CS Beres 24/7',
                    onTap: () {},
                  ),
                  _buildProfileTile(
                    icon: Icons.description_outlined,
                    iconBg: const Color(0xFFF1F5F9),
                    iconColor: AppColors.textMuted,
                    title: 'Syarat, Ketentuan & Privasi',
                    subtitle: 'Kebijakan privasi & aturan pengguna',
                    onTap: () {},
                  ),

                  const SizedBox(height: 20),

                  // Logout Button Card
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 24),
                    child: OutlinedButton.icon(
                      onPressed: () => _showLogoutDialog(context),
                      icon: const Icon(Icons.logout, color: AppColors.dangerRed),
                      label: const Text('Keluar dari Akun', style: TextStyle(color: AppColors.dangerRed, fontWeight: FontWeight.bold)),
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

  void _showAddressModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Alamat Tersimpan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.home, color: AppColors.primary),
                title: const Text('Rumah (Utama)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Jl. Wijaya II No. 18, Kebayoran Baru, Jakarta Selatan'),
                trailing: const Icon(Icons.check_circle, color: AppColors.successGreen),
                onTap: () => Navigator.pop(context),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.work, color: AppColors.textMuted),
                title: const Text('Kantor'),
                subtitle: const Text('Gedung Menara Mandiri Lt. 12, Jl. Jend. Sudirman'),
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.add_location_alt, color: Colors.white),
                  label: const Text('Tambah Alamat Baru', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Konfirmasi Keluar', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Apakah Anda yakin ingin keluar dari akun Beres?'),
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
