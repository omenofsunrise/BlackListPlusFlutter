part of 'profile_cubit.dart';

@immutable
sealed class ProfileState {}

final class ProfileInitial extends ProfileState {}

final class ProfileLoading extends ProfileState {}

final class ProfileLoaded extends ProfileState {
  final Employee employee;
  final EmployeeRole role;
  final List<Permission> permissions;
  final bool myProfile;

  ProfileLoaded({
    required this.employee,
    required this.role,
    required this.permissions,
    required this.myProfile,
  });
}

final class ProfileError extends ProfileState {
  final String message;

  ProfileError(this.message);
}
