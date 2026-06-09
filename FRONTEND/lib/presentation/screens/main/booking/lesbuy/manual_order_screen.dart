import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/routers/booking/booking_routes.dart';
import '../../../../../core/constants/routers/app_router.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../../../../../core/utils/booking_geo_utils.dart';
import '../../../../../core/utils/booking_checkout_payment.dart';
import '../../../../../core/utils/network_guard.dart';
import '../../../../../core/utils/active_order_limit_guard.dart';
import '../../../../../core/utils/lesbuy_manual_delivery_utils.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../data/data_source/order_remote_datasource.dart';
import '../../../../../data/data_source/dto/order/create_order_request_dto.dart';
import '../../../../provider/main/booking/lesbuy/lesbuy_checkout_provider.dart';
import '../../../../provider/main/booking/lesbuy/manual_order_provider.dart';
import '../../../../provider/main/profile/profile_provider.dart';
import '../../../../provider/main/address/address_provider.dart';
import '../../../../widgets/payment/booking_payment_method_section.dart';
import '../../../../widgets/widgets.dart';

class ManualOrderScreen extends ConsumerStatefulWidget {
  final bool fromCart;

  const ManualOrderScreen({super.key, this.fromCart = false});

  @override
  ConsumerState<ManualOrderScreen> createState() => _ManualOrderScreenState();
}

class _ManualOrderScreenState extends ConsumerState<ManualOrderScreen> {
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

