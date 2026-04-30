import 'package:blacklist_plus_flutter/features/profile/presentation/cubit/credit_stats_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class CreditCount extends StatefulWidget {
  final int? employeeId;

  const CreditCount({super.key, this.employeeId});

  @override
  State<CreditCount> createState() => _CreditCountState();
}

class _CreditCountState extends State<CreditCount> {
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    const months = 12;
    final cubit = context.read<CreditStatsCubit>();
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

  @override
  Widget build(BuildContext context) {
    final NumberFormat numberFormatter = NumberFormat.decimalPattern('ru_RU');

    return BlocBuilder<CreditStatsCubit, CreditStatsState>(
      builder: (context, state) {
        if (state is CreditStatsLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is CreditStatsError) {
          return Center(child: Text(state.message));
        }
        if (state is CreditStatsLoaded) {
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
                          'Количество договоров',
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _monthName(stat.month),
                                style: AppStyle.manrope(
                                  size: 14,
                                  weight: FontWeight.w400,
                                ),
                              ),
                            ),
                            Text(
                              numberFormatter.format(stat.count),
                              style: AppStyle.manrope(
                                size: 22,
                                weight: FontWeight.w500,
                                color: const Color(AppColors.black),
                              ),
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
