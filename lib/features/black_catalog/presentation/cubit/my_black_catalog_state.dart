part of 'my_black_catalog_cubit.dart';

abstract class MyBlackCatalogState {
  const MyBlackCatalogState();
}

class MyBlackCatalogInitial extends MyBlackCatalogState {
  const MyBlackCatalogInitial();
}

class MyBlackCatalogLoading extends MyBlackCatalogState {
  const MyBlackCatalogLoading();
}

class MyBlackCatalogLoaded extends MyBlackCatalogState {
  final List<BlackCatalogItem> items;
  final bool hasMore;
  final String? nextPageToken;
  final String query;
  final bool isLoadingMore;

  const MyBlackCatalogLoaded({
    required this.items,
    required this.hasMore,
    required this.query,
    this.nextPageToken,
    this.isLoadingMore = false,
  });

  MyBlackCatalogLoaded copyWith({
    List<BlackCatalogItem>? items,
    bool? hasMore,
    String? nextPageToken,
    String? query,
    bool? isLoadingMore,
  }) {
    return MyBlackCatalogLoaded(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      nextPageToken: nextPageToken ?? this.nextPageToken,
      query: query ?? this.query,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class MyBlackCatalogError extends MyBlackCatalogState {
  final String message;
  const MyBlackCatalogError(this.message);
}
