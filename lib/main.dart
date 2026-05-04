import 'dart:async';
import 'package:blacklist_plus_flutter/core/di/dependency_injection.dart';
import 'package:blacklist_plus_flutter/features/network_error/screens/network_error_screen.dart';
import 'package:blacklist_plus_flutter/features/profile/presentation/bloc/employees_bloc.dart';
import 'package:blacklist_plus_flutter/features/profile/presentation/cubit/credit_stats_cubit.dart';
import 'package:blacklist_plus_flutter/features/profile/presentation/cubit/payment_stats_cubit.dart';
import 'package:blacklist_plus_flutter/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:blacklist_plus_flutter/routes/app_router.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru_RU', null);
  await initDependencies();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool? isOffline;
  late final StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();
    _checkInitial();
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      setState(() {
        isOffline = !hasConnection;
      });
    });
  }

  Future<void> _checkInitial() async {
    final results = await Connectivity().checkConnectivity();
    final hasConnection = results.any((r) => r != ConnectivityResult.none);
    setState(() {
      isOffline = !hasConnection;
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isOffline == null) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: _appTextScaleBuilder,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    final app = isOffline!
        ? const MaterialApp(
            debugShowCheckedModeBanner: false,
            builder: _appTextScaleBuilder,
            home: NetworkErrorScreen(),
          )
        : MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'waypay_mobile',
            builder: _appTextScaleBuilder,
            routerConfig: AppRouter.router,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
              scaffoldBackgroundColor: Colors.white,
              appBarTheme: const AppBarTheme(
                iconTheme: IconThemeData(color: Colors.black),
                backgroundColor: Colors.white,
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              outlinedButtonTheme: OutlinedButtonThemeData(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          );

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<ProfileCubit>()),
        BlocProvider(create: (_) => getIt<EmployeesBloc>()),
        BlocProvider(create: (_) => getIt<PaymentStatsCubit>()),
        BlocProvider(create: (_) => getIt<CreditStatsCubit>()),
      ],
      child: app,
    );
  }
}

Widget _appTextScaleBuilder(BuildContext context, Widget? child) {
  final mediaQuery = MediaQuery.of(context);
  return MediaQuery(
    data: mediaQuery.copyWith(textScaler: const TextScaler.linear(0.94)),
    child: child ?? const SizedBox.shrink(),
  );
}
