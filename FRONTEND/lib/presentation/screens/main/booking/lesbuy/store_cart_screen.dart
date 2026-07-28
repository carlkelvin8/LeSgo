import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../../core/constants/routers/booking/booking_routes.dart';
import '../../../../../core/constants/routers/app_router.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/utils/booking_checkout_payment.dart';
import '../../../../../core/utils/network_guard.dart';
import '../../../../../core/utils/active_order_limit_guard.dart';
import '../../../../../core/utils/lesbuy_manual_delivery_utils.dart';
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
import '../../../../provider/main/lespay/lespay_provider.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userId = ref.read(profileProvider).user?.id;
      if (userId != null) {
        await ref.read(addressProvider.notifier).loadAddresses(userId);
      }
      if (!mounted) return;

      final storeState = ref.read(storeDetailProvider);
      final deliveryAddr = ref.read(addressProvider).deliveryAddress;
      await ref.read(lesbuyCheckoutProvider.notifier).initialize(
            storePartnerId: storeState.partnerStoreId,
          );
      _syncDeliveryFeeQuote(ref, deliveryAddr);
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

  void _syncDeliveryFeeQuote(WidgetRef ref, AddressDto? deliveryAddr) {
    final storeState = ref.read(storeDetailProvider);
    final manualState = ref.read(manualOrderProvider);
    final hasStoreItems = storeState.cartItems.isNotEmpty;
    final hasManualItems = manualState.confirmedItems.isNotEmpty;

    if (LesbuyManualDeliveryUtils.isManualOnlyCart(
      hasStoreItems: hasStoreItems,
      hasManualItems: hasManualItems,
    )) {
      ref.read(lesbuyCheckoutProvider.notifier).setManualDeliveryFeeUncertain(true);
      return;
    }

    ref.read(lesbuyCheckoutProvider.notifier).setManualDeliveryFeeUncertain(false);
    if (deliveryAddr != null) {
      ref.read(lesbuyCheckoutProvider.notifier).refreshDeliveryFee(
            dropoffLat: deliveryAddr.latitude,
            dropoffLng: deliveryAddr.longitude,
            hasManualItems: hasManualItems,
            hasStoreItems: hasStoreItems,
          );
    }
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
                  _syncDeliveryFeeQuote(ref, address);
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

  void _showPickupLocationSelector(BuildContext context, WidgetRef ref) {
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
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: AddressSelectorWidget(
                title: 'Where should rider buy?',
                onAddressSelected: (address) {
                  ref.read(manualOrderProvider.notifier).setPickupLocation(
                    address.addressLine1,
                    address.latitude,
                    address.longitude,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pickup location set!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
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

  Widget _buildPickupLocationSection(
    BuildContext context,
    WidgetRef ref,
    dynamic manualOrderState,
  ) {
    final hasLocation = manualOrderState.hasPickupLocation;
    final locationName = manualOrderState.pickupLocationName ?? '';

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, 16),
      ),
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasLocation ? Colors.green.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.store_mall_directory_outlined,
                color: hasLocation ? Colors.green.shade700 : Colors.orange.shade700,
                size: 20,
              ),
              SizedBox(width: ResponsiveUtils.spacing(context, 8)),
              Expanded(
                child: Text(
                  'Where should rider buy?',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 14),
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _showPickupLocationSelector(context, ref),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.spacing(context, 12),
                    vertical: ResponsiveUtils.spacing(context, 6),
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5F2D82).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    hasLocation ? 'Change' : 'Set Location',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 12),
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF5F2D82),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (hasLocation) ...[
            SizedBox(height: ResponsiveUtils.spacing(context, 8)),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.green.shade600),
                SizedBox(width: ResponsiveUtils.spacing(context, 4)),
                Expanded(
                  child: Text(
                    locationName,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 13),
                      color: Colors.grey.shade700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ] else ...[
            SizedBox(height: ResponsiveUtils.spacing(context, 6)),
            Text(
              'Pin the store/location where the rider should go buy your items',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 12),
                color: Colors.orange.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(manualOrderProvider, (previous, next) {
      if (previous?.confirmedItems.length != next.confirmedItems.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _syncDeliveryFeeQuote(
            ref,
            _selectedAddress ?? ref.read(addressProvider).deliveryAddress,
          );
        });
      }
    });

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
    } else if (addressState.deliveryAddress != null) {
      final addr = addressState.deliveryAddress!;
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
    final manualOnly = LesbuyManualDeliveryUtils.isManualOnlyCart(
      hasStoreItems: !isStoreCartEmpty,
      hasManualItems: !isManualOrderEmpty,
    );
    final deliveryFeeUncertain =
        manualOnly || lesbuyCheckout.deliveryFeeUncertain;
    final deliveryFee = deliveryFeeUncertain
        ? 0.0
        : (isCartEmpty ? 0.0 : lesbuyCheckout.deliveryFee);
    final discount = isCartEmpty ? 0.0 : lesbuyCheckout.discount;
    final total = manualOnly
        ? 0.0
        : subtotal + deliveryFee - discount;
    final orderValueUncertain = manualOnly;
    final deliveryNote = manualOnly
        ? LesbuyManualDeliveryUtils.pendingHint
        : (!isManualOrderEmpty && !isStoreCartEmpty)
            ? 'Store delivery is estimated. Manual items may add delivery fee after rider uploads a photo at the shop.'
            : null;
    final orderValueNote =
        orderValueUncertain ? LesbuyManualDeliveryUtils.orderValuePendingHint : null;
    final walletMinimum = LesbuyManualDeliveryUtils.walletMinimumAmount(
      orderValueUncertain: orderValueUncertain,
      checkoutTotal: total,
    );

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
                          storeNotifier.updateCartItemQuantity(
                            item.product,
                            newQuantity,
                          );
                        },
                        onRemove: (index) {
                          storeNotifier.removeFromCart(
                            storeState.cartItems[index].product,
                          );
                        },
                        onAddMoreItems: () => Navigator.pop(context),
                      ),

                    // Manual Order Section (below store items)
                    if (!isManualOrderEmpty) ...[
                      SizedBox(height: ResponsiveUtils.spacing(context, 16)),

                      // Pickup Location for manual orders
                      if (isStoreCartEmpty) ...[
                        _buildPickupLocationSection(context, ref, manualOrderState),
                        SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                      ],

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
                      minimumAmount: isCartEmpty ? null : walletMinimum,
                    ),

                    SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                  ],
                ),
              ),
            ),

            // Fixed Voucher Section
            VoucherSection(
              enabled: !isCartEmpty && !orderValueUncertain,
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
              deliveryFeeUncertain: deliveryFeeUncertain,
              deliveryFeeNote: deliveryNote,
              orderValueUncertain: orderValueUncertain,
              orderValueNote: orderValueNote,
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
                    if (!await NetworkGuard.ensureOnline(context)) return;
                    if (!await ActiveOrderLimitGuard.ensureCanBook(context)) {
                      return;
                    }

                    // Validate pickup location for manual-only orders
                    final isManualOnly = isStoreCartEmpty && !isManualOrderEmpty;
                    if (isManualOnly && !manualOrderState.hasPickupLocation) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please set where the rider should buy your items (tap "Set Location" above)',
                          ),
                          backgroundColor: Colors.orange,
                          duration: Duration(seconds: 3),
                        ),
                      );
                      return;
                    }

                    // Pre-check wallet balance before API call
                    if (_paymentMethod == 'wallet') {
                      final lespayBalance = ref.read(lespayProvider).balance;
                      if (lespayBalance < walletMinimum) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Insufficient LesPay balance. '
                              'Your balance: ₱${lespayBalance.toStringAsFixed(2)}, '
                              'required: ₱${walletMinimum.toStringAsFixed(2)}. '
                              'Please top up your wallet first.',
                            ),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                        return;
                      }
                    }

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
                      final isManualOnlyCheckout =
                          isStoreCartEmpty && !isManualOrderEmpty;

                      final createOrderRequest = CreateOrderRequestDto(
                        serviceId: 4,
                        estimatedDistanceM: isManualOnlyCheckout
                            ? 1000  // Default to 1km for manual orders (backend requires min:1)
                            : checkoutQuote.estimatedDistanceM,
                        pickup: OrderAddressDto(
                          address: isManualOnlyCheckout
                              ? (manualOrderState.pickupLocationName ?? 'Store location — rider will confirm')
                              : (storeState.storeName ?? 'Store'),
                          lat: isManualOnlyCheckout
                              ? (manualOrderState.pickupLat ?? 0)
                              : checkoutQuote.pickupLat,
                          lng: isManualOnlyCheckout
                              ? (manualOrderState.pickupLng ?? 0)
                              : checkoutQuote.pickupLng,
                          contactName: isManualOnlyCheckout
                              ? 'LesBuy Rider'
                              : (storeState.storeName ?? 'Store'),
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
                        voucherCode: isManualOnlyCheckout
                            ? null
                            : checkoutQuote.voucherCode,
                        discountAmount:
                            isManualOnlyCheckout ? 0 : discount,
                        items: orderItems,
                        meta: {
                          'store_name': storeState.storeName,
                          'subtotal': subtotal,
                          'delivery_fee': deliveryFee,
                          'delivery_fee_uncertain': isManualOnlyCheckout,
                          'manual_items_delivery_uncertain':
                              !isManualOrderEmpty && !isManualOnlyCheckout,
                          'discount': discount,
                          'voucher_code': checkoutQuote.voucherCode,
                          'total': total,
                          'grand_total': total,
                          'order_type':
                              isManualOnlyCheckout ? 'lesbuy_manual' : 'lesbuy',
                          if (isManualOnlyCheckout) ...{
                            'manual_pickup_source': 'rider_first_item_photo',
                            'order_value_uncertain': true,
                            'minimum_order_exempt': true,
                          },
                        },
                      );

                      print('🔵 LesBuy: Creating order with API...');
                      final response = await orderDataSource.createOrder(createOrderRequest);
                      print('🟢 LesBuy: Order created successfully - ID: ${response.data.id}');

                      final payAmount =
                          LesbuyManualDeliveryUtils.resolveCheckoutPayAmount(
                        orderValueUncertain: isManualOnlyCheckout,
                        checkoutTotal: total,
                        apiEffectiveTotal: response.data.effectiveTotalAmount,
                      );

                      if (!context.mounted) return;

                      final paid = await completeBookingPayment(
                        context: context,
                        ref: ref,
                        orderId: response.data.id,
                        amount: payAmount,
                        paymentMethod: _paymentMethod,
                        serviceLabel: 'LesBuy',
                      );
                      if (!paid) return;

                      await storeNotifier.clearCart();
                      ref.read(manualOrderProvider.notifier).clearAll();

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
                              'deliveryFeeUncertain': isManualOnlyCheckout,
                              'orderValueUncertain': isManualOnlyCheckout,
                            },
                          },
                        );
                      }
                    } catch (e) {
                      print('🔴 LesBuy: Error creating order - $e');
                      // Debug: Print full error details
                      if (e is DioException) {
                        print('🔴 DioException status: ${e.response?.statusCode}');
                        print('🔴 DioException data: ${e.response?.data}');
                      }
                      if (context.mounted) {
                        final raw = e.toString();
                        final msg = raw.startsWith('Exception: ')
                            ? raw.substring(11)
                            : raw;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(msg),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 4),
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
