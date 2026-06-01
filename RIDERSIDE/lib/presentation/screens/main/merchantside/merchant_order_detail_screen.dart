import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../data/data_source/dto/merchant/order_dto.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../provider/main/merchantside/merchant_orders_provider.dart';
import '../../../widgets/main/merchantside/orders/merchant_order_dialogs.dart';

class MerchantOrderDetailScreen extends ConsumerWidget {
  final OrderDto order;

  const MerchantOrderDetailScreen({
    super.key,
    required this.order,
  });

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'searching_driver':
      case 'accepted':
      case 'ready_for_pickup':
        return 'For Pick Up';
      case 'picked_up':
      case 'in_progress':
      case 'driver_arrived_at_pickup':
        return 'For Delivery';
      case 'completed':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.toUpperCase();
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFF9800); // Orange
      case 'searching_driver':
      case 'accepted':
        return const Color(0xFF2196F3); // Blue
      case 'picked_up':
      case 'in_progress':
      case 'driver_arrived_at_pickup':
        return const Color(0xFF9C27B0); // Purple
      case 'completed':
        return const Color(0xFF4CAF50); // Green
      case 'cancelled':
        return const Color(0xFFF44336); // Red
      default:
        return const Color(0xFF757575); // Grey
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);
    final status = order.status.toLowerCase();
    
    // Calculate subtotals
    double itemSubtotal = 0;
    if (order.orderItems != null) {
      for (var item in order.orderItems!) {
        itemSubtotal += (item.unitPrice ?? 0.0) * (item.quantity);
      }
    }
    
    // Format dates
    String orderDate = 'Unknown date';
    if (order.createdAt != null) {
      try {
        final date = DateTime.parse(order.createdAt!).toLocal();
        orderDate = DateFormat('MMM dd, yyyy • hh:mm a').format(date);
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Order Details',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 18),
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Header
            Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: ResponsiveUtils.spacing(context, 20),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '#${order.referenceNumber ?? order.id.toString()}',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 20),
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(order.status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getStatusColor(order.status).withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          _getStatusLabel(order.status),
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 12),
                            fontWeight: FontWeight.w700,
                            color: _getStatusColor(order.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        orderDate,
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 13),
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
            
            // Order Items
            Container(
              color: Colors.white,
              padding: EdgeInsets.all(horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Items',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 16),
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                  
                  if (order.orderItems == null || order.orderItems!.isEmpty)
                    const Text('No items found')
                  else
                    ...order.orderItems!.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${item.quantity ?? 1}x',
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontWeight: FontWeight.w700,
                                fontSize: ResponsiveUtils.fontSize(context, 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.itemName ?? 'Unknown Item',
                                  style: TextStyle(
                                    fontFamily: 'TT Fors',
                                    fontWeight: FontWeight.w600,
                                    fontSize: ResponsiveUtils.fontSize(context, 15),
                                  ),
                                ),
                                if (item.options != null && item.options!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Note: ${item.options}',
                                    style: TextStyle(
                                      fontFamily: 'TT Fors',
                                      fontSize: ResponsiveUtils.fontSize(context, 12),
                                      color: Colors.orange.shade700,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Text(
                            'PHP ${((item.unitPrice ?? 0.0) * (item.quantity)).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontWeight: FontWeight.w600,
                              fontSize: ResponsiveUtils.fontSize(context, 15),
                            ),
                          ),
                        ],
                      ),
                    )),
                    
                  const Divider(height: 24),
                  
                  // Summary
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Items Subtotal',
                        style: TextStyle(fontFamily: 'TT Fors', color: Colors.black54),
                      ),
                      Text(
                        'PHP ${itemSubtotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontFamily: 'TT Fors', fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Delivery Fee',
                        style: TextStyle(fontFamily: 'TT Fors', color: Colors.black54),
                      ),
                      Text(
                        'PHP ${(order.estimatedFare ?? order.totalFare ?? order.distanceFare ?? 0.0).toStringAsFixed(2)}',
                        style: const TextStyle(fontFamily: 'TT Fors', fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 16),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'PHP ${(itemSubtotal + (order.estimatedFare ?? order.totalFare ?? order.distanceFare ?? 0.0)).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 18),
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF5F2D82),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
            
            // Customer Info
            Container(
              color: Colors.white,
              padding: EdgeInsets.all(horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customer Details',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 16),
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF5F2D82).withValues(alpha: 0.1),
                        child: const Icon(Icons.person, color: Color(0xFF5F2D82)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.user?.name ?? 'Guest Customer',
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: ResponsiveUtils.fontSize(context, 15),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              order.user?.phoneNumber ?? 'No phone number',
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: ResponsiveUtils.fontSize(context, 13),
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, color: Colors.grey, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Delivery Address',
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              order.dropoffAddress ?? 'Unknown Address',
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: ResponsiveUtils.fontSize(context, 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Rider Info (If assigned)
            if (order.driver != null) ...[
              SizedBox(height: ResponsiveUtils.spacing(context, 12)),
              Container(
                color: Colors.white,
                padding: EdgeInsets.all(horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rider Details',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 16),
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.orange.withValues(alpha: 0.1),
                          child: const Icon(Icons.two_wheeler, color: Colors.orange),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.driver?.name ?? 'Unknown Rider',
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: ResponsiveUtils.fontSize(context, 15),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                order.driver?.phoneNumber ?? 'No phone number',
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: ResponsiveUtils.fontSize(context, 13),
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              if (order.driver?.vehicleType != null || order.driver?.plateNumber != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.motorcycle, size: 12, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${order.driver?.vehicleType ?? 'Vehicle'} • ${order.driver?.plateNumber ?? 'No Plate'}'.toUpperCase(),
                                      style: TextStyle(
                                        fontFamily: 'TT Fors',
                                        fontSize: ResponsiveUtils.fontSize(context, 12),
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            
            // Bottom padding for scroll
            const SizedBox(height: 100),
          ],
        ),
      ),
      // Bottom Action Button (Accept)
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildBottomActions(context, ref, status, horizontalPadding),
    );
  }

  Widget? _buildBottomActions(
    BuildContext context,
    WidgetRef ref,
    String status,
    double horizontalPadding,
  ) {
    Future<void> run(Future<void> Function() action, String success) async {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Updating order...')),
        );
        await action();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(success)),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: $e')),
          );
        }
      }
    }

    Widget actionButton({
      required String label,
      required Color color,
      required VoidCallback onPressed,
    }) {
      return Expanded(
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 14),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    if (status == 'pending') {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(horizontalPadding),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            actionButton(
              label: 'Reject',
              color: Colors.red.shade400,
              onPressed: () async {
                final reason = await showMerchantCancelReasonDialog(
                  context,
                  title: 'Reject Order',
                  hint: 'Why are you rejecting this order?',
                );
                if (reason != null && context.mounted) {
                  await run(
                    () => ref.read(merchantOrderActionProvider).rejectOrder(order.id, reason),
                    'Order rejected.',
                  );
                }
              },
            ),
            SizedBox(width: ResponsiveUtils.spacing(context, 12)),
            actionButton(
              label: 'Accept',
              color: const Color(0xFF5F2D82),
              onPressed: () async {
                final confirm = await showMerchantConfirmDialog(
                  context,
                  title: 'Accept Order?',
                  message: 'Start searching for a driver?',
                  confirmLabel: 'Accept',
                );
                if (confirm && context.mounted) {
                  await run(
                    () => ref.read(merchantOrderActionProvider).acceptOrder(order.id),
                    'Order accepted successfully!',
                  );
                }
              },
            ),
          ],
        ),
      );
    }

    if (status == 'searching_driver' || status == 'accepted') {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(horizontalPadding),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            actionButton(
              label: 'Cancel',
              color: Colors.red.shade400,
              onPressed: () async {
                final reason = await showMerchantCancelReasonDialog(
                  context,
                  title: 'Cancel Order',
                );
                if (reason != null && context.mounted) {
                  await run(
                    () => ref.read(merchantOrderActionProvider).cancelOrder(order.id, reason),
                    'Order cancelled.',
                  );
                }
              },
            ),
            SizedBox(width: ResponsiveUtils.spacing(context, 12)),
            actionButton(
              label: 'Ready for Pickup',
              color: const Color(0xFF5F2D82),
              onPressed: () async {
                final confirm = await showMerchantConfirmDialog(
                  context,
                  title: 'Ready for Pickup?',
                  message: 'Mark this order as ready for driver pickup?',
                  confirmLabel: 'Mark Ready',
                );
                if (confirm && context.mounted) {
                  await run(
                    () => ref.read(merchantOrderActionProvider).markReadyForPickup(order.id),
                    'Order marked ready for pickup!',
                  );
                }
              },
            ),
          ],
        ),
      );
    }

    if (status == 'ready_for_pickup') {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(horizontalPadding),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: actionButton(
          label: 'Cancel Order',
          color: Colors.red.shade400,
          onPressed: () async {
            final reason = await showMerchantCancelReasonDialog(
              context,
              title: 'Cancel Order',
            );
            if (reason != null && context.mounted) {
              await run(
                () => ref.read(merchantOrderActionProvider).cancelOrder(order.id, reason),
                'Order cancelled.',
              );
            }
          },
        ),
      );
    }

    return null;
  }
}
