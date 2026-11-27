import 'package:lesgo/core/utils/money.dart';
import 'package:lesgo/presentation/widgets/booking/common/order_design.dart';
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
import '../../../../../core/utils/voucher_service_utils.dart';
import '../../../../provider/main/address/address_provider.dart';
import '../../../../widgets/address/delivery_address_picker.dart';
import '../../../../widgets/booking/common/store_branch_selector.dart';
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
  bool _promptedForAddress = false;

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
    if (!mounted) return;
    if (deliveryAddr == null) {
      _promptForAddressIfNeeded();
      return;
    }

    setState(() => _selectedAddress = deliveryAddr);
    ref
        .read(checkoutProvider.notifier)
        .updateDeliveryAddress(
          deliveryAddr.addressLine1,
          deliveryAddr.latitude,
          deliveryAddr.longitude,
          deliveryAddr.contactName ?? '',
          deliveryAddr.contactPhone ?? '',
        );
  }

  /// Opens the address sheet once when checkout has no usable delivery address,
  /// so the customer is not left on a blocked checkout with no next step.
  void _promptForAddressIfNeeded() {
    if (_promptedForAddress || !mounted) return;
    final checkout = ref.read(checkoutProvider);
    if (checkout.order == null ||
        checkout.hasValidDropoffLocation ||
        checkout.isLoading) {
      return;
    }
    _promptedForAddress = true;
    _showAddressSelector(context, ref);
  }

  void _showAddressSelector(BuildContext context, WidgetRef ref) {
    showDeliveryAddressPicker(
      context,
      onSelected: (sheetContext, address) {
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
        Navigator.pop(sheetContext);
        SnackBarUtils.showSuccess(context, 'Delivery address updated');
      },
    );
  }

  Future<void> _showVoucherDialog(BuildContext context, WidgetRef ref) async {
    final order = ref.read(checkoutProvider).order;
    final code = await showVoucherBottomSheet(
      context,
      serviceId: BookingServiceIds.leseat,
      // The backend checks the minimum against subtotal + delivery fee.
      orderValue: order == null ? null : order.subtotal + order.deliveryFee,
    );
    if (code == null || !context.mounted) return;

    final error = await ref.read(checkoutProvider.notifier).applyVoucher(code);
    if (!context.mounted) return;

    if (error == null) {
      SnackBarUtils.showSuccess(context, 'Voucher applied');
    }
  }

  /// Keeps the local selection valid when saved addresses change (e.g. the
  /// selected one was deleted): fall back to the delivery address or clear.
  void _onAddressesChanged(List<AddressDto> addresses) {
    final selected = _selectedAddress;
    if (selected == null || addresses.any((a) => a.id == selected.id)) return;
    final fallback = ref.read(addressProvider).deliveryAddress;
    setState(() => _selectedAddress = fallback);
    ref
        .read(checkoutProvider.notifier)
        .updateDeliveryAddress(
          fallback?.addressLine1 ?? '',
          fallback?.latitude ?? 0,
          fallback?.longitude ?? 0,
          fallback?.contactName ?? '',
          fallback?.contactPhone ?? '',
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<List<AddressDto>>(
      addressProvider.select((state) => state.addresses),
      (previous, next) {
        if (mounted) _onAddressesChanged(next);
      },
    );
    ref.listen<String?>(
      checkoutProvider.select((state) => state.voucherError),
      (previous, next) {
        if (next != null && next != previous && context.mounted) {
          SnackBarUtils.showError(context, next);
        }
      },
    );
    ref.listen<String?>(checkoutProvider.select((state) => state.fareError), (
      previous,
      next,
    ) {
      if (next != null &&
          next != previous &&
          next != kMissingDeliveryAddressMessage &&
          context.mounted) {
        SnackBarUtils.showError(context, next);
      }
    });
    // The customer just added or picked an address while checkout still had
    // none (e.g. via Manage > Add Address): use it now, so the "selected" tick
    // in the address sheet matches what checkout actually delivers to.
    ref.listen<AddressDto?>(
      addressProvider.select((state) => state.deliveryAddress),
      (previous, next) {
        if (next == null || !mounted) return;
        final checkout = ref.read(checkoutProvider);
        if (checkout.order == null || checkout.hasValidDropoffLocation) return;
        setState(() => _selectedAddress = next);
        ref
            .read(checkoutProvider.notifier)
            .updateDeliveryAddress(
              next.addressLine1,
              next.latitude,
              next.longitude,
              next.contactName ?? '',
              next.contactPhone ?? '',
            );
      },
    );
    // No usable delivery address: open the address sheet once so the customer
    // can pick or add one instead of landing on a silently blocked checkout.
    ref.listen<bool>(
      checkoutProvider.select(
        (state) =>
            state.order != null &&
            !state.hasValidDropoffLocation &&
            !state.isLoading,
      ),
      (previous, needsAddress) {
        if (!needsAddress) return;
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _promptForAddressIfNeeded(),
        );
      },
    );
    final checkoutState = ref.watch(checkoutProvider);
    final checkoutNotifier = ref.read(checkoutProvider.notifier);
    final order = checkoutState.order;

    if (order == null) {
      return Scaffold(
        backgroundColor: OrderDesign.canvas(context),
        body: SafeArea(
          child: Column(
            children: [
              BookingServiceHeader(title: 'Checkout', orderStyle: true),
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
      backgroundColor: OrderDesign.canvas(context),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            BookingServiceHeader(
              title: 'Checkout',
              orderStyle: true,
              action: const SizedBox.shrink(),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OrderReceiptHeader(
                      title: 'Your bag',
                      detail:
                          '${order.totalItems} ${order.totalItems == 1 ? 'item' : 'items'}',
                      subtotal: !isCartEmpty ? Money.format(subtotal) : null,
                      icon: Icons.restaurant_rounded,
                    ),

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

                    // Pickup branch (multi-branch stores)
                    if (checkoutState.branches.isNotEmpty) ...[
                      StoreBranchSelector(
                        branches: checkoutState.branches,
                        selected: checkoutState.selectedBranch,
                        dropoffLat: checkoutState.dropoffLat,
                        dropoffLng: checkoutState.dropoffLng,
                        enabled: !checkoutState.isLoading,
                        onSelected: checkoutNotifier.selectBranch,
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                    ],

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
                              color: AppColors.foreground(
                                context,
                                Colors.grey[400]!,
                              ),
                            ),
                            SizedBox(
                              height: ResponsiveUtils.spacing(context, 16),
                            ),
                            Text(
                              'Your cart is empty',
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: ResponsiveUtils.fontSize(context, 16),
                                color: AppColors.foreground(
                                  context,
                                  Colors.grey[600]!,
                                ),
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
                                  color: AppColors.accent(
                                    context,
                                    Color(0xFF5F2D82),
                                  ),
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

                    // Voucher (scrolls with the page so small screens keep the items visible)
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

                    // Order summary
                    OrderSummarySection(
                      subtotal: subtotal,
                      delivery: deliveryFee,
                      discount: order.discount,
                      total: total,
                      itemCount: isCartEmpty ? 0 : order.totalItems,
                    ),

                    const SizedBox(height: 16),
                    // Payment Method Section
                    BookingPaymentMethodSection(
                      selectedMethod:
                          checkoutState.selectedPaymentMethod ?? 'cash',
                      onMethodChanged: checkoutNotifier.selectPaymentMethod,
                      enabled: !isCartEmpty,
                      minimumAmount: isCartEmpty ? null : total,
                    ),

                    SizedBox(height: ResponsiveUtils.spacing(context, 16)),

                    SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Bottom Continue Button
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
        decoration: OrderDesign.dock(context),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (checkoutState.fareError != null &&
                  !checkoutState.isLoadingFare)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    checkoutState.fareError!,
                    key: const ValueKey('checkout-fare-error'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 12.5,
                      color: Color(0xFFD32F2F),
                    ),
                  ),
                ),
              if (checkoutState.fareError == kMissingDeliveryAddressMessage)
                TextButton.icon(
                  key: const ValueKey('checkout-add-address'),
                  onPressed: () => _showAddressSelector(context, ref),
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: const Text('Add delivery address'),
                )
              else if (isOutOfRangeDeliveryMessage(checkoutState.fareError))
                TextButton.icon(
                  key: const ValueKey('checkout-change-address'),
                  onPressed: () => _showAddressSelector(context, ref),
                  icon: const Icon(Icons.edit_location_alt_outlined),
                  label: const Text('Change delivery address'),
                )
              else if (checkoutState.fareError != null)
                TextButton.icon(
                  onPressed: checkoutState.isLoadingFare
                      ? null
                      : checkoutNotifier.refreshDeliveryFee,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry delivery fee'),
                ),
              OrderActionWithTotal(
                total:
                    !isCartEmpty &&
                        checkoutState.hasValidDeliveryFee &&
                        !checkoutState.isLoadingFare &&
                        !checkoutState.isValidatingVoucher
                    ? total
                    : null,
                child: PrimaryButton(
                  text: 'Checkout',
                  isLoading: checkoutState.isLoading,
                  backgroundColor: isCartEmpty
                      ? Colors.grey
                      : const Color(0xFF5F2D82),
                  onPressed:
                      isCartEmpty ||
                          checkoutState.isLoading ||
                          checkoutState.isLoadingFare ||
                          checkoutState.isValidatingVoucher ||
                          !checkoutState.hasValidDeliveryFee
                      ? null
                      : () async {
                          final success = await checkoutNotifier.placeOrder(
                            context,
                          );
                          if (!context.mounted) return;
                          if (success) {
                            final checkoutState = ref.read(checkoutProvider);
                            final createdId = checkoutState.createdOrderId;
                            if (createdId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Order was not created. Please try again.',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            final items = [
                              for (final item in order.items)
                                {
                                  'name': item.name,
                                  'price': item.price,
                                  'quantity': item.quantity,
                                  'restaurantName': item.restaurantName,
                                },
                            ];
                            if (checkoutState.canStartRiderSearch) {
                              AppRouter.pushReplacement(
                                context,
                                BookingRoutes.driverFinding,
                                arguments: {
                                  'orderId': createdId.toString(),
                                  'orderType': 'LesEat',
                                  'orderData': {
                                    'deliveryAddress': order.deliveryAddress,
                                    'items': items,
                                    'status': checkoutState.createdOrderStatus,
                                  },
                                },
                              );
                            } else {
                              AppRouter.pushReplacement(
                                context,
                                BookingRoutes.leseatWaitingConfirmation,
                                arguments: {
                                  'orderId': createdId,
                                  'address': order.deliveryAddress,
                                  'orderItems': items,
                                },
                              );
                            }
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
