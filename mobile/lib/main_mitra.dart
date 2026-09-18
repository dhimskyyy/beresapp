import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/constants/app_colors.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/auth/bloc/auth_state.dart';
import 'features/auth/pages/tukang_login_page.dart';
import 'features/auth/pages/tukang_onboarding_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BeresMitraApp());
}

class BeresMitraApp extends StatelessWidget {
  const BeresMitraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => AuthRepositoryImpl(),
      child: BlocProvider(
        create: (context) => AuthBloc(
          authRepository: context.read<AuthRepositoryImpl>(),
        )..add(CheckAuthStatusEvent()),
        child: MaterialApp(
          title: 'Beres Mitra - Aplikasi Tukang',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primaryColor: AppColors.textDark,
            scaffoldBackgroundColor: AppColors.background,
            fontFamily: 'Roboto',
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.textDark,
              primary: AppColors.textDark,
            ),
          ),
          routes: {
            '/': (context) => const MitraMainRouter(),
            '/tukang-login': (context) => const TukangLoginPage(),
            '/tukang-onboarding': (context) => const TukangOnboardingPage(),
          },
        ),
      ),
    );
  }
}

class MitraMainRouter extends StatelessWidget {
  const MitraMainRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is TukangAuthenticatedState) {
          final t = state.tukang;

          if (t.verificationStatus != 'verified') {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Status Verifikasi KTP'),
                backgroundColor: AppColors.textDark,
                foregroundColor: Colors.white,
              ),
              body: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.hourglass_top_rounded, size: 64, color: AppColors.safetyAmber),
                          const SizedBox(height: 16),
                          const Text(
                            'Dokumen KTP Sedang Ditinjau Admin',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Halo ${t.name}. KTP dan data keahlian (${t.services.join(', ')}) Anda sedang diperiksa oleh Admin Beres.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              context.read<AuthBloc>().add(SignOutRequestedEvent());
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.textDark),
                            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: const Text('Beres Mitra Dashboard'),
              backgroundColor: AppColors.textDark,
              foregroundColor: Colors.white,
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () {
                    context.read<AuthBloc>().add(SignOutRequestedEvent());
                  },
                )
              ],
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.textDark,
                    child: Text(
                      t.name.isNotEmpty ? t.name[0].toUpperCase() : 'M',
                      style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Mitra Aktif: ${t.name}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('Status: ${t.isOnline ? 'ONLINE' : 'OFFLINE'}', style: const TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: t.services.map((s) => Chip(label: Text(s.toUpperCase()))).toList(),
                  )
                ],
              ),
            ),
          );
        }

        return const TukangLoginPage();
      },
    );
  }
}
