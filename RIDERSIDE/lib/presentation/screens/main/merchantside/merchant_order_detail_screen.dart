import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/merchant_order_amount_utils.dart';
import '../../../../core/utils/merchant_order_ops_utils.dart';
import '../../../../core/utils/merchant_payment_utils.dart';
import '../../../../core/utils/screen_auto_refresh.dart';
import '../../../mixins/auto_refresh_mixin.dart';
import '../../../../data/data_source/dto/merchant/order_dto.dart';
import '../../../widgets/common/menu_image_widget.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../provider/main/merchantside/merchant_menu_image_lookup.dart';
import '../../../provider/main/merchantside/merchant_menu_provider.dart';
import '../../../provider/main/merchantside/merchant_orders_provider.dart';
import '../../../provider/main/merchantside/merchant_prep_timer_provider.dart';
import '../../../widgets/main/merchantside/orders/merchant_order_action_handlers.dart';
import '../../../widgets/main/merchantside/orders/merchant_order_dialogs.dart';
import '../../../widgets/main/merchantside/orders/merchant_prep_timer_badge.dart';
import '../../../widgets/main/merchantside/orders/merchant_special_instructions_banner.dart';

class MerchantOrderDetailScreen extends ConsumerStatefulWidget {
  final OrderDto order;

  const MerchantOrderDetailScreen({
    super.key,
    required this.order,
  });

  @override
  ConsumerState<MerchantOrderDetailScreen> createState() =>
      _MerchantOrderDetailScreenState();
}

