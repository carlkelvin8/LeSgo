import 'package:flutter/material.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../provider/main/merchantside/merchant_prep_timer_provider.dart';

class MerchantPrepTimerBadge extends StatelessWidget {
  final MerchantPrepTimerEntry? timer;
  final bool compact;

  const MerchantPrepTimerBadge({
    super.key,
    required this.timer,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (timer == null) return const SizedBox.shrink();

    final isOverdue = timer!.isOverdue;
    final bgColor = isOverdue ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9);
    final borderColor = isOverdue ? const Color(0xFFE53935) : const Color(0xFF43A047);
    final textColor = isOverdue ? const Color(0xFFC62828) : const Color(0xFF2E7D32);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, compact ? 8 : 12),
        vertical: ResponsiveUtils.spacing(context, compact ? 4 : 8),
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(compact ? 6 : 10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: ResponsiveUtils.fontSize(context, compact ? 12 : 16),
            color: textColor,
          ),
          SizedBox(width: ResponsiveUtils.spacing(context, 4)),
          Text(
            compact ? timer!.displayLabel : 'Prep ${timer!.displayLabel}',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, compact ? 10 : 13),
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
