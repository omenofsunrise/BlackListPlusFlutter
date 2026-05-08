bool isUserModerated(Map<String, dynamic>? authInfo) {
  if (authInfo == null) return true;

  Map<String, dynamic>? asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  bool? readModerationFlag(Map<String, dynamic>? source) {
    if (source == null) return null;
    final value =
        source['is_moderated'] ??
        source['isModerated'] ??
        source['moderated'] ??
        source['moderate'];
    return value is bool ? value : null;
  }

  return readModerationFlag(authInfo) ??
      readModerationFlag(asMap(authInfo['employee'])) ??
      readModerationFlag(asMap(authInfo['client'])) ??
      true;
}
