import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/service_categories.dart';
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
import 'features/user/pages/create_ticket_page.dart';
import 'features/user/pages/live_tracking_page.dart';
import 'features/user/pages/ticket_bids_page.dart';
import 'features/user/pages/user_profile_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
    return BlocBuilder<AuthBloc, AuthState>(
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

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    context.read<TicketBloc>().add(FetchUserTicketsEvent(_currentUser.id));
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

                  return const Center(child: CircularProgressIndicator());
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
// TAB 2: User Tickets / Orders Page
// -----------------------------------------------------------------------------
class UserTicketsPage extends StatelessWidget {
  final UserModel user;
  const UserTicketsPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesanan & Tiket Saya', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocBuilder<TicketBloc, TicketState>(
        builder: (context, state) {
          if (state is TicketListLoadedState) {
            final tickets = state.tickets;
            if (tickets.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    const Text('Belum Ada Riwayat Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    const Text('Buat tiket pesanan jasa tukang pertama Anda.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/create-ticket'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      child: const Text('Buat Pesanan Baru', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tickets.length,
              itemBuilder: (context, idx) {
                final ticket = tickets[idx];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.bgAC,
                      child: Icon(
                        ServiceCategories.getIconForCategory(ticket.category),
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(ticket.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Kategori: ${ticket.category.toUpperCase()}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        const SizedBox(height: 2),
                        Text('Status: ${ticket.status.label}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      if (ticket.status == TicketStatus.open || ticket.status == TicketStatus.bidding) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => TicketBidsPage(ticket: ticket)));
                      } else {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => LiveTrackingPage(ticket: ticket)));
                      }
                    },
                  ),
                );
              },
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 3: User Chat List Page
// -----------------------------------------------------------------------------
class UserChatListPage extends StatelessWidget {
  final UserModel user;
  const UserChatListPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Pesan & Chat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocBuilder<TicketBloc, TicketState>(
        builder: (context, state) {
          if (state is! TicketListLoadedState || state.tickets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded, size: 64, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  const Text('Belum Ada Percakapan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  const Text('Percakapan dengan tukang akan otomatis muncul di sini saat pesanan aktif.', style: TextStyle(color: AppColors.textMuted, fontSize: 12), textAlign: TextAlign.center),
                ],
              ),
            );
          }

          final tickets = state.tickets;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tickets.length,
            itemBuilder: (context, idx) {
              final ticket = tickets[idx];
              final tradesmanName = ticket.selectedTukangName ?? 'Mitra (${ticket.category.toUpperCase()})';
              final lastMsg = ticket.status == TicketStatus.completed
                  ? 'Pekerjaan telah selesai. Terima kasih!'
                  : (ticket.status == TicketStatus.inProgress
                      ? 'Tukang sedang mengerjakan pesanan...'
                      : 'Tiket aktif: ${ticket.title}');

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)],
                ),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primaryLight,
                      child: Icon(
                        ServiceCategories.getIconForCategory(ticket.category),
                        color: Colors.white,
                      ),
                    ),
                    title: Text(tradesmanName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(lastMsg, style: const TextStyle(fontSize: 12, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            ticket.status.label,
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(
                            ticket: ticket,
                            currentUserId: user.id,
                            currentUserRole: 'user',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
