import 'dart:async';
import 'package:blacklist_plus_flutter/core/di/dependency_injection.dart';
import 'package:blacklist_plus_flutter/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:blacklist_plus_flutter/features/auth/data/models/call_confirm_request_model.dart';
import 'package:blacklist_plus_flutter/features/auth/data/models/start_auth_request_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'auth_state.dart';

/// AuthCubit повторяет внутреннюю логику компонента AuthPage из
/// waypay_react_library (минифицированный исходник
/// blacklist-plus/node_modules/waypay_react_library/dist/waypay-react-library.es.js,
/// функция Ji ≈ строки 4249–4326).
///
/// Что было перенесено 1-в-1:
///   1. Нормализация телефона перед отправкой на бэкенд:
///        digits.startsWith("8") ? "+7" + digits.slice(1)
///        : digits.startsWith("7") ? "+" + digits
///        : "+" + digits
///   2. Поведение initiateCallAuth → если в ответе name_required:
///        • при enableRegistration=true  → открыть AuthNameModal (у нас AuthNameRequired)
///        • при enableRegistration=false → ошибка "Этот номер не зарегистрирован
///                                          в системе. Обратитесь в поддержку
///                                          для регистрации."
///   3. Запуск авто-поллинга confirmCallAuth (по умолчанию каждые 3000 мс).
///   4. Защита от параллельных вызовов confirm: флаг _isVerifying (в React это `P`).
///   5. Тихое игнорирование ошибок confirm во время поллинга — в React оно
///      обёрнуто в try/catch с console.error и поллинг не прерывается.
///   6. Успех = пришли access_token И refresh_token (data source их уже сохранил).
class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    Duration pollingInterval = const Duration(milliseconds: 3000),
    bool enableRegistration = true,
  }) : _pollingInterval = pollingInterval,
       _enableRegistration = enableRegistration,
       super(AuthInitial());

  final _authDataSource = getIt<AuthRemoteDataSource>();

  /// Интервал авто-проверки звонка. По умолчанию 3000 мс — как
  /// `pollingIntervalMs = 3e3` в React.
  final Duration _pollingInterval;

  /// В React-приложении `enableRegistration={true}` (см. App.tsx, AuthPage).
  /// Если выставить false, при name_required будет показана ошибка
  /// "Этот номер не зарегистрирован в системе…".
  final bool _enableRegistration;

  /// Защита от параллельных confirm-запросов (аналог `P` в React).
  bool _isVerifying = false;

  /// Текущий контекст авторизации (заполняется после успешного startAuth).
  String? _phone; // нормализованный +7XXXXXXXXXX
  String? _checkId;
  String? _callPhone;
  String? _userType;
  String? _name;

  /// Таймер поллинга на стороне cubit (аналог setInterval в React).
  /// UI-диалог `CallConfirmationDialog` уже сам периодически дёргает
  /// confirmCall, поэтому таймер тут используется как страховка/единый
  /// источник истины при сценариях без диалога.
  Timer? _pollTimer;

  /// Старт авторизации (аналог handleSubmit в React AuthPage).
  /// На вход принимает телефон в любом формате, который пришёл из UI
  /// (например "8XXXXXXXXXX" из существующего phone_auth_screen.dart).
  Future<void> startAuth(String phone, String userType) async {
    final normalized = _normalizePhone(phone);
    _phone = normalized;
    _userType = userType;
    _name = null;

    emit(AuthLoading());
    try {
      final startResponse = await _authDataSource.startAuth(
        StartAuthRequestModel(phone: normalized, userType: userType),
      );

      _checkId = startResponse.checkId;
      _callPhone = startResponse.callPhone;

      // Логика из React (Ji, ветка после await Ur(...)):
      //   if (enableRegistration && name_required) → показать модалку имени
      //   if (!enableRegistration && name_required) → ошибка
      //   else → открыть call-modal и стартовать поллинг
      if (startResponse.nameRequired) {
        if (_enableRegistration) {
          emit(
            AuthNameRequired(
              checkId: startResponse.checkId,
              callPhone: startResponse.callPhone,
            ),
          );
        } else {
          _resetContext();
          emit(
            AuthError(
              'Этот номер не зарегистрирован в системе. '
              'Обратитесь в поддержку для регистрации.',
            ),
          );
        }
        return;
      }

      emit(
        AuthCodeSent(
          checkId: startResponse.checkId,
          callPhone: startResponse.callPhone,
        ),
      );
      _startPolling();
    } catch (e) {
      _resetContext();
      emit(
        AuthError(
          _mapAuthError(
            e,
            'Не удалось инициировать авторизацию. Проверьте номер.',
          ),
        ),
      );
    }
  }

  /// Аналог handleSubmitName в React — пользователь ввёл ФИО, закрываем
  /// модалку имени и запускаем поллинг confirmCallAuth с этим именем.
  Future<void> submitName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      emit(AuthError('Введите ФИО'));
      return;
    }
    final phone = _phone;
    final checkId = _checkId;
    final callPhone = _callPhone;
    if (phone == null || checkId == null || callPhone == null) {
      emit(AuthError('Сессия авторизации не найдена. Начните заново.'));
      return;
    }

    _name = trimmed;
    emit(AuthCodeSent(checkId: checkId, callPhone: callPhone));
    _startPolling();
  }

  /// Подтверждение звонка (вызывается как из таймера, так и из UI).
  /// Возвращает true, если авторизация успешно завершилась.
  ///
  /// [phone] из UI приходит в формате "8XXXXXXXXXX" — здесь нормализуем
  /// в "+7XXXXXXXXXX", чтобы тело запроса совпадало с тем, что отправляет
  /// React (там телефон уже нормализован на этапе initiate и передаётся
  /// в confirm в том же виде).
  Future<bool> confirmCall(String checkId, String phone) async {
    if (state is AuthSuccess) return true;
    if (_isVerifying) return false;

    _isVerifying = true;
    final normalized = _normalizePhone(phone);

    // Сохраняем контекст, если ещё не сохранён (например, когда confirmCall
    // вызвал UI напрямую, в обход startAuth).
    _phone ??= normalized;
    _checkId ??= checkId;

    try {
      final confirmed = await _authDataSource.confirmCall(
        CallConfirmRequestModel(
          checkId: checkId,
          phone: normalized,
          name: _name,
          userType: _userType ?? 'blacklist_plus',
        ),
      );

      if (confirmed) {
        _stopPolling();
        _resetContext();
        emit(AuthSuccess());
        return true;
      }
      // AUTH_PENDING / нет токенов — оставляем текущее состояние без изменений,
      // поллинг продолжается (как в React: при пустых токенах функция просто
      // выходит, ничего не эмитя).
      return false;
    } catch (e) {
      // В React ошибки confirmCallAuth тихо логируются (console.error) и
      // поллинг идёт дальше. Повторяем то же самое: не эмитим AuthError,
      // чтобы не закрывать диалог звонка из-за временного 5xx или сети.
      // ignore: avoid_print
      print('⚠️ Verification error (ignored, polling continues): $e');
      return false;
    } finally {
      _isVerifying = false;
    }
  }

  /// Полный logout по логике waypay_react_library:
  ///   await authStorage.logout(tokenId?);
  ///   // дальше UI обычно делает navigate('/') + reload.
  Future<void> logout({String? tokenId}) async {
    try {
      await _authDataSource.logout(tokenId: tokenId);
    } finally {
      _stopPolling();
      _resetContext();
      emit(AuthInitial());
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollingInterval, (_) async {
      final checkId = _checkId;
      final phone = _phone;
      if (checkId == null || phone == null) return;
      if (state is AuthSuccess) {
        _stopPolling();
        return;
      }
      await confirmCall(checkId, phone);
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _resetContext() {
    _phone = null;
    _checkId = null;
    _callPhone = null;
    _userType = null;
    _name = null;
  }

  /// Нормализация телефона из waypay_react_library/AuthPage:
  ///   const V = ($) => {
  ///     const g = $.replace(/\D/g, "");
  ///     return g
  ///       ? g.startsWith("8") ? `+7${g.slice(1)}`
  ///       : g.startsWith("7") ? `+${g}`
  ///       : `+${g}`
  ///       : "";
  ///   };
  String _normalizePhone(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    if (digits.startsWith('8')) {
      return '+7${digits.substring(1)}';
    }
    if (digits.startsWith('7')) {
      return '+$digits';
    }
    return '+$digits';
  }

  String _mapAuthError(Object error, String fallback) {
    final raw = error.toString();
    if (raw.startsWith('Exception:')) {
      final message = raw.replaceFirst('Exception:', '').trim();
      if (message.isNotEmpty) return message;
    }
    return fallback;
  }

  @override
  Future<void> close() {
    _stopPolling();
    return super.close();
  }
}
