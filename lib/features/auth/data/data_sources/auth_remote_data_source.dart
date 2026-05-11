import 'package:blacklist_plus_flutter/features/auth/data/models/refresh_token_request_model.dart';
import 'package:blacklist_plus_flutter/features/auth/data/models/refresh_token_response_model.dart';
import 'package:blacklist_plus_flutter/features/auth/data/models/session_model.dart';
import 'package:blacklist_plus_flutter/features/auth/data/models/start_auth_response_model.dart';

import '../models/start_auth_request_model.dart';
import '../models/call_confirm_request_model.dart';

abstract class AuthRemoteDataSource {
  Future<StartAuthResponseModel> startAuth(StartAuthRequestModel request);

  Future<bool> confirmCall(CallConfirmRequestModel request);

  Future<RefreshTokenResponseModel> refreshToken(
    RefreshTokenRequestModel request,
  );

  Future<Map<String, dynamic>?> getSessionInfo();

  Future<Map<String, dynamic>> getAuthInfo();

  Future<bool> hasActiveSubscription();

  Future<List<SessionModel>> getSessions();
  Future<void> revokeSession(int sessionId);

  Future<void> logout({String? tokenId});
}
