import 'package:blacklist_plus_flutter/core/di/dependency_injection.dart';
import 'package:blacklist_plus_flutter/features/black_catalog/data/data_sources/black_catalog_remote_data_source.dart';
import 'package:blacklist_plus_flutter/features/black_catalog/data/models/comment.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'comments_state.dart';

/// Cubit комментариев досье. Аналог логики работы с комментариями в
/// BlackCatalogDossier.tsx.
class CommentsCubit extends Cubit<CommentsState> {
  CommentsCubit({required this.blacklistId, required this.currentUserId})
      : super(const CommentsLoading());

  final int blacklistId;
  final String currentUserId;

  final BlackCatalogRemoteDataSource _dataSource =
      getIt<BlackCatalogRemoteDataSource>();

  Future<void> load() async {
    emit(const CommentsLoading());
    try {
      final list = await _dataSource.getComments(blacklistId, pageSize: 20);
      emit(CommentsLoaded(comments: list));
    } catch (e) {
      emit(CommentsError(_msg(e)));
    }
  }

  Future<void> create(String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      emit(const CommentsError('Введите текст комментария.'));
      return;
    }
    try {
      await _dataSource.createComment(blacklistId, content: trimmed);
      await load();
    } catch (e) {
      emit(CommentsError(_msg(e)));
    }
  }

  Future<void> updateOne(String commentId, String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      emit(const CommentsError('Введите текст комментария.'));
      return;
    }
    try {
      await _dataSource.updateComment(commentId, trimmed);
      await load();
    } catch (e) {
      emit(CommentsError(_msg(e)));
    }
  }

  Future<void> deleteOne(String commentId) async {
    try {
      await _dataSource.deleteComment(blacklistId, commentId);
      await load();
    } catch (e) {
      emit(CommentsError(_msg(e)));
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
