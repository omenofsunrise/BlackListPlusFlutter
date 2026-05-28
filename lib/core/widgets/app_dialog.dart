import 'package:flutter/material.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class AppDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;
  final EdgeInsets contentPadding;

  const AppDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
    this.contentPadding = const EdgeInsets.fromLTRB(20, 12, 20, 0),
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(AppColors.white),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      contentPadding: contentPadding,
      actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      title: Text(
        title,
        style: AppStyle.manrope(
          size: 18,
          weight: FontWeight.w700,
          color: const Color(AppColors.black),
        ),
      ),
      content: SingleChildScrollView(child: content),
      actions: actions,
    );
  }
}

class AppDialogCancelButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  const AppDialogCancelButton({
    super.key,
    this.text = 'Отмена',
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed ?? () => Navigator.of(context).pop(),
      child: Text(
        text,
        style: AppStyle.manrope(
          size: 14,
          weight: FontWeight.w500,
          color: const Color(AppColors.uiBorder),
        ),
      ),
    );
  }
}

Future<bool> showAppConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String cancelText = 'Отмена',
  String confirmText = 'Подтвердить',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AppDialog(
      title: title,
      content: Text(
        message,
        style: AppStyle.manrope(
          size: 14,
          weight: FontWeight.w400,
          height: 1.4,
          color: const Color(AppColors.uiBorder),
        ),
      ),
      actions: [
        AppDialogCancelButton(
          text: cancelText,
          onPressed: () => Navigator.pop(ctx, false),
        ),
        SizedBox(
          width: 140,
          child: DefaultButton(
            text: confirmText,
            isPrimary: true,
            color: destructive ? const Color(AppColors.red) : null,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ),
      ],
    ),
  );
  return result == true;
}
