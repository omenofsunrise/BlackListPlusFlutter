import 'package:blacklist_plus_flutter/core/di/dependency_injection.dart';
import 'package:blacklist_plus_flutter/features/black_catalog/data/data_sources/black_catalog_remote_data_source.dart';
import 'package:blacklist_plus_flutter/features/black_catalog/data/models/black_catalog_item.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'my_black_catalog_state.dart';

class MyBlackCatalogCubit extends Cubit<MyBlackCatalogState> {
  MyBlackCatalogCubit({this.pageSize = 10})
    : super(const MyBlackCatalogInitial());

  final BlackCatalogRemoteDataSource _dataSource =
      getIt<BlackCatalogRemoteDataSource>();

  final int pageSize;

  String _query = '';

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
          hasMore:
              response.nextPageToken != null &&
              response.nextPageToken!.isNotEmpty,
          nextPageToken: response.nextPageToken,
          query: query,
        ),
      );
    } catch (e) {
      emit(MyBlackCatalogError(_msg(e)));
    }
  }

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
          hasMore:
              response.nextPageToken != null &&
              response.nextPageToken!.isNotEmpty,
          nextPageToken: response.nextPageToken,
          query: _query,
        ),
      );
    } catch (e) {
      emit(current.copyWith(isLoadingMore: false));
    }
  }

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
