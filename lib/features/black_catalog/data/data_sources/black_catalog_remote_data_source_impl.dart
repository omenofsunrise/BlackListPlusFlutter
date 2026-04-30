import 'package:blacklist_plus_flutter/features/black_catalog/data/data_sources/black_catalog_remote_data_source.dart';
import 'package:blacklist_plus_flutter/features/black_catalog/data/models/comment.dart';
import 'package:blacklist_plus_flutter/features/black_catalog/data/models/notification.dart';
import 'package:blacklist_plus_flutter/features/black_catalog/data/models/search_response.dart';
import 'package:dio/dio.dart';

/// Реализация поверх Dio. Аналог BlackCatalogService из waypay-react.
class BlackCatalogRemoteDataSourceImpl implements BlackCatalogRemoteDataSource {
  final Dio dio;

  static const _basePath = '/black-catalog';

  BlackCatalogRemoteDataSourceImpl(this.dio);

  @override
  Future<SearchBlackCatalogResponse> search({
    bool? mine,
    String? name,
    String? pageToken,
    int? pageSize,
    int? id,
  }) async {
    final query = <String, dynamic>{};
    if (name != null && name.isNotEmpty) {
      // BlackCatalogService.search дублирует имя в name+fullname.
      query['name'] = name;
      query['fullname'] = name;
    }
    if (mine == true) {
      query['mine'] = 'true';
    }
    if (id != null) {
      query['id'] = id.toString();
    }
    if (pageToken != null && pageToken.isNotEmpty) {
      query['page_token'] = pageToken;
    }
    if (pageSize != null) {
      query['page_size'] = pageSize.toString();
    }

    try {
      final response = await dio.get('$_basePath/search', queryParameters: query);
      final data = response.data;
      if (data is Map) {
        return SearchBlackCatalogResponse.fromJson(
          Map<String, dynamic>.from(data),
        );
      }
      throw Exception('Неожиданный формат ответа /black-catalog/search');
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, 'Не удалось загрузить чёрный каталог'),
      );
    }
  }

  @override
  Future<void> deleteEntry(int id) async {
    try {
      await dio.delete('$_basePath/$id');
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Не удалось удалить запись'));
    }
  }

  @override
  Future<int> createEntry({
    required String fullname,
    required String doc,
    required String address,
    required String birthdate,
    String? comment,
    bool? isSwindler,
    String? debtEndingAt,
  }) async {
    // В React BlackCatalogService.create использует FormData (для файлов
    // паспорта). У нас файлы пока не поддерживаются — отправляем JSON.
    // Если бэкенд требует строго multipart, можно перейти на FormData
    // позже без изменения UI.
    final body = <String, dynamic>{
      'fullname': fullname,
      'doc': doc,
      'address': address,
      'birthdate': birthdate.isEmpty ? null : birthdate,
    };
    if (comment != null && comment.trim().isNotEmpty) {
      body['comment'] = comment.trim();
    }
    if (isSwindler != null) body['is_swindler'] = isSwindler;
    if (debtEndingAt != null && debtEndingAt.isNotEmpty) {
      body['debt_ending_at'] = debtEndingAt;
    }

    try {
      final response = await dio.post(_basePath, data: body);
      final data = response.data;
      if (data is Map) {
        final id = data['id'];
        if (id is num) return id.toInt();
      }
      // Если сервер не вернул id, возвращаем 0 — фронт всё равно сделает
      // refresh списка через search().
      return 0;
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Не удалось создать запись'));
    }
  }

  @override
  Future<void> updateEntry({
    required int id,
    required String fullname,
    required String doc,
    required String address,
    required String birthdate,
    String? comment,
    bool? isSwindler,
    String? debtEndingAt,
  }) async {
    final blackCatalog = <String, dynamic>{
      'fullname': fullname,
      'doc': doc,
      'address': address,
      'birthdate': birthdate.isEmpty ? null : birthdate,
    };
    if (comment != null && comment.trim().isNotEmpty) {
      blackCatalog['comment'] = comment.trim();
    }
    if (isSwindler != null) {
      blackCatalog['is_swindler'] = isSwindler;
    }
    blackCatalog['debt_ending_at'] =
        (debtEndingAt == null || debtEndingAt.isEmpty) ? null : debtEndingAt;

    try {
      await dio.put('$_basePath/$id', data: {'black_catalog': blackCatalog});
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Не удалось обновить запись'));
    }
  }

  @override
  Future<int> getCount() async {
    try {
      final response = await dio.get('$_basePath/count');
      final data = response.data;
      if (data is Map && data['count'] is num) {
        return (data['count'] as num).toInt();
      }
      return 0;
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Не удалось получить count'));
    }
  }

  @override
  Future<void> addDebt({
    required int blacklistId,
    required DateTime debtEndingAt,
  }) async {
    try {
      await dio.post(
        '$_basePath/debt',
        data: {
          'blacklist_id': blacklistId,
          // ISO-8601 — бэкенду на сайте отдаётся такой же Date.
          'debt_ending_at': debtEndingAt.toUtc().toIso8601String(),
        },
      );
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Не удалось добавить долг'));
    }
  }

  @override
  Future<void> deleteDebt(int debtId) async {
    try {
      await dio.delete('$_basePath/debt/$debtId');
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Не удалось удалить долг'));
    }
  }

  @override
  Future<List<CatalogComment>> getComments(
    int blacklistId, {
    int pageSize = 20,
  }) async {
    try {
      final response = await dio.get(
        '$_basePath/$blacklistId/comments',
        queryParameters: {'page_size': pageSize.toString()},
      );
      final data = response.data;
      if (data is Map) {
        final list = data['comments'];
        final result = <CatalogComment>[];
        if (list is List) {
          for (final raw in list) {
            if (raw is Map) {
              result.add(
                CatalogComment.fromJson(Map<String, dynamic>.from(raw)),
              );
            }
          }
        }
        return result;
      }
      return const [];
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, 'Не удалось загрузить комментарии'),
      );
    }
  }

  @override
  Future<void> createComment(int blacklistId, {required String content}) async {
    try {
      await dio.post(
        '$_basePath/$blacklistId/comments',
        data: {'content': content},
      );
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Не удалось добавить комментарий'));
    }
  }

  @override
  Future<void> updateComment(String commentId, String content) async {
    try {
      await dio.put('/comments/$commentId', data: {'content': content});
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Не удалось обновить комментарий'));
    }
  }

  @override
  Future<void> deleteComment(int blacklistId, String commentId) async {
    try {
      await dio.delete('$_basePath/$blacklistId/comments/$commentId');
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Не удалось удалить комментарий'));
    }
  }

  @override
  Future<NotificationsResponse> getNotifications({String? pageToken}) async {
    try {
      final query = <String, dynamic>{};
      if (pageToken != null && pageToken.isNotEmpty) {
        query['page_token'] = pageToken;
      }
      final response = await dio.get(
        '$_basePath/notifications',
        queryParameters: query.isEmpty ? null : query,
      );
      final data = response.data;
      if (data is Map) {
        return NotificationsResponse.fromJson(
          Map<String, dynamic>.from(data),
        );
      }
      return const NotificationsResponse(notifications: []);
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, 'Не удалось загрузить уведомления'),
      );
    }
  }

  @override
  Future<void> markNotificationAsRead(int notificationId) async {
    try {
      await dio.put('$_basePath/notifications/$notificationId/read');
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, 'Не удалось отметить уведомление прочитанным'),
      );
    }
  }

  String _extractErrorMessage(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map) {
      for (final key in const [
        'message',
        'Message',
        'error',
        'detail',
        'title',
      ]) {
        final value = data[key];
        if (value is String && value.trim().isNotEmpty) return value.trim();
      }
    }
    if (data is String && data.trim().isNotEmpty) return data.trim();
    final m = e.message?.trim();
    if (m != null && m.isNotEmpty) return m;
    return fallback;
  }
}
