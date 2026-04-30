import 'package:blacklist_plus_flutter/core/di/dependency_injection.dart';
import 'package:blacklist_plus_flutter/features/black_catalog/data/data_sources/black_catalog_remote_data_source.dart';
import 'package:blacklist_plus_flutter/features/black_catalog/data/models/black_catalog_item.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'my_black_catalog_state.dart';

/// Cubit для блока «Мой чёрный список» в профиле.
///
/// Повторяет поведение ProfileBlackCatalog.tsx из React:
///   • Поиск по ФИО (минимум 5 символов, debounce 300 мс — реализуется на UI).
///   • Загрузка списка через GET /black-catalog/search?mine=true.
///   • Пагинация next_page_token + бесконечная подгрузка.
///   • Удаление записи с обновлением списка.
class MyBlackCatalogCubit extends Cubit<MyBlackCatalogState> {
  MyBlackCatalogCubit({this.pageSize = 10}) : super(const MyBlackCatalogInitial());

  final BlackCatalogRemoteDataSource _dataSource =
      getIt<BlackCatalogRemoteDataSource>();

  /// Размер страницы — в React по умолчанию 10.
  final int pageSize;

  String _query = '';

  /// Загрузка/перезагрузка с нуля. Вызывается при первом открытии и при
  /// изменении поискового запроса (длиной 0 или ≥ 5 символов).
  Future<void> loadInitial({String query = ''}) async {
    _query = query;
    emit(const MyBlackCatalogLoading());

    try {
      final response = await _dataSource.search(
        mine: true,
        name: query.length >= 5 ? query : null,
        pageSize: pageSize,
      );
      emit(
        MyBlackCatalogLoaded(
          items: response.blackCatalogs,
          hasMore: response.nextPageToken != null &&
              response.nextPageToken!.isNotEmpty,
          nextPageToken: response.nextPageToken,
          query: query,
        ),
      );
    } catch (e) {
      emit(MyBlackCatalogError(_msg(e)));
    }
  }

  /// Подгрузка следующей страницы по next_page_token.
  Future<void> loadMore() async {
    final current = state;
    if (current is! MyBlackCatalogLoaded) return;
    if (!current.hasMore) return;
    if (current.isLoadingMore) return;
    final pageToken = current.nextPageToken;
    if (pageToken == null || pageToken.isEmpty) return;

    emit(current.copyWith(isLoadingMore: true));

    try {
      final response = await _dataSource.search(
        mine: true,
        name: _query.length >= 5 ? _query : null,
        pageSize: pageSize,
        pageToken: pageToken,
      );
      emit(
        MyBlackCatalogLoaded(
          items: [...current.items, ...response.blackCatalogs],
          hasMore: response.nextPageToken != null &&
              response.nextPageToken!.isNotEmpty,
          nextPageToken: response.nextPageToken,
          query: _query,
        ),
      );
    } catch (e) {
      // Не уходим в error-стейт целиком — просто откатываем флаг загрузки и
      // оставляем уже загруженные элементы. В React тоже только console.error.
      emit(current.copyWith(isLoadingMore: false));
    }
  }

  /// Удаление записи. После успеха — перезагружаем список с текущим запросом
  /// (как в React: после deleteEntry вызывается loadMyBlacklist(null, false)).
  Future<void> deleteItem(int id) async {
    final current = state;
    try {
      await _dataSource.deleteEntry(id);
    } catch (e) {
      if (current is MyBlackCatalogLoaded) {
        emit(current);
      }
      rethrow;
    }
    await loadInitial(query: _query);
  }

  /// Обновление записи (вызывается из модалки редактирования).
  Future<void> updateItem({
    required int id,
    required String fullname,
    required String doc,
    required String address,
    required String birthdate,
    String? comment,
    bool? isSwindler,
    String? debtEndingAt,
  }) async {
    await _dataSource.updateEntry(
      id: id,
      fullname: fullname,
      doc: doc,
      address: address,
      birthdate: birthdate,
      comment: comment,
      isSwindler: isSwindler,
      debtEndingAt: debtEndingAt,
    );
    await loadInitial(query: _query);
  }

  String _msg(Object e) {
    final raw = e.toString();
    if (raw.startsWith('Exception:')) {
      return raw.replaceFirst('Exception:', '').trim();
    }
    return raw;
  }
}
