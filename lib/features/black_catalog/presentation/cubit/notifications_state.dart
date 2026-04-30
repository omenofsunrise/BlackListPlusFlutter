part of 'notifications_cubit.dart';

abstract class NotificationsState {
  const NotificationsState();
}

class NotificationsLoading extends NotificationsState {
  const NotificationsLoading();
}

class NotificationsLoaded extends NotificationsState {
  final List<BlackCatalogNotification> items;
  final bool hasMore;
  final String? nextPageToken;
  final bool isLoadingMore;

  const NotificationsLoaded({
    required this.items,
    required this.hasMore,
    this.nextPageToken,
    this.isLoadingMore = false,
  });

  NotificationsLoaded copyWith({
    List<BlackCatalogNotification>? items,
    bool? hasMore,
    String? nextPageToken,
    bool? isLoadingMore,
  }) {
    return NotificationsLoaded(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      nextPageToken: nextPageToken ?? this.nextPageToken,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class NotificationsError extends NotificationsState {
  final String message;
  const NotificationsError(this.message);
}
