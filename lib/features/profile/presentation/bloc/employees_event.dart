abstract class EmployeesEvent {}

class LoadEmployeesEvent extends EmployeesEvent {
  final int page;
  final String? fullName;

  LoadEmployeesEvent({this.page = 1, this.fullName});
}

class SearchEmployeesEvent extends EmployeesEvent {
  final String query;

  SearchEmployeesEvent(this.query);
}

class LoadEmployeeFullNamesEvent extends EmployeesEvent {}
