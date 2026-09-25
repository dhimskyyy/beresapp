import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class UserTermsPrivacyPage extends StatefulWidget {
  final int initialTabIndex;

  const UserTermsPrivacyPage({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<UserTermsPrivacyPage> createState() => _UserTermsPrivacyPageState();
}

class _UserTermsPrivacyPageState extends State<UserTermsPrivacyPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Syarat & Privasi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Syarat & Ketentuan'),
            Tab(text: 'Kebijakan Privasi (UU PDP)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTermsTab(),
          _buildPrivacyTab(),
        ],
      ),
    );
  }

  Widget _buildTermsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard(
          title: '1. Ketentuan Umum Penggunaan Platform',
          content:
              'Aplikasi BeresApp adalah platform teknologi yang mempertemukan pengguna yang membutuhkan layanan perbaikan/konstruksi rumah dengan mitra tukang dan penyedia jasa independen.\n\n'
              'BeresApp tidak bertindak sebagai kontraktor langsung, melainkan sebagai fasilitator komunikasi, penawaran harga (bidding), verifikasi identitas, dan sistem transaksi yang aman.',
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          title: '2. Transparansi Invoice & Sistem Bidding',
          content:
              'Mitra tukang berhak mengajukan penawaran harga awal berdasarkan deskripsi masalah yang Anda masukkan.\n\n'
              'Setelah survei atau pemeriksaan langsung di lokasi, tukang wajib menerbitkan Nota/Invoice resmi di dalam Room Chat. Pengguna berhak menolak atau menyetujui invoice tersebut sebelum tukang memulai pekerjaan.',
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          title: '3. Larangan Transaksi di Luar Sistem (Off-Platform)',
          content:
              'Untuk menjaga keamanan transaksi dan perlindungan pengguna, seluruh bentuk pembayaran biaya jasa dan material wajib dilakukan melalui sistem pembayaran resmi di aplikasi BeresApp.\n\n'
              'Transaksi yang disepakati atau dibayarkan di luar sistem BeresApp berada di luar tanggung jawab platform.',
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          title: '4. Pembatalan & Penyelesaian Sengketa',
          content:
              'Pengguna dapat membatalkan pesanan tanpa penalti selama tukang belum menuju lokasi atau belum ada persetujuan invoice.\n\n'
              'Jika terjadi ketidaksesuaian hasil pengerjaan, tim mediasi Customer Service BeresApp siap membantu investigasi dan resolusi yang adil bagi kedua belah pihak.',
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPrivacyTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: const Row(
            children: [
              Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Kepatuhan Penuh terhadap UU Perlindungan Data Pribadi (UU PDP No. 27 Tahun 2022).',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          title: '1. Data Pribadi yang Kami Kumpulkan',
          content:
              'Kami hanya mengumpulkan data yang esensial untuk penyediaan layanan, meliputi:\n'
              '• Identitas dasar: Nama lengkap, alamat email, nomor telepon (WhatsApp).\n'
              '• Data geolokasi: Koordinat titik peta dan alamat tujuan kedatangan tukang.\n'
              '• Riwayat transaksi: Catatan pemesanan, invoice kesepakatan, dan riwayat status pembayaran.',
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          title: '2. Tujuan Penggunaan Data',
          content:
              'Data Anda digunakan semata-mata untuk:\n'
              '• Menghubungkan Anda dengan mitra tukang terdekat sesuai radius.\n'
              '• Memungkinkan fitur navigasi kedatangan tukang ke alamat Anda.\n'
              '• Keperluan verifikasi keamanan dan penyelesaian komplain pesanan.',
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          title: '3. Jaminan Tidak Menjual Data',
          content:
              'BeresApp berkomitmen penuh tidak akan pernah menjual, menyewakan, atau memberikan data pribadi Anda kepada pihak ketiga pengiklan tanpa persetujuan eksplisit Anda.',
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          title: '4. Hak Pengguna & Penghapusan Akun',
          content:
              'Sesuai UU PDP, Anda memiliki hak untuk mengakses, memperbarui, atau meminta penghapusan akun serta seluruh data terkait dari server BeresApp melalui menu Pengaturan atau Customer Service.',
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildInfoCard({required String title, required String content}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
