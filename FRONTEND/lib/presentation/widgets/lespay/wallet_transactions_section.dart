import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/routers/app_router.dart';
import '../../../core/constants/routers/main/main_routes.dart';
import '../../../core/utils/app_localization.dart';
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
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final horizontalPadding = isDesktop ? 64.0 : 16.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  tr(context, 'transaction_history'),
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(
                      context,
                      isDesktop ? 20 : 18,
                    ),
                    fontWeight: FontWeight.w700,
                    color: AppColors.foreground(context, Colors.black87),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () {
                  AppRouter.push(
                    context,
                    MainRoutes.transactions,
                    arguments: {'kind': 'wallet'},
                  );
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.spacing(context, 8),
                    vertical: ResponsiveUtils.spacing(context, 4),
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tr(context, 'view_all'),
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        color: AppColors.accent(context, Color(0xFF5F2D82)),
                        fontWeight: FontWeight.w600,
                        fontSize: ResponsiveUtils.fontSize(
                          context,
                          isDesktop ? 14 : 13,
                        ),
                      ),
                    ),
                    SizedBox(width: ResponsiveUtils.spacing(context, 4)),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: ResponsiveUtils.fontSize(context, 12),
                      color: AppColors.accent(context, Color(0xFF5F2D82)),
                    ),
                  ],
                ),
              ),
            ],
          ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.1, end: 0),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          if (state.transactionsError != null)
            _buildErrorState(context, state.transactionsError!)
          else if (state.isLoadingTransactions && state.transactions.isEmpty)
            _buildSkeletonList(context)
          else if (state.transactions.isEmpty)
            _buildEmptyState(context)
          else
            _buildTransactionList(context, state.transactions),
        ],
      ),
    );
  }

  Widget _buildSkeletonList(BuildContext context) {
    return Column(
      children: List.generate(5, (index) {
        return Padding(
              padding: EdgeInsets.only(
                bottom: ResponsiveUtils.spacing(context, 12),
              ),
              child: _TransactionSkeleton(),
            )
            .animate()
            .fadeIn(duration: 300.ms, delay: (100 * index).ms)
            .slideX(begin: 0.1, end: 0);
      }),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, 24),
        vertical: ResponsiveUtils.spacing(context, 24),
      ),
      decoration: BoxDecoration(
        color: AppColors.surface(context, Colors.grey).withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(context, Colors.grey).withValues(alpha: 0.1), width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 20)),
            decoration: BoxDecoration(
              color: AppColors.accent(context, Color(0xFF5F2D82)).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: ResponsiveUtils.fontSize(context, 32),
              color: AppColors.accent(context, Color(0xFF5F2D82)),
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
          SizedBox(height: ResponsiveUtils.spacing(context, 16)),
          Text(
                tr(context, 'no_transactions_yet'),
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 16),
                  fontWeight: FontWeight.w700,
                  color: AppColors.foreground(context, Colors.black87),
                ),
              )
              .animate()
              .fadeIn(duration: 300.ms, delay: 200.ms)
              .slideY(begin: 0.2, end: 0),
          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
          Text(
                tr(context, 'top_up_your_wallet'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 13),
                  color: AppColors.foreground(context, Colors.grey[600]!),
                  fontWeight: FontWeight.w500,
                ),
              )
              .animate()
              .fadeIn(duration: 300.ms, delay: 300.ms)
              .slideY(begin: 0.2, end: 0),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange.shade700,
            size: ResponsiveUtils.fontSize(context, 20),
          ),
          SizedBox(width: ResponsiveUtils.spacing(context, 12)),
          Expanded(
            child: Text(
              error,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 13),
                color: Colors.orange.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ).animate().shake(duration: 500.ms).fadeIn(duration: 300.ms);
  }

  Widget _buildTransactionList(
    BuildContext context,
    List<WalletTransactionDto> transactions,
  ) {
    final displayTransactions = transactions.take(20).toList();
    return Column(
      children: displayTransactions.asMap().entries.map((entry) {
        final index = entry.key;
        final tx = entry.value;
        return _AnimatedTransactionTile(transaction: tx, index: index);
      }).toList(),
    );
  }
}

class _AnimatedTransactionTile extends StatelessWidget {
  final WalletTransactionDto transaction;
  final int index;

