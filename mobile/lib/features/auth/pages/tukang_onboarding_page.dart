import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/service_categories.dart';
import '../../../data/models/tukang_model.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class TukangOnboardingPage extends StatefulWidget {
  const TukangOnboardingPage({super.key});

  @override
  State<TukangOnboardingPage> createState() => _TukangOnboardingPageState();
}

class _TukangOnboardingPageState extends State<TukangOnboardingPage> {
  int _currentStep = 0;

  // Step 1: Personal Info
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  DateTime? _birthDate;
  int _age = 0;

  // Step 2: Keahlian (Multi-select)
  final List<String> _selectedServices = [];

  // Step 3: Payout Accounts
  final List<PayoutAccount> _payoutAccounts = [];
  String _selectedProviderType = 'bank';
  String _selectedProvider = 'BCA';
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();

  // Step 4: KTP Upload
  XFile? _ktpFile;
  final ImagePicker _picker = ImagePicker();

  void _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    setState(() {
      _birthDate = birthDate;
      _age = age;
    });
  }

  Future<void> _pickKtp(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        setState(() {
          _ktpFile = picked;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil gambar: $e')),
      );
    }
  }

  void _addPayoutAccount() {
    if (_accountNumberController.text.isEmpty || _accountNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi nomor dan nama pemilik rekening')),
      );
      return;
    }

    setState(() {
      _payoutAccounts.add(
        PayoutAccount(
          type: _selectedProviderType,
          provider: _selectedProvider,
          accountNumber: _accountNumberController.text.trim(),
          accountName: _accountNameController.text.trim(),
        ),
      );
      _accountNumberController.clear();
      _accountNameController.clear();
    });
  }

  void _submitOnboarding() {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Isi biodata diri lengkap')));
      return;
    }
    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih tanggal lahir Anda')));
      return;
    }
    if (_selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih minimal 1 keahlian')));
      return;
    }
    if (_payoutAccounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tambahkan minimal 1 rekening payout')));
      return;
    }
    if (_ktpFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unggah foto KTP Anda')));
      return;
    }

    context.read<AuthBloc>().add(
      TukangRegisterRequestedEvent(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        birthDate: _birthDate!.toIso8601String().split('T')[0],
        age: _age,
        services: _selectedServices,
        payoutAccounts: _payoutAccounts,
        ktpPath: _ktpFile!.path,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pendaftaran Beres Mitra'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailureState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.dangerRed),
            );
          }
        },
        builder: (context, state) {
          if (state is AuthLoadingState) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('Mengirim data pendaftaran Mitra...', style: TextStyle(color: AppColors.textMuted)),
                ],
              ),
            );
          }

          if (state is TukangAuthenticatedState) {
            final t = state.tukang;
            return _buildVerificationPendingView(t);
          }

          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(primary: AppColors.primary),
            ),
            child: Stepper(
              type: StepperType.horizontal,
              currentStep: _currentStep,
              onStepContinue: () {
                if (_currentStep < 3) {
                  setState(() => _currentStep++);
                } else {
                  _submitOnboarding();
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep--);
                }
              },
              controlsBuilder: (context, details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: details.onStepContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            _currentStep == 3 ? 'Kirim Pendaftaran' : 'Lanjut',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      if (_currentStep > 0) ...[
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: details.onStepCancel,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Kembali'),
                        ),
                      ]
                    ],
                  ),
                );
              },
              steps: [
                // Step 1: Biodata Diri
                Step(
                  title: const Text('Biodata'),
                  isActive: _currentStep >= 0,
                  content: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Nama Lengkap (Sesuai KTP)', prefixIcon: Icon(Icons.person)),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Nomor WhatsApp / HP', prefixIcon: Icon(Icons.phone)),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Kata Sandi', prefixIcon: Icon(Icons.lock)),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        tileColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        leading: const Icon(Icons.calendar_month, color: AppColors.primary),
                        title: Text(
                          _birthDate == null
                              ? 'Pilih Tanggal Lahir'
                              : '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year} (Usia: $_age Tahun)',
                          style: TextStyle(
                            fontWeight: _birthDate == null ? FontWeight.normal : FontWeight.bold,
                            color: _birthDate == null ? AppColors.textMuted : AppColors.textDark,
                          ),
                        ),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime(1990),
                            firstDate: DateTime(1950),
                            lastDate: DateTime.now().subtract(const Duration(days: 365 * 17)),
                          );
                          if (picked != null) _calculateAge(picked);
                        },
                      ),
                    ],
                  ),
                ),

                // Step 2: Keahlian (Multi-select)
                Step(
                  title: const Text('Keahlian'),
                  isActive: _currentStep >= 1,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pilih Keahlian Layanan (Bisa Lebih Dari 1):',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ServiceCategories.all.map((cat) {
                          final isSelected = _selectedServices.contains(cat.id);
                          return FilterChip(
                            selected: isSelected,
                            avatar: Icon(cat.icon, size: 18, color: isSelected ? Colors.white : AppColors.primary),
                            label: Text(cat.name),
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textDark,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  _selectedServices.add(cat.id);
                                } else {
                                  _selectedServices.remove(cat.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                // Step 3: Payout Accounts
                Step(
                  title: const Text('Rekening'),
                  isActive: _currentStep >= 2,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tambahkan Rekening Bank / E-Wallet Pencairan:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedProviderType,
                              items: const [
                                DropdownMenuItem(value: 'bank', child: Text('Bank Transfer')),
                                DropdownMenuItem(value: 'ewallet', child: Text('E-Wallet')),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  _selectedProviderType = val!;
                                  _selectedProvider = val == 'bank' ? 'BCA' : 'DANA';
                                });
                              },
                              decoration: const InputDecoration(labelText: 'Tipe Account'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedProvider,
                              items: (_selectedProviderType == 'bank'
                                      ? ['BCA', 'BRI', 'BNI', 'MANDIRI']
                                      : ['DANA', 'GOPAY', 'OVO', 'SHOPEEPAY'])
                                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                                  .toList(),
                              onChanged: (val) => setState(() => _selectedProvider = val!),
                              decoration: const InputDecoration(labelText: 'Penyedia'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _accountNumberController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Nomor Rekening / No. HP E-Wallet'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _accountNameController,
                        decoration: const InputDecoration(labelText: 'Nama Pemilik Rekening'),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _addPayoutAccount,
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah Rekening'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryLight),
                      ),
                      const SizedBox(height: 16),
                      if (_payoutAccounts.isNotEmpty) ...[
                        const Text('Daftar Rekening Tersimpan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 8),
                        ..._payoutAccounts.map((acc) => Card(
                              margin: const EdgeInsets.only(bottom: 6),
                              child: ListTile(
                                dense: true,
                                title: Text('${acc.provider} - ${acc.accountNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('a.n ${acc.accountName}'),
                              ),
                            )),
                      ]
                    ],
                  ),
                ),

                // Step 4: KTP Upload
                Step(
                  title: const Text('Upload KTP'),
                  isActive: _currentStep >= 3,
                  content: Column(
                    children: [
                      const Text(
                        'Unggah Foto KTP Asli untuk Verifikasi Keamanan Admin',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border, width: 2),
                        ),
                        child: _ktpFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.file(File(_ktpFile!.path), fit: BoxFit.cover),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.badge_outlined, size: 48, color: AppColors.textMuted),
                                  SizedBox(height: 8),
                                  Text('Foto KTP Belum Diunggah', style: TextStyle(color: AppColors.textMuted)),
                                ],
                              ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pickKtp(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Ambil Kamera'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pickKtp(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Dari Galeri'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVerificationPendingView(TukangModel tukang) {
    final isVerified = tukang.verificationStatus == 'verified';

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isVerified ? Icons.verified : Icons.hourglass_top_rounded,
                  size: 64,
                  color: isVerified ? AppColors.successGreen : AppColors.safetyAmber,
                ),
                const SizedBox(height: 16),
                Text(
                  isVerified ? 'Akun Mitra Terverifikasi!' : 'Dokumen Anda Sedang Ditinjau Admin',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  isVerified
                      ? 'Selamat, KTP Anda telah disetujui Admin. Anda sudah bisa menerima order.'
                      : 'Terima kasih ${tukang.name}. KTP dan data keahlian Anda sedang ditinjau Admin Beres. Begitu disetujui, Anda siap menerima tiket pekerjaan.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    context.read<AuthBloc>().add(SignOutRequestedEvent());
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('Keluar / Refresh Status', style: TextStyle(color: Colors.white)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
