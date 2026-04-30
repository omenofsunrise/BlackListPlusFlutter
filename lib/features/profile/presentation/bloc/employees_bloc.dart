import 'package:blacklist_plus_flutter/core/di/dependency_injection.dart';
import 'package:blacklist_plus_flutter/features/profile/data/data_sources/employee_remote_data_source.dart';
import 'package:blacklist_plus_flutter/features/profile/data/models/employee.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'employees_event.dart';
import 'employees_state.dart';

class EmployeesBloc extends Bloc<EmployeesEvent, EmployeesState> {
  final EmployeeRemoteDataSource _remoteDataSource =
      getIt<EmployeeRemoteDataSource>();

  EmployeesBloc() : super(EmployeesInitial()) {
    on<LoadEmployeesEvent>(_onLoadEmployees);
    on<SearchEmployeesEvent>(_onSearchEmployees);
    on<LoadEmployeeFullNamesEvent>(_onLoadEmployeeFullNames);
  }

  Future<void> _onLoadEmployees(
    LoadEmployeesEvent event,
    Emitter<EmployeesState> emit,
  ) async {
    emit(EmployeesLoading());
    try {
      const pageSize = 10;

      final EmployeesResponse response = await _remoteDataSource.fetchEmployees(
        page: event.page,
        pageSize: pageSize,
        fullName: event.fullName,
      );

      emit(
        EmployeesLoaded(
          employees: response.employees,
          total: response.total,
          currentPage: response.currentPage,
          totalPages: response.totalPages,
        ),
      );
    } catch (e) {
      emit(EmployeesError('Ошибка при загрузке сотрудников: $e'));
    }
  }

  Future<void> _onSearchEmployees(
    SearchEmployeesEvent event,
    Emitter<EmployeesState> emit,
  ) async {
    add(LoadEmployeesEvent(fullName: event.query, page: 1));
  }

  Future<void> _onLoadEmployeeFullNames(
    LoadEmployeeFullNamesEvent event,
    Emitter<EmployeesState> emit,
  ) async {
    emit(EmployeesLoading());
    try {
      final names = await _remoteDataSource.getEmployeeFullNames();
      emit(EmployeeFullNamesLoaded(names));
    } catch (e) {
      emit(EmployeesError('Ошибка при загрузке имён: $e'));
    }
  }
}
