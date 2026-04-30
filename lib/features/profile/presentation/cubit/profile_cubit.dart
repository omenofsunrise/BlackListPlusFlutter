import 'package:blacklist_plus_flutter/core/di/dependency_injection.dart';
import 'package:blacklist_plus_flutter/core/network/token_storage.dart';
import 'package:blacklist_plus_flutter/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:blacklist_plus_flutter/features/profile/data/data_sources/employee_remote_data_source.dart';
import 'package:blacklist_plus_flutter/features/profile/data/models/employee.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final AuthRemoteDataSource _dataSource = getIt<AuthRemoteDataSource>();
  final EmployeeRemoteDataSource _employeeDataSource =
      getIt<EmployeeRemoteDataSource>();
  final TokenStorage _tokenStorage = getIt<TokenStorage>();

  ProfileCubit() : super(ProfileInitial());

  Future<void> loadProfile() async {
    emit(ProfileLoading());
    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      emit(ProfileError('Сессия истекла. Пожалуйста, войдите снова.'));
      return;
    }
    try {
      final info = await _dataSource.getAuthInfo();
      final employeeJson = info['employee'] as Map<String, dynamic>?;

      if (employeeJson == null) {
        emit(ProfileError('Данные пользователя не найдены'));
        return;
      }

      final employee = Employee.fromJson(employeeJson);

      final role = employee.role;
      final permissions = employee.permissions;

      emit(
        ProfileLoaded(
          employee: employee,
          role: role,
          permissions: permissions,
          myProfile: true,
        ),
      );
    } catch (e) {
      emit(ProfileError('Ошибка загрузки профиля: $e'));
    }
  }

  Future<void> loadProfileById(int id) async {
    emit(ProfileLoading());

    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      emit(ProfileError('Сессия истекла. Пожалуйста, войдите снова.'));
      return;
    }

    try {
      final authInfo = await _dataSource.getAuthInfo();
      final currentUserId =
          (authInfo['employee'] as Map<String, dynamic>?)?['id'];

      final employeeJson = await _employeeDataSource.getEmployeeById(id);
      final employee = Employee.fromJson(employeeJson);

      emit(
        ProfileLoaded(
          employee: employee,
          role: employee.role,
          permissions: employee.permissions,
          myProfile: employee.id == currentUserId,
        ),
      );
    } catch (e) {
      emit(ProfileError('Ошибка загрузки профиля сотрудника: $e'));
    }
  }

  Future<void> updateEmployeeProfile({
    required int id,
    required String fullName,
    required String address,
  }) async {
    emit(ProfileLoading());
    try {
      final info = await _dataSource.getAuthInfo();
      final employeeJson = info['employee'] as Map<String, dynamic>?;

      if (employeeJson == null) {
        emit(ProfileError('Данные пользователя не найдены'));
        return;
      }

      final employee = Employee.fromJson(employeeJson);
      if (employee.id == id) {
        await _employeeDataSource.updateEmployeeProfile(
          id: id,
          fullName: fullName,
          address: address,
        );
      }

      await loadProfileById(id);
    } catch (e) {
      emit(ProfileError('Ошибка обновления профиля: $e'));
    }
  }

  Future<void> uploadEmployeePhoto({
    required int id,
    required String filePath,
  }) async {
    emit(ProfileLoading());
    try {
      final info = await _dataSource.getAuthInfo();
      final employeeJson = info['employee'] as Map<String, dynamic>?;

      if (employeeJson == null) {
        emit(ProfileError('Данные пользователя не найдены'));
        return;
      }

      final employee = Employee.fromJson(employeeJson);
      if (employee.id == id) {
        await _employeeDataSource.uploadEmployeePhoto(
          id: id,
          filePath: filePath,
        );
      }

      await loadProfileById(id);
    } catch (e) {
      emit(ProfileError('Ошибка загрузки фото: $e'));
    }
  }

  Future<void> deleteEmployeePhoto() async {
    emit(ProfileLoading());
    try {
      await _employeeDataSource.deleteEmployeePhoto();
      await loadProfile();
    } catch (e) {
      emit(ProfileError('Ошибка удаления фото: $e'));
    }
  }

  Future<void> updateEmployeeById({
    required int id,
    String? role,
    String? phone,
    int? minSurcharge,
  }) async {
    emit(ProfileLoading());

    try {
      if (role != null) {
        await _employeeDataSource.updateEmployeeRole(id, role);
      }
      if (phone != null) {
        await _employeeDataSource.updateEmployeePhone(id, phone);
      }
      if (minSurcharge != null) {
        await _employeeDataSource.updateEmployeeMinSurcharge(id, minSurcharge);
      }

      await loadProfileById(id);
    } catch (e) {
      emit(ProfileError('Ошибка обновления данных сотрудника: $e'));
    }
  }
}
