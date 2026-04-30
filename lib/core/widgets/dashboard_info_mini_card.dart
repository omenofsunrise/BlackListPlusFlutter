import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class DashboardInfoMiniCard extends StatelessWidget {
  final Color circleColor;
  final String iconAsset;
  final String title;
  final String value;
  final Color? valueColor;

  const DashboardInfoMiniCard({
    super.key,
    required this.circleColor,
    required this.iconAsset,
    required this.title,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(AppColors.white),
        borderRadius: BorderRadius.all(Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000809),
            blurRadius: 4,
            offset: Offset(2, 2),
          ),
          BoxShadow(
            color: Color(0x05000809),
            blurRadius: 6,
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: circleColor,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Center(
                child: SvgPicture.asset(iconAsset, width: 18, height: 18),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: AppStyle.manrope(
                size: 14,
                weight: FontWeight.w500,
                height: 20 / 14,
                color: const Color(0xFF50555C),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: AppStyle.manrope(
                size: 22,
                weight: FontWeight.w600,
                height: 1.1,
                color: valueColor ?? const Color(0xFF111111),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
