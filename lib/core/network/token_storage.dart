import 'dart:convert';
import 'package:blacklist_plus_flutter/core/config/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _accessExpiryKey = 'access_token_expiry';
  static const _isAuthenticatedKey = 'is_authenticated';
  static const _privacyAcceptedKey = 'privacy_policy_accepted';

  static const Duration _defaultAccessTtl = Duration(minutes: 5);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    Duration? accessTtl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final ttl = accessTtl ?? _defaultAccessTtl;
    await prefs.setString(_accessKey, accessToken);
    await prefs.setString(_refreshKey, refreshToken);
    await prefs.setString(
      _accessExpiryKey,
      DateTime.now().add(ttl).toIso8601String(),
    );
  }

  Future<String?> getAccessToken({
    Duration skew = const Duration(seconds: 30),
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final access = prefs.getString(_accessKey);
    final expiryStr = prefs.getString(_accessExpiryKey);
    if (access == null || expiryStr == null) {
      if (access != null) {
        return await _refreshAccessToken();
      }
      return null;
    }

    final expiry = DateTime.tryParse(expiryStr);
    final now = DateTime.now();

    if (expiry == null) {
      return await _refreshAccessToken();
    }

    if (now.isAfter(expiry.subtract(skew))) {
      return await _refreshAccessToken();
    }
    return access;
  }

  Future<String?> refreshNow() => _refreshAccessToken();

  Future<void> debugExpireAccessTokenNow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _accessExpiryKey,
      DateTime.now().subtract(const Duration(seconds: 1)).toIso8601String(),
    );
  }

  Future<void> debugSetAccessTtl(Duration ttl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _accessExpiryKey,
      DateTime.now().add(ttl).toIso8601String(),
    );
  }

  Future<void> setAuthenticated(bool isAuthenticated) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isAuthenticatedKey, isAuthenticated);
  }

  Future<void> setPrivacyAccepted(bool accepted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_privacyAcceptedKey, accepted);
  }

  Future<bool> isPrivacyAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_privacyAcceptedKey) ?? false;
  }

  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isAuthenticatedKey) ?? false;
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
    await prefs.remove(_accessExpiryKey);
    await prefs.remove(_isAuthenticatedKey);
  }

  Future<String?> _refreshAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refresh = prefs.getString(_refreshKey);
    final access = prefs.getString(_accessKey);
    if (refresh == null || access == null) {
      return null;
    }

    final body = <String, dynamic>{
      'access_token': access,
      'refresh_token': refresh,
    };

    try {
      final resp = await http.post(
        Uri.parse('${ApiConfig.apiBaseUrl}/auth/refresh'),
        headers: {'Content-Type': 'application/json', 'X-Environment': 'dev'},
        body: jsonEncode(body),
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final newAccess =
            (data['access_token'] ?? data['accessToken']) as String?;
        final newRefresh =
            ((data['refresh_token'] ?? data['refreshToken']) as String?) ??
            refresh;

        if (newAccess != null) {
          await saveTokens(
            accessToken: newAccess,
            refreshToken: newRefresh,
            accessTtl: _defaultAccessTtl,
          );
          return newAccess;
        } else {
          return null;
        }
      } else {
        await clearAll();
        return null;
      }
    } catch (e) {
      await clearAll();
      return null;
    }
  }
}
