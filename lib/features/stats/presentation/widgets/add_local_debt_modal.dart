import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class LocalDebtFormResult {
  final String debtorName;
  final int amountRub;
  final DateTime? dueDate;
  final String? comment;

  const LocalDebtFormResult({
    required this.debtorName,
    required this.amountRub,
    this.dueDate,
    this.comment,
  });
}

Future<LocalDebtFormResult?> showAddLocalDebtModal({
  required BuildContext context,
}) {
  return showDialog<LocalDebtFormResult>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _AddLocalDebtDialog(),
  );
}

class _AddLocalDebtDialog extends StatefulWidget {
  const _AddLocalDebtDialog();

  @override
  State<_AddLocalDebtDialog> createState() => _AddLocalDebtDialogState();
}

class _AddLocalDebtDialogState extends State<_AddLocalDebtDialog> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  final _commentController = TextEditingController();

  DateTime? _selectedDate;
  String? _nameError;
  String? _amountError;
  String? _dateError;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      _dateError = null;
    });
  }

  DateTime? _parseDate(String input) {
    if (input.isEmpty) return null;
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

  void _submit() {
    final name = _nameController.text.trim();
    final amountRaw = _amountController.text.replaceAll(' ', '');
    final amount = int.tryParse(amountRaw) ?? 0;
    final dateInput = _dateController.text.trim();

    bool ok = true;
    if (name.isEmpty) {
      setState(() => _nameError = 'Укажите имя должника');
      ok = false;
    } else {
      _nameError = null;
    }
    if (amount <= 0) {
      setState(() => _amountError = 'Укажите сумму больше нуля');
      ok = false;
    } else {
      _amountError = null;
    }

    DateTime? dueDate = _selectedDate;
    if (dueDate == null && dateInput.isNotEmpty) {
      dueDate = _parseDate(dateInput);
      if (dueDate == null) {
        setState(() => _dateError = 'Формат: ДД.ММ.ГГГГ');
        ok = false;
      }
    }
    if (!ok) return;

    Navigator.of(context).pop(
      LocalDebtFormResult(
        debtorName: name,
        amountRub: amount,
        dueDate: dueDate,
        comment: _commentController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(AppColors.white),
      title: Text(
        'Добавить долг',
        style: AppStyle.manrope(
          size: 18,
          weight: FontWeight.w700,
          color: const Color(AppColors.black),
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ModalTextField(
              controller: _nameController,
              label: 'Имя должника',
              hintText: 'Например, Иван Петров',
              errorText: _nameError,
              keyboardType: TextInputType.name,
            ),
            const SizedBox(height: 12),
            ModalTextField(
              controller: _amountController,
              label: 'Сумма, ₽',
              hintText: '0',
              errorText: _amountError,
              keyboardType: const TextInputType.numberWithOptions(),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                CurrencyInputFormatter(
                  thousandSeparator: ThousandSeparator.Space,
                  mantissaLength: 0,
                  trailingSymbol: '',
                ),
              ],
            ),
            const SizedBox(height: 12),
            DateInput(
              controller: _dateController,
              label: 'Дата возврата (необязательно)',
              onDateSelected: _onDateSelected,
              prefix: 'Возврат до:',
            ),
            if (_dateError != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  _dateError!,
                  style: AppStyle.manrope(
                    size: 12,
                    weight: FontWeight.w400,
                    color: const Color(AppColors.red),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            ModalTextField(
              controller: _commentController,
              label: 'Комментарий (необязательно)',
              hintText: 'За что / на что',
              keyboardType: TextInputType.text,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Отмена',
            style: AppStyle.manrope(
              size: 14,
              weight: FontWeight.w500,
              color: const Color(AppColors.uiBorder),
            ),
          ),
        ),
        SizedBox(
          width: 130,
          child: DefaultButton(
            text: 'Сохранить',
            isPrimary: true,
            onPressed: _submit,
          ),
        ),
      ],
    );
  }
}
