import 'package:blacklist_plus_flutter/features/profile/data/models/credit_stat.dart';
import 'package:blacklist_plus_flutter/features/profile/data/models/employee.dart';
import 'package:blacklist_plus_flutter/features/profile/data/models/payment_stat.dart';

abstract class EmployeeRemoteDataSource {
  Future<void> uploadEmployeePhoto({required int id, required String filePath});
  Future<void> updateEmployeeProfile({
    required int id,
    required String fullName,
    required String address,
  });
  Future<void> deleteEmployeePhoto();
  Future<EmployeesResponse> fetchEmployees({
    int? page,
    int? pageSize,
    String? fullName,
    String? role,
    String? sortBy,
    String? sortDirection,
  });
  Future<void> updateEmployeeRole(int id, String newRole);
  Future<void> updateEmployeePhone(int id, String phone);
  Future<void> updateEmployeeMinSurcharge(int id, int minSurcharge);
  Future<void> createEmployee({
    required String fullName,
    required String phone,
    required String address,
    required int minSurcharge,
    required String role,
  });
  Future<Map<String, dynamic>> getEmployeeById(int id);
  Future<void> deleteEmployee(int id);
  Future<List<PaymentStat>> getPaymentsStats({int months = 12});
  Future<List<PaymentStat>> getPaymentsStatsById({
    required int employeeId,
    int months = 12,
  });
  Future<List<CreditStat>> getCreditsStats({int months = 12});
  Future<List<CreditStat>> getCreditsStatsById({
    required int employeeId,
    int months = 12,
  });
  Future<List<EmployeeName>> getEmployeeFullNames();
}
