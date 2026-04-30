import 'package:flutter/material.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class PaymentStatsPeriodSelector extends StatefulWidget {
  final List<String> items;
  final String initialValue;
  final ValueChanged<String> onChanged;

  const PaymentStatsPeriodSelector({
    super.key,
    required this.items,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<PaymentStatsPeriodSelector> createState() =>
      _PaymentStatsPeriodSelectorState();
}

class _PaymentStatsPeriodSelectorState
    extends State<PaymentStatsPeriodSelector> {
  late String _selectedPeriod;

  @override
  void initState() {
    super.initState();
    _selectedPeriod = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      height: 37,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Color(AppColors.borderColor), width: 1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: PopupMenuButton<String>(
        onSelected: (value) {
          setState(() {
            _selectedPeriod = value;
          });
          widget.onChanged(value);
        },
        itemBuilder: (context) => widget.items
            .map(
              (item) => PopupMenuItem<String>(value: item, child: Text(item)),
            )
            .toList(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedPeriod,
              style: AppStyle.inter(size: 12, weight: FontWeight.w500),
            ),
            const Icon(Icons.keyboard_arrow_down, size: 21),
          ],
        ),
      ),
    );
  }
}
