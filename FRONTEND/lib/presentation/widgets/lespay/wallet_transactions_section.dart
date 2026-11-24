import 'package:lesgo/core/utils/money.dart';
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
import '../orders/premium_order_widgets.dart';
import '../../../core/utils/history_grouping.dart';

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
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
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
        border: Border.all(
          color: AppColors.border(context, Colors.grey).withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 20)),
            decoration: BoxDecoration(
              color: AppColors.accent(
                context,
                Color(0xFF5F2D82),
              ).withValues(alpha: 0.1),
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
        color: AppColors.surface(context, Colors.orange.shade50),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border(context, Colors.orange.shade200),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: AppColors.foreground(context, Colors.orange.shade700),
            size: ResponsiveUtils.fontSize(context, 20),
          ),
          SizedBox(width: ResponsiveUtils.spacing(context, 12)),
          Expanded(
            child: Text(
              error,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 13),
                color: AppColors.foreground(context, Colors.orange.shade800),
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
    final now = DateTime.now();
    final groups = HistoryGrouping.group<WalletTransactionDto>(
      transactions.take(20).toList(),
      (t) => HistoryGrouping.parse(t.createdAt),
      (d) => HistoryGrouping.dayLabel(d, now),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var g = 0; g < groups.length; g++)
          Reveal(
            index: g,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
                    child: SectionLabel(groups[g].label),
                  ),
                  PremiumCard(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    radius: 20,
                    child: Column(
                      children: [
                        for (var i = 0; i < groups[g].items.length; i++) ...[
                          if (i > 0)
                            Divider(
                              height: 1,
                              indent: 72,
                              endIndent: 16,
                              color: AppColors.border(
                                context,
                                const Color(0xFFF0EAF5),
                              ),
                            ),
                          _TransactionTile(transaction: groups[g].items[i]),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// One wallet movement: what it was, when, how much, and only a status chip
/// when something is off (a settled payment needs no badge).
class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final WalletTransactionDto transaction;

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.type.toLowerCase() == 'credit';
    final status = PaymentStatusUtils.fromWalletTransaction(transaction);
    final accent = _accent(status, isCredit);
    final time = HistoryGrouping.parse(transaction.createdAt);
    final timeText = time == null ? '' : DateFormat('h:mm a').format(time);
    final failed = status == PaymentStatus.failed;
    final amountColor = switch (status) {
      PaymentStatus.failed => const Color(0xFFE5484D),
      PaymentStatus.refunded => const Color(0xFF1E88E5),
      PaymentStatus.pending => const Color(0xFFEF8A1B),
      PaymentStatus.paid =>
        isCredit
            ? const Color(0xFF2E9E5B)
            : AppColors.foreground(context, Colors.black87),
    };
    final sign = isCredit ? '+' : '−';
    final title = _title(context);

    return Semantics(
      label: '$title, $sign${Money.format(transaction.amount)}',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_icon(status, isCredit), color: accent, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 14.5),
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                      letterSpacing: -0.1,
                      color: AppColors.foreground(context, Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (timeText.isNotEmpty)
                        Text(
                          timeText,
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 12),
                            color: AppColors.foreground(
                              context,
                              Colors.grey[500]!,
                            ),
                          ),
                        ),
                      if (status != PaymentStatus.paid)
                        PaymentStatusBadge(status: status, compact: true),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              flex: 0,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * 0.34,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    '$sign${Money.format(transaction.amount)}',
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 16),
                      fontWeight: FontWeight.w800,
                      decoration: failed ? TextDecoration.lineThrough : null,
                      color: amountColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _title(BuildContext context) {
    // Never show order numbers (database ids) to the customer.
    final d = (transaction.description ?? '')
        .replaceAll(RegExp(r'\s*#\d+'), '')
        .trim();
    if (d.isNotEmpty) return d;
    final isCredit = transaction.type.toLowerCase() == 'credit';
    return tr(context, isCredit ? 'type_topup' : 'type_payment');
  }

  Color _accent(PaymentStatus status, bool isCredit) {
    switch (status) {
      case PaymentStatus.failed:
        return const Color(0xFFE5484D);
      case PaymentStatus.refunded:
        return const Color(0xFF1E88E5);
      case PaymentStatus.pending:
        return const Color(0xFFEF8A1B);
      case PaymentStatus.paid:
        return isCredit ? const Color(0xFF2E9E5B) : const Color(0xFF5F2D82);
    }
  }

  IconData _icon(PaymentStatus status, bool isCredit) {
    switch (status) {
      case PaymentStatus.failed:
        return Icons.close_rounded;
      case PaymentStatus.refunded:
        return Icons.replay_rounded;
      case PaymentStatus.pending:
        return Icons.schedule_rounded;
      case PaymentStatus.paid:
        return isCredit ? Icons.south_west_rounded : Icons.north_east_rounded;
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
          color: AppColors.foreground(
            context,
            Colors.grey,
          ).withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              color: AppColors.surface(
                context,
                Colors.grey,
              ).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
          ).animate().shimmer(
            duration: 1200.ms,
            color: AppColors.foreground(context, Colors.grey[200]!),
          ),
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
                    color: AppColors.surface(
                      context,
                      Colors.grey,
                    ).withValues(alpha: 0.1),
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
                    color: AppColors.surface(
                      context,
                      Colors.grey,
                    ).withValues(alpha: 0.1),
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
              color: AppColors.surface(
                context,
                Colors.grey,
              ).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
          ).animate().shimmer(
            duration: 1200.ms,
            color: AppColors.foreground(context, Colors.grey[200]!),
          ),
        ],
      ),
    );
  }
}
