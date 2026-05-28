import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:chs_ui/chs_styles.dart';

class CallConfirmationDialog extends StatefulWidget {
  final String callPhone;
  final String checkId;
  final String phone;
  final Future<void> Function() onTryConfirm;

  const CallConfirmationDialog({
    super.key,
    required this.callPhone,
    required this.checkId,
    required this.phone,
    required this.onTryConfirm,
  });

  @override
  State<CallConfirmationDialog> createState() => _CallConfirmationDialogState();
}

class _CallConfirmationDialogState extends State<CallConfirmationDialog> {
  Timer? _timer;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _startAutoCheck();
  }

  void _startAutoCheck() {
    _timer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_isChecking) return;

      try {
        setState(() => _isChecking = true);
        await widget.onTryConfirm();
      } finally {
        if (mounted) {
          setState(() => _isChecking = false);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _callNumber() async {
    final digits = widget.callPhone.replaceAll(RegExp(r'\\D'), '');
    if (digits.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: digits);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть телефон')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Подтверждение авторизации',
              style: AppStyle.semiBold20,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Для завершения авторизации позвоните на номер:',
              style: AppStyle.medium16.copyWith(
                color: const Color(AppColors.grey),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _callNumber,
              child: Text(
                widget.callPhone,
                style: AppStyle.inter(
                  size: 20,
                  weight: FontWeight.w700,
                  color: const Color(AppColors.primary),
                ).copyWith(decoration: TextDecoration.underline),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'После звонка проверка будет происходить автоматически.',
              style: AppStyle.medium16.copyWith(
                color: const Color(AppColors.grey),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
