import 'package:flutter/material.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

Future<String?> showNameRequiredDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (_) => const _NameRequiredDialog(),
  );
}

class _NameRequiredDialog extends StatefulWidget {
  const _NameRequiredDialog();

  @override
  State<_NameRequiredDialog> createState() => _NameRequiredDialogState();
}

class _NameRequiredDialogState extends State<_NameRequiredDialog> {
  final _controller = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _error = 'Введите ФИО');
      return;
    }
    setState(() => _submitting = true);
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = !_submitting && _controller.text.trim().isNotEmpty;
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Как вас зовут?',
                style: TextStyle(
                  fontSize: 27,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              ModalTextField(
                controller: _controller,
                label: 'ФИО',
                hintText: 'Иванов Иван Иванович',
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                  setState(() {});
                },
                errorText: _error,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: DefaultButton(
                  text: 'Подтвердить',
                  isPrimary: true,
                  onPressed: canSubmit ? _submit : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
