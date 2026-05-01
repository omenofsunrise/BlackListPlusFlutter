import 'package:blacklist_plus_flutter/features/black_catalog/data/models/comment.dart';
import 'package:blacklist_plus_flutter/features/black_catalog/data/models/notification.dart';
import 'package:blacklist_plus_flutter/features/black_catalog/data/models/search_response.dart';

abstract class BlackCatalogRemoteDataSource {
  Future<SearchBlackCatalogResponse> search({
    bool? mine,
    String? name,
    String? pageToken,
    int? pageSize,
    int? id,
  });

  Future<void> deleteEntry(int id);

  Future<int> createEntry({
    required String fullname,
    required String doc,
    required String address,
    required String birthdate,
    String? comment,
    bool? isSwindler,
    String? debtEndingAt,
  });

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

  Future<int> getCount();

  Future<void> addDebt({
    required int blacklistId,
    required DateTime debtEndingAt,
  });

  Future<void> deleteDebt(int debtId);

  Future<List<CatalogComment>> getComments(
    int blacklistId, {
    int pageSize = 20,
  });

  Future<void> createComment(int blacklistId, {required String content});

  Future<void> updateComment(String commentId, String content);

  Future<void> deleteComment(int blacklistId, String commentId);

  Future<NotificationsResponse> getNotifications({String? pageToken});

  Future<void> markNotificationAsRead(int notificationId);
}
