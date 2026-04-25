import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/routers/booking/booking_routes.dart';
import '../../../../../core/constants/routers/app_router.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../data/data_source/order_remote_datasource.dart';
import '../../../../../data/data_source/dto/order/create_order_request_dto.dart';
import '../../../../../data/data_source/dto/address/address_dto.dart';
import '../../../../provider/main/booking/lesbuy/manual_order_provider.dart';
import '../../../../provider/main/booking/lesbuy/store_detail_provider.dart';
import '../../../../provider/main/profile/profile_provider.dart';
import '../../../../provider/main/address/address_provider.dart';
import '../../../../widgets/booking/lesbuy/cart/manual_order_section.dart';
import '../../../../widgets/booking/lesbuy/cart/store_order_section.dart';
import '../../../../widgets/address/address_selector_widget.dart';
import '../../../../widgets/widgets.dart';

class StoreCartScreen extends ConsumerStatefulWidget {
  const StoreCartScreen({super.key});

  @override
  ConsumerState<StoreCartScreen> createState() => _StoreCartScreenState();
}

class _StoreCartScreenState extends ConsumerState<StoreCartScreen> {
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
    final storeState = ref.watch(storeDetailProvider);
    final storeNotifier = ref.read(storeDetailProvider.notifier);
    final manualOrderState = ref.watch(manualOrderProvider);
    final manualOrderNotifier = ref.read(manualOrderProvider.notifier);
    final profileState = ref.watch(profileProvider);

    // Get delivery address - use selected address or fallback to profile
    final String userAddress;
    final double dropoffLat;
    final double dropoffLng;
    final String contactName;
    final String contactPhone;

    if (_selectedAddress != null) {
      userAddress = _selectedAddress!.addressLine1;
      dropoffLat = _selectedAddress!.latitude;
      dropoffLng = _selectedAddress!.longitude;
      contactName = _selectedAddress!.contactName.isNotEmpty 
          ? _selectedAddress!.contactName 
          : (profileState.user?.name ?? 'Customer');
      contactPhone = _selectedAddress!.contactPhone.isNotEmpty 
          ? _selectedAddress!.contactPhone 
          : (profileState.user?.phone ?? '+639123456789');
    } else {
      userAddress = profileState.address1.isNotEmpty 
          ? profileState.address1 
          : (profileState.user?.addressLine1 ?? 'No address set');
      dropoffLat = 8.4542; // Default coordinates
      dropoffLng = 124.6319;
      contactName = profileState.user?.name ?? 'Customer';
      contactPhone = profileState.user?.phone ?? '+639123456789';
    }

    // Calculate totals
    final bool isStoreCartEmpty = storeState.cartItems.isEmpty;
    final bool isManualOrderEmpty = manualOrderState.confirmedItems.isEmpty;
    final bool isCartEmpty = isStoreCartEmpty && isManualOrderEmpty;
    final subtotal = isStoreCartEmpty ? 0.0 : storeState.cartTotal;
    final deliveryFee = isCartEmpty ? 0.0 : 50.0;
    final total = subtotal + deliveryFee;

    // Total item count for summary
    final storeItemCount = storeState.cartItems.fold(
      0,
      (sum, item) => sum + item.quantity,
    );
    final manualItemCount = manualOrderState.totalConfirmedItems;
    final totalItemCount = storeItemCount + manualItemCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            const BookingServiceHeader(
              title: 'Checkout',
              action: SizedBox.shrink(),
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
                      address: userAddress,
                      onTap: () {
                        _showAddressSelector(context, ref);
                      },
                    ),

                    SizedBox(height: ResponsiveUtils.spacing(context, 16)),

