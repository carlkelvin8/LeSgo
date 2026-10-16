import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../../../../../core/constants/routers/booking/booking_routes.dart';
import '../../../../../core/constants/routers/app_router.dart';
import '../../../../../data/data_source/dto/address/address_dto.dart';
import '../../../../../domain/entities/booking/leseat/order.dart';
import '../../../../../domain/entities/booking/leseat/order_item.dart';
import '../../../../provider/auth/auth_provider.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncDeliveryAddress());
  }

  Future<void> _syncDeliveryAddress() async {
    final authState = ref.read(authProvider);
    final userId = int.tryParse(authState.user?.id ?? '0') ?? 0;
    if (userId > 0) {
      await ref.read(addressProvider.notifier).loadAddresses(userId);
    }

    final deliveryAddr = ref.read(addressProvider).deliveryAddress;
    if (deliveryAddr == null || !mounted) return;

    setState(() => _selectedAddress = deliveryAddr);
    ref.read(checkoutProvider.notifier).updateDeliveryAddress(
          deliveryAddr.addressLine1,
          deliveryAddr.latitude,
          deliveryAddr.longitude,
          deliveryAddr.contactName ?? '',
          deliveryAddr.contactPhone ?? '',
        );
  }

  void _showAddressSelector(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration:  BoxDecoration(
          color: AppColors.surface(context, Colors.white),
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
                color: AppColors.surface(context, Colors.grey[300]!),
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
                  SnackBarUtils.showSuccess(
                    context,
                    'Delivery address updated',
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

    if (error == null) {
      SnackBarUtils.showSuccess(context, 'Voucher applied');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(
      checkoutProvider.select((state) => state.voucherError),
      (previous, next) {
        if (next != null && next != previous && context.mounted) {
          SnackBarUtils.showError(context, next);
        }
      },
    );
    ref.listen<String?>(
      checkoutProvider.select((state) => state.fareError),
      (previous, next) {
        if (next != null && next != previous && context.mounted) {
          SnackBarUtils.showError(context, next);
        }
      },
    );
    final checkoutState = ref.watch(checkoutProvider);
    final checkoutNotifier = ref.read(checkoutProvider.notifier);
    final order = checkoutState.order;

    if (order == null) {
      return Scaffold(
        backgroundColor: AppColors.surface(context, Color(0xFFF5F5F5)),
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
      backgroundColor: AppColors.surface(context, Color(0xFFF5F5F5)),
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
                              color: AppColors.foreground(context, Colors.grey[400]!),
                            ),
                            SizedBox(
                              height: ResponsiveUtils.spacing(context, 16),
                            ),
                            Text(
                              'Your cart is empty',
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: ResponsiveUtils.fontSize(context, 16),
                                color: AppColors.foreground(context, Colors.grey[600]!),
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
                                  color: AppColors.accent(context, Color(0xFF5F2D82)),
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
          color: AppColors.surface(context, Colors.white),
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
              if (checkoutState.fareError != null)
                TextButton.icon(
                  onPressed: checkoutState.isLoadingFare
                      ? null
                      : checkoutNotifier.refreshDeliveryFee,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry delivery fee'),
                ),
              PrimaryButton(
            text: 'Checkout',
            isLoading: checkoutState.isLoading,
            backgroundColor: isCartEmpty
                ? Colors.grey
                : const Color(0xFF5F2D82),
            onPressed: isCartEmpty || checkoutState.isLoading ||
                    checkoutState.isLoadingFare ||
                    checkoutState.isValidatingVoucher ||
                    !checkoutState.hasValidDeliveryFee
                ? null
                : () async {
                    final success = await checkoutNotifier.placeOrder(context);
                    if (!context.mounted) return;
                    if (success) {
                      final checkoutState = ref.read(checkoutProvider);
                      final createdId = checkoutState.createdOrderId;
                      if (createdId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Order was not created. Please try again.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      AppRouter.pushReplacement(
                        context,
                        BookingRoutes.leseatWaitingConfirmation,
                        arguments: {
                          'orderId': createdId,
                          'address': order.deliveryAddress,
                          'orderItems': order.items
                              .map(
                                (item) => {
                                  'name': item.name,
                                  'price': item.price,
                                  'quantity': item.quantity,
                                  'restaurantName': item.restaurantName,
                                },
                              )
                              .toList(),
                        },
                      );
                    } else {
                      final raw =
                          ref.read(checkoutProvider).error ??
                          'Failed to place order. Please try again.';
                      final errorMsg = raw.startsWith('Exception: ')
                          ? raw.substring(11)
                          : raw;
                      SnackBarUtils.showError(context, errorMsg);
                    }
                  },
              ),
            ],
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
