import 'package:blacklist_plus_flutter/features/profile/data/models/employee.dart';

abstract class EmployeesState {}

class EmployeesInitial extends EmployeesState {}

class EmployeesLoading extends EmployeesState {}

class EmployeesLoaded extends EmployeesState {
  final List<Employee> employees;
  final int total;
  final int currentPage;
  final int totalPages;

  EmployeesLoaded({
    required this.employees,
    required this.total,
    required this.currentPage,
    required this.totalPages,
  });
}

class EmployeesError extends EmployeesState {
  final String message;

  EmployeesError(this.message);
}

class EmployeeFullNamesLoaded extends EmployeesState {
  final List<EmployeeName> fullNames;

  EmployeeFullNamesLoaded(this.fullNames);
}
