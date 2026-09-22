import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/constants/app_colors.dart';
import 'data/models/ticket_model.dart';
import 'data/models/tukang_model.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/chat_repository_impl.dart';
import 'data/repositories/payment_repository_impl.dart';
import 'data/repositories/ticket_repository_impl.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/auth/bloc/auth_state.dart';
import 'features/auth/pages/tukang_login_page.dart';
import 'features/auth/pages/tukang_onboarding_page.dart';
import 'features/chat/bloc/chat_bloc.dart';
import 'features/payment/bloc/payment_bloc.dart';
import 'features/payment/pages/tukang_wallet_page.dart';
import 'features/ticket/bloc/ticket_bloc.dart';
import 'features/ticket/bloc/ticket_event.dart';
import 'features/ticket/bloc/ticket_state.dart';
import 'features/tukang/pages/mitra_active_job_page.dart';
import 'features/tukang/pages/mitra_chat_list_page.dart';
import 'features/tukang/pages/mitra_job_feed_page.dart';
import 'features/tukang/pages/mitra_job_history_page.dart';
import 'features/tukang/pages/tukang_profile_page.dart';

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
        RepositoryProvider(create: (context) => ChatRepositoryImpl()),
        RepositoryProvider(create: (context) => PaymentRepositoryImpl()),
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
          BlocProvider(
            create: (context) => ChatBloc(
              chatRepository: context.read<ChatRepositoryImpl>(),
            ),
          ),
          BlocProvider(
            create: (context) => PaymentBloc(
              paymentRepository: context.read<PaymentRepositoryImpl>(),
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

  Widget _buildNavIcon(IconData unselectedIcon, IconData selectedIcon, int index) {
    final isSelected = _selectedIndex == index;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.textDark.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        isSelected ? selectedIcon : unselectedIcon,
        color: isSelected ? AppColors.textDark : AppColors.textMuted,
        size: isSelected ? 23 : 21,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TicketBloc, TicketState>(
      builder: (context, state) {
        final pages = [
          MitraJobFeedPage(tukang: widget.tukang),
          MitraWorkManagementPage(
            tukang: widget.tukang,
            onGoToRadar: () => setState(() => _selectedIndex = 0),
          ),
          MitraChatListPage(tukang: widget.tukang),
          TukangWalletPage(tukang: widget.tukang),
          TukangProfilePage(tukang: widget.tukang),
        ];

        return Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: pages,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -3),
                )
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              selectedItemColor: AppColors.textDark,
              unselectedItemColor: AppColors.textMuted,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 10),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              elevation: 0,
              onTap: (idx) => setState(() => _selectedIndex = idx),
              items: [
                BottomNavigationBarItem(
                  icon: _buildNavIcon(Icons.radar_outlined, Icons.radar_rounded, 0),
                  label: 'Radar Job',
                ),
                BottomNavigationBarItem(
                  icon: _buildNavIcon(Icons.engineering_outlined, Icons.engineering_rounded, 1),
                  label: 'Pengerjaan',
                ),
                BottomNavigationBarItem(
                  icon: _buildNavIcon(Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, 2),
                  label: 'Chat',
                ),
                BottomNavigationBarItem(
                  icon: _buildNavIcon(Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded, 3),
                  label: 'Dompet',
                ),
                BottomNavigationBarItem(
                  icon: _buildNavIcon(Icons.person_outline_rounded, Icons.person_rounded, 4),
                  label: 'Profil',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class MitraWorkManagementPage extends StatefulWidget {
  final TukangModel tukang;
  final VoidCallback onGoToRadar;
  const MitraWorkManagementPage({super.key, required this.tukang, required this.onGoToRadar});

  @override
  State<MitraWorkManagementPage> createState() => _MitraWorkManagementPageState();
}

class _MitraWorkManagementPageState extends State<MitraWorkManagementPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TicketBloc, TicketState>(
      builder: (context, tState) {
        TicketModel? activeTicket;
        if (tState is TicketListLoadedState && tState.tickets.isNotEmpty) {
          // Find first in-flight ticket (not completed and not canceled)
          try {
            activeTicket = tState.tickets.firstWhere((t) => t.status.isActive);
          } catch (_) {
            activeTicket = null;
          }
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.textDark,
            foregroundColor: Colors.white,
            elevation: 0,
            title: const Text('Manajemen Pengerjaan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.safetyAmber,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_circle_outline, size: 16),
                      SizedBox(width: 6),
                      Text('Pekerjaan Aktif'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('Riwayat Selesai'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Active Job
              activeTicket != null
                  ? MitraActiveJobPage(ticket: activeTicket, tukang: widget.tukang)
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.textDark.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.engineering_outlined, size: 56, color: AppColors.textDark),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Belum Ada Pengerjaan Aktif',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textDark),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Silakan ajukan penawaran harga pada tab Radar Job untuk mengambil pesanan baru.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: widget.onGoToRadar,
                                  icon: const Icon(Icons.radar, size: 18, color: Colors.white),
                                  label: const Text('Buka Radar Job', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.textDark,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                OutlinedButton.icon(
                                  onPressed: () => _tabController.animateTo(1),
                                  icon: const Icon(Icons.history, size: 18, color: AppColors.textDark),
                                  label: const Text('Lihat Riwayat', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    side: const BorderSide(color: AppColors.border),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

              // Tab 2: History
              MitraJobHistoryPage(tukang: widget.tukang),
            ],
          ),
        );
      },
    );
  }
}

