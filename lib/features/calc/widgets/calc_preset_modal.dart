import 'package:blacklist_plus_flutter/core/widgets/app_dialog.dart';
import 'package:blacklist_plus_flutter/features/calc/data/calc_preset.dart';
import 'package:blacklist_plus_flutter/features/calc/data/calculation_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:chs_ui/chs_styles.dart';

class CalcPresetFormResult {
  final String title;
  final int amount;
  final int months;
  final int initial;
  final int percent;
  final int round;
  final CalculationMode mode;

  const CalcPresetFormResult({
    required this.title,
    required this.amount,
    required this.months,
    required this.initial,
    required this.percent,
    required this.round,
    required this.mode,
  });
}

Future<CalcPresetFormResult?> showCalcPresetModal({
  required BuildContext context,
  CalcPreset? editing,
}) {
  return showDialog<CalcPresetFormResult>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _CalcPresetDialog(editing: editing),
  );
}

class _CalcPresetDialog extends StatefulWidget {
  final CalcPreset? editing;
  const _CalcPresetDialog({this.editing});

  @override
  State<_CalcPresetDialog> createState() => _CalcPresetDialogState();
}

class _CalcPresetDialogState extends State<_CalcPresetDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _monthsController;
  late final TextEditingController _initialController;
  late final TextEditingController _percentController;
  late final TextEditingController _roundController;

  String? _titleError;
  String? _amountError;
  String? _monthsError;
  String? _percentError;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _titleController = TextEditingController(text: e?.title ?? '');
    _amountController = TextEditingController(
      text: e == null ? '' : _formatMoney(e.amount),
    );
    _monthsController = TextEditingController(
      text: e == null ? '' : e.months.toString(),
    );
    _initialController = TextEditingController(
      text: (e == null || e.initial == 0) ? '' : _formatMoney(e.initial),
    );
    _percentController = TextEditingController(
      text: e == null ? '' : e.percent.toString(),
    );
    _roundController = TextEditingController(
      text: (e?.round ?? 50).toString(),
    );
  }

  static String _formatMoney(int value) {
    final raw = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (i > 0 && (raw.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(raw[i]);
    }
    return buffer.toString();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _monthsController.dispose();
    _initialController.dispose();
    _percentController.dispose();
    _roundController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    final amountStr = _amountController.text.replaceAll(' ', '');
    final amount = int.tryParse(amountStr) ?? 0;
    final months = int.tryParse(_monthsController.text) ?? 0;
    final initialStr = _initialController.text.replaceAll(' ', '');
    final initial = int.tryParse(initialStr) ?? 0;
    final percent = int.tryParse(_percentController.text) ?? 0;
    final round = int.tryParse(_roundController.text) ?? 50;

    bool ok = true;
    if (title.isEmpty) {
      setState(() => _titleError = 'Укажите название категории');
      ok = false;
    } else {
      _titleError = null;
    }
    if (amount <= 0) {
      setState(() => _amountError = 'Сумма больше нуля');
      ok = false;
    } else {
      _amountError = null;
    }
    if (months < 2) {
      setState(() => _monthsError = 'Минимум 2 месяца');
      ok = false;
    } else {
      _monthsError = null;
    }
    if (percent < 0 || percent > 1000) {
      setState(() => _percentError = 'Наценка от 0 до 1000%');
      ok = false;
    } else {
      _percentError = null;
    }
    if (!ok) return;

    Navigator.of(context).pop(
      CalcPresetFormResult(
        title: title,
        amount: amount,
        months: months,
        initial: initial,
        percent: percent,
        round: round,
        mode: widget.editing?.mode ?? CalculationMode.standard,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editing != null;
    return AppDialog(
      title: isEdit ? 'Редактировать категорию' : 'Новая категория наценки',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            ModalTextField(
              controller: _titleController,
              label: 'Название',
              hintText: 'Например, Авто или Бытовая техника',
              errorText: _titleError,
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 12),
            ModalTextField(
              controller: _amountController,
              label: 'Сумма товара, ₽',
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
            ModalTextField(
              controller: _monthsController,
              label: 'Срок рассрочки, мес',
              hintText: '12',
              errorText: _monthsError,
              keyboardType: const TextInputType.numberWithOptions(),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 12),
            ModalTextField(
              controller: _percentController,
              label: 'Наценка, %',
              hintText: '20',
              errorText: _percentError,
              keyboardType: const TextInputType.numberWithOptions(),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 12),
            ModalTextField(
              controller: _initialController,
              label: 'Первоначальный взнос (необязательно), ₽',
              hintText: '0',
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
          ModalTextField(
            controller: _roundController,
            label: 'Округлять до, ₽',
            hintText: '50',
            keyboardType: const TextInputType.numberWithOptions(),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ],
      ),
      actions: [
        const AppDialogCancelButton(),
        SizedBox(
          width: 140,
          child: DefaultButton(
            text: isEdit ? 'Сохранить' : 'Создать',
            isPrimary: true,
            onPressed: _submit,
          ),
        ),
      ],
    );
  }
}
