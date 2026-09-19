import 'package:flutter_bloc/flutter_bloc.dart';
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
      emit(TukangAuthenticatedState(tukang));
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
