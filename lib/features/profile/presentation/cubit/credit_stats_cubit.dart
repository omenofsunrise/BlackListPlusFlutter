import 'package:blacklist_plus_flutter/core/di/dependency_injection.dart';
import 'package:blacklist_plus_flutter/features/profile/data/data_sources/employee_remote_data_source.dart';
import 'package:blacklist_plus_flutter/features/profile/data/models/credit_stat.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';

part 'credit_stats_state.dart';

class CreditStatsCubit extends Cubit<CreditStatsState> {
  final _employeeRemoteDataSource = getIt<EmployeeRemoteDataSource>();

  CreditStatsCubit() : super(CreditStatsInitial());

  Future<void> loadStats({int months = 12}) async {
    emit(CreditStatsLoading());
    try {
      final stats = await _employeeRemoteDataSource.getCreditsStats(
        months: months,
      );
      emit(CreditStatsLoaded(stats));
    } catch (e) {
      emit(CreditStatsError('Ошибка загрузки статистики по договорам: $e'));
    }
  }

  Future<void> loadStatsByEmployeeId({
    required int employeeId,
    int months = 12,
  }) async {
    emit(CreditStatsLoading());

    try {
      final data = await _employeeRemoteDataSource.getCreditsStatsById(
        employeeId: employeeId,
        months: months,
      );
      emit(CreditStatsLoaded(data));
    } catch (e) {
      emit(
        CreditStatsError(
          'Ошибка загрузки статистики по договорам сотрудника: $e',
        ),
      );
    }
  }
}