                    // Empty State
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
                                'Go to Store',
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
                      ),

                    // Store Order Section
                    if (!isStoreCartEmpty)
                      StoreOrderSection(
                        storeName: storeState.storeName ?? 'Store',
                        items: storeState.cartItems,
                        onQuantityChanged: (index, newQuantity) {
                          final item = storeState.cartItems[index];
                          if (newQuantity > item.quantity) {
                            storeNotifier.addToCart(item.product);
                          } else {
                            storeNotifier.removeFromCart(item.product);
                          }
                        },
                        onRemove: (index) {
                          final item = storeState.cartItems[index];
                          storeNotifier.removeFromCart(item.product);
                        },
                        onAddMoreItems: () => Navigator.pop(context),
                      ),

                    // Manual Order Section (below store items)
                    if (!isManualOrderEmpty) ...[
                      SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                      ManualOrderSection(
                        items: manualOrderState.confirmedItems,
                        onIncrement: (itemId) {
                          manualOrderNotifier.incrementConfirmedQuantity(
                            itemId,
                          );
                        },
                        onDecrement: (itemId) {
                          manualOrderNotifier.decrementConfirmedQuantity(
                            itemId,
                          );
                        },
                        onRemove: (itemId) {
                          manualOrderNotifier.removeConfirmedItem(itemId);
                        },
                        onAddMoreItems: () => Navigator.pushNamed(
                          context,
                          BookingRoutes.lesbuyManualOrder,
                          arguments: {'fromCart': true},
                        ),
                      ),
                    ],

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
              itemCount: totalItemCount,
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
            // isLoading: storeState.isLoading,
            backgroundColor: isCartEmpty
                ? Colors.grey
                : const Color(0xFF5F2D82),
            onPressed: isCartEmpty
                ? null
                : () async {
                    // Create LesBuy order using API
                    try {
                      final orderDataSource = getIt<OrderRemoteDataSource>();
                      final profileState = ref.read(profileProvider);
                      final user = profileState.user;

                      // Use selected address or fallback
                      final dropoffAddress = _selectedAddress != null
                          ? _selectedAddress!.addressLine1
                          : (user?.addressLine1 ?? (profileState.address1.isNotEmpty 
                              ? profileState.address1 
                              : 'Brgy 6, Claveria, Cagayan'));
                      
                      final dropoffLat = _selectedAddress?.latitude ?? 8.4542;
                      final dropoffLng = _selectedAddress?.longitude ?? 124.6319;
                      
                      final dropoffContactName = _selectedAddress?.contactName.isNotEmpty == true
                          ? _selectedAddress!.contactName
                          : (user?.name ?? (profileState.name.isNotEmpty 
                              ? profileState.name 
                              : 'Customer'));
                      
                      final dropoffContactPhone = _selectedAddress?.contactPhone.isNotEmpty == true
                          ? _selectedAddress!.contactPhone
                          : (user?.phone ?? '+639123456789');

                      // Prepare order items
                      final orderItems = <OrderItemDto>[];
                      
                      // Add store items
                      for (final item in storeState.cartItems) {
                        orderItems.add(OrderItemDto(
                          name: item.product.name,
                          quantity: item.quantity,
                          estimatedPrice: item.product.price,
                          notes: 'Store item',
                        ));
                      }
                      
                      // Add manual items
                      for (final item in manualOrderState.confirmedItems) {
                        orderItems.add(OrderItemDto(
                          name: item.name,
                          quantity: item.quantity,
                          estimatedPrice: 0.0, // Manual items don't have price
                          notes: item.description,
                        ));
                      }

                      final createOrderRequest = CreateOrderRequestDto(
                        serviceId: 4, // LesBuy service ID
                        estimatedDistanceM: 5000, // 5km default
                        pickup: OrderAddressDto(
                          address: storeState.storeName ?? 'Store',
                          lat: 8.4542, // Default Cagayan de Oro coordinates
                          lng: 124.6319,
                          contactName: storeState.storeName ?? 'Store',
                          contactPhone: '+639123456789',
                        ),
                        dropoff: OrderAddressDto(
                          address: dropoffAddress,
                          lat: dropoffLat,
                          lng: dropoffLng,
                          contactName: dropoffContactName,
                          contactPhone: dropoffContactPhone,
                        ),
                        notes: 'LesBuy order: ${orderItems.length} items',
                        paymentMethod: 'cash', // Use 'cash' instead of 'cod'
                        items: orderItems,
                        meta: {
                          'store_name': storeState.storeName,
                          'subtotal': subtotal,
                          'delivery_fee': deliveryFee,
                          'total': total,
                          'order_type': 'lesbuy',
                        },
                      );

                      print('🔵 LesBuy: Creating order with API...');
                      final response = await orderDataSource.createOrder(createOrderRequest);
                      print('🟢 LesBuy: Order created successfully - ID: ${response.data.id}');

                      if (context.mounted) {
                        final orderId = response.data.id.toString();
                        
                        // Navigate to driver finding screen
                        AppRouter.pushReplacement(
                          context,
                          BookingRoutes.driverFinding,
                          arguments: {
                            'orderId': orderId,
                            'orderType': 'LesBuy',
                            'orderData': {
                              'storeItems': storeState.cartItems.map((item) => {
                                'productName': item.product.name,
                                'quantity': item.quantity,
                                'price': item.product.price,
                              }).toList(),
                              'manualItems': manualOrderState.confirmedItems.map((item) => {
                                'name': item.name,
                                'quantity': item.quantity,
                                'description': item.description,
                              }).toList(),
                              'total': total,
                              'subtotal': subtotal,
                              'deliveryFee': deliveryFee,
                            },
                          },
                        );
                      }
                    } catch (e) {
                      print('🔴 LesBuy: Error creating order - $e');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to place order: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
          ),
        ),
      ),
    );
  }
}
