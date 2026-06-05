import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/routers/app_router.dart';
import '../../../core/constants/routers/main/main_routes.dart';
import '../../../core/utils/payment_status_utils.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../data/data_source/dto/wallet/wallet_dto.dart';
import '../../../domain/entities/transactions/transaction.dart';
import '../../provider/main/lespay/lespay_provider.dart';
import '../common/payment_status_badge.dart';

class WalletTransactionsSection extends ConsumerWidget {
  const WalletTransactionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(lespayProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.spacing(context, 16),
          ),
          child: Row(
            children: [
              if (state.isLoadingTransactions)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  AppRouter.push(
                    context,
                    MainRoutes.transactions,
                    arguments: {'kind': 'wallet'},
                  );
                },
                child: const Text(
                  'View all',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    color: Color(0xFF5F2D82),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (state.transactionsError != null)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.spacing(context, 16),
              vertical: ResponsiveUtils.spacing(context, 4),
            ),
            child: Text(
              state.transactionsError!,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 12),
                color: Colors.orange.shade800,
              ),
            ),
          ),
        if (state.isLoadingTransactions && state.transactions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (state.transactions.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.spacing(context, 16),
              vertical: ResponsiveUtils.spacing(context, 8),
            ),
            child: Text(
              'No transactions yet. Top up to get started.',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 13),
                color: Colors.grey,
              ),
            ),
          )
        else
          Column(
            children: state.transactions.take(20).map((tx) {
              return _TransactionTile(transaction: tx);
            }).toList(),
          ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final WalletTransactionDto transaction;

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.type.toLowerCase() == 'credit';
    final paymentStatus = PaymentStatusUtils.fromWalletTransaction(transaction);
    final amountColor = _amountColor(paymentStatus, isCredit);
    final prefix = isCredit ? '+' : '-';
    final date = _formatDate(transaction.createdAt);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, 16),
        vertical: ResponsiveUtils.spacing(context, 10),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: amountColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _iconForStatus(paymentStatus, isCredit),
              color: amountColor,
              size: 20,
            ),
          ),
          SizedBox(width: ResponsiveUtils.spacing(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        (transaction.description?.isNotEmpty ?? false)
                            ? transaction.description!
                            : (isCredit ? 'Top-up' : 'Payment'),
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 14),
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    PaymentStatusBadge(status: paymentStatus, compact: true),
                  ],
                ),
                if (date.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    date,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 11),
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '$prefix₱${transaction.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 14),
              fontWeight: FontWeight.w700,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _amountColor(PaymentStatus status, bool isCredit) {
    switch (status) {
      case PaymentStatus.failed:
        return Colors.red.shade700;
      case PaymentStatus.refunded:
        return Colors.blue.shade700;
      case PaymentStatus.pending:
        return Colors.orange.shade800;
      case PaymentStatus.paid:
        return isCredit ? Colors.green.shade700 : Colors.red.shade700;
    }
  }

  IconData _iconForStatus(PaymentStatus status, bool isCredit) {
    switch (status) {
      case PaymentStatus.failed:
        return Icons.error_outline;
      case PaymentStatus.refunded:
        return Icons.replay;
      case PaymentStatus.pending:
        return Icons.schedule;
      default:
        return isCredit ? Icons.arrow_downward : Icons.arrow_upward;
    }
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('MMM d, yyyy • h:mm a').format(dt.toLocal());
    } catch (_) {
      return raw;
    }
  }
}
