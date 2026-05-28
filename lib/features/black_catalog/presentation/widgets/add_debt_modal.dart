import 'package:blacklist_plus_flutter/core/widgets/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chs_ui/chs_styles.dart';

Future<DateTime?> showAddDebtModal({
  required BuildContext context,
  required String itemName,
}) {
  return showDialog<DateTime>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _AddDebtDialog(itemName: itemName),
  );
}

class _AddDebtDialog extends StatefulWidget {
  final String itemName;
  const _AddDebtDialog({required this.itemName});

  @override
  State<_AddDebtDialog> createState() => _AddDebtDialogState();
}

class _AddDebtDialogState extends State<_AddDebtDialog> {
  final _controller = TextEditingController();
  String? _error;
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    final clipped = digits.length > 8 ? digits.substring(0, 8) : digits;
    String formatted = clipped;
    if (clipped.length > 2) {
      formatted = '${clipped.substring(0, 2)}.${clipped.substring(2)}';
    }
    if (clipped.length > 4) {
      formatted =
          '${clipped.substring(0, 2)}.${clipped.substring(2, 4)}.${clipped.substring(4)}';
    }
    if (formatted != value) {
      _controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    if (_error != null) setState(() => _error = null);
  }

  DateTime? _parseDate(String input) {
    final match = RegExp(r'^(\d{2})\.(\d{2})\.(\d{4})$').firstMatch(input);
    if (match == null) return null;
    final day = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final year = int.parse(match.group(3)!);
    try {
      final date = DateTime(year, month, day);
      if (date.day != day || date.month != month || date.year != year) {
        return null;
      }
      return date;
    } catch (_) {
      return null;
    }
  }

  Future<void> _submit() async {
    final input = _controller.text.trim();
    if (input.isEmpty) {
      setState(() => _error = 'Укажите дату окончания долга');
      return;
    }
    final parsed = _parseDate(input);
    if (parsed == null) {
      setState(() => _error = 'Неверный формат даты. Используйте ДД.ММ.ГГГГ');
      return;
    }
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    if (parsed.isBefore(todayStart)) {
      setState(() => _error = 'Дата окончания долга не может быть в прошлом');
      return;
    }
    setState(() => _submitting = true);
    Navigator.of(context).pop(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: 'Добавить долг',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.itemName.isNotEmpty) ...[
            Text(
              widget.itemName,
              style: AppStyle.manrope(
                size: 14,
                weight: FontWeight.w400,
                color: const Color(AppColors.uiBorder),
              ),
            ),
            const SizedBox(height: 12),
          ],
          ModalTextField(
            controller: _controller,
            label: 'Дата окончания долга',
            hintText: 'ДД.ММ.ГГГГ',
            onChanged: _onChanged,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              LengthLimitingTextInputFormatter(10),
            ],
            errorText: _error,
          ),
        ],
      ),
      actions: [
        AppDialogCancelButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
        ),
        SizedBox(
          width: 140,
          child: DefaultButton(
            text: 'Добавить',
            isPrimary: true,
            onPressed: _submitting ? null : _submit,
          ),
        ),
      ],
    );
  }
}
