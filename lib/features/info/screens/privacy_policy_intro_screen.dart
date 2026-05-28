import 'package:blacklist_plus_flutter/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:chs_ui/chs_styles.dart';

class PrivacyPolicyIntroScreen extends StatelessWidget {
  const PrivacyPolicyIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),
              Image.asset(
                'assets/images/app_icon.png',
                width: 124,
                height: 124,
              ),
              const SizedBox(height: 40),
              Text(
                'Добро пожаловать!',
                textAlign: TextAlign.center,
                style: AppStyle.manrope(
                  size: 24,
                  weight: FontWeight.w600,
                  color: const Color(AppColors.black),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Для продолжения необходимо ознакомиться и принять политику конфиденциальности',
                textAlign: TextAlign.center,
                style: AppStyle.manrope(
                  size: 16,
                  weight: FontWeight.w400,
                  color: const Color(AppColors.uiBorder),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: DefaultButton(
                  text: 'Ознакомиться',
                  onPressed: () =>
                      context.push(Routes.privacyPolicyScreen.toPath),
                  color: Color(AppColors.primary),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
