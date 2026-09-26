import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/supabase_storage_service.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';
import '../models/tukang_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<UserModel> loginUserWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = credential.user!.uid;

    // 1. Cek apakah akun ini sebenarnya terdaftar sebagai Mitra Tukang
    final tukangSnapshot = await _firestore.collection('tukang').doc(uid).get();
    if (tukangSnapshot.exists) {
      // Hapus dokumen users jika sebelumnya sempat terbuat secara tidak sengaja
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        await _firestore.collection('users').doc(uid).delete().catchError((_) {});
      }
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'role-mismatch',
        message: 'Akun "${email.trim()}" terdaftar sebagai Mitra Tukang. Silakan masuk melalui aplikasi Beres Mitra.',
      );
    }

    // 2. Cek apakah benar-benar terdaftar di koleksi users
    final userSnapshot = await _firestore.collection('users').doc(uid).get();
    if (!userSnapshot.exists) {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Akun pelanggan belum terdaftar. Silakan daftar akun baru terlebih dahulu.',
      );
    }

    final data = userSnapshot.data()!;
    if (data['role'] != null && data['role'] != 'user') {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'role-mismatch',
        message: 'Akun ini bukan akun Pelanggan. Akses ditolak.',
      );
    }

    return UserModel.fromMap(data, uid);
  }

  @override
  Future<UserModel> registerUserWithEmail(
    String name,
    String email,
    String phone,
    String password,
  ) async {
    final cleanEmail = email.trim().toLowerCase();

    // 1. Cek apakah email sudah dipakai oleh Mitra Tukang
    final tukangQuery = await _firestore
        .collection('tukang')
        .where('email', isEqualTo: cleanEmail)
        .limit(1)
        .get();
    if (tukangQuery.docs.isNotEmpty) {
      throw FirebaseAuthException(
        code: 'role-mismatch',
        message: 'Email "$cleanEmail" sudah terdaftar sebagai Mitra Tukang. Gunakan email berbeda untuk mendaftar akun Pelanggan.',
      );
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );

    // Pastikan Firebase Auth token sudah aktif di client sebelum menulis ke Firestore
    await credential.user?.getIdToken(true);

    final user = UserModel(
      id: credential.user!.uid,
      name: name.trim().isNotEmpty ? name.trim() : (credential.user!.displayName ?? 'Pengguna Beres'),
      email: cleanEmail,
      phone: phone.trim(),
      photoUrl: credential.user!.photoURL,
      role: 'user',
      createdAt: DateTime.now(),
    );

    await _firestore.collection('users').doc(user.id).set(
      user.toMap(),
      SetOptions(merge: true),
    );
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
    final uid = credential.user!.uid;

    final tukangSnapshot = await _firestore.collection('tukang').doc(uid).get();
    if (!tukangSnapshot.exists) {
      // Cek apakah akun terdaftar sebagai user/pelanggan biasa
      final userSnapshot = await _firestore.collection('users').doc(uid).get();
      await _auth.signOut();
      if (userSnapshot.exists) {
        throw FirebaseAuthException(
          code: 'role-mismatch',
          message: 'Akun "${email.trim()}" terdaftar sebagai Pelanggan (User). Silakan login di aplikasi Beres Pelanggan.',
        );
      } else {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Akun Mitra Tukang belum terdaftar. Silakan daftar menjadi Mitra terlebih dahulu.',
        );
      }
    }

    final tukang = TukangModel.fromMap(tukangSnapshot.data()!, uid);

    if (tukang.verificationStatus != 'verified') {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'unverified-mitra',
        message: 'Harap tunggu, akun Anda belum aktif. Pendaftaran masih menunggu persetujuan admin.',
      );
    }

    if (tukang.isCurrentlySuspended) {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'account-suspended',
        message: 'Akun Mitra Anda sedang disuspend: ${tukang.suspendReason ?? "Pelanggaran ketentuan"}.',
      );
    }

    return tukang;
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
    final cleanEmail = email.trim().toLowerCase();

    // 1. Cek apakah email sudah dipakai oleh akun Pelanggan
    final userQuery = await _firestore
        .collection('users')
        .where('email', isEqualTo: cleanEmail)
        .limit(1)
        .get();
    if (userQuery.docs.isNotEmpty) {
      throw FirebaseAuthException(
        code: 'role-mismatch',
        message: 'Email "$cleanEmail" sudah terdaftar sebagai Akun Pelanggan. Gunakan email berbeda untuk mendaftar sebagai Mitra Tukang.',
      );
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: cleanEmail,
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
      email: cleanEmail,
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

    final tukangProfile = await _firestore.collection('tukang').doc(user.uid).get();
    if (tukangProfile.exists) return TukangModel.fromMap(tukangProfile.data()!, user.uid);

    final userProfile = await _firestore.collection('users').doc(user.uid).get();
    if (userProfile.exists) return UserModel.fromMap(userProfile.data()!, user.uid);

    await _auth.signOut();
    return null;
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
