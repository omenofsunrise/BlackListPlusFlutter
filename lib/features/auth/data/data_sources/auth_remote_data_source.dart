import 'package:blacklist_plus_flutter/features/auth/data/models/refresh_token_request_model.dart';
import 'package:blacklist_plus_flutter/features/auth/data/models/refresh_token_response_model.dart';
import 'package:blacklist_plus_flutter/features/auth/data/models/session_model.dart';
import 'package:blacklist_plus_flutter/features/auth/data/models/start_auth_response_model.dart';

import '../models/start_auth_request_model.dart';
import '../models/call_confirm_request_model.dart';

/// Контракт авторизации, повторяющий поведение waypay_react_library.
///
/// Соответствие:
///   • [startAuth]      → POST /auth/call/initiate
///   • [confirmCall]    → POST /auth/call/confirm   (вызывается в цикле опроса)
///   • [getSessionInfo] → GET  /auth/session/info   (аналог getSessionInfo() из либы)
///   • [logout]         → POST /auth/session/revoke (аналог authStorage.logout)
abstract class AuthRemoteDataSource {
  Future<StartAuthResponseModel> startAuth(StartAuthRequestModel request);

  /// Возвращает true, когда сервер прислал access/refresh токены и они уже
  /// сохранены в TokenStorage. Возвращает false при статусе AUTH_PENDING
  /// (звонок ещё не подтверждён).
  Future<bool> confirmCall(CallConfirmRequestModel request);

  Future<RefreshTokenResponseModel> refreshToken(
    RefreshTokenRequestModel request,
  );

  /// Аналог `authStorage.getSessionInfo()` из waypay_react_library.
  /// При ошибке возвращает null (никогда не бросает).
  Future<Map<String, dynamic>?> getSessionInfo();

  /// Совместимость со старыми экранами профиля: возвращает Map с маппингом
  /// "client" → "employee", чтобы существующий UI не сломать.
  Future<Map<String, dynamic>> getAuthInfo();

  Future<List<SessionModel>> getSessions();
  Future<void> revokeSession(int sessionId);

  /// Аналог `authStorage.logout(tokenId?)` из React-библиотеки.
  /// Если [tokenId] не задан, вызывает /auth/session/revoke с пустым телом
  /// (выйти из текущей сессии).
  Future<void> logout({String? tokenId});
}
