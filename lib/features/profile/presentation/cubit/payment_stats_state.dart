part of 'payment_stats_cubit.dart';

@immutable
sealed class PaymentStatsState {}

final class PaymentStatsInitial extends PaymentStatsState {}

final class PaymentStatsLoading extends PaymentStatsState {}

final class PaymentStatsLoaded extends PaymentStatsState {
  final List<PaymentStat> stats;

  PaymentStatsLoaded(this.stats);
}

final class PaymentStatsError extends PaymentStatsState {
  final String message;

  PaymentStatsError(this.message);
}
