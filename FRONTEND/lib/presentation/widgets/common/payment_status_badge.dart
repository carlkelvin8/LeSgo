import 'package:flutter/material.dart';

import '../../../core/utils/payment_status_utils.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../domain/entities/transactions/transaction.dart';

class PaymentStatusBadge extends StatelessWidget {
  const PaymentStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  final PaymentStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, compact ? 6 : 8),
        vertical: ResponsiveUtils.spacing(context, compact ? 2 : 4),
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        PaymentStatusUtils.label(status),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: ResponsiveUtils.fontSize(context, compact ? 9 : 10),
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  (Color, Color) _colors(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return (Colors.green.withValues(alpha: 0.12), Colors.green.shade700);
      case PaymentStatus.failed:
        return (Colors.red.withValues(alpha: 0.12), Colors.red.shade700);
      case PaymentStatus.refunded:
        return (Colors.blue.withValues(alpha: 0.12), Colors.blue.shade700);
      case PaymentStatus.pending:
        return (Colors.orange.withValues(alpha: 0.12), Colors.orange.shade800);
    }
  }
}
