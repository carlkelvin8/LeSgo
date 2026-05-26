import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/routers/booking/booking_routes.dart';
import '../../../../../core/constants/routers/app_router.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/utils/lespay_order_payment.dart';
import '../../../../../data/data_source/order_remote_datasource.dart';
import '../../../../../data/data_source/dto/order/create_order_request_dto.dart';
import '../../../../../data/data_source/dto/address/address_dto.dart';
import '../../../../provider/main/booking/lesbuy/lesbuy_checkout_provider.dart';
import '../../../../provider/main/booking/lesbuy/manual_order_provider.dart';
import '../../../../provider/main/booking/lesbuy/store_detail_provider.dart';
import '../../../../widgets/booking/leseat/checkout/voucher_bottom_sheet.dart';
import '../../../../../core/utils/booking_geo_utils.dart';
import '../../../../provider/main/profile/profile_provider.dart';
import '../../../../provider/main/address/address_provider.dart';
import '../../../../widgets/booking/lesbuy/cart/manual_order_section.dart';
import '../../../../widgets/booking/lesbuy/cart/store_order_section.dart';
import '../../../../widgets/address/address_selector_widget.dart';
import '../../../../widgets/payment/booking_payment_method_section.dart';
import '../../../../widgets/widgets.dart';

class StoreCartScreen extends ConsumerStatefulWidget {
  const StoreCartScreen({super.key});

  @override
  ConsumerState<StoreCartScreen> createState() => _StoreCartScreenState();
}

class _StoreCartScreenState extends ConsumerState<StoreCartScreen> {
  AddressDto? _selectedAddress;
  String _paymentMethod = 'cash';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final storeState = ref.read(storeDetailProvider);
      ref.read(lesbuyCheckoutProvider.notifier).initialize(
            storePartnerId: storeState.partnerStoreId,
          );
      final userId = ref.read(profileProvider).user?.id;
      if (userId != null) {
        ref.read(addressProvider.notifier).loadAddresses(userId);
      }
    });
  }

  Future<void> _showVoucherPicker(BuildContext context) async {
    final storeState = ref.read(storeDetailProvider);
    final subtotal = storeState.cartTotal;
    final code = await showVoucherBottomSheet(context);
    if (code == null || !mounted) return;

    final error = await ref
        .read(lesbuyCheckoutProvider.notifier)
        .applyVoucher(code, subtotal);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Voucher applied'),
        backgroundColor: error != null ? Colors.red : Colors.green,
      ),
    );
  }

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
                  ref.read(lesbuyCheckoutProvider.notifier).refreshDeliveryFee(
                        dropoffLat: address.latitude,
                        dropoffLng: address.longitude,
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
    final storeState = ref.watch(storeDetailProvider);
    final storeNotifier = ref.read(storeDetailProvider.notifier);
    final manualOrderState = ref.watch(manualOrderProvider);
    final manualOrderNotifier = ref.read(manualOrderProvider.notifier);
    final profileState = ref.watch(profileProvider);
    final lesbuyCheckout = ref.watch(lesbuyCheckoutProvider);
    final addressState = ref.watch(addressProvider);

    // Get delivery address - use selected address or saved default
    final String userAddress;
    final double dropoffLat;
    final double dropoffLng;
    final String contactName;
    final String contactPhone;

    if (_selectedAddress != null) {
      userAddress = _selectedAddress!.addressLine1;
      dropoffLat = _selectedAddress!.latitude;
      dropoffLng = _selectedAddress!.longitude;
      contactName = _selectedAddress!.contactName?.isNotEmpty == true
          ? _selectedAddress!.contactName!
          : (profileState.user?.name ?? 'Customer');
      contactPhone = _selectedAddress!.contactPhone?.isNotEmpty == true
          ? _selectedAddress!.contactPhone!
          : (profileState.user?.phone ?? '+639123456789');
    } else if (addressState.defaultAddress != null) {
      final addr = addressState.defaultAddress!;
      userAddress = addr.addressLine1;
      dropoffLat = addr.latitude;
      dropoffLng = addr.longitude;
      contactName = addr.contactName?.isNotEmpty == true
          ? addr.contactName!
          : (profileState.user?.name ?? 'Customer');
      contactPhone = addr.contactPhone?.isNotEmpty == true
          ? addr.contactPhone!
          : (profileState.user?.phone ?? '+639123456789');
    } else {
      userAddress = profileState.address1.isNotEmpty
          ? profileState.address1
          : (profileState.user?.addressLine1 ?? 'No address set');
      dropoffLat = BookingGeoUtils.defaultLat;
      dropoffLng = BookingGeoUtils.defaultLng;
      contactName = profileState.user?.name ?? 'Customer';
      contactPhone = profileState.user?.phone ?? '+639123456789';
    }

    // Calculate totals
    final bool isStoreCartEmpty = storeState.cartItems.isEmpty;
    final bool isManualOrderEmpty = manualOrderState.confirmedItems.isEmpty;
    final bool isCartEmpty = isStoreCartEmpty && isManualOrderEmpty;
    final subtotal = isStoreCartEmpty ? 0.0 : storeState.cartTotal;
    final deliveryFee =
        isCartEmpty ? 0.0 : lesbuyCheckout.deliveryFee;
    final discount = isCartEmpty ? 0.0 : lesbuyCheckout.discount;
    final total = subtotal + deliveryFee - discount;

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
                    BookingPaymentMethodSection(
                      selectedMethod: _paymentMethod,
                      onMethodChanged: (method) {
                        setState(() => _paymentMethod = method);
                      },
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
              appliedVoucher: lesbuyCheckout.voucherCode,
              onApplyTap: () => _showVoucherPicker(context),
              onRemoveTap: () {
                ref.read(lesbuyCheckoutProvider.notifier).removeVoucher();
              },
            ),

            // Fixed Order Summary
            OrderSummarySection(
              subtotal: subtotal,
              delivery: deliveryFee,
              discount: discount,
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
                      final dropoffAddress = userAddress;
                      final dropoffContactName = contactName;
                      final dropoffContactPhone = contactPhone;

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

                      final checkoutQuote = ref.read(lesbuyCheckoutProvider);

                      final createOrderRequest = CreateOrderRequestDto(
                        serviceId: 4,
                        estimatedDistanceM: checkoutQuote.estimatedDistanceM,
                        pickup: OrderAddressDto(
                          address: storeState.storeName ?? 'Store',
                          lat: checkoutQuote.pickupLat,
                          lng: checkoutQuote.pickupLng,
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
                        paymentMethod: _paymentMethod,
                        voucherCode: checkoutQuote.voucherCode,
                        discountAmount: discount,
                        items: orderItems,
                        meta: {
                          'store_name': storeState.storeName,
                          'subtotal': subtotal,
                          'delivery_fee': deliveryFee,
                          'discount': discount,
                          'voucher_code': checkoutQuote.voucherCode,
                          'total': total,
                          'grand_total': total,
                          'order_type': 'lesbuy',
                        },
                      );

                      print('🔵 LesBuy: Creating order with API...');
                      final response = await orderDataSource.createOrder(createOrderRequest);
                      print('🟢 LesBuy: Order created successfully - ID: ${response.data.id}');

                      await applyLesPayWalletDeduction(
                        ref,
                        paymentMethod: _paymentMethod,
                        amount: total,
                      );

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
