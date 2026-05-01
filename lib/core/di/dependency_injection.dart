import 'package:blacklist_plus_flutter/core/storage/user_storage.dart';
import 'package:blacklist_plus_flutter/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:blacklist_plus_flutter/features/auth/data/data_sources/auth_remote_data_source_impl.dart';
import 'package:blacklist_plus_flutter/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:blacklist_plus_flutter/features/black_catalog/data/data_sources/black_catalog_remote_data_source.dart';
import 'package:blacklist_plus_flutter/features/black_catalog/data/data_sources/black_catalog_remote_data_source_impl.dart';
import 'package:blacklist_plus_flutter/features/profile/data/data_sources/employee_remote_data_source.dart';
import 'package:blacklist_plus_flutter/features/profile/data/data_sources/employee_remote_data_source_impl.dart';
import 'package:blacklist_plus_flutter/features/profile/presentation/bloc/employees_bloc.dart';
import 'package:blacklist_plus_flutter/features/profile/presentation/cubit/credit_stats_cubit.dart';
import 'package:blacklist_plus_flutter/features/profile/presentation/cubit/payment_stats_cubit.dart';
import 'package:blacklist_plus_flutter/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../network/dio_client.dart';
import '../network/token_storage.dart';

final getIt = GetIt.instance;

Future<void> initDependencies() async {
  getIt.registerLazySingleton(() => createDio());
  getIt.registerLazySingleton(() => TokenStorage());
  getIt.registerLazySingleton<UserStorage>(() => UserStorage());

  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(getIt<Dio>()),
  );
  getIt.registerLazySingleton<EmployeeRemoteDataSource>(
    () => EmployeeRemoteDataSourceImpl(getIt<Dio>()),
  );
  getIt.registerLazySingleton<BlackCatalogRemoteDataSource>(
    () => BlackCatalogRemoteDataSourceImpl(getIt<Dio>()),
  );

  getIt.registerFactory(() => AuthCubit());
  getIt.registerFactory(() => ProfileCubit());
  getIt.registerFactory(() => EmployeesBloc());
  getIt.registerFactory(() => PaymentStatsCubit());
  getIt.registerFactory(() => CreditStatsCubit());
}
