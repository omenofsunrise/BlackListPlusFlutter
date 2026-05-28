enum Routes {
  userTypeSelectionScreen,
  phoneAuthScreen,
  profileScreen,
  homeScreen,
  calculatorScreen,
  blacklistScreen,
  blackCatalogDossierScreen,
  notificationsScreen,
  privacyPolicyScreen,
  privacyPolicyIntroScreen,
  templatesScreen,
  templateDetailScreen,
  statsScreen,
}

extension RoutesExtension on Routes {
  String get toPath {
    switch (this) {
      case Routes.userTypeSelectionScreen:
        return '/user_type_selection_screen';
      case Routes.phoneAuthScreen:
        return '/phone_auth_screen';
      case Routes.profileScreen:
        return '/profile_screen';
      case Routes.homeScreen:
        return '/home_screen';
      case Routes.calculatorScreen:
        return '/calculator_screen';
      case Routes.blacklistScreen:
        return '/blacklist_screen';
      case Routes.blackCatalogDossierScreen:
        return '/black_catalog_dossier_screen';
      case Routes.notificationsScreen:
        return '/notifications_screen';
      case Routes.privacyPolicyScreen:
        return '/privacy_policy_screen';
      case Routes.privacyPolicyIntroScreen:
        return '/privacy_policy_intro_screen';
      case Routes.templatesScreen:
        return '/templates_screen';
      case Routes.templateDetailScreen:
        return '/template_detail_screen';
      case Routes.statsScreen:
        return '/stats_screen';
    }
  }

  String get toName {
    switch (this) {
      case Routes.userTypeSelectionScreen:
        return 'USER_TYPE_SELECTION_SCREEN';
      case Routes.phoneAuthScreen:
        return 'PHONE_AUTH_SCREEN';
      case Routes.profileScreen:
        return 'PROFILE_SCREEN';
      case Routes.homeScreen:
        return 'HOME_SCREEN';
      case Routes.calculatorScreen:
        return 'CALCULATOR_SCREEN';
      case Routes.blacklistScreen:
        return 'BLACKLIST_SCREEN';
      case Routes.blackCatalogDossierScreen:
        return 'BLACK_CATALOG_DOSSIER_SCREEN';
      case Routes.notificationsScreen:
        return 'NOTIFICATIONS_SCREEN';
      case Routes.privacyPolicyScreen:
        return 'PRIVACY_POLICY_SCREEN';
      case Routes.privacyPolicyIntroScreen:
        return 'PRIVACY_POLICY_INTRO_SCREEN';
      case Routes.templatesScreen:
        return 'TEMPLATES_SCREEN';
      case Routes.templateDetailScreen:
        return 'TEMPLATE_DETAIL_SCREEN';
      case Routes.statsScreen:
        return 'STATS_SCREEN';
    }
  }
}