  const _AnimatedTransactionTile({
    required this.transaction,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return _TransactionTile(transaction: transaction)
        .animate()
        .fadeIn(duration: 300.ms, delay: (50 * index).ms)
        .slideX(begin: 0.1, end: 0);
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final WalletTransactionDto transaction;

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    final isCredit = transaction.type.toLowerCase() == 'credit';
    final paymentStatus = PaymentStatusUtils.fromWalletTransaction(transaction);
    final amountColor = _amountColor(paymentStatus, isCredit);
    final prefix = isCredit ? '+' : '−';
    final date = _formatDate(transaction.createdAt);
    final padding = isDesktop ? 18.0 : (isTablet ? 16.0 : 14.0);
    final avatarSize = isDesktop ? 52.0 : (isTablet ? 48.0 : 44.0);
    final borderRadius = isDesktop ? 18.0 : 16.0;
    final titleSize = isDesktop ? 15.0 : (isTablet ? 14.0 : 13.0);
    final subtitleSize = isDesktop ? 12.0 : (isTablet ? 11.0 : 10.0);
    final amountSize = isDesktop ? 17.0 : (isTablet ? 16.0 : 15.0);

    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 10)),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: AppColors.surface(context, Colors.white),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: isDesktop ? 16 : 12,
            offset: const Offset(0, 2),
            spreadRadius: -1,
          ),
        ],
        border: Border.all(
          color: AppColors.foreground(context, Colors.grey).withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _TransactionAvatar(
            isCredit: isCredit,
            status: paymentStatus,
            color: amountColor,
            size: avatarSize,
          ),
          SizedBox(width: ResponsiveUtils.spacing(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        _getDescription(context, transaction, isCredit),
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(
                            context,
                            titleSize,
                          ),
                          fontWeight: FontWeight.w600,
                          color: AppColors.foreground(context, Colors.black87),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                    Flexible(
                      child: PaymentStatusBadge(
                        status: paymentStatus,
                        compact: true,
                      ),
                    ),
                  ],
                ),
                if (date.isNotEmpty) ...[
                  SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: ResponsiveUtils.fontSize(context, subtitleSize),
                        color: AppColors.foreground(context, Colors.grey[500]!),
                      ),
                      SizedBox(width: ResponsiveUtils.spacing(context, 4)),
                      Flexible(
                        child: Text(
                          date,
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(
                              context,
                              subtitleSize,
                            ),
                            color: AppColors.foreground(context, Colors.grey[500]!),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (transaction.reference != null &&
                    transaction.reference!.isNotEmpty) ...[
                  SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                  Row(
                    children: [
                      Icon(
                        Icons.receipt_rounded,
                        size: ResponsiveUtils.fontSize(context, subtitleSize),
                        color: AppColors.foreground(context, Colors.grey[400]!),
                      ),
                      SizedBox(width: ResponsiveUtils.spacing(context, 4)),
                      Flexible(
                        child: Text(
                          'Ref: ${transaction.reference}',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(
                              context,
                              subtitleSize - 1,
                            ),
                            color: AppColors.foreground(context, Colors.grey[400]!),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$prefix₱${transaction.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, amountSize),
                      fontWeight: FontWeight.w700,
                      color: amountColor,
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getDescription(
    BuildContext context,
    WalletTransactionDto transaction,
    bool isCredit,
  ) {
    if (transaction.description?.isNotEmpty ?? false) {
      return transaction.description!;
    }
    if (isCredit) return tr(context, 'type_topup');
    return tr(context, 'type_payment');
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

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('MMM d, yyyy • h:mm a').format(dt.toLocal());
    } catch (_) {
      return raw;
    }
  }
}

class _TransactionAvatar extends StatelessWidget {
  final bool isCredit;
  final PaymentStatus status;
  final Color color;
  final double size;

  const _TransactionAvatar({
    required this.isCredit,
    required this.status,
    required this.color,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Icon(
          _iconForStatus(status, isCredit),
          color: color,
          size: size * 0.45,
        ),
      ),
    );
  }

  IconData _iconForStatus(PaymentStatus status, bool isCredit) {
    switch (status) {
      case PaymentStatus.failed:
        return Icons.close_rounded;
      case PaymentStatus.refunded:
        return Icons.replay_rounded;
      case PaymentStatus.pending:
        return Icons.schedule_rounded;
      default:
        return isCredit
            ? Icons.arrow_downward_rounded
            : Icons.arrow_upward_rounded;
    }
  }
}

class _TransactionSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    final avatarSize = isDesktop ? 52.0 : (isTablet ? 48.0 : 44.0);
    final padding = isDesktop ? 18.0 : (isTablet ? 16.0 : 14.0);
    final borderRadius = isDesktop ? 18.0 : 16.0;

    return Container(
      height: isDesktop ? 80 : 72,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: AppColors.surface(context, Colors.white),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: AppColors.foreground(context, Colors.grey).withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              color: AppColors.surface(context, Colors.grey).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
          ).animate().shimmer(duration: 1200.ms, color: AppColors.foreground(context, Colors.grey[200]!)),
          SizedBox(width: ResponsiveUtils.spacing(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: double.infinity,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.surface(context, Colors.grey).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ).animate().shimmer(
                  duration: 1200.ms,
                  color: AppColors.foreground(context, Colors.grey[200]!),
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 6)),
                Container(
                  width: isDesktop ? 140 : 100,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.surface(context, Colors.grey).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ).animate().shimmer(
                  duration: 1200.ms,
                  color: AppColors.foreground(context, Colors.grey[200]!),
                ),
              ],
            ),
          ),
          Container(
            width: isDesktop ? 80 : 60,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.surface(context, Colors.grey).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
          ).animate().shimmer(duration: 1200.ms, color: AppColors.foreground(context, Colors.grey[200]!)),
        ],
      ),
    );
  }
}
