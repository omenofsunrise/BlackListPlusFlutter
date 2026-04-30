import 'package:blacklist_plus_flutter/features/profile/data/models/employee.dart';
import 'package:blacklist_plus_flutter/features/profile/presentation/bloc/employees_bloc.dart';
import 'package:blacklist_plus_flutter/features/profile/presentation/bloc/employees_event.dart';
import 'package:blacklist_plus_flutter/features/profile/presentation/bloc/employees_state.dart';
import 'package:blacklist_plus_flutter/features/profile/presentation/screens/add_employee_screen.dart';
import 'package:blacklist_plus_flutter/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<EmployeesBloc>().add(LoadEmployeesEvent(page: 1));
  }

  void _openAddEmployeeScreen() {
    final bloc = context.read<EmployeesBloc>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: AddEmployeeScreen(employeesBloc: bloc, isModal: true),
      ),
    );
  }

  Future<void> _refresh() async {
    context.read<EmployeesBloc>().add(LoadEmployeesEvent(page: 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Header(
                title: 'Профиль',
                showBackButton: true,
                showNotifications: false,
                trailing: AddButton(onPressed: _openAddEmployeeScreen),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BlocBuilder<EmployeesBloc, EmployeesState>(
                  builder: (context, state) {
                    if (state is EmployeesLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is EmployeesLoaded) {
                      if (state.employees.isEmpty) {
                        return RefreshIndicator(
                          onRefresh: _refresh,
                          child: ListView(
                            children: const [
                              SizedBox(height: 200),
                              Center(child: Text('Сотрудники не найдены')),
                            ],
                          ),
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: state.employees.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final employee = state.employees[index];
                            return _EmployeeCard(
                              employee: employee,
                              onTap: () => context.pushNamed(
                                Routes.profileScreen.toName,
                                extra: employee.id,
                              ),
                            );
                          },
                        ),
                      );
                    }
                    if (state is EmployeesError) {
                      return Center(child: Text(state.message));
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final Employee employee;
  final VoidCallback onTap;

  const _EmployeeCard({required this.employee, required this.onTap});

  String _initials(String name) {
    final parts = name.trim().split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000809),
                offset: Offset(2, 2),
                blurRadius: 4,
              ),
              BoxShadow(color: Color(0x05000809), blurRadius: 6),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(AppColors.primaryLight),
                      child: Text(
                        _initials(employee.fullName),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        employee.fullName,
                        style: AppStyle.manrope(
                          size: 16,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _InfoRow(label: 'Роль', value: employee.roleLabel),
                    ),
                    Expanded(
                      child: _InfoRow(
                        label: 'Мин надбавка',
                        value: '${employee.minSurcharge}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _InfoRow(label: 'Адрес', value: employee.address),
                    ),
                    Expanded(
                      child: _InfoRow(label: 'Телефон', value: employee.phone),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppStyle.manrope(
            size: 14,
            weight: FontWeight.w400,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: AppStyle.manrope(size: 16, weight: FontWeight.w500)),
      ],
    );
  }
}
