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
      id: _asInt(json['id']),
      content: (json['content'] ?? '').toString(),
      isRead: _asBool(json['is_read'] ?? json['isRead']),
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

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'true' || normalized == '1';
  }
  return false;
}

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
