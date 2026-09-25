import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/supabase_storage_service.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';
import '../models/tukang_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserModel> _loadUserProfile(User user) async {
    final snapshot = await _firestore.collection('users').doc(user.uid).get();
    if (!snapshot.exists) {
      throw Exception('Profil user tidak ditemukan');
    }
    return UserModel.fromMap(snapshot.data()!, user.uid);
  }

  Future<TukangModel> _loadTukangProfile(User user) async {
    final snapshot = await _firestore.collection('tukang').doc(user.uid).get();
    if (!snapshot.exists) {
      throw Exception('Profil mitra tidak ditemukan');
    }
    return TukangModel.fromMap(snapshot.data()!, user.uid);
  }

  @override
  Future<UserModel> loginUserWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return _loadUserProfile(credential.user!);
  }

  @override
  Future<UserModel> registerUserWithEmail(
    String name,
    String email,
    String phone,
    String password,
  ) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = UserModel(
      id: credential.user!.uid,
      name: name,
      email: email,
      phone: phone,
      createdAt: DateTime.now(),
    );
    await _firestore.collection('users').doc(user.id).set(user.toMap());
    return user;
  }

  @override
  Future<UserModel> signInUserWithGoogle() async {
    throw UnimplementedError('Google Sign-In belum dikonfigurasi untuk production');
  }

  @override
  Future<TukangModel> loginTukangWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return _loadTukangProfile(credential.user!);
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
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uploadedKtpUrl = ktpPath.isNotEmpty
        ? await SupabaseStorageService.uploadImage(
            filePath: ktpPath,
            folder: 'ktp',
          )
        : '';

    final tukang = TukangModel(
      id: credential.user!.uid,
      name: name,
      email: email,
      phone: phone,
      birthDate: birthDate,
      age: age,
      services: services,
      payoutAccounts: payoutAccounts,
      ktpUrl: uploadedKtpUrl,
      verificationStatus: 'pending_verification',
      isOnline: false,
      createdAt: DateTime.now(),
    );
    await _firestore.collection('tukang').doc(tukang.id).set(tukang.toMap());
    return tukang;
  }

  @override
  Future<TukangModel> signInTukangWithGoogle() async {
    throw UnimplementedError('Google Sign-In belum dikonfigurasi untuk production');
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  Future<dynamic> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final userProfile = await _firestore.collection('users').doc(user.uid).get();
    if (userProfile.exists) return UserModel.fromMap(userProfile.data()!, user.uid);

    final tukangProfile = await _firestore.collection('tukang').doc(user.uid).get();
    if (tukangProfile.exists) return TukangModel.fromMap(tukangProfile.data()!, user.uid);

    throw Exception('Profil akun tidak ditemukan');
  }

  @override
  Future<TukangModel> updateTukangProfile(TukangModel tukang) async {
    await _firestore.collection('tukang').doc(tukang.id).set(
      tukang.toMap(),
      SetOptions(merge: true),
    );
    return tukang;
  }
}
