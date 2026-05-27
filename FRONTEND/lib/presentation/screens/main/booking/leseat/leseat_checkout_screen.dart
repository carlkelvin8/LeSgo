import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../../core/constants/routers/booking/booking_routes.dart';
import '../../../../../core/constants/routers/app_router.dart';
import '../../../../../data/data_source/dto/address/address_dto.dart';
import '../../../../../domain/entities/booking/leseat/order.dart';
import '../../../../../domain/entities/booking/leseat/order_item.dart';
import '../../../../provider/main/booking/checkout_provider.dart';
import '../../../../provider/main/address/address_provider.dart';
import '../../../../widgets/address/address_selector_widget.dart';
import '../../../../widgets/payment/booking_payment_method_section.dart';
import '../../../../widgets/booking/leseat/checkout/voucher_bottom_sheet.dart';
import '../../../../widgets/widgets.dart';

class LeseatCheckoutScreen extends ConsumerStatefulWidget {
  const LeseatCheckoutScreen({super.key});

  @override
  ConsumerState<LeseatCheckoutScreen> createState() =>
      _LeseatCheckoutScreenState();
}

class _LeseatCheckoutScreenState extends ConsumerState<LeseatCheckoutScreen> {
  AddressDto? _selectedAddress;

  void _showAddressSelector(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Address selector
            Expanded(
              child: AddressSelectorWidget(
                title: 'Select Delivery Address',
                onAddressSelected: (address) {
                  setState(() {
                    _selectedAddress = address;
                  });
                  // Update checkout provider with new address
                  ref
                      .read(checkoutProvider.notifier)
                      .updateDeliveryAddress(
                        address.addressLine1,
                        address.latitude,
                        address.longitude,
                        address.contactName ?? '',
                        address.contactPhone ?? '',
                      );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Delivery address updated'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showVoucherDialog(BuildContext context, WidgetRef ref) async {
    final code = await showVoucherBottomSheet(context);
    if (code == null || !context.mounted) return;

    final error = await ref.read(checkoutProvider.notifier).applyVoucher(code);
    if (!context.mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voucher applied'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final checkoutState = ref.watch(checkoutProvider);
    final checkoutNotifier = ref.read(checkoutProvider.notifier);
    final order = checkoutState.order;

    if (order == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: SafeArea(
          child: Column(
            children: [
              BookingServiceHeader(title: 'Checkout'),
              const Expanded(child: Center(child: CircularProgressIndicator())),
            ],
          ),
        ),
      );
    }

    final bool isCartEmpty = order.items.isEmpty;
    final restaurantGroups = _groupItemsByRestaurant(order);
    // If empty, force totals to 0
    final subtotal = isCartEmpty ? 0.0 : order.subtotal;
    final deliveryFee = isCartEmpty
        ? 0.0
        : order.deliveryFee; // Or keep fixed if needed
    final total = isCartEmpty ? 0.0 : order.total;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            BookingServiceHeader(
              title: 'Checkout',
              action: const SizedBox.shrink(),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: ResponsiveUtils.spacing(context, 8)),

                    // Delivery Address
                    DeliveryAddressSection(
                      address:
                          _selectedAddress?.addressLine1 ??
                          order.deliveryAddress,
                      onTap: () {
                        _showAddressSelector(context, ref);
                      },
                    ),

                    SizedBox(height: ResponsiveUtils.spacing(context, 16)),

                    // Restaurant Section or Empty State
                    if (isCartEmpty)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          vertical: ResponsiveUtils.spacing(context, 48),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            SizedBox(
                              height: ResponsiveUtils.spacing(context, 16),
                            ),
                            Text(
                              'Your cart is empty',
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: ResponsiveUtils.fontSize(context, 16),
                                color: Colors.grey[600],
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'Go to Restaurant',
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: ResponsiveUtils.fontSize(
                                    context,
                                    14,
                                  ),
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF5F2D82),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: [
                          for (final group in restaurantGroups) ...[
                            RestaurantOrderSection(
                              restaurantName: group.restaurantName,
                              items: group.items,
                              onQuantityChanged: (itemId, newQuantity) {
                                checkoutNotifier.updateItemQuantity(
                                  itemId,
                                  newQuantity,
                                );
                              },
                              onRemove: (itemId) {
                                checkoutNotifier.removeItem(itemId);
                              },
                              onAddMoreItems: () => Navigator.pop(context),
                            ),
                            SizedBox(
                              height: ResponsiveUtils.spacing(context, 12),
                            ),
                          ],
                        ],
                      ),

                    SizedBox(height: ResponsiveUtils.spacing(context, 16)),

                    // Payment Method Section
                    BookingPaymentMethodSection(
                      selectedMethod:
                          checkoutState.selectedPaymentMethod ?? 'cash',
                      onMethodChanged: checkoutNotifier.selectPaymentMethod,
                      enabled: !isCartEmpty,
                      minimumAmount: isCartEmpty ? null : total,
                    ),

                    SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                  ],
                ),
              ),
            ),

            // Fixed Voucher Section
            VoucherSection(
              enabled: !isCartEmpty,
              appliedVoucher: order.voucherCode,
              onApplyTap: () {
                _showVoucherDialog(context, ref);
              },
              onRemoveTap: () {
                checkoutNotifier.removeVoucher();
              },
            ),

            // Fixed Order Summary
            OrderSummarySection(
              subtotal: subtotal,
              delivery: deliveryFee,
              discount: order.discount,
              total: total,
              itemCount: isCartEmpty ? 0 : order.totalItems,
            ),
          ],
        ),
      ),

      // Bottom Continue Button
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: PrimaryButton(
            text: 'Checkout',
            isLoading: checkoutState.isLoading,
            backgroundColor: isCartEmpty
                ? Colors.grey
                : const Color(0xFF5F2D82),
            onPressed: isCartEmpty
                ? null
                : () async {
                    final success = await checkoutNotifier.placeOrder();
                    if (!context.mounted) return;
                    if (success) {
                      final checkoutState = ref.read(checkoutProvider);
                      final orderId =
                          checkoutState.createdOrderId?.toString() ??
                          'ORDER_${DateTime.now().millisecondsSinceEpoch}';

                      // Navigate to driver finding screen with real order ID
                      AppRouter.pushReplacement(
                        context,
                        BookingRoutes.driverFinding,
                        arguments: {
                          'orderId': orderId,
                          'orderType': 'LesEat',
                          'orderData': {
                            'restaurantName': restaurantGroups
                                .map((group) => group.restaurantName)
                                .join(', '),
                            'items': order.items
                                .map(
                                  (item) => {
                                    'name': item.name,
                                    'price': item.price,
                                    'quantity': item.quantity,
                                    'restaurantName': item.restaurantName,
                                  },
                                )
                                .toList(),
                            'subtotal': order.subtotal,
                            'deliveryFee': order.deliveryFee,
                            'discount': order.discount,
                            'total': order.total,
                            'deliveryAddress': order.deliveryAddress,
                          },
                        },
                      );
                    } else {
                      final raw =
                          ref.read(checkoutProvider).error ??
                          'Failed to place order. Please try again.';
                      final errorMsg = raw.startsWith('Exception: ')
                          ? raw.substring(11)
                          : raw;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(errorMsg),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  },
          ),
        ),
      ),
    );
  }

  List<_RestaurantOrderGroup> _groupItemsByRestaurant(Order order) {
    final groupedItems = <String, List<OrderItem>>{};
    final groupNames = <String, String>{};

    for (final item in order.items) {
      final restaurantName = item.restaurantName?.trim().isNotEmpty == true
          ? item.restaurantName!.trim()
          : order.restaurantName;
      final restaurantKey = item.restaurantId?.trim().isNotEmpty == true
          ? item.restaurantId!.trim()
          : restaurantName;

      groupedItems.putIfAbsent(restaurantKey, () => []);
      groupedItems[restaurantKey]!.add(item);
      groupNames[restaurantKey] = restaurantName;
    }

    return groupedItems.entries
        .map((entry) {
          return _RestaurantOrderGroup(
            restaurantName: groupNames[entry.key] ?? order.restaurantName,
            items: entry.value,
          );
        })
        .toList(growable: false);
  }
}

class _RestaurantOrderGroup {
  final String restaurantName;
  final List<OrderItem> items;

  const _RestaurantOrderGroup({
    required this.restaurantName,
    required this.items,
  });
}
