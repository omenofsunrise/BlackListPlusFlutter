import 'dart:async';
import 'package:blacklist_plus_flutter/core/config/api_config.dart';
import 'package:dio/dio.dart';
import 'token_storage.dart';

Dio createDio({String baseUrl = ApiConfig.apiBaseUrl}) {
  final tokenStorage = TokenStorage();
  final normalizedBaseUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';

  final dio = Dio(
    BaseOptions(
      baseUrl: normalizedBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  bool isRefreshing = false;
  final List<Completer<void>> waiters = [];

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final access = await tokenStorage.getAccessToken();
        if (access != null) {
          options.headers['Authorization'] = 'Bearer $access';
        }
        handler.next(options);
      },

      onError: (error, handler) async {
        final is401 = error.response?.statusCode == 401;
        final req = error.requestOptions;

        final alreadyRetried = req.extra['__retried__'] == true;
        final isRefreshCall =
            req.path.contains('/auth/refresh') ||
            req.path.contains('Auth/refresh');

        if (is401 && !alreadyRetried && !isRefreshCall) {
          if (isRefreshing) {
            final c = Completer<void>();
            waiters.add(c);
            await c.future;
          } else {
            isRefreshing = true;
            try {
              final newAccess = await tokenStorage.refreshNow();

              for (final w in waiters) {
                w.complete();
              }
              waiters.clear();
              isRefreshing = false;

              if (newAccess == null) {
                return handler.reject(error);
              }
            } catch (_) {
              for (final w in waiters) {
                w.complete();
              }
              waiters.clear();
              isRefreshing = false;
              return handler.reject(error);
            }
          }

          try {
            final fresh = await tokenStorage.getAccessToken();
            if (fresh != null) {
              req.headers['Authorization'] = 'Bearer $fresh';
            }
            req.extra['__retried__'] = true;
            final clonedResponse = await dio.fetch(req);
            return handler.resolve(clonedResponse);
          } catch (e) {
            return handler.reject(
              e is DioException
                  ? e
                  : DioException(requestOptions: req, error: e),
            );
          }
        }

        return handler.next(error);
      },
    ),
  );

  return dio;
}
