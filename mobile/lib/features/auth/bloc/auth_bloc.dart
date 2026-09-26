import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/tukang_model.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitialState()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<UserLoginRequestedEvent>(_onUserLogin);
    on<UserRegisterRequestedEvent>(_onUserRegister);
    on<UserGoogleSignInRequestedEvent>(_onUserGoogleSignIn);
    on<TukangLoginRequestedEvent>(_onTukangLogin);
    on<TukangRegisterRequestedEvent>(_onTukangRegister);
    on<TukangGoogleSignInRequestedEvent>(_onTukangGoogleSignIn);
    on<SignOutRequestedEvent>(_onSignOut);
    on<UserProfileUpdatedEvent>((event, emit) {
      emit(UserAuthenticatedState(event.user));
    });
    on<TukangProfileUpdatedEvent>((event, emit) async {
      try {
        final updated = await authRepository.updateTukangProfile(event.tukang);
        emit(TukangAuthenticatedState(updated));
      } catch (e) {
        // If Firestore update fails, keep previous state and print error
        // so the app doesn't unexpectedly log out
      }
    });
  }

  Future<void> _onCheckAuthStatus(CheckAuthStatusEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoadingState());
    try {
      final user = await authRepository.getCurrentUser();
      if (user is UserModel) {
        emit(UserAuthenticatedState(user));
      } else if (user is TukangModel) {
        emit(TukangAuthenticatedState(user));
      } else {
        emit(UnauthenticatedState());
      }
    } catch (_) {
      emit(UnauthenticatedState());
    }
  }

  Future<void> _onUserLogin(UserLoginRequestedEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoadingState());
    try {
      final user = await authRepository.loginUserWithEmail(event.email, event.password);
      emit(UserAuthenticatedState(user));
    } on FirebaseAuthException catch (e) {
      final message = switch (e.code) {
        'role-mismatch' =>
          e.message ?? 'Akun terdaftar sebagai Mitra Tukang. Silakan masuk melalui aplikasi Beres Mitra.',
        'user-not-found' => (e.message != null && e.message!.contains('pelanggan'))
            ? e.message!
            : 'Email atau kata sandi salah. Silakan periksa kembali.',
        'invalid-credential' || 'wrong-password' =>
          'Email atau kata sandi salah. Silakan periksa kembali.',
        'user-disabled' => 'Akun pengguna ini telah dinonaktifkan. Hubungi bantuan.',
        'too-many-requests' => 'Terlalu banyak percobaan gagal. Harap tunggu beberapa saat.',
        'network-request-failed' => 'Koneksi internet bermasalah. Periksa jaringan Anda.',
        _ => e.message ?? 'Gagal login (${e.code})',
      };
      emit(AuthFailureState(message));
    } catch (e) {
      emit(AuthFailureState('Gagal login: ${e.toString()}'));
    }
  }

  Future<void> _onUserRegister(UserRegisterRequestedEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoadingState());
    try {
      final user = await authRepository.registerUserWithEmail(
        event.name,
        event.email,
        event.phone,
        event.password,
      );
      emit(UserAuthenticatedState(user));
    } on FirebaseAuthException catch (e) {
      final message = switch (e.code) {
        'role-mismatch' =>
          e.message ?? 'Email ini sudah terdaftar sebagai Mitra Tukang.',
        'email-already-in-use' =>
          'Email ini sudah terdaftar. Silakan masuk di halaman Login menggunakan kata sandi Anda.',
        'weak-password' => 'Kata sandi terlalu lemah. Gunakan minimal 6 karakter.',
        'invalid-email' => 'Format email tidak valid. Periksa kembali penulisan email Anda.',
        'operation-not-allowed' =>
          'Metode pendaftaran Email/Password belum diaktifkan di Firebase Console.',
        'network-request-failed' => 'Koneksi internet bermasalah. Periksa jaringan Anda.',
        _ => e.message ?? 'Gagal registrasi (${e.code})',
      };
      emit(AuthFailureState(message));
    } on FirebaseException catch (e) {
      final message = switch (e.code) {
        'permission-denied' =>
          'Izin penyimpanan profil ditolak oleh aturan database (Firestore Rules).',
        'unavailable' => 'Layanan database Firebase sedang offline.',
        _ => 'Gagal menyimpan profil: ${e.message ?? e.code}',
      };
      emit(AuthFailureState(message));
    } catch (e) {
      emit(AuthFailureState('Gagal registrasi: ${e.toString()}'));
    }
  }

  Future<void> _onUserGoogleSignIn(UserGoogleSignInRequestedEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoadingState());
    try {
      final user = await authRepository.signInUserWithGoogle();
      emit(UserAuthenticatedState(user));
    } catch (e) {
      emit(AuthFailureState('Google Sign-In gagal: ${e.toString()}'));
    }
  }

  Future<void> _onTukangLogin(TukangLoginRequestedEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoadingState());
    try {
      final tukang = await authRepository.loginTukangWithEmail(event.email, event.password);
      if (tukang.verificationStatus != 'verified') {
        await authRepository.signOut();
        emit(const AuthFailureState('Harap tunggu, akun Anda belum aktif. Pendaftaran masih menunggu persetujuan admin.'));
        return;
      }
      if (tukang.isCurrentlySuspended) {
        await authRepository.signOut();
        emit(const AuthFailureState('Akun Anda sedang disuspend dan belum dapat digunakan.'));
        return;
      }
      emit(TukangAuthenticatedState(tukang));
    } on FirebaseAuthException catch (e) {
      final message = switch (e.code) {
        'role-mismatch' =>
          e.message ?? 'Akun terdaftar sebagai Pelanggan. Silakan login di aplikasi Beres Pelanggan.',
        'unverified-mitra' =>
          e.message ?? 'Harap tunggu, akun Anda belum aktif. Pendaftaran masih menunggu persetujuan admin.',
        'account-suspended' =>
          e.message ?? 'Akun Mitra Anda sedang disuspend.',
        'user-not-found' => (e.message != null && e.message!.contains('Mitra'))
            ? e.message!
            : 'Email atau kata sandi salah. Silakan periksa kembali.',
        'invalid-credential' || 'wrong-password' =>
          'Email atau kata sandi Mitra salah. Silakan periksa kembali.',
        'user-disabled' => 'Akun Mitra ini dinonaktifkan. Hubungi admin.',
        'too-many-requests' => 'Terlalu banyak percobaan login. Coba lagi beberapa saat.',
        'network-request-failed' => 'Koneksi internet bermasalah. Periksa jaringan Anda.',
        _ => e.message ?? 'Login Mitra gagal: ${e.code}',
      };
      emit(AuthFailureState(message));
    } catch (e) {
      emit(AuthFailureState('Gagal login Mitra: ${e.toString()}'));
    }
  }

  Future<void> _onTukangRegister(TukangRegisterRequestedEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoadingState());
    try {
      final tukang = await authRepository.registerTukangWithEmail(
        name: event.name,
        email: event.email,
        phone: event.phone,
        password: event.password,
        birthDate: event.birthDate,
        age: event.age,
        services: event.services,
        payoutAccounts: event.payoutAccounts,
        ktpPath: event.ktpPath,
      );
      emit(TukangAuthenticatedState(tukang));
    } on FirebaseAuthException catch (e) {
      final message = switch (e.code) {
        'role-mismatch' =>
          e.message ?? 'Email sudah terdaftar sebagai Akun Pelanggan.',
        'email-already-in-use' =>
          'Email ini sudah terdaftar. Silakan masuk di halaman login Mitra atau gunakan email lain.',
        'weak-password' => 'Kata sandi terlalu lemah. Gunakan minimal 6 karakter.',
        'invalid-email' => 'Format email tidak valid. Periksa kembali penulisan email Anda.',
        'network-request-failed' => 'Koneksi internet bermasalah. Periksa jaringan Anda.',
        _ => e.message ?? 'Gagal pendaftaran Mitra (${e.code})',
      };
      emit(AuthFailureState(message));
    } catch (e) {
      emit(AuthFailureState('Gagal pendaftaran Mitra: ${e.toString()}'));
    }
  }

  Future<void> _onTukangGoogleSignIn(TukangGoogleSignInRequestedEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoadingState());
    try {
      final tukang = await authRepository.signInTukangWithGoogle();
      emit(TukangAuthenticatedState(tukang));
    } catch (e) {
      emit(AuthFailureState('Google Sign-In Mitra gagal: ${e.toString()}'));
    }
  }

  Future<void> _onSignOut(SignOutRequestedEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoadingState());
    await authRepository.signOut();
    emit(UnauthenticatedState());
  }
}
