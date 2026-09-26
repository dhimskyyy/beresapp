import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/user_saved_address.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import 'user_address_list_page.dart';
import 'user_edit_profile_page.dart';
import 'user_favorite_tradesmen_page.dart';
import 'user_help_center_page.dart';
import 'user_settings_page.dart';
import 'user_terms_privacy_page.dart';

class UserProfilePage extends StatefulWidget {
  final UserModel user;
  final VoidCallback? onNavigateToOrders;
  final ValueChanged<UserModel>? onUserUpdated;

  const UserProfilePage({
    super.key,
    required this.user,
    this.onNavigateToOrders,
    this.onUserUpdated,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool _pushNotification = true;
  bool _whatsappNotification = true;
  String _activeAddressId = '1';

  late String _userName;
  late String _userPhone;
  String? _userPhotoUrl;
  late List<UserSavedAddress> _savedAddresses;

  @override
  void initState() {
    super.initState();
    _userName = widget.user.name.isNotEmpty ? widget.user.name : 'Dhimas';
    _userPhone = widget.user.phone.isNotEmpty
        ? widget.user.phone
        : '081234567890';
    _userPhotoUrl = widget.user.photoUrl;

    _savedAddresses = [
      UserSavedAddress(
        id: '1',
        label: 'Rumah (Utama)',
        recipientName: _userName,
        phone: _userPhone,
        fullAddress:
            'Jl. Wijaya II No. 18, RT 05 / RW 02, Kebayoran Baru, Jakarta Selatan',
        note: 'Patokan: Pagar hitam depan pos satpam',
        isPrimary: true,
        latitude: -6.2443,
        longitude: 106.8044,
      ),
      UserSavedAddress(
        id: '2',
        label: 'Kantor',
        recipientName: _userName,
        phone: _userPhone,
        fullAddress:
            'Gedung Menara Mandiri Lt. 12, Jl. Jend. Sudirman Kav 54-55, Jakarta Selatan',
        note: 'Lobi Selatan / Meja Resepsionis',
        isPrimary: false,
        latitude: -6.2250,
        longitude: 106.8080,
      ),
    ];
  }

  @override
  void didUpdateWidget(UserProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.user != oldWidget.user) {
      setState(() {
        _userName = widget.user.name.isNotEmpty ? widget.user.name : _userName;
        _userPhone = widget.user.phone.isNotEmpty ? widget.user.phone : _userPhone;
        _userPhotoUrl = widget.user.photoUrl;
      });
    }
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserSettingsPage(
          initialPushNotification: _pushNotification,
          initialWhatsappNotification: _whatsappNotification,
        ),
      ),
    ).then((result) {
      if (result is Map) {
        setState(() {
          _pushNotification = result['push'] ?? _pushNotification;
          _whatsappNotification =
              result['whatsapp'] ?? _whatsappNotification;
        });
      }
    });
  }

  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserEditProfilePage(
          currentName: _userName,
          currentPhone: _userPhone,
          email: widget.user.email,
          currentPhotoUrl: _userPhotoUrl,
        ),
      ),
    ).then((result) {
      if (result is Map) {
        final newName = result['name'] ?? _userName;
        final newPhone = result['phone'] ?? _userPhone;
        final newPhotoUrl = result['photoUrl'] as String?;

        setState(() {
          _userName = newName;
          _userPhone = newPhone;
          _userPhotoUrl = newPhotoUrl;
        });

        final updatedUser = widget.user.copyWith(
          name: newName,
          phone: newPhone,
          photoUrl: newPhotoUrl,
        );

        widget.onUserUpdated?.call(updatedUser);
        context.read<AuthBloc>().add(UserProfileUpdatedEvent(updatedUser));
      }
    });
  }

  void _navigateToAddressList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserAddressListPage(
          initialAddresses: _savedAddresses,
          activeAddressId: _activeAddressId,
          userName: _userName,
          userPhone: _userPhone,
          onAddressesChanged: (updatedAddresses, newActiveId) {
            setState(() {
              _savedAddresses = updatedAddresses;
              _activeAddressId = newActiveId;
            });
          },
        ),
      ),
    );
  }

  void _navigateToFavoriteTradesmen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserFavoriteTradesmenPage(
          onNavigateToOrders: widget.onNavigateToOrders,
        ),
      ),
    );
  }

  void _navigateToHelpCenter() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const UserHelpCenterPage(),
      ),
    );
  }

  void _navigateToTermsPrivacy() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const UserTermsPrivacyPage(),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Konfirmasi Keluar',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Apakah Anda yakin ingin keluar dari akun BeresApp?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text(
                'Batal',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                context.read<AuthBloc>().add(SignOutRequestedEvent());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dangerRed,
              ),
              child: const Text(
                'Keluar',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeAddress = _savedAddresses.firstWhere(
      (a) => a.id == _activeAddressId,
      orElse: () => _savedAddresses.first,
    );

    const Color headerTopColor = Color(0xFF1E3A8A);
    const Color bodyColor = Color(0xFFF8FAFC);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: bodyColor,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: bodyColor,
        body: Stack(
          children: [
            // Background split:
            // Top half matches header top color for top overscroll.
            // Bottom half matches body background for bottom overscroll.
            Column(
              children: [
                Expanded(
                  child: Container(
                    color: headerTopColor,
                  ),
                ),
                Expanded(
                  child: Container(
                    color: bodyColor,
                  ),
                ),
              ],
            ),

            ScrollConfiguration(
              behavior: const ScrollBehavior().copyWith(overscroll: false),
              child: CustomScrollView(
                physics: const ClampingScrollPhysics(),
                slivers: [
                // Modern Decorated Sliver AppBar & Profile Header
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF1E3A8A),
                          Color(0xFF2563EB),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
              child: Stack(
                children: [
                  // Decorative Ambient Orbs
                  Positioned(
                    top: -40,
                    right: -30,
                    child: Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 200,
                    left: -20,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blueAccent.withValues(alpha: 0.12),
                      ),
                    ),
                  ),

                  // Content Column: Header on top, White Body nested below inside the patterned blue container
                  Column(
                    children: [
                      SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                          child: Column(
                        children: [
                          // Top Navigation Bar Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Profil',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.settings_outlined,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                onPressed: _navigateToSettings,
                                tooltip: 'Pengaturan',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // User Avatar & Badges
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3.5),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF60A5FA),
                                      Colors.white,
                                      Color(0xFF3B82F6),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.25,
                                      ),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 42,
                                  backgroundColor: const Color(0xFF1E293B),
                                  backgroundImage: _userPhotoUrl != null && _userPhotoUrl!.isNotEmpty
                                      ? (_userPhotoUrl!.startsWith('http')
                                          ? NetworkImage(_userPhotoUrl!) as ImageProvider
                                          : FileImage(File(_userPhotoUrl!)))
                                      : null,
                                  child: (_userPhotoUrl == null || _userPhotoUrl!.isEmpty)
                                      ? Text(
                                          _userName.isNotEmpty
                                              ? _userName[0].toUpperCase()
                                              : 'U',
                                          style: const TextStyle(
                                            fontSize: 34,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              GestureDetector(
                                onTap: _navigateToEditProfile,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.2,
                                        ),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.edit_outlined,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // User Name
                          Text(
                            _userName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Email & Phone
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.email_outlined,
                                size: 13,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.user.email,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '•',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.phone_outlined,
                                size: 13,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _userPhone,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Ubah Profil Button
                          GestureDetector(
                            onTap: _navigateToEditProfile,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.edit_note_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Ubah Profil',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Main Body Section with Rounded Top Container seamlessly nested inside the patterned blue container
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),

                  // -----------------------------------------------------------
                  // SECTION 1: AKUN & PEMBAYARAN (Moved seamlessly to the top)
                  // -----------------------------------------------------------
                  _buildSectionHeader('AKUN & PEMBAYARAN'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        _buildProfileTile(
                          icon: Icons.location_on_outlined,
                          iconBg: const Color(0xFFEFF6FF),
                          iconColor: AppColors.primary,
                          title: 'Alamat Tersimpan',
                          subtitle:
                              '${activeAddress.label} • ${activeAddress.fullAddress}',
                          badgeText: '${_savedAddresses.length} Alamat',
                          onTap: _navigateToAddressList,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // -----------------------------------------------------------
                  // SECTION 2: PESANAN & MITRA TUKANG
                  // -----------------------------------------------------------
                  _buildSectionHeader('PESANAN & MITRA TUKANG'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        _buildProfileTile(
                          icon: Icons.receipt_long_outlined,
                          iconBg: const Color(0xFFEFF6FF),
                          iconColor: Colors.blueAccent,
                          title: 'Riwayat Pesanan',
                          subtitle:
                              'Daftar pekerjaan aktif, progres, & nota pembayaran',
                          onTap: () {
                            if (widget.onNavigateToOrders != null) {
                              widget.onNavigateToOrders!();
                            }
                          },
                        ),
                        _buildProfileTile(
                          icon: Icons.star_outline_rounded,
                          iconBg: const Color(0xFFFFF7ED),
                          iconColor: AppColors.safetyAmber,
                          title: 'Tukang Favorit Saya',
                          subtitle:
                              'Mitra tukang terpercaya yang telah Anda simpan',
                          onTap: _navigateToFavoriteTradesmen,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // -----------------------------------------------------------
                  // SECTION 3: BANTUAN & PUSAT INFORMASI
                  // -----------------------------------------------------------
                  _buildSectionHeader('BANTUAN & PUSAT INFORMASI'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        _buildProfileTile(
                          icon: Icons.support_agent_rounded,
                          iconBg: const Color(0xFFE0F2FE),
                          iconColor: Colors.blueAccent,
                          title: 'Pusat Bantuan & Customer Service',
                          subtitle: 'FAQ kendala pesanan & chat WhatsApp CS',
                          badgeText: 'Online 24 Jam',
                          badgeColor: AppColors.successGreen,
                          onTap: _navigateToHelpCenter,
                        ),
                        _buildProfileTile(
                          icon: Icons.description_outlined,
                          iconBg: const Color(0xFFF8FAFC),
                          iconColor: AppColors.textMuted,
                          title: 'Syarat, Ketentuan & Privasi',
                          subtitle:
                              'Kebijakan privasi resmi & perlindungan data',
                          onTap: _navigateToTermsPrivacy,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Logout Button Card
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: OutlinedButton.icon(
                      onPressed: () => _showLogoutDialog(context),
                      icon: const Icon(
                        Icons.logout,
                        color: AppColors.dangerRed,
                        size: 20,
                      ),
                      label: const Text(
                        'Keluar dari Akun',
                        style: TextStyle(
                          color: AppColors.dangerRed,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(
                          color: Color(0xFFFECACA),
                          width: 1.5,
                        ),
                        backgroundColor: const Color(0xFFFEF2F2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // App Version Footer
                  const Text(
                    'BeresApp v2.4.0\nSolusi Cepat & Andal Perbaikan Rumah Anda',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 36),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  ),
),
SliverFillRemaining(
  hasScrollBody: false,
  fillOverscroll: false,
  child: Container(color: bodyColor),
),
],
),
),
],
),
),
);
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
      child: Row(
        children: [
          Container(
            width: 3.5,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
              color: AppColors.textMuted,
            ),
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
    String? badgeText,
    Color? badgeColor,
    Widget? trailingWidget,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 2,
          ),
          leading: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppColors.textDark,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: trailingWidget ??
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (badgeText != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: (badgeColor ?? AppColors.primary).withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: badgeColor ?? AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                ],
              ),
          onTap: onTap,
        ),
      ),
    );
  }
}
