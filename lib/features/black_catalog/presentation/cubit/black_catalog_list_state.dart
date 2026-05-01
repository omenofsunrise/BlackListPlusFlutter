part of 'black_catalog_list_cubit.dart';

abstract class BlackCatalogListState {
  const BlackCatalogListState();
}

class BlackCatalogListInitial extends BlackCatalogListState {
  const BlackCatalogListInitial();
}

class BlackCatalogListLoading extends BlackCatalogListState {
  const BlackCatalogListLoading();
}

class BlackCatalogListEmpty extends BlackCatalogListState {
  final int? totalCount;
  final bool hasSearched;
  final String query;

  const BlackCatalogListEmpty({
    this.totalCount,
    required this.hasSearched,
    this.query = '',
  });
}

class BlackCatalogListLoaded extends BlackCatalogListState {
  final List<BlackCatalogItem> items;
  final int totalCount;
  final String query;

  const BlackCatalogListLoaded({
    required this.items,
    required this.totalCount,
    required this.query,
  });

  BlackCatalogListLoaded copyWith({
    List<BlackCatalogItem>? items,
    int? totalCount,
    String? query,
  }) {
    return BlackCatalogListLoaded(
      items: items ?? this.items,
      totalCount: totalCount ?? this.totalCount,
      query: query ?? this.query,
    );
  }
}

class BlackCatalogListError extends BlackCatalogListState {
  final String message;
  final String query;

  const BlackCatalogListError(this.message, {required this.query});
}
