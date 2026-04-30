part of 'credit_stats_cubit.dart';

@immutable
abstract class CreditStatsState {}

class CreditStatsInitial extends CreditStatsState {}

class CreditStatsLoading extends CreditStatsState {}

class CreditStatsLoaded extends CreditStatsState {
  final List<CreditStat> stats;

  CreditStatsLoaded(this.stats);
}

class CreditStatsError extends CreditStatsState {
  final String message;

  CreditStatsError(this.message);
}
