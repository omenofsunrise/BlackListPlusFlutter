import 'package:blacklist_plus_flutter/core/network/token_storage.dart';
import 'package:blacklist_plus_flutter/features/auth/presentation/screens/phone_auth_screen.dart';
import 'package:blacklist_plus_flutter/features/black_catalog/data/models/black_catalog_item.dart';
import 'package:blacklist_plus_flutter/features/black_catalog/presentation/screens/black_catalog_dossier_screen.dart';
import 'package:blacklist_plus_flutter/features/black_catalog/presentation/screens/black_catalog_screen.dart';
import 'package:blacklist_plus_flutter/features/black_catalog/presentation/screens/notifications_screen.dart';
import 'package:blacklist_plus_flutter/features/bottom_navigation_bar/main_layout.dart';
import 'package:blacklist_plus_flutter/features/calc/calculator_page.dart';
import 'package:blacklist_plus_flutter/features/info/privacy_policy_screen.dart';
import 'package:blacklist_plus_flutter/features/info/screens/privacy_policy_intro_screen.dart';
import 'package:blacklist_plus_flutter/features/profile/presentation/bloc/employees_bloc.dart';
import 'package:blacklist_plus_flutter/features/profile/presentation/screens/active_sessions_screen.dart';
import 'package:blacklist_plus_flutter/features/profile/presentation/screens/add_employee_screen.dart';
import 'package:blacklist_plus_flutter/features/profile/presentation/screens/employees_screen.dart';
import 'package:blacklist_plus_flutter/features/profile/presentation/screens/profile_screen.dart';
import 'package:blacklist_plus_flutter/features/profile/presentation/screens/profile_statistics_screen.dart';
import 'package:blacklist_plus_flutter/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) async {
      final tokenStorage = TokenStorage();
      var isAuthenticated = await tokenStorage.isAuthenticated();
      final privacyAccepted = await tokenStorage.isPrivacyAccepted();

      final here = state.uri.toString();

      if (isAuthenticated) {
        final access = await tokenStorage.getAccessToken();
        if (access == null) {
          await tokenStorage.setAuthenticated(false);
          isAuthenticated = false;
        }
      }

      if (!privacyAccepted) {
        final allowed = {
          Routes.privacyPolicyIntroScreen.toPath,
          Routes.privacyPolicyScreen.toPath,
        };
        final location = state.uri.toString();
        if (!allowed.contains(location)) {
          return Routes.privacyPolicyIntroScreen.toPath;
        }
        return null;
      }

      if (!isAuthenticated) {
        if (here == '/') return Routes.phoneAuthScreen.toPath;

        final guestAllowed = {Routes.phoneAuthScreen.toPath};
        if (!guestAllowed.contains(here)) {
          return Routes.phoneAuthScreen.toPath;
        }
        return null;
      }
      if (here == '/' || here == Routes.phoneAuthScreen.toPath) {
        return Routes.calculatorScreen.toPath;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const PhoneAuthScreen(userType: 'blacklist_plus'),
      ),
      GoRoute(
        path: Routes.phoneAuthScreen.toPath,
        name: Routes.phoneAuthScreen.toName,
        builder: (context, state) {
          final userType = state.extra as String? ?? 'blacklist_plus';
          return PhoneAuthScreen(userType: userType);
        },
      ),

      GoRoute(
        path: Routes.privacyPolicyIntroScreen.toPath,
        name: Routes.privacyPolicyIntroScreen.toName,
        builder: (context, state) => const PrivacyPolicyIntroScreen(),
      ),
      GoRoute(
        path: Routes.privacyPolicyScreen.toPath,
        name: Routes.privacyPolicyScreen.toName,
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainLayout(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.calculatorScreen.toPath,
                name: Routes.calculatorScreen.toName,
                builder: (context, state) => const CalculatorScreen(),
              ),
            ],
          ),
          // Вкладка «Чёрный список» (порт BlackCatalogPage из waypay-react).
          // Должна совпадать по индексу с _navConfigs[1] в main_layout.dart.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.blacklistScreen.toPath,
                name: Routes.blacklistScreen.toName,
                builder: (context, state) => const BlackCatalogScreen(),
              ),
            ],
          ),
          // Вкладка «Уведомления» (порт NotificationsPage из waypay-react).
          // Должна совпадать по индексу с _navConfigs[2] в main_layout.dart.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.notificationsScreen.toPath,
                name: Routes.notificationsScreen.toName,
                builder: (context, state) => const NotificationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profileScreen.toPath,
                name: Routes.profileScreen.toName,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Routes.profileActiveSessionsScreen.toPath,
        name: Routes.profileActiveSessionsScreen.toName,
        builder: (context, state) => const ActiveSessionsScreen(),
      ),
      GoRoute(
        path: Routes.profileEmployeesScreen.toPath,
        name: Routes.profileEmployeesScreen.toName,
        builder: (context, state) => const EmployeesScreen(),
      ),
      GoRoute(
        path: Routes.profileAddEmployeeScreen.toPath,
        name: Routes.profileAddEmployeeScreen.toName,
        builder: (context, state) {
          final bloc = state.extra as EmployeesBloc?;
          if (bloc == null) {
            return const Scaffold(
              body: Center(child: Text('Нет данных для создания')),
            );
          }
          return AddEmployeeScreen(employeesBloc: bloc);
        },
      ),
      GoRoute(
        path: Routes.profileStatsScreen.toPath,
        name: Routes.profileStatsScreen.toName,
        builder: (context, state) {
          final employeeId = state.extra as int?;
          return ProfileStatisticsScreen(employeeId: employeeId);
        },
      ),
      // Досье записи чёрного каталога — открывается тапом по карточке.
      // Это отдельный экран ВНЕ shell-роута: он перекрывает нижний бар, как
      // и другие "детали" (active sessions, employees и т.д.). Принимает
      // BlackCatalogItem через `extra`.
      GoRoute(
        path: Routes.blackCatalogDossierScreen.toPath,
        name: Routes.blackCatalogDossierScreen.toName,
        builder: (context, state) {
          final item = state.extra as BlackCatalogItem?;
          if (item == null) {
            return const Scaffold(
              body: Center(child: Text('Запись не передана')),
            );
          }
          return BlackCatalogDossierScreen(initialItem: item);
        },
      ),
    ],
  );
}
