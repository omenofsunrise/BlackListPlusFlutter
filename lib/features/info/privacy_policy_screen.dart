import 'package:blacklist_plus_flutter/core/network/token_storage.dart';
import 'package:blacklist_plus_flutter/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Header(
                  title: '',
                  showBackButton: true,
                  showNotifications: false,
                  showAvatar: false,
                ),
              ),
              Text(
                '1. Общие положения',
                style: AppStyle.manrope(size: 18, weight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  textAlign: TextAlign.justify,
                  'Настоящая Политика конфиденциальности персональных данных (далее - Политика конфиденциальности) действует в отношении всей информации, которую приложение может получить о пользователе во время использования.',
                  style: AppStyle.manrope(size: 16, weight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '2. Персональные данные пользователей',
                textAlign: TextAlign.center,
                style: AppStyle.manrope(size: 18, weight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  textAlign: TextAlign.justify,
                  'Приложение может собирать и обрабатывать следующие персональные данные: имя, контактные данные (телефон, email), технические данные устройства (модель, версия ОС).',
                  style: AppStyle.manrope(size: 16, weight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '3. Цели сбора персональных данных',
                style: AppStyle.manrope(size: 18, weight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  textAlign: TextAlign.justify,
                  'Персональные данные собираются для: предоставления услуг, улучшения качества работы приложения, связи с пользователем.',
                  style: AppStyle.manrope(size: 16, weight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '4. Условия обработки персональных данных',
                textAlign: TextAlign.center,
                style: AppStyle.manrope(size: 18, weight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  textAlign: TextAlign.justify,
                  'Обработка персональных данных осуществляется с согласия пользователя. Приложение принимает необходимые меры для защиты персональных данных.',
                  style: AppStyle.manrope(size: 16, weight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '5. Контактная информация',
                style: AppStyle.manrope(size: 18, weight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  textAlign: TextAlign.justify,
                  'По вопросам, связанным с политикой конфиденциальности, вы можете обратиться по телефону: 8 (995) 702-23-04 (Элипханов Ибрахим Султанович).',
                  style: AppStyle.manrope(size: 16, weight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: DefaultButton(
                    text: 'Принять и продолжить',
                    isPrimary: true,
                    onPressed: () async {
                      await TokenStorage().setPrivacyAccepted(true);
                      if (context.mounted) {
                        context.go(Routes.phoneAuthScreen.toPath);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
