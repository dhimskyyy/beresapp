import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/constants/app_colors.dart';
import 'data/models/tukang_model.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/ticket_repository_impl.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/auth/bloc/auth_state.dart';
import 'features/auth/pages/tukang_login_page.dart';
import 'features/auth/pages/tukang_onboarding_page.dart';
import 'features/ticket/bloc/ticket_bloc.dart';
import 'features/ticket/bloc/ticket_event.dart';
import 'features/ticket/bloc/ticket_state.dart';
import 'features/tukang/pages/mitra_active_job_page.dart';
import 'features/tukang/pages/mitra_job_feed_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BeresMitraApp());
}

class BeresMitraApp extends StatelessWidget {
  const BeresMitraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => AuthRepositoryImpl()),
        RepositoryProvider(create: (context) => TicketRepositoryImpl()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthBloc(
              authRepository: context.read<AuthRepositoryImpl>(),
            )..add(CheckAuthStatusEvent()),
          ),
          BlocProvider(
            create: (context) => TicketBloc(
              ticketRepository: context.read<TicketRepositoryImpl>(),
            ),
          ),
        ],
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

          return MitraBottomNavWrapper(tukang: t);
        }

        return const TukangLoginPage();
      },
    );
  }
}

class MitraBottomNavWrapper extends StatefulWidget {
  final TukangModel tukang;
  const MitraBottomNavWrapper({super.key, required this.tukang});

  @override
  State<MitraBottomNavWrapper> createState() => _MitraBottomNavWrapperState();
}

class _MitraBottomNavWrapperState extends State<MitraBottomNavWrapper> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<TicketBloc>().add(FetchTukangActiveTicketsEvent(widget.tukang.id));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TicketBloc, TicketState>(
      builder: (context, state) {
        return Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              MitraJobFeedPage(tukang: widget.tukang),
              BlocBuilder<TicketBloc, TicketState>(
                builder: (context, tState) {
                  if (tState is TicketListLoadedState && tState.tickets.isNotEmpty) {
                    final active = tState.tickets.first;
                    return MitraActiveJobPage(ticket: active, tukang: widget.tukang);
                  }
                  return Scaffold(
                    appBar: AppBar(title: const Text('Pengerjaan Aktif'), backgroundColor: AppColors.textDark, foregroundColor: Colors.white),
                    body: const Center(child: Text('Belum ada pengerjaan tiket terpilih saat ini.', style: TextStyle(color: AppColors.textMuted))),
                  );
                },
              ),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            selectedItemColor: AppColors.textDark,
            unselectedItemColor: AppColors.textMuted,
            onTap: (idx) => setState(() => _selectedIndex = idx),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.radar), label: 'Radar Job'),
              BottomNavigationBarItem(icon: Icon(Icons.engineering), label: 'Pengerjaan Aktif'),
            ],
          ),
        );
      },
    );
  }
}
