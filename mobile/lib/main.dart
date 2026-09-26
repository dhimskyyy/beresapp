import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/service_categories.dart';
import 'core/services/supabase_storage_service.dart';
import 'core/widgets/app_state_view.dart';
import 'core/widgets/gps_requirement_dialog.dart';
import 'data/models/ticket_model.dart';
import 'data/models/user_model.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/chat_repository_impl.dart';
import 'data/repositories/payment_repository_impl.dart';
import 'data/repositories/ticket_repository_impl.dart';
import 'domain/entities/ticket_status.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/auth/bloc/auth_state.dart';
import 'features/auth/pages/user_login_page.dart';
import 'features/auth/pages/user_register_page.dart';
import 'features/chat/bloc/chat_bloc.dart';
import 'features/chat/pages/chat_page.dart';
import 'features/payment/bloc/payment_bloc.dart';
import 'features/ticket/bloc/ticket_bloc.dart';
import 'features/ticket/bloc/ticket_event.dart';
import 'features/ticket/bloc/ticket_state.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'features/payment/pages/user_rating_modal.dart';
import 'features/user/pages/create_ticket_page.dart';
import 'features/user/pages/live_tracking_page.dart';
import 'features/user/pages/ticket_bids_page.dart';
import 'features/user/pages/user_profile_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization note: $e');
  }
  try {
    await initializeDateFormatting('id_ID', null);
  } catch (e) {
    debugPrint('Date formatting initialization note: $e');
  }
  try {
    await SupabaseStorageService.init();
  } catch (e) {
    debugPrint('Supabase storage initialization note: $e');
  }
  runApp(const BeresUserApp());
}

class BeresUserApp extends StatelessWidget {
  const BeresUserApp({super.key});

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
          title: 'Beres - Solusi Jasa Tukang',
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
            '/create-ticket': (context) => const CreateTicketPage(),
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
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        // Jika akun Tukang terdeteksi aktif saat membuka User app, sign out agar sesi bersih
        if (state is TukangAuthenticatedState) {
          context.read<AuthBloc>().add(SignOutRequestedEvent());
        }
      },
      builder: (context, state) {
        if (state is UserAuthenticatedState) {
          return UserBottomNavWrapper(user: state.user);
        }
        return const UserLoginPage();
      },
    );
  }
}

class UserBottomNavWrapper extends StatefulWidget {
  final UserModel user;
  const UserBottomNavWrapper({super.key, required this.user});

  @override
  State<UserBottomNavWrapper> createState() => _UserBottomNavWrapperState();
}

class _UserBottomNavWrapperState extends State<UserBottomNavWrapper> {
  int _selectedIndex = 0;
  late UserModel _currentUser;
  StreamSubscription? _userTicketsSub;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    context.read<TicketBloc>().add(FetchUserTicketsEvent(_currentUser.id));
    _userTicketsSub = FirebaseFirestore.instance
        .collection('tickets')
        .where('userId', isEqualTo: _currentUser.id)
        .snapshots()
        .listen((_) {
      if (mounted) {
        context.read<TicketBloc>().add(FetchUserTicketsEvent(_currentUser.id));
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GpsRequirementDialog.checkAndShow(context, isTukang: false);
    });
  }

