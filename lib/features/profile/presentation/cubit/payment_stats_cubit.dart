import 'package:blacklist_plus_flutter/core/di/dependency_injection.dart';
import 'package:blacklist_plus_flutter/features/profile/data/data_sources/employee_remote_data_source.dart';
import 'package:blacklist_plus_flutter/features/profile/data/models/payment_stat.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'payment_stats_state.dart';

class PaymentStatsCubit extends Cubit<PaymentStatsState> {
  final _employeeRemoteDataSource = getIt<EmployeeRemoteDataSource>();

  PaymentStatsCubit() : super(PaymentStatsInitial());

  Future<void> loadStats({int months = 12}) async {
    emit(PaymentStatsLoading());
    try {
      final data = await _employeeRemoteDataSource.getPaymentsStats(
        months: months,
      );
      emit(PaymentStatsLoaded(data));
    } catch (e) {
      emit(PaymentStatsError('Ошибка загрузки статистики: $e'));
    }
  }

  Future<void> loadStatsByEmployeeId({
    required int employeeId,
    int months = 12,
  }) async {
    emit(PaymentStatsLoading());

    try {
      final data = await _employeeRemoteDataSource.getPaymentsStatsById(
        employeeId: employeeId,
        months: months,
      );
      emit(PaymentStatsLoaded(data));
    } catch (e) {
      emit(PaymentStatsError('Ошибка загрузки статистики сотрудника: $e'));
    }
  }
}
