part of 'auth_cubit.dart';

/// Состояния AuthCubit повторяют состояния React-страницы AuthPage:
///   • AuthInitial      — страница только открыта.
///   • AuthLoading      — пользователь нажал "Подтвердить", идёт initiateCallAuth.
///   • AuthCodeSent     — initiate прошёл успешно, поллинг confirmCallAuth активен.
///   • AuthNameRequired — сервер вернул name_required:true, нужно ФИО
///                        (аналог isNameModalOpen=true в React).
///   • AuthSuccess      — пришли access_token+refresh_token, уже сохранены.
///   • AuthError        — ошибка, которую надо показать пользователю.
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthCodeSent extends AuthState {
  final String checkId;
  final String callPhone;

  AuthCodeSent({required this.checkId, required this.callPhone});
}

/// Бэкенд просит ФИО для регистрации (name_required=true).
/// UI должен попросить ввести имя и вызвать `cubit.submitName(name)`.
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
