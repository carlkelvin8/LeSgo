import 'package:lesgo/core/theme/app_tokens.dart';
import 'package:lesgo/core/utils/money.dart';
import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/history_grouping.dart';
import '../../../domain/entities/transactions/transaction.dart';
import '../../../core/utils/responsive_utils.dart';
import '../common/payment_status_badge.dart';
import '../common/service_icon.dart';
import '../orders/order_style.dart';

/// A compact ledger row: icon tile, what it was, when, the amount, and one
/// clear status. The date lives in the list's group heading, so the row only
/// shows the time.
class TransactionListItem extends StatelessWidget {
  final Transaction transaction;
  final int index;
  final VoidCallback onTap;
  final VoidCallback? onReorder;

  const TransactionListItem({
    super.key,
    required this.transaction,
    required this.index,
    required this.onTap,
    this.onReorder,
  });

  static String _firstPart(String address) {
    final i = address.indexOf(',');
    return (i > 0 ? address.substring(0, i) : address).trim();
  }

  /// "1-pc Chickenjoy ×2 · +1 more", or "Claveria → Belado Avenue".
  String _subtitle() {
    final t = transaction;
    if (t.isWallet) {
      final ref = t.walletReference;
      return (ref != null && ref.isNotEmpty) ? ref : 'LesPay wallet';
    }
    final items = t.items;
    if ((t.serviceName == 'LesEat' || t.serviceName == 'LesBuy') &&
        items != null &&
        items.isNotEmpty) {
      final first = items.first;
      final head = first.quantity > 1
          ? '${first.name} ×${first.quantity}'
          : first.name;
      return items.length > 1 ? '$head · +${items.length - 1} more' : head;
    }
    final from = _firstPart(t.pickupLocation);
    final to = _firstPart(t.dropoffLocation);
    if (from.isEmpty && to.isEmpty) return t.serviceName;
    if (from.isEmpty) return to;
    if (to.isEmpty) return from;
    return '$from → $to';
  }

  ({String label, Color color}) _status() {
    final t = transaction;
    if (t.isWallet) {
      return (label: '', color: Colors.transparent);
    }
    switch (t.status) {
      case TransactionStatus.cancelled:
        return t.paymentStatus == PaymentStatus.refunded
            ? (label: 'Refunded', color: const Color(0xFF1E88E5))
            : (label: 'Cancelled', color: const Color(0xFFE5484D));
      case TransactionStatus.completed:
        return t.paymentStatus == PaymentStatus.failed
            ? (label: 'Payment failed', color: const Color(0xFFE5484D))
            : (label: 'Completed', color: const Color(0xFF2E9E5B));
      case TransactionStatus.pending:
        final s = OrderStyle.status(t.rawStatus);
        return (label: s.label, color: s.color);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final isWallet = t.isWallet;
    final credit = t.isWalletCredit ?? true;
    final cancelled = !isWallet && t.status == TransactionStatus.cancelled;
    final time = HistoryGrouping.parse(t.date);
    final timeText = time == null ? '' : DateFormat('h:mm a').format(time);
    final status = _status();
    final muted = AppColors.foreground(context, Colors.grey[600]!);

    final amountText = isWallet
        ? '${credit ? '+' : '-'}${Money.format(t.amount)}'
        : Money.format(t.amount);
    final amountColor = isWallet
        ? (credit
              ? const Color(0xFF2E9E5B)
              : AppColors.foreground(context, Colors.black87))
        : (cancelled
              ? AppColors.foreground(context, Colors.grey[500]!)
              : AppColors.accent(context, const Color(0xFF5F2D82)));

    final canReorder =
        t.isOrder &&
        t.status == TransactionStatus.completed &&
        t.paymentStatus != PaymentStatus.failed &&
        onReorder != null;

    final bigText = MediaQuery.textScalerOf(context).scale(1) > 1.35;
    final amountWidget = Text(
      amountText,
      style: TextStyle(
        fontFamily: 'TT Fors',
        fontSize: ResponsiveUtils.fontSize(context, 16),
        fontWeight: FontWeight.w800,
        decoration: cancelled ? TextDecoration.lineThrough : null,
        color: amountColor,
      ),
    );
    final statusWidget = isWallet
        ? PaymentStatusBadge(status: t.paymentStatus, compact: true)
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              status.label,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 10),
                fontWeight: FontWeight.w700,
                color: status.color,
              ),
            ),
          );

    return Semantics(
      button: true,
      label:
          '${t.displayTitle}, $amountText${status.label.isEmpty ? '' : ', ${status.label}'}',
      child: Container(
        margin: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 8)),
        decoration: AppCard.decoration(context, radius: 16),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  if (bigText) ...[
                    // Large text: icon + details on top, amount + status below.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ServiceIcon(isWallet ? 'LesPay' : t.serviceName, size: 46),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.displayTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: ResponsiveUtils.fontSize(
                                    context,
                                    15,
                                  ),
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.foreground(
                                    context,
                                    Colors.black87,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _subtitle(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: ResponsiveUtils.fontSize(
                                    context,
                                    12,
                                  ),
                                  color: muted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                [
                                  if (timeText.isNotEmpty) timeText,

                                ].join(' • '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: ResponsiveUtils.fontSize(
                                    context,
                                    11,
                                  ),
                                  color: AppColors.foreground(
                                    context,
                                    Colors.grey[500]!,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: amountWidget,
                          ),
                        ),
                        const SizedBox(width: 8),
                        statusWidget,
                      ],
                    ),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ServiceIcon(isWallet ? 'LesPay' : t.serviceName, size: 46),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.displayTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: ResponsiveUtils.fontSize(
                                    context,
                                    15,
                                  ),
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.foreground(
                                    context,
                                    Colors.black87,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _subtitle(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: ResponsiveUtils.fontSize(
                                    context,
                                    12,
                                  ),
                                  color: muted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                [
                                  if (timeText.isNotEmpty) timeText,

                                ].join(' • '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: ResponsiveUtils.fontSize(
                                    context,
                                    11,
                                  ),
                                  color: AppColors.foreground(
                                    context,
                                    Colors.grey[500]!,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            amountWidget,
                            const SizedBox(height: 4),
                            statusWidget,
                          ],
                        ),
                      ],
                    ),
                  if (canReorder) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: onReorder,
                        icon: const Icon(Icons.replay_rounded, size: 16),
                        label: const Text('Order again'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.accent(
                            context,
                            const Color(0xFF5F2D82),
                          ),
                          minimumSize: const Size(0, 34),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
