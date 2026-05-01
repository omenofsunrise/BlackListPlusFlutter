part of 'auth_cubit.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthCodeSent extends AuthState {
  final String checkId;
  final String callPhone;

  AuthCodeSent({required this.checkId, required this.callPhone});
}

class AuthNameRequired extends AuthState {
  final String checkId;
  final String callPhone;

  AuthNameRequired({required this.checkId, required this.callPhone});
}

class AuthSuccess extends AuthState {}

class AuthError extends AuthState {
  final String message;

  AuthError(this.message);
}