      final deliveryAddr = ref.read(addressProvider).deliveryAddress;
      await ref.read(lesbuyCheckoutProvider.notifier).initialize(
            storePartnerId: null,
          );
      ref
          .read(lesbuyCheckoutProvider.notifier)
          .setManualDeliveryFeeUncertain(true);
    });
  }

  Future<void> _directCheckout(
    BuildContext context,
    ManualOrderState manualOrderState,
  ) async {
    if (!await NetworkGuard.ensureOnline(context)) return;
    if (!await ActiveOrderLimitGuard.ensureCanBook(context)) return;

    try {
      final orderDataSource = getIt<OrderRemoteDataSource>();
      final profileState = ref.read(profileProvider);
      final addressState = ref.read(addressProvider);
      final user = profileState.user;

      var dropoffLat = BookingGeoUtils.defaultLat;
      var dropoffLng = BookingGeoUtils.defaultLng;
      var dropoffAddress = user?.addressLine1 ??
          (profileState.address1.isNotEmpty
              ? profileState.address1
              : 'Brgy 6, Claveria, Cagayan');

      final deliveryAddr = addressState.deliveryAddress;
      if (deliveryAddr != null) {
        dropoffLat = deliveryAddr.latitude;
        dropoffLng = deliveryAddr.longitude;
        dropoffAddress = deliveryAddr.addressLine1;
      }

      const deliveryFee = 0.0;
      const total = 0.0;
      const orderValueUncertain = true;

      final orderItems = manualOrderState.items
          .map(
            (item) => OrderItemDto(
              name: item.name,
              quantity: item.quantity,
              estimatedPrice: 0.0,
              notes: item.description,
            ),
          )
          .toList();

      final createOrderRequest = CreateOrderRequestDto(
        serviceId: 4,
        estimatedDistanceM: 0,
        pickup: OrderAddressDto(
          address: 'Store location — set when rider uploads item photo',
          lat: 0,
          lng: 0,
          contactName: 'LesBuy Rider',
          contactPhone: '+639123456789',
        ),
        dropoff: OrderAddressDto(
          address: dropoffAddress,
          lat: dropoffLat,
          lng: dropoffLng,
          contactName: user?.name ??
              (profileState.name.isNotEmpty ? profileState.name : 'Customer'),
          contactPhone: user?.phone ?? '+639123456789',
        ),
        notes: 'Manual LesBuy order: ${orderItems.length} items',
        paymentMethod: _paymentMethod,
        items: orderItems,
        meta: {
          'subtotal': 0.0,
          'delivery_fee': deliveryFee,
          'delivery_fee_uncertain': true,
          'total': total,
          'grand_total': total,
          'order_type': 'lesbuy_manual',
          'manual_pickup_source': 'rider_first_item_photo',
          'order_value_uncertain': true,
          'minimum_order_exempt': true,
        },
      );

      final response = await orderDataSource.createOrder(createOrderRequest);

      final payAmount = LesbuyManualDeliveryUtils.resolveCheckoutPayAmount(
        orderValueUncertain: orderValueUncertain,
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

      if (context.mounted) {
        final orderId = response.data.id.toString();
        ref.read(manualOrderProvider.notifier).clearAll();

        AppRouter.pushReplacement(
          context,
          BookingRoutes.driverFinding,
          arguments: {
            'orderId': orderId,
            'orderType': 'LesBuy Manual',
            'orderData': {
              'manualItems': manualOrderState.items
                  .map(
                    (item) => {
                      'name': item.name,
                      'quantity': item.quantity,
                      'description': item.description,
                    },
                  )
                  .toList(),
              'total': total,
              'deliveryFee': deliveryFee,
              'deliveryFeeUncertain': true,
              'orderValueUncertain': true,
              'paymentMethod': _paymentMethod,
            },
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final manualOrderState = ref.watch(manualOrderProvider);
    final manualOrderNotifier = ref.read(manualOrderProvider.notifier);
    final lesbuyCheckout = ref.watch(lesbuyCheckoutProvider);
    final bool isEmpty = manualOrderState.items.isEmpty;
    final deliveryFeeUncertain = lesbuyCheckout.deliveryFeeUncertain;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            BookingServiceHeader(
              title: 'Manual Order',
              action: const SizedBox.shrink(),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                    Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: ResponsiveUtils.horizontalPadding(context),
                      ),
                      padding: EdgeInsets.all(
                        ResponsiveUtils.spacing(context, 16),
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: Color(0xFF5F2D82),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit_note,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: ResponsiveUtils.spacing(context, 12)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Create your custom list',
                                  style: TextStyle(
                                    fontFamily: 'TT Fors',
                                    fontSize: ResponsiveUtils.fontSize(
                                      context,
                                      14,
                                    ),
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF5F2D82),
                                  ),
                                ),
                                SizedBox(
                                  height: ResponsiveUtils.spacing(context, 4),
                                ),
                                Text(
                                  'Can\'t find what you need in the store? Add items manually below and our rider will find them for you.',
                                  style: TextStyle(
                                    fontFamily: 'TT Fors',
                                    fontSize: ResponsiveUtils.fontSize(
                                      context,
                                      12,
                                    ),
                                    color: const Color(0xFF5F2D82),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveUtils.horizontalPadding(context),
                      ),
                      child: ManualOrderFormSection(
                        onAddItem: (name, description, quantity) {
                          manualOrderNotifier.addItem(
                            name,
                            description,
                            quantity,
                          );
                        },
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 24)),
                    if (isEmpty) ...[
                      Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveUtils.horizontalPadding(
                              context,
                            ),
                            vertical: ResponsiveUtils.spacing(context, 40),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.shopping_bag_outlined,
                                size: 80,
                                color: Colors.grey[300],
                              ),
                              SizedBox(
                                height: ResponsiveUtils.spacing(context, 16),
                              ),
                              Text(
                                'Your list is empty',
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: ResponsiveUtils.fontSize(
                                    context,
                                    16,
                                  ),
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(
                                height: ResponsiveUtils.spacing(context, 8),
                              ),
                              Text(
                                'Start adding items above to build\nyour custom order!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: ResponsiveUtils.fontSize(
                                    context,
                                    13,
                                  ),
                                  color: Colors.grey[600],
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveUtils.horizontalPadding(
                            context,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Your List (${manualOrderState.items.length} items)',
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: ResponsiveUtils.fontSize(context, 16),
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Clear All Items'),
                                    content: const Text(
                                      'Are you sure you want to remove all items from your list?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          manualOrderNotifier.clearAll();
                                          Navigator.pop(context);
                                        },
                                        child: const Text(
                                          'Clear all',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Text(
                                'Clear all',
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
                      SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveUtils.horizontalPadding(context),
                        ),
                        child: Column(
                          children: manualOrderState.items.map((item) {
                            return ManualOrderItemCard(
                              item: item,
                              onIncrement: () {
                                manualOrderNotifier.incrementQuantity(item.id);
                              },
                              onDecrement: () {
                                manualOrderNotifier.decrementQuantity(item.id);
                              },
                              onRemove: () {
                                manualOrderNotifier.removeItem(item.id);
                              },
                            );
                          }).toList(),
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                      BookingPaymentMethodSection(
                        selectedMethod: _paymentMethod,
                        onMethodChanged: (method) {
                          setState(() => _paymentMethod = method);
                        },
                        enabled: !isEmpty,
                        minimumAmount: isEmpty ? null : 0,
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveUtils.horizontalPadding(context),
                          vertical: ResponsiveUtils.spacing(context, 8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              deliveryFeeUncertain
                                  ? 'Delivery fee: TBD'
                                  : 'Estimated delivery fee: ₱${lesbuyCheckout.deliveryFee.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: ResponsiveUtils.fontSize(context, 13),
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            if (deliveryFeeUncertain) ...[
                              SizedBox(
                                height: ResponsiveUtils.spacing(context, 4),
                              ),
                              Text(
                                LesbuyManualDeliveryUtils.pendingHint,
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: ResponsiveUtils.fontSize(context, 11),
                                  color: Colors.grey[600],
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 80)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '📋 No minimum order. Item prices, delivery fee & total are TBD until rider finds your items.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 10),
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 12)),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: ResponsiveUtils.buttonHeight(context),
                      child: OutlinedButton(
                        onPressed: isEmpty
                            ? null
                            : () {
                                manualOrderNotifier.confirmItems();
                                SnackBarUtils.showSuccess(
                                  context,
                                  'Added ${manualOrderState.totalItems} items to checkout!',
                                );
                                if (widget.fromCart) {
                                  Navigator.pop(context);
                                } else {
                                  Navigator.pushReplacementNamed(
                                    context,
                                    BookingRoutes.lesbuyCart,
                                  );
                                }
                              },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isEmpty
                                ? Colors.grey[300]!
                                : const Color(0xFF5F2D82),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: Colors.white,
                        ),
                        child: Text(
                          'Add to Cart',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 16),
                            fontWeight: FontWeight.w600,
                            color: isEmpty
                                ? Colors.grey[600]
                                : const Color(0xFF5F2D82),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: ResponsiveUtils.spacing(context, 12)),
                  Expanded(
                    child: PrimaryButton(
                      text: 'Checkout Now',
                      backgroundColor: isEmpty
                          ? Colors.grey[300]
                          : const Color(0xFF5F2D82),
                      onPressed: isEmpty
                          ? null
                          : () async {
                              await _directCheckout(context, manualOrderState);
                            },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
