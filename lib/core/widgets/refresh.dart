import 'package:blacklist_plus_flutter/core/di/dependency_injection.dart';
import 'package:blacklist_plus_flutter/core/storage/user_storage.dart';
import 'package:blacklist_plus_flutter/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:blacklist_plus_flutter/features/profile/data/models/employee.dart';
import 'package:flutter/material.dart';

class Refresher extends StatelessWidget {
  final Widget content;
  final Future<void> Function() onRefresh;

  const Refresher({super.key, required this.content, required this.onRefresh});

  Future<void> _updateUserRole() async {
    final authDataSource = getIt<AuthRemoteDataSource>();
    final userStorage = UserStorage();

    try {
      final info = await authDataSource.getAuthInfo();
      final employee = info['employee'] as Map<String, dynamic>?;

      if (employee == null) {
        return;
      }

      final roleStr = employee['role']?.toString() ?? '';
      final role = EmployeeRoleMapper.fromApi(roleStr);
      await userStorage.saveRole(role);

      final permissionsList = (employee['permissions'] as List?) ?? [];
      final permissions = permissionsList
          .map((p) => PermissionMapper.fromApi(p.toString()))
          .toList();
      await userStorage.savePermissions(permissions);
    } catch (e) {}
  }

  Future<void> _handleRefresh() async {
    await _updateUserRole();
    await onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(onRefresh: _handleRefresh, child: content);
  }
}
