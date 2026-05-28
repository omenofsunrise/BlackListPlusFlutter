import 'package:blacklist_plus_flutter/features/black_catalog/data/models/black_catalog_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chs_ui/chs_styles.dart';

enum BlackCatalogAddOption { blacklist, completed }

class BlackCatalogFormResult {
  final String fullname;
  final String doc;
  final String address;
  final String birthdate;
  final String comment;
  final bool isSwindler;
  final String debtEndingAt;

  const BlackCatalogFormResult({
    required this.fullname,
    required this.doc,
    required this.address,
    required this.birthdate,
    required this.comment,
    required this.isSwindler,
    required this.debtEndingAt,
  });
}

Future<BlackCatalogFormResult?> showBlackCatalogFormModal({
  required BuildContext context,
  BlackCatalogItem? editing,
  BlackCatalogAddOption option = BlackCatalogAddOption.blacklist,
}) {
  final showDebtSection =
      editing == null && option == BlackCatalogAddOption.completed;
  final requireDebtDate = showDebtSection;
  return showDialog<BlackCatalogFormResult>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _BlackCatalogFormDialog(
      editing: editing,
      showDebtSection: showDebtSection,
      requireDebtDate: requireDebtDate,
    ),
  );
}

class _BlackCatalogFormDialog extends StatefulWidget {
  final BlackCatalogItem? editing;
  final bool showDebtSection;
  final bool requireDebtDate;

  const _BlackCatalogFormDialog({
    required this.editing,
    required this.showDebtSection,
    required this.requireDebtDate,
  });

  @override
  State<_BlackCatalogFormDialog> createState() =>
      _BlackCatalogFormDialogState();
}

class _BlackCatalogFormDialogState extends State<_BlackCatalogFormDialog> {
  late final TextEditingController _fullnameController;
  late final TextEditingController _birthdateController;
  late final TextEditingController _docController;
  late final TextEditingController _addressController;
  late final TextEditingController _debtEndingController;
  late final TextEditingController _commentController;

  String? _debtError;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    _fullnameController = TextEditingController(text: editing?.fullname ?? '');
    _birthdateController = TextEditingController(
      text: _normalizeIncomingDate(editing?.birthdate),
    );
    _docController = TextEditingController(text: editing?.doc ?? '');
    _addressController = TextEditingController(text: editing?.address ?? '');
    _debtEndingController = TextEditingController();
    _commentController = TextEditingController();
  }

  @override
  void dispose() {
    _fullnameController.dispose();
    _birthdateController.dispose();
    _docController.dispose();
    _addressController.dispose();
    _debtEndingController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  String _normalizeIncomingDate(String? value) {
    if (value == null || value.isEmpty) return '';
    if (value.contains('T')) {
      final datePart = value.split('T').first;
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(datePart)) {
        final parts = datePart.split('-');
        return '${parts[2]}.${parts[1]}.${parts[0]}';
      }
      return datePart;
    }
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      final parts = value.split('-');
      return '${parts[2]}.${parts[1]}.${parts[0]}';
    }
    return value;
  }

  String _formatDateForApi(String input) {
    if (input.isEmpty) return '';
    if (input.contains('T')) return input.split('T').first;
    if (RegExp(r'^\d{2}\.\d{2}\.\d{4}$').hasMatch(input)) {
      final parts = input.split('.');
      return '${parts[2]}-${parts[1]}-${parts[0]}';
    }
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(input)) return input;
    return input;
  }

  String _formatFullName(String input) {
    if (input.isEmpty) return '';
    final parts = <String>[];
    String current = '';
    bool lastWasSpace = false;
    for (final ch in input.split('')) {
      if (ch == ' ') {
        if (!lastWasSpace) {
          if (current.isNotEmpty) {
            parts.add(current);
            current = '';
          }
          parts.add(' ');
        }
        lastWasSpace = true;
      } else {
        current += ch;
        lastWasSpace = false;
      }
    }
    if (current.isNotEmpty) parts.add(current);

    final formatted = parts.map((part) {
      if (part == ' ') return ' ';
      if (part.contains('-')) {
        return part
            .split('-')
            .map((segment) {
              if (segment.isEmpty) return '';
              return segment[0].toUpperCase() +
                  segment.substring(1).toLowerCase();
            })
            .join('-');
      }
      if (part.isNotEmpty) {
        return part[0].toUpperCase() + part.substring(1).toLowerCase();
      }
      return part;
    });
    return formatted.join('');
  }

  void _onFullnameChanged(String value) {
    final formatted = _formatFullName(value);
    if (formatted != value) {
      _fullnameController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  void _onDateChanged(TextEditingController controller, String value) {
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
      controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    if (_debtError != null && controller == _debtEndingController) {
      setState(() => _debtError = null);
    }
  }

  bool _validate() {
    if (widget.showDebtSection &&
        widget.requireDebtDate &&
        widget.editing == null &&
        _debtEndingController.text.trim().isEmpty) {
      setState(() => _debtError = 'Укажите дату окончания оформления');
      return false;
    }
    return true;
  }

  void _submit() {
    if (!_validate()) return;

    setState(() => _submitting = true);

    final isSwindler = widget.editing != null
        ? (widget.editing!.isSwindler ?? false)
        : !widget.showDebtSection;

    final result = BlackCatalogFormResult(
      fullname: _fullnameController.text.trim(),
      doc: _docController.text.trim(),
      address: _addressController.text.trim(),
      birthdate: _formatDateForApi(_birthdateController.text.trim()),
      comment: _commentController.text.trim(),
      isSwindler: isSwindler,
      debtEndingAt: widget.showDebtSection
          ? _formatDateForApi(_debtEndingController.text.trim())
          : '',
    );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editing != null;
    final title = isEditing ? 'Редактировать запись' : 'Добавить запись';
    final saveButton = isEditing ? 'Сохранить' : 'Добавить';

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 16),
                _input(
                  controller: _fullnameController,
                  hint: 'ФИО',
                  onChanged: _onFullnameChanged,
                ),
                const SizedBox(height: 12),
                _input(
                  controller: _birthdateController,
                  hint: 'Дата рождения (ДД.ММ.ГГГГ)',
                  onChanged: (v) => _onDateChanged(_birthdateController, v),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    LengthLimitingTextInputFormatter(10),
                  ],
                ),
                const SizedBox(height: 12),
                _input(
                  controller: _docController,
                  hint: 'Документ (серия и номер)',
                ),
                const SizedBox(height: 12),
                _input(controller: _addressController, hint: 'Адрес'),
                if (!isEditing) ...[
                  if (widget.showDebtSection) ...[
                    const SizedBox(height: 12),
                    _input(
                      controller: _debtEndingController,
                      hint: 'Оформлен до (ДД.ММ.ГГГГ)',
                      onChanged: (v) =>
                          _onDateChanged(_debtEndingController, v),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        LengthLimitingTextInputFormatter(10),
                      ],
                      errorText: _debtError,
                    ),
                  ],
                  const SizedBox(height: 12),
                  ModalTextField(
                    controller: _commentController,
                    label: 'Комментарий',
                    maxLines: 4,
                    minLines: 3,
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: DefaultButton(
                    text: saveButton,
                    isPrimary: true,
                    onPressed: _submitting ? null : _submit,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Отмена'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String hint,
    ValueChanged<String>? onChanged,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? errorText,
  }) {
    return ModalTextField(
      controller: controller,
      label: hint,
      hintText: hint,
      onChanged: onChanged,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      errorText: errorText,
    );
  }
}
