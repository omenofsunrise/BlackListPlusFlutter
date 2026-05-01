import 'package:blacklist_plus_flutter/core/di/dependency_injection.dart';
import 'package:blacklist_plus_flutter/features/profile/data/data_sources/employee_remote_data_source.dart';
import 'package:blacklist_plus_flutter/features/profile/data/models/employee.dart';
import 'package:blacklist_plus_flutter/features/profile/presentation/bloc/employees_bloc.dart';
import 'package:blacklist_plus_flutter/features/profile/presentation/bloc/employees_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class AddEmployeeScreen extends StatefulWidget {
  final EmployeesBloc employeesBloc;
  final bool isModal;
  const AddEmployeeScreen({
    super.key,
    required this.employeesBloc,
    this.isModal = false,
  });

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final _fullNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _surchargeController = TextEditingController();
  final _roleController = TextEditingController();
  final phoneFormatter = MaskTextInputFormatter(
    mask: '+7 (###) ###-##-##',
    filter: {'#': RegExp(r'\d')},
  );

  EmployeeRole? _selectedRole;
  bool _isSaving = false;
  bool _canSubmit = false;

  @override
  void initState() {
    super.initState();
    _fullNameController.addListener(_updateCanSubmit);
    _addressController.addListener(_updateCanSubmit);
    _phoneController.addListener(_updateCanSubmit);
    _surchargeController.addListener(_updateCanSubmit);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _surchargeController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  void _updateCanSubmit() {
    final digits = phoneFormatter.getUnmaskedText();
    final isFilled =
        _fullNameController.text.trim().isNotEmpty &&
        _addressController.text.trim().isNotEmpty &&
        digits.length == 10 &&
        _surchargeController.text.trim().isNotEmpty &&
        _selectedRole != null;
    if (_canSubmit != isFilled) {
      setState(() {
        _canSubmit = isFilled;
      });
    }
  }

  Future<void> _save() async {
    final fullName = _fullNameController.text.trim();
    final address = _addressController.text.trim();
    final digits = phoneFormatter.getUnmaskedText();
    final surchargeText = _surchargeController.text.trim();

    if (fullName.isEmpty) {
      _showError('Введите ФИО');
      return;
    }
    if (address.isEmpty) {
      _showError('Введите адрес');
      return;
    }
    if (_selectedRole == null) {
      _showError('Выберите роль');
      return;
    }
    if (digits.length != 10) {
      _showError('Введите корректный номер телефона');
      return;
    }
    final minSurcharge = int.tryParse(surchargeText);
    if (minSurcharge == null) {
      _showError('Введите корректную надбавку');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await getIt<EmployeeRemoteDataSource>().createEmployee(
        fullName: fullName,
        phone: '7$digits',
        address: address,
        minSurcharge: minSurcharge,
        role: _selectedRole!.toApi(),
      );
      widget.employeesBloc.add(LoadEmployeesEvent(page: 1));
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Сотрудник добавлен')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка создания: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _pickRole() async {
    final role = await showModalBottomSheet<EmployeeRole>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: EmployeeRole.values.map((role) {
            if (role == EmployeeRole.superAdmin ||
                role == EmployeeRole.director ||
                role == EmployeeRole.accountant) {
              return const SizedBox.shrink();
            }
            return ListTile(
              title: Text(role.toLabel()),
              onTap: () => Navigator.pop(sheetContext, role),
            );
          }).toList(),
        ),
      ),
    );

    if (role != null) {
      setState(() {
        _selectedRole = role;
        _roleController.text = role.toLabel();
      });
      _updateCanSubmit();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildPickerField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
    Widget? customSuffixIcon,
  }) {
    return ModalTextField(
      controller: controller,
      label: label,
      hintText: label,
      readOnly: true,
      onTap: onTap,
      suffixIcon:
          customSuffixIcon ??
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(AppColors.uiBorder),
          ),
      suffixIconConstraints: const BoxConstraints(
        minHeight: 24,
        minWidth: 32,
        maxWidth: 60,
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return ModalTextField(
      controller: controller,
      label: label,
      hintText: label,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final double bottomPadding = widget.isModal ? 16.0 : 16.0 + bottomInset;

    final content = SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Header(
              title: 'Добавление сотрудника',
              showBackButton: true,
              showNotifications: false,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _fullNameController,
              label: 'ФИО сотрудника',
            ),
            const SizedBox(height: 12),
            _buildInputField(controller: _addressController, label: 'Адрес'),
            const SizedBox(height: 12),
            _buildPickerField(
              controller: _roleController,
              label: 'Роль',
              onTap: _pickRole,
            ),
            const SizedBox(height: 12),
            _buildInputField(
              controller: _phoneController,
              label: 'Телефон',
              keyboardType: TextInputType.phone,
              inputFormatters: [phoneFormatter],
            ),
            const SizedBox(height: 12),
            _buildInputField(
              controller: _surchargeController,
              label: 'Минимальная надбавка, %',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: DefaultButton(
                    text: 'Отменить',
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    isPrimary: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DefaultButton(
                    text: _isSaving ? 'Сохранение...' : 'Сохранить',
                    onPressed: _isSaving || !_canSubmit ? null : _save,
                    isPrimary: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (widget.isModal) {
      return AnimatedPadding(
        padding: EdgeInsets.only(bottom: bottomInset),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Material(color: Colors.white, child: content),
        ),
      );
    }

    return Scaffold(backgroundColor: Colors.white, body: content);
  }
}
