class SessionModel {
  final int id;
  final DateTime createdAt;
  final DateTime lastUsedAt;
  final DateTime expiresAt;
  final String ipAddress;
  final String deviceInfo;
  final bool isMobile;
  final bool isCurrentSession;

  const SessionModel({
    required this.id,
    required this.createdAt,
    required this.lastUsedAt,
    required this.expiresAt,
    required this.ipAddress,
    required this.deviceInfo,
    required this.isMobile,
    required this.isCurrentSession,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    int readId(Map<String, dynamic> j) {
      final v = j['id'] ?? j['tokenId'] ?? j['sessionId'];
      if (v is int) return v;
      if (v is String) {
        return int.tryParse(v) ?? (throw const FormatException('Invalid id'));
      }
      throw const FormatException('Missing id');
    }

    DateTime parseDt(String v) => DateTime.parse(v);

    return SessionModel(
      id: readId(json),
      createdAt: parseDt(json['createdAt'] as String),
      lastUsedAt: parseDt(json['lastUsedAt'] as String),
      expiresAt: parseDt(json['expiresAt'] as String),
      ipAddress: (json['ipAddress'] ?? '') as String,
      deviceInfo: (json['deviceInfo'] ?? '') as String,
      isMobile: (json['isMobile'] ?? false) as bool,
      isCurrentSession: (json['isCurrentSession'] ?? false) as bool,
    );
  }

  factory SessionModel.fromMap(Map<String, dynamic> map) =>
      SessionModel.fromJson(map);

  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'lastUsedAt': lastUsedAt.toUtc().toIso8601String(),
    'expiresAt': expiresAt.toUtc().toIso8601String(),
    'ipAddress': ipAddress,
    'deviceInfo': deviceInfo,
    'isMobile': isMobile,
    'isCurrentSession': isCurrentSession,
  };
}

extension SessionModelX on SessionModel {
  DateTime get createdAtLocal => createdAt.toLocal();
  DateTime get lastUsedAtLocal => lastUsedAt.toLocal();
  DateTime get expiresAtLocal => expiresAt.toLocal();
}
