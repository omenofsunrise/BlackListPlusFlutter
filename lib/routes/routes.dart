enum Routes {
  userTypeSelectionScreen,
  phoneAuthScreen,
  investorsScreen,
  investorsHubScreen,
  investorPoolScreen,
  investorPoolDetailScreen,
  profileScreen,
  profileStatsScreen,
  profileActiveSessionsScreen,
  profileEmployeesScreen,
  profileAddEmployeeScreen,
  financeScreen,
  budgetApplicationsScreen,
  productScreen,
  budgetScreen,
  creditsScreen,
  homeScreen,
  todoScreen,
  chatScreen,
  blogScreen,
  calculatorScreen,
  mainClientScreen,
  clientListScreen,
  clientDetailScreen,
  blacklistScreen,
  blackCatalogDossierScreen,
  notificationsScreen,
  clientCreateScreen,
  clientApplicationDetailScreen,
  clientApplicationsScreen,
  queueListScreen,
  newCreditProductsScreen,
  newCreditDetailsScreen,
  newCreditSchedulesScreen,
  scheduleScreen,
  paymentScreen,
  paymentHistoryScreen,
  paymentDetailScreen,
  paymentAnalyticsScreen,
  paymentIncomeScreen,
  analyticsScreen,
  companyDataScreen,
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
      case Routes.investorsScreen:
        return '/investors_screen';
      case Routes.investorsHubScreen:
        return '/investors_hub_screen';
      case Routes.investorPoolScreen:
        return '/investor_pool_screen';
      case Routes.investorPoolDetailScreen:
        return '/investor_pool_detail_screen';
      case Routes.profileScreen:
        return '/profile_screen';
      case Routes.profileStatsScreen:
        return '/profile_stats_screen';
      case Routes.profileActiveSessionsScreen:
        return '/profile_active_sessions_screen';
      case Routes.profileEmployeesScreen:
        return '/profile_employees_screen';
      case Routes.profileAddEmployeeScreen:
        return '/profile_add_employee_screen';
      case Routes.financeScreen:
        return '/finance_screen';
      case Routes.budgetApplicationsScreen:
        return '/budget_applications_screen';
      case Routes.productScreen:
        return '/product_screen';
      case Routes.budgetScreen:
        return '/budget_screen';
      case Routes.creditsScreen:
        return '/credits_screen';
      case Routes.homeScreen:
        return '/home_screen';
      case Routes.todoScreen:
        return '/todo_screen';
      case Routes.chatScreen:
        return '/chat_screen';
      case Routes.blogScreen:
        return '/blog_creen';
      case Routes.calculatorScreen:
        return '/calculator_screen';
      case Routes.mainClientScreen:
        return '/main_client_screen';
      case Routes.clientListScreen:
        return '/client_list_screen';
      case Routes.clientDetailScreen:
        return '/client_detail_screen';
      case Routes.blacklistScreen:
        return '/blacklist_screen';
      case Routes.blackCatalogDossierScreen:
        return '/black_catalog_dossier_screen';
      case Routes.notificationsScreen:
        return '/notifications_screen';
      case Routes.clientCreateScreen:
        return '/client_create_screen';
      case Routes.clientApplicationDetailScreen:
        return '/client_application_detail_screen';
      case Routes.clientApplicationsScreen:
        return '/client_applications_screen';
      case Routes.queueListScreen:
        return '/queue_list_screen';
      case Routes.newCreditProductsScreen:
        return '/new_credit_products_screen';
      case Routes.newCreditDetailsScreen:
        return '/new_credit_details_screen';
      case Routes.newCreditSchedulesScreen:
        return '/new_credit_schedules_screen';
      case Routes.scheduleScreen:
        return '/schedule_screen';
      case Routes.paymentScreen:
        return '/payment_screen';
      case Routes.paymentHistoryScreen:
        return '/payment_history_screen';
      case Routes.paymentDetailScreen:
        return '/payment_detail_screen';
      case Routes.paymentAnalyticsScreen:
        return '/payment_analytics_screen';
      case Routes.paymentIncomeScreen:
        return '/payment_income_screen';
      case Routes.analyticsScreen:
        return '/analytics_screen';
      case Routes.companyDataScreen:
        return '/company_data_screen';
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
      case Routes.investorsScreen:
        return 'INVESTORS_SCREEN';
      case Routes.investorsHubScreen:
        return 'INVESTORS_HUB_SCREEN';
      case Routes.investorPoolScreen:
        return 'INVESTOR_POOL_SCREEN';
      case Routes.investorPoolDetailScreen:
        return 'INVESTOR_POOL_DETAIL_SCREEN';
      case Routes.profileScreen:
        return 'PROFILE_SCREEN';
      case Routes.profileStatsScreen:
        return 'PROFILE_STATS_SCREEN';
      case Routes.profileActiveSessionsScreen:
        return 'PROFILE_ACTIVE_SESSIONS_SCREEN';
      case Routes.profileEmployeesScreen:
        return 'PROFILE_EMPLOYEES_SCREEN';
      case Routes.profileAddEmployeeScreen:
        return 'PROFILE_ADD_EMPLOYEE_SCREEN';
      case Routes.financeScreen:
        return 'FINANCE_SCREEN';
      case Routes.budgetApplicationsScreen:
        return 'BUDGET_APPLICATIONS_SCREEN';
      case Routes.productScreen:
        return 'PRODUCT_SCREEN';
      case Routes.budgetScreen:
        return 'BUDGET_SCREEN';
      case Routes.creditsScreen:
        return 'CREDITS_SCREEN';
      case Routes.homeScreen:
        return 'HOME_SCREEN';
      case Routes.todoScreen:
        return 'TODO_SCREEN';
      case Routes.chatScreen:
        return 'CHAT_SCREEN';
      case Routes.blogScreen:
        return 'BLOG_SCREEN';
      case Routes.calculatorScreen:
        return 'CALCULATOR_SCREEN';
      case Routes.mainClientScreen:
        return 'MAIN_CLIENT_SCREEN';
      case Routes.clientListScreen:
        return 'CLIENT_LIST_SCREEN';
      case Routes.clientDetailScreen:
        return 'CLIENT_DETAIL_SCREEN';
      case Routes.blacklistScreen:
        return 'BLACKLIST_SCREEN';
      case Routes.blackCatalogDossierScreen:
        return 'BLACK_CATALOG_DOSSIER_SCREEN';
      case Routes.notificationsScreen:
        return 'NOTIFICATIONS_SCREEN';
      case Routes.clientCreateScreen:
        return 'CLIENT_CREATE_SCREEN';
      case Routes.clientApplicationDetailScreen:
        return 'CLIENT_APPLICATION_DETAIL_SCREEN';
      case Routes.clientApplicationsScreen:
        return 'CLIENT_APPLICATIONS_SCREEN';
      case Routes.queueListScreen:
        return 'QUEUE_LIST_SCREEN';
      case Routes.newCreditProductsScreen:
        return 'NEW_CREDIT_PRODUCTS_SCREEN';
      case Routes.newCreditDetailsScreen:
        return 'NEW_CREDIT_DETAILS_SCREEN';
      case Routes.newCreditSchedulesScreen:
        return 'NEW_CREDIT_SCHEDULES_SCREEN';
      case Routes.scheduleScreen:
        return 'SCHEDULE_SCREEN';
      case Routes.paymentScreen:
        return 'PAYMENT_SCREEN';
      case Routes.paymentHistoryScreen:
        return 'PAYMENT_HISTORY_SCREEN';
      case Routes.paymentDetailScreen:
        return 'PAYMENT_DETAIL_SCREEN';
      case Routes.paymentAnalyticsScreen:
        return 'PAYMENT_ANALYTICS_SCREEN';
      case Routes.paymentIncomeScreen:
        return 'PAYMENT_INCOME_SCREEN';
      case Routes.analyticsScreen:
        return 'ANALYTICS_SCREEN';
      case Routes.companyDataScreen:
        return 'COMPANY_DATA_SCREEN';
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
