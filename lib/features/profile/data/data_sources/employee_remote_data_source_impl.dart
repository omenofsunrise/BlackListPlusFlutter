import 'package:blacklist_plus_flutter/features/profile/data/data_sources/employee_remote_data_source.dart';
import 'package:blacklist_plus_flutter/features/profile/data/models/credit_stat.dart';
import 'package:blacklist_plus_flutter/features/profile/data/models/employee.dart';
import 'package:blacklist_plus_flutter/features/profile/data/models/payment_stat.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class EmployeeRemoteDataSourceImpl implements EmployeeRemoteDataSource {
  final Dio dio;

  EmployeeRemoteDataSourceImpl(this.dio);

  @override
  Future<void> uploadEmployeePhoto({
    required int id,
    required String filePath,
  }) async {
    try {
      final fileName = filePath.split('/').last;
      final mimeType = lookupMimeType(filePath) ?? 'application/octet-stream';
      final mimeParts = mimeType.split('/');
      final formData = FormData.fromMap({
        'Id': id.toString(),
        'Photo': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
          contentType: MediaType(mimeParts[0], mimeParts[1]),
        ),
      });

      await dio.put('Employee/photo', data: formData);
    } on DioException catch (e) {
      throw Exception('Ошибка загрузки фото: ${e.message}');
    }
  }

  @override
  Future<void> updateEmployeeProfile({
    required int id,
    required String fullName,
    required String address,
  }) async {
    try {
      final formData = FormData.fromMap({
        'Id': id.toString(),
        'FullName': fullName,
        'Address': address,
      });

      await dio.put(
        'Employee',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
    } on DioException catch (e) {
      throw Exception('Ошибка обновления профиля сотрудника: ${e.message}');
    }
  }

  @override
  Future<void> deleteEmployeePhoto() async {
    try {
      await dio.delete('Employee/photo');
    } on DioException catch (e) {
      throw Exception('Ошибка удаления фото: ${e.message}');
    }
  }

  @override
  Future<EmployeesResponse> fetchEmployees({
    int? page,
    int? pageSize,
    String? fullName,
    String? role,
    String? sortBy,
    String? sortDirection,
  }) async {
    final Map<String, dynamic> queryParams = {};

    if (page != null) queryParams['page'] = page;
    if (pageSize != null) queryParams['pageSize'] = pageSize;
    if (fullName != null) queryParams['fullName'] = fullName;
    if (role != null) queryParams['role'] = role;
    if (sortBy != null) queryParams['sortBy'] = sortBy;
    if (sortDirection != null) queryParams['sortDirection'] = sortDirection;

    final response = await dio.get('Employee', queryParameters: queryParams);

    print('Ответ от API /api/Employee: ${response.data}');

    if (response.statusCode == 200) {
      return EmployeesResponse.fromJson(response.data);
    } else {
      throw Exception(
        'Ошибка при загрузке сотрудников: ${response.statusCode}',
      );
    }
  }

  @override
  Future<void> updateEmployeeRole(int id, String newRole) async {
    try {
      final response = await dio.patch(
        'Employee/role/$id',
        data: '"$newRole"',
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      print('Ответ от PATCH /api/Employee/role/$id: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception('Ошибка обновления роли: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка при PATCH /role/$id: $e');
    }
  }

  @override
  Future<void> updateEmployeePhone(int id, String phone) async {
    final response = await dio.patch(
      'Employee/phone/$id',
      data: '"$phone"',
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
    if (response.statusCode != 200) {
      throw Exception('Не удалось обновить телефон: ${response.statusCode}');
    }
  }

  @override
  Future<void> updateEmployeeMinSurcharge(int id, int minSurcharge) async {
    final response = await dio.patch(
      'Employee/min-surcharge/$id',
      data: minSurcharge,
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
    if (response.statusCode != 200) {
      throw Exception('Не удалось обновить надбавку: ${response.statusCode}');
    }
  }

  @override
  Future<void> createEmployee({
    required String fullName,
    required String phone,
    required String address,
    required int minSurcharge,
    required String role,
  }) async {
    print('=== Создание сотрудника ===');
    print('FullName: $fullName');
    print('Phone: $phone');
    print('Address: $address');
    print('MinSurcharge: $minSurcharge');
    print('Role: $role');
    print('===========================');

    final formData = FormData.fromMap({
      'FullName': fullName,
      'Phone': phone,
      'Address': address,
      'MinSurcharge': minSurcharge,
      'Role': role,
    });

    try {
      final response = await dio.post(
        'Employee',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      print('Ответ от POST /api/Employee: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception(
          'Ошибка при создании сотрудника: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Ошибка при создании сотрудника: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getEmployeeById(int id) async {
    final response = await dio.get('Employee/$id');
    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception('Ошибка загрузки пользователя: ${response.statusCode}');
    }
  }

  @override
  @override
  Future<void> deleteEmployee(int id) async {
    final response = await dio.delete('Employee/$id');

    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    } else {
      throw Exception('Ошибка удаления: ${response.statusCode}');
    }
  }

  @override
  Future<List<CreditStat>> getCreditsStats({int months = 12}) async {
    final response = await dio.get(
      'Employee/credits-stats',
      queryParameters: {'months': months},
    );

    if (response.statusCode == 200) {
      final List list = response.data;
      return list.map((e) => CreditStat.fromJson(e)).toList();
    } else {
      throw Exception('Ошибка загрузки статистики по договорам');
    }
  }

  @override
  Future<List<PaymentStat>> getPaymentsStats({int months = 12}) async {
    final response = await dio.get(
      'Employee/payments-stats',
      queryParameters: {'months': months},
    );
    if (response.statusCode == 200 && response.data is List) {
      return (response.data as List)
          .map((e) => PaymentStat.fromJson(e))
          .toList();
    } else {
      throw Exception('Ошибка загрузки статистики по платежам');
    }
  }

  @override
  Future<List<PaymentStat>> getPaymentsStatsById({
    required int employeeId,
    int months = 12,
  }) async {
    final url = 'Employee/payments-stats$employeeId';
    print('📡 [Request] GET $url?months=$months');

    final response = await dio.get(url, queryParameters: {'months': months});

    print('✅ [Response ${response.statusCode}] $url');

    if (response.statusCode == 200) {
      final List data = response.data;
      print('📦 [Data] Loaded ${data.length} records');
      return data.map((e) => PaymentStat.fromJson(e)).toList();
    } else {
      throw Exception('Ошибка загрузки статистики по платежам');
    }
  }

  Future<List<CreditStat>> getCreditsStatsById({
    required int employeeId,
    int months = 12,
  }) async {
    try {
      final url = 'Employee/credits-stats$employeeId';
      final query = {'months': months};

      print('📡 [Request] GET $url?months=$months');

      final response = await dio.get(url, queryParameters: query);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;

        print('✅ [Response] ${data.length} items loaded');

        return data.map((e) => CreditStat.fromJson(e)).toList();
      } else {
        print('❌ [Error] Status code: ${response.statusCode}');
        throw Exception('Ошибка загрузки статистики по договорам');
      }
    } catch (e, stackTrace) {
      print('❌ [Exception] $e');
      print(stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<EmployeeName>> getEmployeeFullNames() async {
    try {
      final response = await dio.get('Employee/fullnames');

      print('📡 [Request] GET /api/Employee/fullnames');
      print('✅ [Response ${response.statusCode}] ${response.data}');

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((e) => EmployeeName.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Ошибка получения списка полных имён');
      }
    } on DioException catch (e) {
      throw Exception('Ошибка запроса /api/Employee/fullnames: ${e.message}');
    }
  }
}
