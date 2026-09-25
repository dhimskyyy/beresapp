import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

    context.read<AuthBloc>().add(
      TukangRegisterRequestedEvent(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        birthDate: _birthDate!.toIso8601String().split('T')[0],
        age: _age,
        services: _selectedServices,
        payoutAccounts: const [],
        ktpPath: '',
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
          if (state is TukangAuthenticatedState) {
            context.read<AuthBloc>().add(SignOutRequestedEvent());
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pendaftaran berhasil dikirim. Silakan login setelah akun disetujui admin.'),
                backgroundColor: AppColors.successGreen,
              ),
            );
          } else if (state is AuthFailureState) {
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
                if (_currentStep < 1) {
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
                            _currentStep == 1 ? 'Kirim Pendaftaran' : 'Lanjut',
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
                        decoration: const InputDecoration(labelText: 'Nama Lengkap', prefixIcon: Icon(Icons.person)),
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
                  isVerified ? 'Akun Mitra Terverifikasi!' : 'Pendaftaran Anda Sedang Ditinjau Admin',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  isVerified
                      ? 'Selamat, pendaftaran Anda telah disetujui Admin. Anda sudah bisa mulai menerima order pekerjaan.'
                      : 'Terima kasih ${tukang.name}. Data pendaftaran dan keahlian Anda sedang ditinjau Admin Beres.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    if (isVerified) {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    } else {
                      context.read<AuthBloc>().add(SignOutRequestedEvent());
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: Text(
                    isVerified ? 'Masuk ke Dashboard Mitra' : 'Keluar / Refresh Status',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
