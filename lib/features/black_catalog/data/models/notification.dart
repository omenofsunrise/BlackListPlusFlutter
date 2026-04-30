/// Уведомление чёрного каталога.
/// Соответствует типу `Notification` из waypay-react
/// (blacklist-plus/src/api/BlackCatalog/blackCatalog.ts).
class BlackCatalogNotification {
  final int id;
  final String content;
  final bool isRead;
  final String userId;
  final String createdAt;
  final String? entityId;

  const BlackCatalogNotification({
    required this.id,
    required this.content,
    required this.isRead,
    required this.userId,
    required this.createdAt,
    this.entityId,
  });

  factory BlackCatalogNotification.fromJson(Map<String, dynamic> json) {
    return BlackCatalogNotification(
      id: (json['id'] as num?)?.toInt() ?? 0,
      content: (json['content'] ?? '').toString(),
      isRead: json['is_read'] == true,
      userId: (json['user_id'] ?? json['userId'] ?? '').toString(),
      createdAt: (json['created_at'] ?? json['createdAt'] ?? '').toString(),
      entityId: (json['entity_id'] ?? json['entityId'])?.toString(),
    );
  }

  BlackCatalogNotification copyWith({bool? isRead}) {
    return BlackCatalogNotification(
      id: id,
      content: content,
      isRead: isRead ?? this.isRead,
      userId: userId,
      createdAt: createdAt,
      entityId: entityId,
    );
  }
}

/// Ответ на GET /black-catalog/notifications.
class NotificationsResponse {
  final List<BlackCatalogNotification> notifications;
  final String? nextPageToken;

  const NotificationsResponse({
    required this.notifications,
    this.nextPageToken,
  });

  factory NotificationsResponse.fromJson(Map<String, dynamic> json) {
    final list = <BlackCatalogNotification>[];
    final raw = json['notifications'];
    if (raw is List) {
      for (final n in raw) {
        if (n is Map) {
          list.add(
            BlackCatalogNotification.fromJson(Map<String, dynamic>.from(n)),
          );
        }
      }
    }
    return NotificationsResponse(
      notifications: list,
      nextPageToken: (json['next_page_token'] ?? json['nextPageToken'])
          ?.toString(),
    );
  }
}
