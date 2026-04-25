import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../../core/constants/routers/booking/booking_routes.dart';
import '../../../../../core/constants/routers/app_router.dart';
import '../../../../../data/data_source/dto/address/address_dto.dart';
import '../../../../provider/main/booking/checkout_provider.dart';
import '../../../../provider/main/address/address_provider.dart';
import '../../../../widgets/address/address_selector_widget.dart';
import '../../../../widgets/widgets.dart';

class LeseatCheckoutScreen extends ConsumerStatefulWidget {
  const LeseatCheckoutScreen({super.key});

  @override
  ConsumerState<LeseatCheckoutScreen> createState() => _LeseatCheckoutScreenState();
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
                  ref.read(checkoutProvider.notifier).updateDeliveryAddress(
                    address.addressLine1,
                    address.latitude,
                    address.longitude,
                    address.contactName,
                    address.contactPhone,
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
                      address: _selectedAddress?.addressLine1 ?? order.deliveryAddress,
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
                      RestaurantOrderSection(
                        restaurantName: order.restaurantName,
                        items: order.items,
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

                    SizedBox(height: ResponsiveUtils.spacing(context, 16)),

                    // Payment Method Section
                    PaymentMethodSelector(
                      selectedMethod: 'cash',
                      onMethodChanged: (method) {
                        // Payment method changed - currently only COD supported
                        print('Payment method changed to: $method');
                      },
                      enabled: !isCartEmpty,
                    ),

                    SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                  ],
                ),
              ),
            ),

            // Fixed Voucher Section
            VoucherSection(
              enabled: !isCartEmpty,
              onApplyTap: () {
                // TODO: Navigate to voucher selection
              },
            ),

            // Fixed Order Summary
            OrderSummarySection(
              subtotal: subtotal,
              delivery: deliveryFee,
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
                    if (success && context.mounted) {
                      final checkoutState = ref.read(checkoutProvider);
                      final orderId = checkoutState.createdOrderId?.toString() ?? 
                                     'ORDER_${DateTime.now().millisecondsSinceEpoch}';
                      
                      // Navigate to driver finding screen with real order ID
                      AppRouter.pushReplacement(
                        context,
                        BookingRoutes.driverFinding,
                        arguments: {
                          'orderId': orderId,
                          'orderType': 'LesEat',
                          'orderData': {
                            'restaurantName': order.restaurantName,
                            'items': order.items.length,
                            'total': order.total,
                            'deliveryAddress': order.deliveryAddress,
                          },
                        },
                      );
                    }
                  },
          ),
        ),
      ),
    );
  }
}
