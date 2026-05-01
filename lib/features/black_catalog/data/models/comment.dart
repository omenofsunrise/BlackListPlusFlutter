class CatalogComment {
  final String id;
  final String content;
  final String createdAt;
  final String userId;
  final String? authorFullName;
  final String? authorAvatarUrl;
  final String? parentId;
  final List<CatalogCommentFile> files;

  const CatalogComment({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.userId,
    this.authorFullName,
    this.authorAvatarUrl,
    this.parentId,
    this.files = const [],
  });

  factory CatalogComment.fromJson(Map<String, dynamic> json) {
    final author = json['author'];
    final authorMap = author is Map ? Map<String, dynamic>.from(author) : null;

    final filesRaw = json['files'];
    final files = <CatalogCommentFile>[];
    if (filesRaw is List) {
      for (final f in filesRaw) {
        if (f is Map) {
          files.add(CatalogCommentFile.fromJson(Map<String, dynamic>.from(f)));
        }
      }
    }

    return CatalogComment(
      id: (json['id'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      createdAt: (json['created_at'] ?? json['createdAt'] ?? '').toString(),
      userId: (json['user_id'] ?? json['userId'] ?? '').toString(),
      authorFullName: (authorMap?['full_name'] ?? authorMap?['fullName'])
          ?.toString(),
      authorAvatarUrl: (authorMap?['avatar_url'] ?? authorMap?['avatarUrl'])
          ?.toString(),
      parentId: (json['parent_id'] ?? json['parentId'])?.toString(),
      files: files,
    );
  }
}

class CatalogCommentFile {
  final String id;
  final String filename;
  final String? url;
  final String? contentType;
  final int? sizeBytes;

  const CatalogCommentFile({
    required this.id,
    required this.filename,
    this.url,
    this.contentType,
    this.sizeBytes,
  });

  factory CatalogCommentFile.fromJson(Map<String, dynamic> json) {
    return CatalogCommentFile(
      id: (json['id'] ?? '').toString(),
      filename: (json['filename'] ?? '').toString(),
      url: (json['url'])?.toString(),
      contentType: (json['content_type'] ?? json['contentType'])?.toString(),
      sizeBytes: (json['size_bytes'] ?? json['sizeBytes']) is num
          ? ((json['size_bytes'] ?? json['sizeBytes']) as num).toInt()
          : null,
    );
  }

  bool get isImage {
    if (contentType != null && contentType!.startsWith('image/')) return true;
    final lower = filename.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp');
  }
}
