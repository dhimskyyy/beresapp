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
  String? _savedPin = '123456'; // Default PIN aktif untuk simulasi

  @override
  void initState() {
    super.initState();
    _pushNotification = widget.initialPushNotification;
    _whatsappNotification = widget.initialWhatsappNotification;
  }

  Widget _buildModernPasswordField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool obscureText,
    required IconData prefixIcon,
    required VoidCallback onToggleObscure,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            prefixIcon: Icon(prefixIcon, color: AppColors.primary, size: 20),
            suffixIcon: IconButton(
              icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, size: 18, color: AppColors.textMuted),
              onPressed: onToggleObscure,
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  void _showChangePasswordBottomSheet() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top drag pill
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ubah Kata Sandi',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Perbarui kata sandi untuk mengamankan akun',
                                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textMuted),
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Field 1: Kata Sandi Saat Ini
                    _buildModernPasswordField(
                      label: 'Kata Sandi Saat Ini',
                      hint: 'Masukkan kata sandi lama Anda',
                      controller: oldPasswordController,
                      obscureText: obscureOld,
                      prefixIcon: Icons.vpn_key_outlined,
                      onToggleObscure: () => setSheetState(() => obscureOld = !obscureOld),
                      validator: (val) => (val == null || val.length < 6) ? 'Minimal 6 karakter' : null,
                    ),
                    const SizedBox(height: 14),

                    // Field 2: Kata Sandi Baru
                    _buildModernPasswordField(
                      label: 'Kata Sandi Baru',
                      hint: 'Minimal 6 karakter kombinasi',
                      controller: newPasswordController,
                      obscureText: obscureNew,
                      prefixIcon: Icons.lock_outline_rounded,
                      onToggleObscure: () => setSheetState(() => obscureNew = !obscureNew),
                      validator: (val) {
                        if (val == null || val.length < 6) return 'Minimal 6 karakter';
                        if (val == oldPasswordController.text) return 'Kata sandi baru tidak boleh sama dengan kata sandi lama';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Field 3: Konfirmasi Kata Sandi Baru
                    _buildModernPasswordField(
                      label: 'Konfirmasi Kata Sandi Baru',
                      hint: 'Ketik ulang kata sandi baru',
                      controller: confirmPasswordController,
                      obscureText: obscureConfirm,
                      prefixIcon: Icons.check_circle_outline_rounded,
                      onToggleObscure: () => setSheetState(() => obscureConfirm = !obscureConfirm),
                      validator: (val) {
                        if (val != newPasswordController.text) {
                          return 'Konfirmasi kata sandi tidak cocok';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Security Hint
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.shield_outlined, color: AppColors.primary, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Gunakan kombinasi huruf besar, huruf kecil, dan angka untuk keamanan optimal.',
                              style: TextStyle(fontSize: 11, color: Color(0xFF1E40AF)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(sheetCtx),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            child: const Text('Batal', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (formKey.currentState!.validate()) {
                                Navigator.pop(sheetCtx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Kata sandi berhasil diperbarui!'),
                                    backgroundColor: AppColors.successGreen,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.check, color: Colors.white, size: 18),
                            label: const Text('Simpan Kata Sandi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
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
            ),
          );
        },
      ),
    );
  }

  void _showChangePinBottomSheet() {
    final hasExistingPin = _savedPin != null && _savedPin!.isNotEmpty;
    bool isVerified = !hasExistingPin; // Jika belum pernah buat PIN, langsung siap buat baru
    bool isVerifying = false; // State animasi saat cek PIN
    final currentPinCtrl = TextEditingController();
    final newPinCtrl = TextEditingController();
    final confirmPinCtrl = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    String? currentPinError;
    String? newPinError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: hasExistingPin
                                ? [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)]
                                : [const Color(0xFF10B981), const Color(0xFF059669)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          hasExistingPin ? Icons.pin_rounded : Icons.shield_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasExistingPin ? 'Ubah PIN Transaksi' : 'Buat PIN Transaksi Baru',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              hasExistingPin
                                  ? 'Verifikasi PIN saat ini terlebih dahulu'
                                  : 'Wajib diatur untuk transaksi dompet & pembayaran',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textMuted),
                        onPressed: () => Navigator.pop(sheetCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // STEP 1: VERIFIKASI PIN SAAT INI (Hanya jika user sudah pernah punya PIN)
                  if (hasExistingPin) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isVerified ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isVerified ? const Color(0xFF86EFAC) : AppColors.border,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.lock_clock_outlined, size: 16, color: AppColors.primary),
                              const SizedBox(width: 6),
                              const Expanded(
                                child: Text(
                                  '1. Masukkan PIN Transaksi Anda',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isVerified) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle, size: 12, color: Color(0xFF16A34A)),
                                      SizedBox(width: 4),
                                      Text(
                                        'Terverifikasi',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: currentPinCtrl,
                            enabled: !isVerified && !isVerifying,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            obscureText: obscureCurrent,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: '••••••',
                              filled: true,
                              fillColor: isVerified ? const Color(0xFFF0FDF4) : Colors.white,
                              suffixIcon: IconButton(
                                icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility, size: 18, color: AppColors.textMuted),
                                onPressed: (isVerified || isVerifying) ? null : () => setSheetState(() => obscureCurrent = !obscureCurrent),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: currentPinError != null ? AppColors.dangerRed : AppColors.border,
                                ),
                              ),
                            ),
                          ),
                          if (currentPinError != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.error_outline, color: AppColors.dangerRed, size: 14),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    currentPinError!,
                                    style: const TextStyle(color: AppColors.dangerRed, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (!isVerified) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isVerifying
                                    ? null
                                    : () async {
                                        final entered = currentPinCtrl.text.trim();
                                        if (entered.length < 6) {
                                          setSheetState(() {
                                            currentPinError = 'Masukkan 6-digit PIN saat ini secara lengkap.';
                                          });
                                          return;
                                        }

                                        // Mulai animasi loading cek PIN
                                        setSheetState(() {
                                          isVerifying = true;
                                          currentPinError = null;
                                        });

                                        // Tunggu sekitar 2.5 detik untuk simulasi autentikasi keamanan sistem
                                        await Future.delayed(const Duration(milliseconds: 2500));
                                        if (!sheetCtx.mounted) return;

                                        if (entered == _savedPin) {
                                          setSheetState(() {
                                            isVerifying = false;
                                            isVerified = true;
                                            currentPinError = null;
                                          });
                                        } else {
                                          setSheetState(() {
                                            isVerifying = false;
                                            currentPinError = 'PIN yang Anda masukkan salah. Silakan coba lagi.';
                                          });
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isVerifying ? AppColors.primary.withValues(alpha: 0.8) : AppColors.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: isVerifying
                                    ? const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            'Memverifikasi PIN Transaksi...',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                                          ),
                                        ],
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.verified_outlined, size: 16, color: Colors.white),
                                          SizedBox(width: 8),
                                          Text(
                                            'Verifikasi / Cek PIN',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            if (isVerifying) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFBFDBFE)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.security_rounded, size: 14, color: AppColors.primary),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Mengontak server enkripsi untuk memvalidasi PIN...',
                                        style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // STEP 2: INPUT PIN BARU (Terbuka jika isVerified == true)
                  if (isVerified) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                hasExistingPin ? Icons.pin_end_rounded : Icons.fiber_new_rounded,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  hasExistingPin ? '2. Masukkan & Konfirmasi PIN Baru' : 'Atur 6-Digit PIN Transaksi Baru',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // PIN Baru
                          const Text('PIN Baru (6 Digit Angka):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: newPinCtrl,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            obscureText: obscureNew,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: '••••••',
                              filled: true,
                              fillColor: Colors.white,
                              suffixIcon: IconButton(
                                icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, size: 18, color: AppColors.textMuted),
                                onPressed: () => setSheetState(() => obscureNew = !obscureNew),
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Konfirmasi PIN Baru
                          const Text('Konfirmasi PIN Baru:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: confirmPinCtrl,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            obscureText: obscureConfirm,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: '••••••',
                              filled: true,
                              fillColor: Colors.white,
                              suffixIcon: IconButton(
                                icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 18, color: AppColors.textMuted),
                                onPressed: () => setSheetState(() => obscureConfirm = !obscureConfirm),
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                            ),
                          ),

                          if (newPinError != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.error_outline, color: AppColors.dangerRed, size: 14),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    newPinError!,
                                    style: const TextStyle(color: AppColors.dangerRed, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tombol Save
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final newPin = newPinCtrl.text.trim();
                          final confirmPin = confirmPinCtrl.text.trim();

                          if (newPin.length != 6) {
                            setSheetState(() => newPinError = 'PIN baru harus terdiri dari tepat 6 digit angka.');
                            return;
                          }
                          if (newPin != confirmPin) {
                            setSheetState(() => newPinError = 'Konfirmasi PIN baru tidak cocok.');
                            return;
                          }
                          if (hasExistingPin && newPin == _savedPin) {
                            setSheetState(() => newPinError = 'PIN baru tidak boleh sama dengan PIN saat ini.');
                            return;
                          }

                          // Success save!
                          setState(() {
                            _savedPin = newPin;
                          });
                          Navigator.pop(sheetCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                hasExistingPin
                                    ? 'PIN Transaksi berhasil diubah dan disimpan!'
                                    : 'PIN Transaksi baru berhasil dibuat & diaktifkan!',
                              ),
                              backgroundColor: AppColors.successGreen,
                            ),
                          );
                        },
                        icon: const Icon(Icons.save_rounded, color: Colors.white),
                        label: Text(
                          hasExistingPin ? 'Simpan PIN Baru' : 'Simpan & Aktifkan PIN',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
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
                    onTap: _showChangePasswordBottomSheet,
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _savedPin != null ? const Color(0xFFEFF6FF) : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _savedPin != null ? Icons.pin_outlined : Icons.shield_outlined,
                        color: _savedPin != null ? AppColors.primary : AppColors.dangerRed,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      _savedPin != null ? 'Ubah PIN Transaksi' : 'Buat PIN Transaksi Baru',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                    ),
                    subtitle: Text(
                      _savedPin != null
                          ? 'PIN Aktif (6-digit) • Klik untuk verifikasi & ubah'
                          : 'Belum Diatur • Wajib untuk transaksi & keamanan dompet',
                      style: TextStyle(
                        fontSize: 11,
                        color: _savedPin != null ? AppColors.textMuted : AppColors.dangerRed,
                        fontWeight: _savedPin != null ? FontWeight.normal : FontWeight.w600,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _savedPin != null ? const Color(0xFFEFF6FF) : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _savedPin != null ? 'Aktif' : 'Belum Ada',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _savedPin != null ? AppColors.primary : AppColors.dangerRed,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
                      ],
                    ),
                    onTap: _showChangePinBottomSheet,
                  ),
                  if (_savedPin != null) ...[
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Simulasi Pengujian PIN:',
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _savedPin = null;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('PIN di-reset: aplikasi sekarang dalam mode belum pernah membuat PIN.'),
                                  backgroundColor: AppColors.primary,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            child: const Text(
                              'Hapus PIN (Uji Alur Buat Baru)',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.dangerRed),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Simulasi Pengujian PIN:',
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _savedPin = '123456';
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('PIN diatur ke default 123456: siap untuk uji verifikasi & ubah PIN.'),
                                  backgroundColor: AppColors.primary,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            child: const Text(
                              'Pasang Default 123456 (Uji Alur Ubah PIN)',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
