import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/constants/app_colors.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/auth/bloc/auth_state.dart';
import 'features/auth/pages/user_login_page.dart';
import 'features/auth/pages/user_register_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BeresUserApp());
}

class BeresUserApp extends StatelessWidget {
  const BeresUserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => AuthRepositoryImpl(),
      child: BlocProvider(
        create: (context) => AuthBloc(
          authRepository: context.read<AuthRepositoryImpl>(),
        )..add(CheckAuthStatusEvent()),
        child: MaterialApp(
          title: 'Beres - Pencari Tukang',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primaryColor: AppColors.primary,
            scaffoldBackgroundColor: AppColors.background,
            fontFamily: 'Roboto',
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              primary: AppColors.primary,
            ),
          ),
          routes: {
            '/': (context) => const UserMainRouter(),
            '/user-login': (context) => const UserLoginPage(),
            '/user-register': (context) => const UserRegisterPage(),
          },
        ),
      ),
    );
  }
}

class UserMainRouter extends StatelessWidget {
  const UserMainRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is UserAuthenticatedState) {
          final user = state.user;
          return Scaffold(
            appBar: AppBar(
              title: const Text('Beres User'),
              backgroundColor: AppColors.primary,
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
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Halo, ${user.name}!',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(user.email, style: const TextStyle(color: AppColors.textMuted)),
                  const SizedBox(height: 24),
                  const Card(
                    margin: EdgeInsets.all(16),
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Pilihan 10 Kategori Layanan Siap Dipesan:\n• AC  • Cleaning  • Elektronik  • Las\n• Bangunan  • Besi & Baja  • Bengkel Motor\n• Bengkel Mobil  • Pengrajin Kayu  • Plumbing',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        }

        return const UserLoginPage();
      },
    );
  }
}
