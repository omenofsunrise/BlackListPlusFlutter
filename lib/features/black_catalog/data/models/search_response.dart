import 'package:blacklist_plus_flutter/features/black_catalog/data/models/black_catalog_item.dart';

/// Ответ на GET /black-catalog/search — соответствует SearchBlackCatalogResponse
/// из waypay-react.
class SearchBlackCatalogResponse {
  final List<BlackCatalogItem> blackCatalogs;
  final int count;
  final String? nextPageToken;
  final bool success;
  final String? error;

  const SearchBlackCatalogResponse({
    required this.blackCatalogs,
    required this.count,
    this.nextPageToken,
    this.success = true,
    this.error,
  });

  factory SearchBlackCatalogResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['black_catalogs'] ?? json['blackCatalogs'];
    final items = <BlackCatalogItem>[];
    if (rawList is List) {
      for (final raw in rawList) {
        if (raw is Map) {
          items.add(BlackCatalogItem.fromJson(Map<String, dynamic>.from(raw)));
        }
      }
    }
    return SearchBlackCatalogResponse(
      blackCatalogs: items,
      count: (json['count'] as num?)?.toInt() ?? items.length,
      nextPageToken: (json['next_page_token'] ?? json['nextPageToken'])
          ?.toString(),
      success: json['success'] is bool ? json['success'] as bool : true,
      error: (json['error'])?.toString(),
    );
  }
}
