import 'package:blacklist_plus_flutter/core/di/dependency_injection.dart';
import 'package:blacklist_plus_flutter/features/black_catalog/data/data_sources/black_catalog_remote_data_source.dart';
import 'package:blacklist_plus_flutter/features/black_catalog/data/models/notification.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'notifications_state.dart';

/// Cubit для NotificationsScreen — порт логики NotificationsPage.tsx из
/// waypay-react.
///
/// Поведение 1-в-1:
///   • Первая загрузка — GET /black-catalog/notifications.
///   • Подгрузка по next_page_token при прокрутке вниз.
///   • markAsRead меняет статус и перезагружает текущий список.
class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit() : super(const NotificationsLoading());

  final BlackCatalogRemoteDataSource _dataSource =
      getIt<BlackCatalogRemoteDataSource>();

  /// Полная перезагрузка списка с первой страницы.
  Future<void> loadInitial() async {
    emit(const NotificationsLoading());
    try {
      final response = await _dataSource.getNotifications();
      emit(
        NotificationsLoaded(
          items: response.notifications,
          hasMore: response.nextPageToken != null &&
              response.nextPageToken!.isNotEmpty,
          nextPageToken: response.nextPageToken,
        ),
      );
    } catch (e) {
      emit(NotificationsError(_msg(e)));
    }
  }

  /// Подгрузка следующей страницы.
  Future<void> loadMore() async {
    final current = state;
    if (current is! NotificationsLoaded) return;
    if (!current.hasMore || current.isLoadingMore) return;
    final pageToken = current.nextPageToken;
    if (pageToken == null || pageToken.isEmpty) return;

    emit(current.copyWith(isLoadingMore: true));
    try {
      final response = await _dataSource.getNotifications(pageToken: pageToken);
      emit(
        NotificationsLoaded(
          items: [...current.items, ...response.notifications],
          hasMore: response.nextPageToken != null &&
              response.nextPageToken!.isNotEmpty,
          nextPageToken: response.nextPageToken,
        ),
      );
    } catch (_) {
      // Не уходим в общий error — просто откатываем флаг подгрузки.
      emit(current.copyWith(isLoadingMore: false));
    }
  }

  /// Отметить уведомление прочитанным. После успеха обновляем список.
  Future<void> markAsRead(int id) async {
    try {
      await _dataSource.markNotificationAsRead(id);
    } catch (e) {
      emit(NotificationsError(_msg(e)));
      return;
    }
    final current = state;
    if (current is NotificationsLoaded) {
      emit(
        current.copyWith(
          items: current.items
              .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
              .toList(),
        ),
      );
    }
  }

  String _msg(Object e) {
    final raw = e.toString();
    if (raw.startsWith('Exception:')) {
      return raw.replaceFirst('Exception:', '').trim();
    }
    return raw;
  }
}