  @override
  void dispose() {
    _userTicketsSub?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(UserBottomNavWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.user != oldWidget.user) {
      setState(() {
        _currentUser = widget.user;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      UserHomePage(
        user: _currentUser,
        onNavigateToTicket: () => setState(() => _selectedIndex = 1),
        onNavigateToProfile: () => setState(() => _selectedIndex = 3),
      ),
      UserTicketsPage(user: _currentUser),
      UserChatListPage(user: _currentUser),
      UserProfilePage(
        user: _currentUser,
        onNavigateToOrders: () => setState(() => _selectedIndex = 1),
        onUserUpdated: (updatedUser) {
          setState(() {
            _currentUser = updatedUser;
          });
        },
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            )
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          onTap: (idx) => setState(() => _selectedIndex = idx),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Beranda'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Pesanan'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline_rounded), label: 'Pesan'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profil'),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 1: User Home Page (Modern Dashboard UI/UX)
// -----------------------------------------------------------------------------
class UserHomePage extends StatelessWidget {
  final UserModel user;
  final VoidCallback onNavigateToTicket;
  final VoidCallback? onNavigateToProfile;

  const UserHomePage({
    super.key,
    required this.user,
    required this.onNavigateToTicket,
    this.onNavigateToProfile,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: SafeArea(
          top: true,
          bottom: true,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Modern Header with Location Pill & Profile Avatar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Halo, ${user.name} 👋',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => _showLocationSelector(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.bgAC,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.location_on, size: 14, color: AppColors.primary),
                                SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Jl. Wijaya II No. 18, Kebayoran Baru',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(Icons.keyboard_arrow_down, size: 14, color: AppColors.primary),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
                          ],
                        ),
                        child: Stack(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textDark),
                              onPressed: () => _showUserNotificationCenter(context),
                            ),
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.dangerRed,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onNavigateToProfile,
                        child: CircleAvatar(
                          radius: 19,
                          backgroundColor: AppColors.primary,
                          backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                              ? (user.photoUrl!.startsWith('http')
                                  ? NetworkImage(user.photoUrl!) as ImageProvider
                                  : FileImage(File(user.photoUrl!)))
                              : null,
                          child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                              ? Text(
                                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Service Banner Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.safetyAmber,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('LAYANAN TERPERCAYA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Butuh Perbaikan Rumah?',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Panggil Tukang Berpengalaman Terdekat Hanya Dalam 5 Menit.',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 11),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => Navigator.pushNamed(context, '/create-ticket'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            child: const Text('Buat Pesanan Custom +', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.home_repair_service_rounded, size: 72, color: Colors.white24),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Category Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Layanan Utama', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/create-ticket'),
                    child: const Text('Lihat Semua', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 10 Service Categories Grid (Modern UI)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.78,
                ),
                itemCount: ServiceCategories.all.length,
                itemBuilder: (context, index) {
                  final cat = ServiceCategories.all[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateTicketPage(initialCategory: cat.id),
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        Container(
                          height: 52,
                          width: 52,
                          decoration: BoxDecoration(
                            color: cat.backgroundColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 3)),
                            ],
                          ),
                          child: Icon(cat.icon, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          cat.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textDark),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Active Orders Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Status Tiket Pekerjaan Aktif', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  TextButton(
                    onPressed: onNavigateToTicket,
                    child: const Text('Riwayat →', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              BlocBuilder<TicketBloc, TicketState>(
                builder: (context, ticketState) {
                  if (ticketState is TicketLoadingState) {
                    return const AppLoadingView(message: 'Memuat tiket aktif...');
                  }

                  if (ticketState is TicketOperationFailureState) {
                    return AppErrorView(
                      message: ticketState.message,
                      onRetry: () => context.read<TicketBloc>().add(FetchUserTicketsEvent(user.id)),
                    );
                  }

                  if (ticketState is TicketListLoadedState) {
                    final tickets = ticketState.tickets;
                    if (tickets.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.assignment_outlined, size: 36, color: AppColors.textMuted),
                            SizedBox(height: 8),
                            Text('Belum ada tiket pekerjaan aktif', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            SizedBox(height: 2),
                            Text('Pilih salah satu kategori layanan di atas untuk memanggil tukang.', style: TextStyle(fontSize: 12, color: AppColors.textMuted), textAlign: TextAlign.center),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: tickets.length,
                      itemBuilder: (context, idx) {
                        final ticket = tickets[idx];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            clipBehavior: Clip.antiAlias,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.bgAC,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.build_rounded, color: AppColors.primary),
                              ),
                              title: Text(ticket.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(ticket.status.label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('${ticket.bids.length} penawaran', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                              onTap: () {
                                if (ticket.status == TicketStatus.open || ticket.status == TicketStatus.bidding) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TicketBidsPage(ticket: ticket),
                                    ),
                                  );
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => LiveTrackingPage(ticket: ticket),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        );
                      },
                    );
                  }

                  return AppErrorView(
                    message: 'Gagal memuat status tiket pekerjaan.',
                    onRetry: () => context.read<TicketBloc>().add(FetchUserTicketsEvent(user.id)),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  void _showLocationSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.location_on, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Pilih Alamat Pekerjaan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(backgroundColor: AppColors.bgAC, child: Icon(Icons.home, color: AppColors.primary)),
              title: const Text('Rumah (Alamat Utama)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: const Text('Jl. Wijaya II No. 18, Kebayoran Baru, Jakarta Selatan', style: TextStyle(fontSize: 11)),
              trailing: const Icon(Icons.check_circle, color: AppColors.successGreen),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Alamat lokasi aktif: Rumah (Utama)')),
                );
              },
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: AppColors.bgAC, child: Icon(Icons.business, color: AppColors.primary)),
              title: const Text('Kantor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: const Text('Gedung Menara Mandiri Lt. 12, Senayan, Jakarta Selatan', style: TextStyle(fontSize: 11)),
              trailing: const Icon(Icons.radio_button_unchecked, color: AppColors.textMuted),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Alamat lokasi aktif: Kantor')),
                );
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, '/create-ticket');
                },
                icon: const Icon(Icons.add_location_alt_outlined),
                label: const Text('Gunakan Alamat Kustom di Tiket Baru'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserNotificationCenter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DefaultTabController(
        length: 2,
        child: Container(
          height: MediaQuery.of(ctx).size.height * 0.75,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.notifications_active_rounded, color: AppColors.primary, size: 24),
                      SizedBox(width: 8),
                      Text('Notifikasi Pesanan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.bgAC,
                            child: Icon(Icons.engineering_rounded, color: AppColors.primary),
                          ),
                          title: const Text('Tukang Menuju Lokasi Anda', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: const Text('Pak Budi (AC) sedang dalam perjalanan. Perkiraan sampai 15 menit lagi.', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          trailing: const Text('10:42', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                          onTap: () {
                            Navigator.pop(ctx);
                            onNavigateToTicket();
                          },
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFDCFCE7),
                            child: Icon(Icons.handyman_rounded, color: AppColors.successGreen),
                          ),
                          title: const Text('Penawaran Baru Masuk!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: const Text('Mitra telah mengajukan penawaran untuk pesanan perbaikan pompa air Anda.', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          trailing: const Text('Kemarin', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                          onTap: () {
                            Navigator.pop(ctx);
                            onNavigateToTicket();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 2: User Tickets / Orders Page (Modernized)
// -----------------------------------------------------------------------------
class UserTicketsPage extends StatefulWidget {
  final UserModel user;
  const UserTicketsPage({super.key, required this.user});

  @override
  State<UserTicketsPage> createState() => _UserTicketsPageState();
}

class _UserTicketsPageState extends State<UserTicketsPage> {
  int _selectedFilterIndex = 0; // 0: Semua, 1: Berjalan, 2: Selesai, 3: Batal

  final _currency = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  Color _getStatusColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
      case TicketStatus.bidding:
        return const Color(0xFFD97706); // Amber
      case TicketStatus.locked:
      case TicketStatus.onTheWay:
        return const Color(0xFF2563EB); // Blue
      case TicketStatus.arrived:
      case TicketStatus.inProgress:
        return const Color(0xFFEA580C); // Orange
      case TicketStatus.workCompleted:
      case TicketStatus.paymentPending:
        return const Color(0xFF7C3AED); // Purple
      case TicketStatus.completed:
        return const Color(0xFF16A34A); // Green
      case TicketStatus.canceled:
        return const Color(0xFFDC2626); // Red
    }
  }

  Color _getStatusBgColor(TicketStatus status) {
    return _getStatusColor(status).withValues(alpha: 0.12);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Pesanan & Tiket Saya', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh Pesanan',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: () {
              context.read<TicketBloc>().add(FetchUserTicketsEvent(widget.user.id));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Memperbarui data pesanan...'), duration: Duration(seconds: 1)),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<TicketBloc, TicketState>(
        builder: (context, state) {
          if (state is TicketLoadingState) {
            return const AppLoadingView(message: 'Memuat riwayat pesanan...');
          }

          if (state is TicketOperationFailureState) {
            return AppErrorView(
              message: state.message,
              onRetry: () => context.read<TicketBloc>().add(FetchUserTicketsEvent(widget.user.id)),
            );
          }

          if (state is TicketListLoadedState) {
            final allTickets = state.tickets;

            // Filter logic
            final runningTickets = allTickets.where((t) =>
                t.status != TicketStatus.completed && t.status != TicketStatus.canceled).toList();
            final completedTickets = allTickets.where((t) => t.status == TicketStatus.completed).toList();
            final canceledTickets = allTickets.where((t) => t.status == TicketStatus.canceled).toList();

            List<TicketModel> displayedTickets;
            switch (_selectedFilterIndex) {
              case 1:
                displayedTickets = runningTickets;
                break;
              case 2:
                displayedTickets = completedTickets;
                break;
              case 3:
                displayedTickets = canceledTickets;
                break;
              default:
                displayedTickets = allTickets;
                break;
            }

            return Column(
              children: [
                // Filter Tabs Header
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(0, 'Semua', allTickets.length),
                        const SizedBox(width: 8),
                        _buildFilterChip(1, 'Sedang Berjalan', runningTickets.length, activeColor: const Color(0xFF2563EB)),
                        const SizedBox(width: 8),
                        _buildFilterChip(2, 'Selesai', completedTickets.length, activeColor: const Color(0xFF16A34A)),
                        const SizedBox(width: 8),
                        _buildFilterChip(3, 'Dibatalkan', canceledTickets.length, activeColor: const Color(0xFFDC2626)),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),

                // Ticket Cards List
                Expanded(
                  child: displayedTickets.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: () async {
                            context.read<TicketBloc>().add(FetchUserTicketsEvent(widget.user.id));
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: displayedTickets.length,
                            itemBuilder: (context, idx) {
                              final ticket = displayedTickets[idx];
                              return _buildModernTicketCard(context, ticket);
                            },
                          ),
                        ),
                ),
              ],
            );
          }

          return AppErrorView(
            message: 'Terjadi kesalahan saat memuat tiket pesanan.',
            onRetry: () => context.read<TicketBloc>().add(FetchUserTicketsEvent(widget.user.id)),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(int index, String label, int count, {Color activeColor = AppColors.primary}) {
    final isSelected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilterIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? activeColor : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textDark,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String title = 'Belum Ada Tiket Pesanan';
    String desc = 'Pesan tukang panggilan pertama Anda dengan cepat & aman.';
    if (_selectedFilterIndex == 1) {
      title = 'Tidak Ada Pekerjaan Aktif';
      desc = 'Semua pesanan perbaikan rumah Anda saat ini telah selesai atau belum dibuat.';
    } else if (_selectedFilterIndex == 2) {
      title = 'Belum Ada Riwayat Selesai';
      desc = 'Pesanan yang telah diselesaikan teknisi akan tercatat rapi di sini.';
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long_rounded, size: 56, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
            const SizedBox(height: 6),
            Text(desc, style: const TextStyle(color: AppColors.textMuted, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/create-ticket'),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Buat Pesanan Baru', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTicketCard(BuildContext context, TicketModel ticket) {
    final statusColor = _getStatusColor(ticket.status);
    final statusBgColor = _getStatusBgColor(ticket.status);
    String formattedDate;
    try {
      formattedDate = DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(ticket.createdAt);
    } catch (_) {
      formattedDate = DateFormat('d MMM yyyy, HH:mm').format(ticket.createdAt);
    }

    final hasTukang = ticket.selectedTukangName != null && ticket.selectedTukangName!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Category Icon + ID + Status Pill
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    ServiceCategories.getIconForCategory(ticket.category),
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ServiceCategories.findById(ticket.category)?.name ?? ticket.category,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5),
                      ),
                      Text(
                        '#${ticket.id}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textDark),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(
                        ticket.status.label,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: statusColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Body: Title, Address, Date
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket.title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined, size: 15, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        ticket.address,
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      formattedDate,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),

                // Assigned Tukang Info (if any)
                if (hasTukang) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.textDark,
                          child: const Icon(Icons.person, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ticket.selectedTukangName!,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                              ),
                              const Text('Teknisi Mitra Terverifikasi', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                              SizedBox(width: 2),
                              Text('4.9', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Price / Cost Summary
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ticket.finalBill != null ? 'Total Kesepakatan:' : 'Estimasi Biaya:',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    Text(
                      ticket.finalBill != null
                          ? _currency.format(ticket.finalBill!.totalAmount)
                          : (ticket.bids.isNotEmpty
                              ? _currency.format(ticket.bids.first.estimatedPrice)
                              : 'Menunggu Penawaran'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Rating review pill if already rated
          if (ticket.status == TicketStatus.completed && ticket.ratingStars != null) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < ticket.ratingStars! ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 16,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ticket.ratingReview?.isNotEmpty == true ? '"${ticket.ratingReview}"' : 'Ulasan selesai',
                      style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.amber.shade900),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Action Buttons Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              children: [
                // If Bidding/Open
                if (ticket.status == TicketStatus.open || ticket.status == TicketStatus.bidding) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => TicketBidsPage(ticket: ticket)),
                        );
                      },
                      icon: const Icon(Icons.local_offer_outlined, size: 16),
                      label: Text('Lihat ${ticket.bids.length} Penawaran Masuk'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ]
                // If In Progress / En Route / Arrived / Working / PendingPayment
                else if (ticket.status != TicketStatus.completed && ticket.status != TicketStatus.canceled) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => LiveTrackingPage(ticket: ticket)),
                        );
                      },
                      icon: const Icon(Icons.navigation_rounded, size: 16),
                      label: const Text('Lacak GPS & Status'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Buka Chat',
                    icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Color(0xFFCBD5E1))),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(
                            ticket: ticket,
                            currentUserId: widget.user.id,
                            currentUserRole: 'user',
                          ),
                        ),
                      );
                    },
                  ),
                ]
                // If Completed
                else if (ticket.status == TicketStatus.completed) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        UserRatingModal.show(context, ticket, onSubmitted: () {
                          context.read<TicketBloc>().add(FetchUserTicketsEvent(widget.user.id));
                        });
                      },
                      icon: const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
                      label: Text(
                        ticket.ratingStars != null ? 'Ubah Penilaian Bintang' : 'Beri Ulasan Bintang',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Lihat Arsip Chat',
                    icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.textMuted),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Color(0xFFCBD5E1))),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(
                            ticket: ticket,
                            currentUserId: widget.user.id,
                            currentUserRole: 'user',
                          ),
                        ),
                      );
                    },
                  ),
                ]
                // If Canceled
                else ...[
                  const Expanded(
                    child: Text(
                      'Pesanan ini telah dibatalkan',
                      style: TextStyle(fontSize: 12, color: AppColors.dangerRed, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 3: User Chat List Page (Modernized)
// -----------------------------------------------------------------------------
class UserChatListPage extends StatefulWidget {
  final UserModel user;
  const UserChatListPage({super.key, required this.user});

  @override
  State<UserChatListPage> createState() => _UserChatListPageState();
}

class _UserChatListPageState extends State<UserChatListPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Pesan & Obrolan Mitra', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: BlocBuilder<TicketBloc, TicketState>(
        builder: (context, state) {
          if (state is TicketLoadingState) {
            return const AppLoadingView(message: 'Memuat percakapan...');
          }

          if (state is TicketOperationFailureState) {
            return AppErrorView(
              message: state.message,
              onRetry: () => context.read<TicketBloc>().add(FetchUserTicketsEvent(widget.user.id)),
            );
          }

          if (state is TicketListLoadedState) {
            if (state.tickets.isEmpty) {
              return const AppEmptyView(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Belum Ada Percakapan',
                subtitle: 'Ruang chat akan otomatis terbuka ketika pesanan Anda diambil oleh teknisi mitra.',
              );
            }

            var tickets = state.tickets;
          if (_searchQuery.isNotEmpty) {
            tickets = tickets.where((t) {
              final name = t.selectedTukangName ?? '';
              final title = t.title;
              return name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  title.toLowerCase().contains(_searchQuery.toLowerCase());
            }).toList();
          }

          return Column(
            children: [
              // Search Input
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'Cari percakapan / teknisi...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              // Chat List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: tickets.length,
                  itemBuilder: (context, idx) {
                    final ticket = tickets[idx];
                    final tradesmanName = ticket.selectedTukangName ?? 'Mitra (${ticket.category.toUpperCase()})';
                    final lastMsg = ticket.status == TicketStatus.completed
                        ? '✅ Pekerjaan telah selesai lunas.'
                        : (ticket.status == TicketStatus.inProgress
                            ? '🛠️ Mitra sedang melakukan servis pengerjaan...'
                            : (ticket.status == TicketStatus.onTheWay
                                ? '🛵 Mitra sedang menuju ke alamat Anda'
                                : '📋 Tiket: ${ticket.title}'));

                    final timeStr = DateFormat('HH:mm').format(ticket.updatedAt);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(0xFF0F172A),
                                child: Text(
                                  tradesmanName.isNotEmpty ? tradesmanName[0].toUpperCase() : 'M',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    ServiceCategories.getIconForCategory(ticket.category),
                                    color: Colors.white,
                                    size: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  tradesmanName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(timeStr, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text(
                                ticket.title,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                lastMsg,
                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              ticket.status.label,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatPage(
                                  ticket: ticket,
                                  currentUserId: widget.user.id,
                                  currentUserRole: 'user',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }

        return AppErrorView(
          message: 'Terjadi kesalahan saat memuat obrolan.',
          onRetry: () => context.read<TicketBloc>().add(FetchUserTicketsEvent(widget.user.id)),
        );
      },
    ),
  );
}
}
