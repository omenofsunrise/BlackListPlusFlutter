part of 'comments_cubit.dart';

abstract class CommentsState {
  const CommentsState();
}

class CommentsLoading extends CommentsState {
  const CommentsLoading();
}

class CommentsLoaded extends CommentsState {
  final List<CatalogComment> comments;
  const CommentsLoaded({required this.comments});
}

class CommentsError extends CommentsState {
  final String message;
  const CommentsError(this.message);
}
