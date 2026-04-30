import 'package:blacklist_plus_flutter/core/di/dependency_injection.dart';
import 'package:blacklist_plus_flutter/features/black_catalog/data/data_sources/black_catalog_remote_data_source.dart';
import 'package:blacklist_plus_flutter/features/black_catalog/data/models/black_catalog_item.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'black_catalog_list_state.dart';

/// Cubit главной страницы «Чёрный список» (BlackCatalogPage из waypay-react).
///
/// Поведение 1-в-1:
///   • Поиск работает только при длине запроса >= 5 символов (debounce — на UI).
///   • До поиска показывается empty state c текстом "Введите ФИО клиента…".
///   • Если запрос отдал пустой список — отдельный empty state «Не найдено».
///   • totalCount берётся из GET /black-catalog/count (когда понадобится для
///     отображения, всегда хранится в state).
class BlackCatalogListCubit extends Cubit<BlackCatalogListState> {
  BlackCatalogListCubit() : super(const BlackCatalogListInitial());

  final BlackCatalogRemoteDataSource _dataSource =
      getIt<BlackCatalogRemoteDataSource>();

  String _query = '';

  /// Загрузить total count (для отображения в шапке/где угодно).
  Future<void> refreshTotalCount() async {
    try {
      final count = await _dataSource.getCount();
      final current = state;
      if (current is BlackCatalogListLoaded) {
        emit(current.copyWith(totalCount: count));
      } else if (current is BlackCatalogListEmpty) {
        emit(BlackCatalogListEmpty(totalCount: count, hasSearched: false));
      } else if (current is BlackCatalogListInitial) {
        emit(BlackCatalogListEmpty(totalCount: count, hasSearched: false));
      }
    } catch (_) {
      // не критично, count просто не отобразится
    }
  }

  /// Выполнить поиск. Если query короче 5 символов или пуст — сбросить в
  /// "не искали ещё" (empty state с подсказкой).
  Future<void> search(String query) async {
    _query = query;
    if (query.isEmpty || query.length < 5) {
      final current = state;
      final total = current is BlackCatalogListLoaded
          ? current.totalCount
          : current is BlackCatalogListEmpty
              ? current.totalCount
              : null;
      emit(BlackCatalogListEmpty(totalCount: total, hasSearched: false));
      return;
    }

    emit(const BlackCatalogListLoading());
    try {
      final response = await _dataSource.search(name: query);
      if (response.blackCatalogs.isEmpty) {
        emit(BlackCatalogListEmpty(
          totalCount: null,
          hasSearched: true,
          query: query,
        ));
      } else {
        emit(BlackCatalogListLoaded(
          items: response.blackCatalogs,
          totalCount: response.count,
          query: query,
        ));
      }
    } catch (e) {
      emit(BlackCatalogListError(_msg(e), query: query));
    }
  }

  /// Перезагрузить с текущим запросом — после create/update/delete/addDebt.
  Future<void> refresh() async {
    if (_query.isEmpty || _query.length < 5) {
      await refreshTotalCount();
      return;
    }
    await search(_query);
  }

  /// Удалить запись (используется из контекстного меню/листа).
  Future<void> deleteItem(int id) async {
    await _dataSource.deleteEntry(id);
    await refresh();
    await refreshTotalCount();
  }

  /// Создать новую запись.
  /// [isSwindler] = true для варианта «Чёрный список»,
  /// = false для варианта «Оформленный».
  Future<int> createItem({
    required String fullname,
    required String doc,
    required String address,
    required String birthdate,
    String? comment,
    required bool isSwindler,
    String? debtEndingAt,
  }) async {
    final id = await _dataSource.createEntry(
      fullname: fullname,
      doc: doc,
      address: address,
      birthdate: birthdate,
      comment: comment,
      isSwindler: isSwindler,
      debtEndingAt: debtEndingAt,
    );
    await refresh();
    await refreshTotalCount();
    return id;
  }

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
    await refresh();
  }

  Future<void> addDebt(int blacklistId, DateTime endingAt) async {
    await _dataSource.addDebt(blacklistId: blacklistId, debtEndingAt: endingAt);
    await refresh();
  }

  Future<void> deleteDebt(int debtId) async {
    await _dataSource.deleteDebt(debtId);
    await refresh();
  }

  String _msg(Object e) {
    final raw = e.toString();
    if (raw.startsWith('Exception:')) {
      return raw.replaceFirst('Exception:', '').trim();
    }
    return raw;
  }
}
