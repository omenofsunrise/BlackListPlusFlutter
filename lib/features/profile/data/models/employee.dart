enum EmployeeRole { accountant, employee, admin, superAdmin, director }

extension EmployeeRoleMapper on EmployeeRole {
  static EmployeeRole fromApi(String apiValue) {
    switch (apiValue.toLowerCase()) {
      case 'бухгалтер':
        return EmployeeRole.accountant;
      case 'сотрудник':
        return EmployeeRole.employee;
      case 'админ':
        return EmployeeRole.admin;
      case 'суперадмин':
        return EmployeeRole.superAdmin;
      case 'директор':
        return EmployeeRole.director;
      default:
        throw Exception('Неизвестная роль: $apiValue');
    }
  }

  String toLabel() {
    switch (this) {
      case EmployeeRole.accountant:
        return 'Бухгалтер';
      case EmployeeRole.employee:
        return 'Сотрудник';
      case EmployeeRole.admin:
        return 'Администратор';
      case EmployeeRole.superAdmin:
        return 'Супер админ';
      case EmployeeRole.director:
        return 'Директор';
    }
  }

  static EmployeeRole fromLabel(String label) {
    switch (label.trim().toLowerCase()) {
      case 'бухгалтер':
        return EmployeeRole.accountant;
      case 'сотрудник':
        return EmployeeRole.employee;
      case 'администратор':
        return EmployeeRole.admin;
      case 'суперадминистратор':
      case 'супер админ':
        return EmployeeRole.superAdmin;
      case 'директор':
        return EmployeeRole.director;
      default:
        throw Exception('Неизвестная роль: $label');
    }
  }

  String toApi() {
    switch (this) {
      case EmployeeRole.accountant:
        return 'бухгалтер';
      case EmployeeRole.employee:
        return 'сотрудник';
      case EmployeeRole.admin:
        return 'админ';
      case EmployeeRole.superAdmin:
        return 'суперадмин';
      case EmployeeRole.director:
        return 'директор';
    }
  }

  int get level {
    switch (this) {
      case EmployeeRole.superAdmin:
        return 4;
      case EmployeeRole.director:
        return 3;
      case EmployeeRole.admin:
        return 2;
      case EmployeeRole.accountant:
        return 1;
      case EmployeeRole.employee:
        return 0;
    }
  }

  bool canAssign(EmployeeRole targetRole) {
    return targetRole.level <= level;
  }
}

enum Permission {
  createCredits,
  deleteCredits,
  viewAnalytic,
  viewAllCredits,
  forbidCreatingCredits,
  forbidCreatingPayments,
  forbidDeletingPayments,
  forbidCreditApplications,
  manageAccounting,
}

extension PermissionMapper on Permission {
  static Permission fromApi(String apiValue) {
    switch (apiValue.toUpperCase()) {
      case 'CREATE_CREDITS':
        return Permission.createCredits;
      case 'DELETE_CREDITS':
        return Permission.deleteCredits;
      case 'VIEW_ANALYTIC':
        return Permission.viewAnalytic;
      case 'VIEW_ALL_CREDITS':
        return Permission.viewAllCredits;
      case 'FORBID_CREATING_CREDITS':
        return Permission.forbidCreatingCredits;
      case 'FORBID_CREATING_PAYMENTS':
        return Permission.forbidCreatingPayments;
      case 'FORBID_DELETING_PAYMENTS':
        return Permission.forbidDeletingPayments;
      case 'FORBID_CREDIT_APPLICATIONS':
        return Permission.forbidCreditApplications;
      case 'MANAGE_ACCOUNTING':
        return Permission.manageAccounting;
      default:
        throw Exception('Неизвестное разрешение: $apiValue');
    }
  }

  String toLabel() {
    switch (this) {
      case Permission.createCredits:
        return 'Создание договоров';
      case Permission.deleteCredits:
        return 'Удаление договоров';
      case Permission.viewAnalytic:
        return 'Просмотр аналитики';
      case Permission.viewAllCredits:
        return 'Просмотр чужих договоро';
      case Permission.forbidCreatingCredits:
        return 'Запрет на создание договоров';
      case Permission.forbidCreatingPayments:
        return 'Запрет на добавление платежей';
      case Permission.forbidDeletingPayments:
        return 'Запрет на удаление платежей';
      case Permission.forbidCreditApplications:
        return 'Запрет к заявкам';
      case Permission.manageAccounting:
        return 'Вести бухгалтерский учет';
    }
  }
}

class Employee {
  final int id;
  final String fullName;
  final String address;
  final String phone;
  final EmployeeRole role;
  final List<Permission> permissions;
  final int minSurcharge;
  final String? photoPath;

  Employee({
    required this.id,
    required this.fullName,
    required this.address,
    required this.phone,
    required this.role,
    required this.permissions,
    required this.minSurcharge,
    this.photoPath,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Employee && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  factory Employee.fromJson(Map<String, dynamic> json) {
    final rawPermissions = json['permissions'] as List<dynamic>? ?? [];

    return Employee(
      id: _readIntId(json['id']),
      fullName: json['fullName'] as String? ?? '',
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: EmployeeRoleMapper.fromApi(json['role'] as String? ?? ''),
      permissions: rawPermissions
          .map((p) {
            try {
              if (p is String) {
                return PermissionMapper.fromApi(p);
              } else if (p is Map<String, dynamic> && p.containsKey('code')) {
                return PermissionMapper.fromApi(p['code'] as String);
              } else {
                print('⚠️ Неверный формат permission: $p');
                return null;
              }
            } catch (e) {
              print('⚠️ Неизвестное разрешение: $p, ошибка: $e');
              return null;
            }
          })
          .whereType<Permission>()
          .toList(),
      minSurcharge: (json['minSurcharge'] is int)
          ? json['minSurcharge'] as int
          : (json['minSurcharge'] is double)
          ? (json['minSurcharge'] as double).round()
          : 0,
      photoPath: json['photoPath'] as String?,
    );
  }

  String get roleLabel => role.toLabel();

  List<String> get permissionsLabels =>
      permissions.map((p) => p.toLabel()).toList();
}

int _readIntId(dynamic value) {
  if (value is int) return value;
  if (value is String) {
    final parsed = int.tryParse(value);
    if (parsed != null) return parsed;
    if (value.isNotEmpty) return value.hashCode;
  }
  return 0;
}

class EmployeesResponse {
  final List<Employee> employees;
  final int total;
  final int totalPages;
  final int currentPage;

  EmployeesResponse({
    required this.employees,
    required this.total,
    required this.totalPages,
    required this.currentPage,
  });

  factory EmployeesResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> items = json['items'] ?? [];
    return EmployeesResponse(
      employees: items.map((e) => Employee.fromJson(e)).toList(),
      total: json['totalCount'] ?? items.length,
      totalPages: json['totalPages'] ?? 1,
      currentPage: json['page'] ?? 1,
    );
  }
}

class EmployeeName {
  final int id;
  final String fullName;

  EmployeeName({required this.id, required this.fullName});

  factory EmployeeName.fromJson(Map<String, dynamic> json) {
    return EmployeeName(
      id: _readIntId(json['id']),
      fullName: json['fullName'] as String,
    );
  }
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmployeeName &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
