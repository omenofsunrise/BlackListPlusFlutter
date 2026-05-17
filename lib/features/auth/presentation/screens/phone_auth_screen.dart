import 'package:blacklist_plus_flutter/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:blacklist_plus_flutter/core/di/dependency_injection.dart';
import 'package:blacklist_plus_flutter/core/utils/moderation_utils.dart';
import 'package:blacklist_plus_flutter/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:blacklist_plus_flutter/features/auth/presentation/widgets/call_confirmation_dialog.dart';
import 'package:blacklist_plus_flutter/features/auth/presentation/widgets/name_required_dialog.dart';
import 'package:blacklist_plus_flutter/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class PhoneAuthScreen extends StatefulWidget {
  final String userType;

  const PhoneAuthScreen({super.key, required this.userType});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  final _phoneFocus = FocusNode();
  final _phoneFormatter = MaskTextInputFormatter(
    mask: ' (###) ###-##-##',
    filter: {"#": RegExp(r'\d')},
  );
  bool _isDialogShowing = false;
  bool _isNameDialogShowing = false;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _phoneFocus.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _phoneFocus.removeListener(_onFocusChanged);
    _phoneFocus.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(enableRegistration: true),
      child: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          debugPrint('🎯 Состояние AuthCubit изменилось: $state');

          if (state is AuthNameRequired) {
            debugPrint('📝 Показываем диалог ввода ФИО');

            if (!_isNameDialogShowing) {
              _isNameDialogShowing = true;
              final cubit = context.read<AuthCubit>();
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                final name = await showNameRequiredDialog(context);
                _isNameDialogShowing = false;
                if (!mounted) return;
                final trimmed = name?.trim() ?? '';
                if (trimmed.isNotEmpty) {
                  await cubit.submitName(trimmed);
                }
              });
            }
          }

          if (state is AuthCodeSent) {
            debugPrint('📞 Показываем диалог подтверждения');
            final formattedPhone = '8${_phoneFormatter.getUnmaskedText()}';

            if (!_isDialogShowing) {
              _isDialogShowing = true;

              WidgetsBinding.instance.addPostFrameCallback((_) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => CallConfirmationDialog(
                    callPhone: state.callPhone,
                    checkId: state.checkId,
                    phone: formattedPhone,
                    onTryConfirm: () async {
                      await context.read<AuthCubit>().confirmCall(
                        state.checkId,
                        formattedPhone,
                      );
                    },
                  ),
                ).then((_) {});
              });
            }
          }

          if (state is AuthSuccess) {
            debugPrint('✅ AuthSuccess получен, закрываем диалог и переходим');

            if (_isDialogShowing && Navigator.canPop(context)) {
              Navigator.of(context, rootNavigator: true).pop();
              _isDialogShowing = false;
            }

            _navigateAfterAuth();
          }

          if (state is AuthError) {
            debugPrint('❌ AuthError: ${state.message}');
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          final errorMessage = state is AuthError ? state.message : null;

          debugPrint(
            '🔄 Builder вызван, состояние: $state, isLoading: $isLoading',
          );

          return Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (errorMessage != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1F0),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFFFCCC7),
                              ),
                            ),
                            child: Text(
                              errorMessage,
                              style: AppStyle.inter(
                                size: 14,
                                weight: FontWeight.w500,
                                color: const Color(0xFFCF1322),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        Text(
                          'Регистрация / Авторизация',
                          style: AppStyle.manrope(
                            size: 24,
                            weight: FontWeight.w600,
                            color: const Color(AppColors.black),
                          ),
                        ),
                        const SizedBox(height: 36),
                        ModalTextField(
                          controller: _phoneController,
                          focusNode: _phoneFocus,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [_phoneFormatter],
                          label: 'Номер телефона',
                          prefixText: '+7',
                          hintText: ' (___) ___-__-__',
                        ),
                        const SizedBox(height: 18),
                        isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : DefaultButton(
                                text: 'Подтвердить',
                                isPrimary: true,
                                onPressed: () {
                                  final digits = _phoneFormatter
                                      .getUnmaskedText();
                                  if (digits.length != 10) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Номер должен состоять из 10 цифр',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  final formattedPhone = '8$digits';
                                  debugPrint(
                                    '🔐 Начинаем авторизацию для: $formattedPhone',
                                  );
                                  context.read<AuthCubit>().startAuth(
                                    formattedPhone,
                                    widget.userType,
                                  );
                                },
                              ),
                      ],
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _navigateAfterAuth() async {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;
    try {
      final authDataSource = getIt<AuthRemoteDataSource>();
      final authInfo = await authDataSource.getAuthInfo();
      final moderated = isUserModerated(authInfo);
      if (!mounted) return;
      context.go(
        moderated
            ? Routes.calculatorScreen.toPath
            : Routes.blacklistScreen.toPath,
      );
    } catch (_) {
      if (!mounted) return;
      context.go(Routes.blacklistScreen.toPath);
    } finally {
      _isNavigating = false;
    }
  }
}
