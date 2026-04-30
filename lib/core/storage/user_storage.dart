import 'package:blacklist_plus_flutter/features/profile/data/models/employee.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserStorage {
  static final UserStorage _instance = UserStorage._internal();

  factory UserStorage() => _instance;

  UserStorage._internal() {
    _init();
  }

  static const _roleKey = 'user_role';
  static const _permissionsKey = 'user_permissions';

  final ValueNotifier<EmployeeRole?> roleNotifier =
      ValueNotifier<EmployeeRole?>(null);

  final ValueNotifier<Set<Permission>> permissionsNotifier =
      ValueNotifier<Set<Permission>>({});

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final roleStr = prefs.getString(_roleKey);
    if (roleStr != null) {
      roleNotifier.value = EmployeeRole.values.firstWhere(
        (r) => r.name == roleStr,
      );
    }
    final perms = prefs.getStringList(_permissionsKey);
    if (perms != null) {
      permissionsNotifier.value = perms
          .map((e) => Permission.values.firstWhere((p) => p.name == e))
          .toSet();
    }
  }

  Future<void> saveRole(EmployeeRole role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role.name);
    roleNotifier.value = role;
  }

  EmployeeRole? getRoleSync() {
    return roleNotifier.value;
  }

  Future<void> savePermissions(List<Permission> permissions) async {
    final prefs = await SharedPreferences.getInstance();
    final list = permissions.map((e) => e.name).toList();
    await prefs.setStringList(_permissionsKey, list);
    permissionsNotifier.value = permissions.toSet();
  }

  Set<Permission> getPermissionsSync() {
    return permissionsNotifier.value;
  }

  Future<Set<Permission>> getPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_permissionsKey);
    if (list == null) return {};
    return list
        .map((e) => Permission.values.firstWhere((p) => p.name == e))
        .toSet();
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_roleKey);
    await prefs.remove(_permissionsKey);
    roleNotifier.value = null;
    permissionsNotifier.value = {};
  }

  bool hasRoleSync(List<EmployeeRole> roles) {
    final role = roleNotifier.value;
    return role != null && roles.contains(role);
  }

  bool forbiddenRoleSync(List<EmployeeRole> roles) {
    final role = roleNotifier.value;
    return role != null && roles.contains(role);
  }

  bool hasPermissionSync(List<Permission> permissions) {
    final role = roleNotifier.value;
    if (_hasAllPrivileges(role)) {
      return true;
    }
    final perms = permissionsNotifier.value;
    return permissions.every((p) => perms.contains(p));
  }

  bool hasAnyPermissionSync(List<Permission> permissions) {
    final role = roleNotifier.value;
    if (_hasAllPrivileges(role)) {
      return true;
    }
    final perms = permissionsNotifier.value;
    return permissions.any((p) => perms.contains(p));
  }

  bool canViewAdminContent() {
    final role = roleNotifier.value;

    return role == EmployeeRole.superAdmin ||
        role == EmployeeRole.director ||
        role == EmployeeRole.admin;
  }

  bool canViewContent() {
    final role = roleNotifier.value;

    return role == EmployeeRole.superAdmin || role == EmployeeRole.director;
  }

  bool hasViewContent(List<EmployeeRole> roles) {
    final role = roleNotifier.value;

    return role != null && roles.contains(role);
  }

  bool hasPermission(Permission permission) {
    final perms = permissionsNotifier.value;
    final hasPermission = perms.contains(permission);

    return hasPermission;
  }

  bool denyPermission(Permission permission) {
    final perms = permissionsNotifier.value;
    return !perms.contains(permission);
  }

  bool _hasAllPrivileges(EmployeeRole? role) {
    return role == EmployeeRole.superAdmin || role == EmployeeRole.director;
  }
}
