import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class UserSettingsPage extends StatefulWidget {
  final bool initialPushNotification;
  final bool initialWhatsappNotification;

  const UserSettingsPage({
    super.key,
    this.initialPushNotification = true,
    this.initialWhatsappNotification = true,
  });

  @override
  State<UserSettingsPage> createState() => _UserSettingsPageState();
}

class _UserSettingsPageState extends State<UserSettingsPage> {
  late bool _pushNotification;
  late bool _whatsappNotification;
  bool _biometricLogin = true;

  @override
  void initState() {
    super.initState();
    _pushNotification = widget.initialPushNotification;
    _whatsappNotification = widget.initialWhatsappNotification;
  }

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.lock_reset_rounded, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Ubah Kata Sandi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: oldPasswordController,
                      obscureText: obscureOld,
                      decoration: InputDecoration(
                        labelText: 'Kata Sandi Saat Ini',
                        suffixIcon: IconButton(
                          icon: Icon(obscureOld ? Icons.visibility_off : Icons.visibility, size: 18),
                          onPressed: () => setDialogState(() => obscureOld = !obscureOld),
                        ),
                      ),
                      validator: (val) => (val == null || val.length < 6) ? 'Minimal 6 karakter' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: 'Kata Sandi Baru',
                        suffixIcon: IconButton(
                          icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, size: 18),
                          onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                        ),
                      ),
                      validator: (val) => (val == null || val.length < 6) ? 'Minimal 6 karakter' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Konfirmasi Kata Sandi Baru',
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 18),
                          onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                        ),
                      ),
                      validator: (val) {
                        if (val != newPasswordController.text) {
                          return 'Kata sandi baru tidak cocok';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Kata sandi berhasil diperbarui!'),
                        backgroundColor: AppColors.successGreen,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showChangePinDialog() {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.pin_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('PIN Transaksi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan 6-digit PIN baru untuk otorisasi pembayaran dompet & rilis invoice:',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, letterSpacing: 10, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                counterText: '',
                hintText: '••••••',
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              if (pinController.text.length == 6) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PIN Transaksi berhasil diperbarui!'),
                    backgroundColor: AppColors.successGreen,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Konfirmasi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, {
          'push': _pushNotification,
          'whatsapp': _whatsappNotification,
        });
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text(
            'Pengaturan Akun',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textDark,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context, {
              'push': _pushNotification,
              'whatsapp': _whatsappNotification,
            }),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Section 1: Notifikasi
            _buildSectionHeader('PREFERENSI NOTIFIKASI'),
            Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text(
                      'Push Notifikasi Status Pesanan',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                    ),
                    subtitle: const Text(
                      'Dapatkan update langsung saat tukang mengajukan penawaran atau menuju lokasi',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    value: _pushNotification,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _pushNotification = val),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  SwitchListTile(
                    title: const Text(
                      'Pemberitahuan via WhatsApp',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                    ),
                    subtitle: const Text(
                      'Kirimkan salinan invoice dan konfirmasi kedatangan ke nomor WhatsApp Anda',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    value: _whatsappNotification,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _whatsappNotification = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Section 2: Keamanan Akun
            _buildSectionHeader('KEAMANAN AKUN'),
            Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text(
                      'Biometrik (Fingerprint / Face ID)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                    ),
                    subtitle: const Text(
                      'Gunakan sensor biometrik untuk masuk aplikasi lebih cepat & aman',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    value: _biometricLogin,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _biometricLogin = val),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 20),
                    ),
                    title: const Text(
                      'Ubah Kata Sandi',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                    ),
                    subtitle: const Text(
                      'Perbarui kata sandi login akun Anda secara berkala',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
                    onTap: _showChangePasswordDialog,
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.pin_outlined, color: AppColors.primary, size: 20),
                    ),
                    title: const Text(
                      'Ubah PIN Transaksi',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                    ),
                    subtitle: const Text(
                      'Atur 6-digit PIN untuk keamanan konfirmasi pembayaran & rilis nota',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
                    onTap: _showChangePinDialog,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
                        
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.6,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
