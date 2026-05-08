import 'dart:async';
import 'package:blacklist_plus_flutter/core/di/dependency_injection.dart';
import 'package:blacklist_plus_flutter/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:blacklist_plus_flutter/features/auth/data/models/call_confirm_request_model.dart';
import 'package:blacklist_plus_flutter/features/auth/data/models/start_auth_request_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    Duration pollingInterval = const Duration(milliseconds: 3000),
    bool enableRegistration = true,
  }) : _pollingInterval = pollingInterval,
       _enableRegistration = enableRegistration,
       super(AuthInitial());

  final _authDataSource = getIt<AuthRemoteDataSource>();

  final Duration _pollingInterval;

  final bool _enableRegistration;

  bool _isVerifying = false;

  String? _phone; // нормализованный +7XXXXXXXXXX
  String? _checkId;
  String? _callPhone;
  String? _userType;
  String? _name;

  Timer? _pollTimer;

  Future<void> startAuth(String phone, String userType) async {
    final normalized = _normalizePhone(phone);
    _phone = normalized;
    _userType = userType;
    _name = null;

    emit(AuthLoading());
    try {
      final startResponse = await _authDataSource.startAuth(
        StartAuthRequestModel(
          phone: normalized,
          userType: userType,
        ),
      );

      _checkId = startResponse.checkId;
      _callPhone = startResponse.callPhone;

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

  Future<bool> confirmCall(String checkId, String phone) async {
    if (state is AuthSuccess) return true;
    if (_isVerifying) return false;

    _isVerifying = true;
    final normalized = _normalizePhone(phone);

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
      return false;
    } catch (e) {
      print('⚠️ Verification error (ignored, polling continues): $e');
      return false;
    } finally {
      _isVerifying = false;
    }
  }

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
