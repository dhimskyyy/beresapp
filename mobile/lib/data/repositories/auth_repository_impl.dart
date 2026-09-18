import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';
import '../models/tukang_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  // In-memory mock storage for local testing when Firebase config is pending
  static final Map<String, UserModel> _mockUsers = {};
  static final Map<String, TukangModel> _mockTukangs = {};
  dynamic _currentUser;

  @override
  Future<UserModel> loginUserWithEmail(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final existing = _mockUsers.values.firstWhere(
      (u) => u.email.toLowerCase() == email.toLowerCase(),
      orElse: () => UserModel(
        id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
        name: email.split('@').first,
        email: email,
        phone: '081234567890',
        createdAt: DateTime.now(),
      ),
    );
    _currentUser = existing;
    return existing;
  }

  @override
  Future<UserModel> registerUserWithEmail(
    String name,
    String email,
    String phone,
    String password,
  ) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    final user = UserModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      phone: phone,
      createdAt: DateTime.now(),
    );
    _mockUsers[user.id] = user;
    _currentUser = user;
    return user;
  }

  @override
  Future<UserModel> signInUserWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    final user = UserModel(
      id: 'usr_google_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Google User',
      email: 'user.google@gmail.com',
      phone: '081299887766',
      photoUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
      createdAt: DateTime.now(),
    );
    _currentUser = user;
    return user;
  }

  @override
  Future<TukangModel> loginTukangWithEmail(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final existing = _mockTukangs.values.firstWhere(
      (t) => t.email.toLowerCase() == email.toLowerCase(),
      orElse: () => TukangModel(
        id: 'tkg_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Pak ${email.split('@').first}',
        email: email,
        phone: '081388990011',
        birthDate: '1990-05-12',
        age: 35,
        services: ['ac', 'plumbing'],
        payoutAccounts: [
          PayoutAccount(type: 'bank', provider: 'BCA', accountNumber: '2102198765', accountName: email.split('@').first)
        ],
        ktpUrl: 'https://images.unsplash.com/photo-1557804506-669a67965ba0?w=800',
        verificationStatus: 'verified',
        isOnline: true,
        createdAt: DateTime.now(),
      ),
    );
    _currentUser = existing;
    return existing;
  }

  @override
  Future<TukangModel> registerTukangWithEmail({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String birthDate,
    required int age,
    required List<String> services,
    required List<PayoutAccount> payoutAccounts,
    required String ktpPath,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    final tukang = TukangModel(
      id: 'tkg_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      phone: phone,
      birthDate: birthDate,
      age: age,
      services: services,
      payoutAccounts: payoutAccounts,
      ktpUrl: ktpPath.startsWith('http') ? ktpPath : 'file://$ktpPath',
      verificationStatus: 'pending_verification',
      isOnline: false,
      createdAt: DateTime.now(),
    );
    _mockTukangs[tukang.id] = tukang;
    _currentUser = tukang;
    return tukang;
  }

  @override
  Future<TukangModel> signInTukangWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    final tukang = TukangModel(
      id: 'tkg_google_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Budi Tukang Google',
      email: 'tukang.google@gmail.com',
      phone: '081399887766',
      birthDate: '1988-08-08',
      age: 38,
      services: ['ac', 'elektronik'],
      payoutAccounts: [
        PayoutAccount(type: 'bank', provider: 'BCA', accountNumber: '2102198888', accountName: 'Budi Tukang')
      ],
      ktpUrl: 'https://images.unsplash.com/photo-1557804506-669a67965ba0?w=800',
      verificationStatus: 'pending_verification',
      isOnline: false,
      createdAt: DateTime.now(),
    );
    _currentUser = tukang;
    return tukang;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
  }

  @override
  Future<dynamic> getCurrentUser() async {
    return _currentUser;
  }
}
