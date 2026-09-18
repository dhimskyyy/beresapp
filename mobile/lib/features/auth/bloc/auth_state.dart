import 'package:equatable/equatable.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/tukang_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitialState extends AuthState {}

class AuthLoadingState extends AuthState {}

class UserAuthenticatedState extends AuthState {
  final UserModel user;
  const UserAuthenticatedState(this.user);
  @override
  List<Object?> get props => [user];
}

class TukangAuthenticatedState extends AuthState {
  final TukangModel tukang;
  const TukangAuthenticatedState(this.tukang);
  @override
  List<Object?> get props => [tukang];
}

class UnauthenticatedState extends AuthState {}

class AuthFailureState extends AuthState {
  final String message;
  const AuthFailureState(this.message);
  @override
  List<Object?> get props => [message];
}
