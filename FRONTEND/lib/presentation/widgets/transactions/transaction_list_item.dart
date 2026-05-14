import 'package:flutter/material.dart';
import '../../../domain/entities/transactions/transaction.dart';
import '../../../core/utils/responsive_utils.dart';

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
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
                // Service icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getServiceColor(transaction.serviceName).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getServiceIcon(transaction.serviceName),
                    color: _getServiceColor(transaction.serviceName),
                    size: 20,
                  ),
                ),
                SizedBox(width: ResponsiveUtils.spacing(context, 12)),
                
                // Transaction details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Service name and status
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              transaction.serviceName,
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: ResponsiveUtils.fontSize(context, 16),
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          _buildStatusBadge(context, transaction.status, transaction.rawStatus),
                        ],
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                      
                      // Order ID and items info
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Order #${transaction.id}',
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: ResponsiveUtils.fontSize(context, 12),
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          if (transaction.items != null && transaction.items!.isNotEmpty)
                            Text(
                              '${transaction.items!.length} item${transaction.items!.length > 1 ? 's' : ''}',
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: ResponsiveUtils.fontSize(context, 11),
                                color: Colors.grey[500],
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                      
                      // Pickup location or first item for LesBuy/LesEat
                      Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 8,
                            color: Colors.green,
                          ),
                          SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                          Expanded(
                            child: Text(
                              _getDisplayLocation(transaction, isPickup: true),
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: ResponsiveUtils.fontSize(context, 12),
                                color: Colors.grey[700],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                      
                      // Dropoff location or item count for LesBuy/LesEat
                      Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 8,
                            color: Colors.red,
                          ),
                          SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                          Expanded(
                            child: Text(
                              _getDisplayLocation(transaction, isPickup: false),
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: ResponsiveUtils.fontSize(context, 12),
                                color: Colors.grey[700],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Divider
            Padding(
              padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.spacing(context, 12)),
              child: Divider(height: 1, color: Colors.grey[200]),
            ),
            
            // Amount and reorder button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PHP ${transaction.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 18),
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF5F2D82),
                  ),
                ),
                
                // Reorder button (only for completed orders)
                if (transaction.status == TransactionStatus.completed && onReorder != null)
                  OutlinedButton.icon(
                    onPressed: onReorder,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Reorder'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF5F2D82),
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
        backgroundColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        text = 'Completed';
        break;
      case TransactionStatus.cancelled:
        backgroundColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        text = 'Cancelled';
        break;
      case TransactionStatus.pending:
        // Show more specific label for active orders
        switch (rawStatus.toLowerCase()) {
          case 'accepted':
            backgroundColor = Colors.blue.withOpacity(0.1);
            textColor = Colors.blue;
            text = 'Accepted';
            break;
          case 'picked_up':
            backgroundColor = Colors.indigo.withOpacity(0.1);
            textColor = Colors.indigo;
            text = 'Picked Up';
            break;
          case 'in_transit':
            backgroundColor = Colors.teal.withOpacity(0.1);
            textColor = Colors.teal;
            text = 'In Transit';
            break;
          case 'driver_arrived_at_pickup':
            backgroundColor = Colors.purple.withOpacity(0.1);
            textColor = Colors.purple;
            text = 'Driver Arrived';
            break;
          case 'in_progress':
            backgroundColor = Colors.cyan.withOpacity(0.1);
            textColor = Colors.cyan;
            text = 'In Progress';
            break;
          default:
            backgroundColor = Colors.orange.withOpacity(0.1);
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
