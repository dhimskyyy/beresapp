import 'package:equatable/equatable.dart';
import '../../../data/models/tukang_model.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class CheckAuthStatusEvent extends AuthEvent {}

class UserLoginRequestedEvent extends AuthEvent {
  final String email;
  final String password;
  const UserLoginRequestedEvent({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class UserRegisterRequestedEvent extends AuthEvent {
  final String name;
  final String email;
  final String phone;
  final String password;
  const UserRegisterRequestedEvent({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
  });
  @override
  List<Object?> get props => [name, email, phone, password];
}

class UserGoogleSignInRequestedEvent extends AuthEvent {}

class TukangLoginRequestedEvent extends AuthEvent {
  final String email;
  final String password;
  const TukangLoginRequestedEvent({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class TukangRegisterRequestedEvent extends AuthEvent {
  final String name;
  final String email;
  final String phone;
  final String password;
  final String birthDate;
  final int age;
  final List<String> services;
  final List<PayoutAccount> payoutAccounts;
  final String ktpPath;

  const TukangRegisterRequestedEvent({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.birthDate,
    required this.age,
    required this.services,
    required this.payoutAccounts,
    required this.ktpPath,
  });

  @override
  List<Object?> get props => [name, email, phone, password, birthDate, age, services, payoutAccounts, ktpPath];
}

class TukangGoogleSignInRequestedEvent extends AuthEvent {}

class SignOutRequestedEvent extends AuthEvent {}