class _MerchantOrderDetailScreenState extends ConsumerState<MerchantOrderDetailScreen>
    with WidgetsBindingObserver, AutoRefreshMixin {
  @override
  Duration get autoRefreshInterval => kScreenAutoRefreshInterval;

  @override
  void onAutoRefresh() {
    ref.invalidate(merchantOrderDetailProvider(widget.order.id));
    ref.invalidate(merchantMenuProvider);
  }

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
  Widget build(BuildContext context) {
    ref.watch(merchantMenuProvider);
    final imageLookup = ref.watch(menuItemImageLookupProvider);
    final detailAsync = ref.watch(merchantOrderDetailProvider(widget.order.id));
    final resolvedOrder = detailAsync.maybeWhen(
      data: (freshOrder) => freshOrder,
      orElse: () => widget.order,
    );
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);
    final status = resolvedOrder.status.toLowerCase();
    final prepTimer = ref.watch(merchantPrepTimerProvider)[resolvedOrder.id];
    final orderInstructions =
        MerchantOrderOpsUtils.orderSpecialInstructions(resolvedOrder);
    final itemInstructions =
        MerchantOrderOpsUtils.itemSpecialInstructions(resolvedOrder);
    
    // Calculate subtotals
    double itemSubtotal = 0;
    if (resolvedOrder.orderItems != null) {
      for (var item in resolvedOrder.orderItems!) {
        itemSubtotal += item.totalPrice ?? ((item.unitPrice ?? 0.0) * item.quantity);
      }
    }
    
    // Format dates
    String orderDate = 'Unknown date';
    if (resolvedOrder.createdAt.isNotEmpty) {
      try {
        final date = DateTime.parse(resolvedOrder.createdAt).toLocal();
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
                        '#${resolvedOrder.referenceNumber ?? resolvedOrder.id.toString()}',
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
                          color: _getStatusColor(resolvedOrder.status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getStatusColor(resolvedOrder.status).withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          _getStatusLabel(resolvedOrder.status),
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 12),
                            fontWeight: FontWeight.w700,
                            color: _getStatusColor(resolvedOrder.status),
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
                  if (MerchantOrderOpsUtils.showsPrepTimer(status) &&
                      prepTimer != null) ...[
                    SizedBox(height: ResponsiveUtils.spacing(context, 10)),
                    MerchantPrepTimerBadge(timer: prepTimer),
                  ],
                ],
              ),
            ),

            if (MerchantOrderOpsUtils.isRiderFlowStatus(status)) ...[
              SizedBox(height: ResponsiveUtils.spacing(context, 12)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 14)),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF90CAF9)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.two_wheeler,
                        color: Colors.blue.shade800,
                        size: ResponsiveUtils.fontSize(context, 20),
                      ),
                      SizedBox(width: ResponsiveUtils.spacing(context, 10)),
                      Expanded(
                        child: Text(
                          'This order is with the rider. Merchant cancel is no longer available.',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 13),
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            if (MerchantOrderOpsUtils.hasSpecialInstructions(resolvedOrder)) ...[
              SizedBox(height: ResponsiveUtils.spacing(context, 12)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: MerchantSpecialInstructionsBanner(
                  orderInstructions: orderInstructions,
                  itemInstructions: itemInstructions,
                ),
              ),
            ],
            
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
                  
                  if (resolvedOrder.orderItems == null || resolvedOrder.orderItems!.isEmpty)
                    const Text('No items found')
                  else
                    ...resolvedOrder.orderItems!.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: ResponsiveUtils.spacing(context, 52),
                            height: ResponsiveUtils.spacing(context, 52),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD69A),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: MenuImageWidget(
                              source: imageLookup.resolve(item),
                              fit: BoxFit.cover,
                              placeholder: Icon(
                                Icons.restaurant,
                                size: ResponsiveUtils.fontSize(context, 24),
                                color: const Color(0xFF9A5A00),
                              ),
                            ),
                          ),
                          SizedBox(width: ResponsiveUtils.spacing(context, 10)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${item.quantity}x',
                                        style: TextStyle(
                                          fontFamily: 'TT Fors',
                                          fontWeight: FontWeight.w700,
                                          fontSize:
                                              ResponsiveUtils.fontSize(context, 14),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item.itemName,
                                        style: TextStyle(
                                          fontFamily: 'TT Fors',
                                          fontWeight: FontWeight.w600,
                                          fontSize:
                                              ResponsiveUtils.fontSize(context, 15),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (item.optionsDisplay != null &&
                                    item.optionsDisplay!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: item.notes != null &&
                                              item.notes!.trim().isNotEmpty
                                          ? const Color(0xFFFFF8E1)
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: item.notes != null &&
                                                item.notes!.trim().isNotEmpty
                                            ? const Color(0xFFFFB300)
                                            : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Text(
                                      item.optionsDisplay!,
                                      style: TextStyle(
                                        fontFamily: 'TT Fors',
                                        fontSize:
                                            ResponsiveUtils.fontSize(context, 12),
                                        color: item.notes != null &&
                                                item.notes!.trim().isNotEmpty
                                            ? Colors.orange.shade900
                                            : Colors.black54,
                                        fontWeight: item.notes != null &&
                                                item.notes!.trim().isNotEmpty
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'PHP ${((item.unitPrice ?? 0.0) * item.quantity).toStringAsFixed(2)}',
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
                        'PHP ${(resolvedOrder.totalFare ?? resolvedOrder.estimatedFare ?? resolvedOrder.distanceFare ?? 0.0).toStringAsFixed(2)}',
                        style: const TextStyle(fontFamily: 'TT Fors', fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Payment Method',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        MerchantPaymentUtils.methodLabel(
                          resolvedOrder.paymentMethod,
                        ),
                        style: const TextStyle(
                          fontFamily: 'TT Fors',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Payment Status',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        MerchantPaymentUtils.statusLabel(
                          resolvedOrder.paymentStatus,
                        ),
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontWeight: FontWeight.w600,
                          color: MerchantPaymentUtils.creditsMerchantWallet(
                            resolvedOrder.paymentMethod,
                            resolvedOrder.paymentStatus,
                          )
                              ? Colors.green.shade700
                              : Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                  if (MerchantPaymentUtils.creditsMerchantWallet(
                    resolvedOrder.paymentMethod,
                    resolvedOrder.paymentStatus,
                  )) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Credited to E-Wallet',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          'PHP ${MerchantOrderAmountUtils.foodEarnings(resolvedOrder).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontWeight: FontWeight.w700,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
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
                        'PHP ${(itemSubtotal + (resolvedOrder.totalFare ?? resolvedOrder.estimatedFare ?? resolvedOrder.distanceFare ?? 0.0)).toStringAsFixed(2)}',
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
                      ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child: _buildProfileAvatar(
                            context,
                            resolvedOrder.user?.resolvedProfilePhotoUrl,
                            fallbackIcon: Icons.person,
                            fallbackColor: const Color(0xFF5F2D82),
                            backgroundColor:
                                const Color(0xFF5F2D82).withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              resolvedOrder.user?.name ?? 'Guest Customer',
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: ResponsiveUtils.fontSize(context, 15),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              resolvedOrder.user?.phoneNumber ?? 'No phone number',
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
                              resolvedOrder.dropoffAddress,
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
            
            // Rider Info
            if (resolvedOrder.driverId != null || resolvedOrder.driver != null) ...[
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
                    if (detailAsync.isLoading && resolvedOrder.driver == null)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else if (resolvedOrder.driver != null)
                      _buildRiderDetails(context, resolvedOrder.driver!)
                    else
                      Text(
                        'Rider assigned. Loading rider details...',
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

  Widget _buildRiderDetails(BuildContext context, DriverDto driver) {
    final avatarSize = ResponsiveUtils.spacing(context, 56);
    final photoUrl = driver.profilePictureUrl;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(avatarSize / 2),
          child: SizedBox(
            width: avatarSize,
            height: avatarSize,
            child: photoUrl != null
                ? MenuImageWidget(
                    source: photoUrl,
                    fit: BoxFit.cover,
                    placeholder: _riderAvatarFallback(context, avatarSize),
                  )
                : _riderAvatarFallback(context, avatarSize),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                driver.name,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 15),
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (driver.phoneNumber != null &&
                  driver.phoneNumber!.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  driver.phoneNumber!,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 13),
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
              if (driver.plateNumber != null &&
                  driver.plateNumber!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F2FB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE8D9F5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.confirmation_number_outlined,
                        size: 14,
                        color: Colors.grey.shade700,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Plate: ${driver.plateNumber!.toUpperCase()}',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 12),
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF5F2D82),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (driver.vehicleType != null &&
                  driver.vehicleType!.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  driver.vehicleType!,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 12),
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _riderAvatarFallback(BuildContext context, double size) {
    return Container(
      width: size,
      height: size,
      color: Colors.orange.withValues(alpha: 0.12),
      child: Icon(
        Icons.two_wheeler,
        color: Colors.orange.shade700,
        size: ResponsiveUtils.fontSize(context, 28),
      ),
    );
  }

  Widget _buildProfileAvatar(
    BuildContext context,
    String? photoUrl, {
    required IconData fallbackIcon,
    required Color fallbackColor,
    required Color backgroundColor,
  }) {
    final fallback = Container(
      color: backgroundColor,
      child: Icon(fallbackIcon, color: fallbackColor),
    );

    if (photoUrl == null || photoUrl.trim().isEmpty) {
      return fallback;
    }

    return MenuImageWidget(
      source: photoUrl,
      fit: BoxFit.cover,
      placeholder: fallback,
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

    Widget actionBar(List<Widget> children) {
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
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) SizedBox(width: ResponsiveUtils.spacing(context, 10)),
              children[i],
            ],
          ],
        ),
      );
    }

    void popOnSuccess() {
      if (context.mounted) Navigator.pop(context);
    }

    if (MerchantOrderOpsUtils.canAccept(status)) {
      return actionBar([
        actionButton(
          label: 'Reject',
          color: const Color(0xFFE53935),
          onPressed: () => MerchantOrderActionHandlers.reject(
            context,
            ref,
            orderId: widget.order.id,
            onSuccess: popOnSuccess,
          ),
        ),
        actionButton(
          label: 'Accept',
          color: const Color(0xFF5F2D82),
          onPressed: () => MerchantOrderActionHandlers.accept(
            context,
            ref,
            orderId: widget.order.id,
            onSuccess: popOnSuccess,
          ),
        ),
      ]);
    }

    if (MerchantOrderOpsUtils.canMarkReadyForPickup(status) ||
        MerchantOrderOpsUtils.canCancelAfterAccept(status)) {
      final actions = <Widget>[];

      if (MerchantOrderOpsUtils.canCancelAfterAccept(status)) {
        actions.add(
          actionButton(
            label: 'Cancel',
            color: const Color(0xFFE53935),
            onPressed: () => MerchantOrderActionHandlers.cancelAfterAccept(
              context,
              ref,
              orderId: widget.order.id,
              onSuccess: popOnSuccess,
            ),
          ),
        );
      }

      if (MerchantOrderOpsUtils.canMarkReadyForPickup(status)) {
        actions.add(
          actionButton(
            label: 'Mark Ready',
            color: const Color(0xFF5F2D82),
            onPressed: () async {
              final confirm = await showMerchantConfirmDialog(
                context,
                title: 'Mark Ready for Pickup?',
                message: 'Let the rider know this order is ready.',
                confirmLabel: 'Mark Ready',
              );
              if (confirm && context.mounted) {
                await run(
                  () => ref
                      .read(merchantOrderActionProvider)
                      .markReadyForPickup(widget.order.id),
                  'Order marked ready for pickup!',
                );
              }
            },
          ),
        );
      }

      if (actions.isEmpty) return null;
      return actionBar(actions);
    }

    return null;
  }
}
