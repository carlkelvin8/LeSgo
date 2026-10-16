import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../../domain/entities/transactions/transaction.dart';
import '../../../core/utils/responsive_utils.dart';
import '../common/payment_status_badge.dart';

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

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 8)),
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
        decoration: BoxDecoration(
          color: AppColors.surface(context, Colors.white),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (transaction.isWallet
                            ? AppColors.accent(context, Color(0xFF5F2D82))
                            : _getServiceColor(transaction.serviceName))
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    transaction.isWallet
                        ? Icons.account_balance_wallet_outlined
                        : _getServiceIcon(transaction.serviceName),
                    color: transaction.isWallet
                        ? AppColors.accent(context, Color(0xFF5F2D82))
                        : _getServiceColor(transaction.serviceName),
                    size: 20,
                  ),
                ),
                SizedBox(width: ResponsiveUtils.spacing(context, 12)),
                
                // Transaction details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              transaction.displayTitle,
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: ResponsiveUtils.fontSize(context, 16),
                                fontWeight: FontWeight.w700,
                                color: AppColors.foreground(context, Colors.black87),
                              ),
                            ),
                          ),
                          if (transaction.isOrder)
                            _buildStatusBadge(
                              context,
                              transaction.status,
                              transaction.rawStatus,
                            )
                          else
                            PaymentStatusBadge(
                              status: transaction.paymentStatus,
                              compact: true,
                            ),
                        ],
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              transaction.displaySubtitle,
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: ResponsiveUtils.fontSize(context, 12),
                                color: AppColors.foreground(context, Colors.grey[600]!),
                              ),
                            ),
                          ),
                          if (transaction.isOrder &&
                              transaction.items != null &&
                              transaction.items!.isNotEmpty)
                            Text(
                              '${transaction.items!.length} item${transaction.items!.length > 1 ? 's' : ''}',
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: ResponsiveUtils.fontSize(context, 11),
                                color: AppColors.foreground(context, Colors.grey[500]!),
                              ),
                            ),
                        ],
                      ),
                      if (transaction.isOrder) ...[
                        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                        Row(
                          children: [
                            const Icon(Icons.circle, size: 8, color: Colors.green),
                            SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                            Expanded(
                              child: Text(
                                _getDisplayLocation(transaction, isPickup: true),
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: ResponsiveUtils.fontSize(context, 12),
                                  color: AppColors.foreground(context, Colors.grey[700]!),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                        Row(
                          children: [
                            const Icon(Icons.circle, size: 8, color: Colors.red),
                            SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                            Expanded(
                              child: Text(
                                _getDisplayLocation(transaction, isPickup: false),
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: ResponsiveUtils.fontSize(context, 12),
                                  color: AppColors.foreground(context, Colors.grey[700]!),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ] else if (transaction.walletReference?.isNotEmpty == true) ...[
                        SizedBox(height: ResponsiveUtils.spacing(context, 6)),
                        Text(
                          transaction.walletReference!,
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 12),
                            color: AppColors.foreground(context, Colors.grey[600]!),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (transaction.isOrder &&
                          transaction.paymentStatus != PaymentStatus.paid) ...[
                        SizedBox(height: ResponsiveUtils.spacing(context, 6)),
                        PaymentStatusBadge(
                          status: transaction.paymentStatus,
                          compact: true,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            
            // Divider
            Padding(
              padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.spacing(context, 12)),
              child: Divider(height: 1, color: AppColors.border(context, Colors.grey[200]!)),
            ),
            
            // Amount and reorder button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  transaction.isWallet
                      ? '${(transaction.isWalletCredit ?? true) ? '+' : '-'}PHP ${transaction.amount.toStringAsFixed(2)}'
                      : 'PHP ${transaction.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 18),
                    fontWeight: FontWeight.w700,
                    color: transaction.isWallet
                        ? ((transaction.isWalletCredit ?? true)
                            ? Colors.green.shade700
                            : Colors.red.shade700)
                        : AppColors.accent(context, Color(0xFF5F2D82)),
                  ),
                ),
                
                if (transaction.isOrder &&
                    transaction.status == TransactionStatus.completed &&
                    transaction.paymentStatus != PaymentStatus.failed &&
                    onReorder != null)
                  OutlinedButton.icon(
                    onPressed: onReorder,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Reorder'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent(context, Color(0xFF5F2D82)),
                      side: const BorderSide(color: Color(0xFF5F2D82)),
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveUtils.spacing(context, 12),
                        vertical: ResponsiveUtils.spacing(context, 8),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, TransactionStatus status, String rawStatus) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case TransactionStatus.completed:
        backgroundColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green;
        text = 'Completed';
        break;
      case TransactionStatus.cancelled:
        backgroundColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red;
        text = 'Cancelled';
        break;
      case TransactionStatus.pending:
        // Show more specific label for active orders
        switch (rawStatus.toLowerCase()) {
          case 'accepted':
            backgroundColor = Colors.blue.withValues(alpha: 0.1);
            textColor = Colors.blue;
            text = 'Accepted';
            break;
          case 'picked_up':
            backgroundColor = Colors.indigo.withValues(alpha: 0.1);
            textColor = Colors.indigo;
            text = 'Picked Up';
            break;
          case 'in_transit':
            backgroundColor = Colors.teal.withValues(alpha: 0.1);
            textColor = Colors.teal;
            text = 'In Transit';
            break;
          case 'driver_arrived_at_pickup':
            backgroundColor = Colors.purple.withValues(alpha: 0.1);
            textColor = Colors.purple;
            text = 'Driver Arrived';
            break;
          case 'in_progress':
            backgroundColor = Colors.cyan.withValues(alpha: 0.1);
            textColor = Colors.cyan;
            text = 'In Progress';
            break;
          default:
            backgroundColor = Colors.orange.withValues(alpha: 0.1);
            textColor = Colors.orange;
            text = 'Pending';
        }
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, 8),
        vertical: ResponsiveUtils.spacing(context, 4),
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: ResponsiveUtils.fontSize(context, 10),
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  String _getDisplayLocation(Transaction transaction, {required bool isPickup}) {
    // For LesBuy and LesEat orders with items, show item information
    if ((transaction.serviceName == 'LesBuy' || transaction.serviceName == 'LesEat') && 
        transaction.items != null && transaction.items!.isNotEmpty) {
      if (isPickup) {
        // Show first item name for pickup
        final firstItem = transaction.items!.first;
        return '${firstItem.name} ${firstItem.quantity > 1 ? '(${firstItem.quantity}x)' : ''}';
      } else {
        // Show total items count for dropoff
        final totalItems = transaction.items!.fold<int>(0, (sum, item) => sum + item.quantity);
        return '${transaction.items!.length} item${transaction.items!.length > 1 ? 's' : ''} ($totalItems total)';
      }
    }
    
    // For other services or orders without items, show regular locations
    return isPickup ? transaction.pickupLocation : transaction.dropoffLocation;
  }

  IconData _getServiceIcon(String serviceName) {
    switch (serviceName) {
      case 'LesGo':
        return Icons.local_shipping;
      case 'LesRide':
        return Icons.directions_bike;
      case 'LesEat':
        return Icons.restaurant;
      case 'LesBuy':
        return Icons.shopping_bag;
      case 'LesTransport':
        return Icons.airport_shuttle;
      default:
        return Icons.receipt;
    }
  }

  Color _getServiceColor(String serviceName) {
    switch (serviceName) {
      case 'LesGo':
        return const Color(0xFF2196F3);
      case 'LesRide':
        return const Color(0xFF9C27B0);
      case 'LesEat':
        return const Color(0xFFFF9800);
      case 'LesBuy':
        return const Color(0xFF4CAF50);
      case 'LesTransport':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF5F2D82);
    }
  }
}

