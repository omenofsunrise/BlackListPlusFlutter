import 'package:blacklist_plus_flutter/features/profile/presentation/widgets/credit_count.dart';
import 'package:blacklist_plus_flutter/features/profile/presentation/widgets/payment_stats_table.dart';
import 'package:flutter/material.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class ProfileStatisticsScreen extends StatelessWidget {
  final int? employeeId;
  const ProfileStatisticsScreen({super.key, this.employeeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Header(
                title: 'Статистика',
                showBackButton: true,
                showNotifications: false,
              ),
              const SizedBox(height: 16),
              PaymentStatsProfileTable(employeeId: employeeId),
              const SizedBox(height: 24),
              CreditCount(employeeId: employeeId),
            ],
          ),
        ),
      ),
    );
  }
}
