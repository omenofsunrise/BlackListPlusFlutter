import 'package:blacklist_plus_flutter/features/profile/presentation/cubit/payment_stats_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class PaymentStatsProfileTable extends StatefulWidget {
  final int? employeeId;

  const PaymentStatsProfileTable({super.key, this.employeeId});

  @override
  State<PaymentStatsProfileTable> createState() =>
      _PaymentStatsProfileTableState();
}

class _PaymentStatsProfileTableState extends State<PaymentStatsProfileTable> {
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    const months = 12;
    final cubit = context.read<PaymentStatsCubit>();
    if (widget.employeeId != null) {
      cubit.loadStatsByEmployeeId(
        employeeId: widget.employeeId!,
        months: months,
      );
    } else {
      cubit.loadStats(months: months);
    }
  }

  String _monthName(int month) {
    const names = [
      '',
      'Январь',
      'Февраль',
      'Март',
      'Апрель',
      'Май',
      'Июнь',
      'Июль',
      'Август',
      'Сентябрь',
      'Октябрь',
      'Ноябрь',
      'Декабрь',
    ];
    return month >= 1 && month <= 12 ? names[month] : '';
  }

  String _formatCurrency(double value) {
    final formatter = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 0,
    );
    return formatter.format(value).replaceAll('\u00A0', ' ');
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaymentStatsCubit, PaymentStatsState>(
      builder: (context, state) {
        if (state is PaymentStatsLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is PaymentStatsError) {
          return Center(child: Text(state.message));
        }

        if (state is PaymentStatsLoaded) {
          final stats = List.of(state.stats.reversed);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000809),
                        offset: Offset(2, 2),
                        blurRadius: 4,
                      ),
                      BoxShadow(color: Color(0x05000809), blurRadius: 6),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Статистика платежей',
                          style: AppStyle.manrope(
                            size: 16,
                            weight: FontWeight.w400,
                          ),
                        ),
                      ),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: const Color(AppColors.uiBorder),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isExpanded) ...[
                const SizedBox(height: 16),
                ...stats.map(
                  (stat) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
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
                            Text(
                              _monthName(stat.month),
                              style: AppStyle.manrope(
                                size: 14,
                                weight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _PaymentStatValue(
                                    label: 'Подтверждённые',
                                    value: _formatCurrency(stat.assumed),
                                    valueColor: const Color(AppColors.uiBorder),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _PaymentStatValue(
                                    label: 'Неподтверждённые',
                                    value: _formatCurrency(stat.notAssumed),
                                    valueColor: const Color(AppColors.primary),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _PaymentStatValue extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _PaymentStatValue({
    required this.label,
    required this.value,
    required this.valueColor,
  });

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
        Text(
          value,
          style: AppStyle.manrope(
            size: 22,
            weight: FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
