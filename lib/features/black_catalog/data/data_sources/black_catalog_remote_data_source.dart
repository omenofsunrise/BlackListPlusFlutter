import 'package:blacklist_plus_flutter/features/black_catalog/data/models/comment.dart';
import 'package:blacklist_plus_flutter/features/black_catalog/data/models/notification.dart';
import 'package:blacklist_plus_flutter/features/black_catalog/data/models/search_response.dart';

/// Контракт API чёрного каталога. Повторяет методы BlackCatalogService
/// из waypay-react (blacklist-plus/src/api/BlackCatalog/BlackCatalogService.ts).
abstract class BlackCatalogRemoteDataSource {
  /// GET /black-catalog/search
  Future<SearchBlackCatalogResponse> search({
    bool? mine,
    String? name,
    String? pageToken,
    int? pageSize,
    int? id,
  });

  /// DELETE /black-catalog/{id}
  Future<void> deleteEntry(int id);

  /// POST /black-catalog
  /// Возвращает id созданной записи.
  Future<int> createEntry({
    required String fullname,
    required String doc,
    required String address,
    required String birthdate,
    String? comment,
    bool? isSwindler,
    String? debtEndingAt,
  });

  /// PUT /black-catalog/{id}
  /// Тело: { black_catalog: { fullname, doc, address, birthdate, comment, is_swindler, debt_ending_at } }
  Future<void> updateEntry({
    required int id,
    required String fullname,
    required String doc,
    required String address,
    required String birthdate,
    String? comment,
    bool? isSwindler,
    String? debtEndingAt,
  });

  /// GET /black-catalog/count
  Future<int> getCount();

  /// POST /black-catalog/debt   { blacklist_id, debt_ending_at }
  Future<void> addDebt({
    required int blacklistId,
    required DateTime debtEndingAt,
  });

  /// DELETE /black-catalog/debt/{id}
  Future<void> deleteDebt(int debtId);

  /// GET /black-catalog/{id}/comments?page_size=...
  Future<List<CatalogComment>> getComments(int blacklistId, {int pageSize = 20});

  /// POST /black-catalog/{id}/comments  { content, parent_id? }
  Future<void> createComment(int blacklistId, {required String content});

  /// PUT /comments/{commentId}  { content }
  Future<void> updateComment(String commentId, String content);

  /// DELETE /black-catalog/{id}/comments/{commentId}
  Future<void> deleteComment(int blacklistId, String commentId);

  /// GET /black-catalog/notifications?page_token=...
  /// Аналог BlackCatalogService.getNotifications из waypay-react.
  Future<NotificationsResponse> getNotifications({String? pageToken});

  /// PUT /black-catalog/notifications/{id}/read
  Future<void> markNotificationAsRead(int notificationId);
}
