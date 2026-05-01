import 'package:blacklist_plus_flutter/core/network/token_storage.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:blacklist_plus_flutter/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:blacklist_plus_flutter/features/auth/data/models/call_confirm_request_model.dart';
import 'package:blacklist_plus_flutter/features/auth/data/models/refresh_token_request_model.dart';
import 'package:blacklist_plus_flutter/features/auth/data/models/refresh_token_response_model.dart';
import 'package:blacklist_plus_flutter/features/auth/data/models/session_model.dart';
import 'package:blacklist_plus_flutter/features/auth/data/models/start_auth_request_model.dart';
import 'package:blacklist_plus_flutter/features/auth/data/models/start_auth_response_model.dart';

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSourceImpl(this.dio);

  @override
  Future<StartAuthResponseModel> startAuth(
    StartAuthRequestModel request,
  ) async {
    try {
      print('➡️ Старт авторизации: ${request.toJson()}');
      final response = await dio.post(
        '/auth/call/initiate',
        data: request.toJson(),
      );
      print('✅ Успешный ответ startAuth: ${response.data}');
      final data = _asMap(response.data);
      final model = StartAuthResponseModel.fromJson(data);
      if (!model.success) {
        throw Exception(model.message ?? 'Ошибка авторизации');
      }
      return model;
    } on DioException catch (e) {
      print('❌ Ошибка startAuth: ${e.response?.data}');
      throw Exception(
        _extractErrorMessage(
          e,
          'Не удалось инициировать авторизацию. Проверьте номер.',
        ),
      );
    }
  }

  @override
  Future<bool> confirmCall(CallConfirmRequestModel request) async {
    try {
      print('➡️ Подтверждение звонка: ${request.toJson()}');
      final response = await dio.post(
        '/auth/call/confirm',
        data: request.toJson(),
      );

      print('✅ Ответ confirmCall: ${response.data}');

      final data = _asMap(response.data);
      final status = (data['status'] ?? '').toString().toUpperCase();

      final accessToken = data['access_token'] ?? data['accessToken'];
      final refreshToken = data['refresh_token'] ?? data['refreshToken'];
      if (accessToken is String &&
          refreshToken is String &&
          accessToken.isNotEmpty &&
          refreshToken.isNotEmpty) {
        final tokenStorage = TokenStorage();
        await tokenStorage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
        await tokenStorage.setAuthenticated(true);

        print('🔐 Токены сохранены после confirmCall');
        return true;
      }

      if (status == 'AUTH_PENDING') {
        print('⏳ Авторизация ещё не подтверждена (AUTH_PENDING)');
      } else {
        print('⚠️ Пустые/некорректные токены в ответе confirmCall');
      }
      return false;
    } on DioException catch (e) {
      print('❌ Ошибка confirmCall: ${e.response?.data}');
      throw Exception(_extractErrorMessage(e, 'Ошибка подтверждения звонка'));
    }
  }

  @override
  Future<RefreshTokenResponseModel> refreshToken(
    RefreshTokenRequestModel request,
  ) async {
    try {
      final tokenStorage = TokenStorage();
      final body = {
        'access_token': request.accessToken,
        'refresh_token': request.refreshToken,
        'moderate': true,
      };
      print('🔄 Запрос на обновление токена: $body');

      final response = await dio.post(
        '/auth/refresh',
        data: body,
        options: Options(
          headers: {'Authorization': 'Bearer ${request.accessToken}'},
        ),
      );

      final data = response.data as Map<String, dynamic>;
      final newAccessToken =
          (data['access_token'] ?? data['accessToken']) as String;
      final newRefreshToken =
          ((data['refresh_token'] ?? data['refreshToken']) as String?) ??
          request.refreshToken;

      await tokenStorage.saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );

      print(
        '✅ Токены обновлены: accessToken=${newAccessToken.substring(0, 10)}...',
      );

      return RefreshTokenResponseModel.fromJson(data);
    } on DioException catch (e) {
      print('❌ Ошибка refreshToken: ${e.response?.data}');
      throw Exception('Ошибка обновления токена: ${e.message}');
    }
  }

  @override
  Future<Map<String, dynamic>?> getSessionInfo() async {
    try {
      final tokenStorage = TokenStorage();
      final access = await tokenStorage.getAccessToken();
      if (access == null || access.isEmpty) {
        return null;
      }

      final response = await dio.get(
        '/auth/session/info',
        options: Options(headers: {'Authorization': 'Bearer $access'}),
      );

      final data = _asMap(response.data);
      return data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return null;
      }
      print('⚠️ getSessionInfo вернул null из-за Dio ошибки: $e');
      return null;
    } catch (e) {
      print('⚠️ getSessionInfo вернул null из-за ошибки: $e');
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>> getAuthInfo() async {
    try {
      print('📥 Получение информации о пользователе...');
      final tokenStorage = TokenStorage();
      final access = await tokenStorage.getAccessToken();
      if (access == null || access.isEmpty) {
        return {'employee': null};
      }

      final response = await dio.get(
        '/auth/session/info',
        options: Options(headers: {'Authorization': 'Bearer $access'}),
      );
      print('✅ Информация получена: ${response.data}');
      final data = response.data as Map<String, dynamic>;
      if (data['employee'] != null) {
        return data;
      }
      if (data['client'] is Map<String, dynamic>) {
        return {...data, 'employee': data['client']};
      }
      return data;
    } on DioException catch (e) {
      print('❌ Ошибка getAuthInfo: ${e.response?.data}');
      throw Exception(
        _extractErrorMessage(e, 'Ошибка получения информации о пользователе'),
      );
    }
  }

  @override
  Future<void> logout({String? tokenId}) async {
    final tokenStorage = TokenStorage();
    final access = await tokenStorage.getAccessToken();

    final body = tokenId != null && tokenId.isNotEmpty
        ? {'token_id': tokenId}
        : <String, dynamic>{};

    try {
      await dio.post(
        '/auth/session/revoke',
        data: body,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (access != null) 'Authorization': 'Bearer $access',
          },
        ),
      );
      print('✅ logout: сессия отозвана на бэкенде');
    } on DioException catch (e) {
      print('❌ Ошибка logout: ${e.response?.data}');
      await tokenStorage.clearAll();
      throw Exception(_extractErrorMessage(e, 'Не удалось выйти из аккаунта'));
    }

    await tokenStorage.clearAll();
  }

  String _extractErrorMessage(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final candidates = [
        data['message'],
        data['Message'],
        data['error'],
        data['Error'],
        data['detail'],
        data['title'],
      ].whereType<String>();
      for (final value in candidates) {
        final trimmed = value.trim();
        if (trimmed.isNotEmpty) return trimmed;
      }
    }
    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }
    final message = e.message?.trim();
    if (message != null && message.isNotEmpty) {
      return message;
    }
    return fallback;
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    if (data is String) {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    }
    throw const FormatException('Invalid response format');
  }

  @override
  Future<List<SessionModel>> getSessions() async {
    try {
      print('📥 Получение списка сессий...');
      final tokenStorage = TokenStorage();
      final access = await tokenStorage.getAccessToken();

      final response = await dio.get(
        'Auth/sessions',
        options: access != null
            ? Options(headers: {'Authorization': 'Bearer $access'})
            : null,
      );

      final data = response.data;
      if (data is List) {
        final result = data
            .map(
              (e) => SessionModel.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
        print('✅ Сессий: ${result.length}');
        return result;
      }

      throw Exception('Неожиданный формат ответа: ${data.runtimeType}');
    } on DioException catch (e) {
      print('❌ Ошибка getSessions: ${e.response?.data}');
      throw Exception('Ошибка получения списка сессий: ${e.message}');
    }
  }

  @override
  Future<void> revokeSession(int tokenId) async {
    final tokenStorage = TokenStorage();
    final access = await tokenStorage.getAccessToken();

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (access != null) 'Authorization': 'Bearer $access',
    };

    Future<Response<dynamic>> post(dynamic body) {
      return dio.post(
        'Auth/revoke-session',
        data: body,
        options: Options(headers: headers),
      );
    }

    try {
      final res = await post(tokenId);
      if (res.statusCode == 200) return;

      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        error: 'Unexpected status: ${res.statusCode}',
        type: DioExceptionType.badResponse,
      );
    } on DioException catch (e) {
      final code = e.response?.statusCode;

      if (code == 400 || code == 415) {
        try {
          final r1 = await post({'sessionId': tokenId});
          if (r1.statusCode == 200) return;

          final r2 = await post({'tokenId': tokenId});
          if (r2.statusCode == 200) return;
        } catch (_) {}
      }

      if (code == 401) {
        throw Exception('Авторизация истекла. Войдите заново.');
      }
      if (code == 404) {
        throw Exception('Сессия не найдена (id=$tokenId).');
      }

      throw Exception(
        'Ошибка при отзыве сессии: code=$code, body=${e.response?.data}',
      );
    }
  }
}
