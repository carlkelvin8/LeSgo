import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lesgo/core/state/user_session_epoch.dart';
import 'dart:async';

import '../../../../domain/entities/booking/leseat/order.dart';

import '../../../../domain/entities/booking/leseat/order_item.dart';

import 'package:dio/dio.dart';

import '../../../../data/data_source/order_remote_datasource.dart';

import '../../../../data/data_source/wallet_remote_datasource.dart';

import '../../../../data/data_source/partner_remote_datasource.dart';

import '../../../../data/data_source/dto/order/create_order_request_dto.dart';

import '../../../../data/data_source/dto/voucher/validate_voucher_request_dto.dart';

import '../../../../core/di/injection.dart';

import '../../../../core/services/service_area_checker.dart';
import '../../../../core/utils/booking_geo_utils.dart';
import '../../../../core/utils/api_error_mapper.dart';
import '../../../../core/utils/booking_checkout_payment.dart';
import '../../../../core/utils/network_guard.dart';
import '../../../../core/utils/active_order_limit_guard.dart';

import '../../../../data/data_source/voucher_remote_datasource.dart';

import 'restaurant_detail_provider.dart';

import '../profile/profile_provider.dart';

import '../address/address_provider.dart';

import '../lespay/lespay_provider.dart';

class CheckoutState {
  final Order? order;

  final bool isLoading;

  final String? error;

  final String? selectedPaymentMethod;

  final int? createdOrderId;

  final double dropoffLat;

  final double dropoffLng;

  final double pickupLat;

  final double pickupLng;

  final int estimatedDistanceM;

  final bool isLoadingFare;

  final bool isValidatingVoucher;

  final String? voucherError;
  final bool hasValidDeliveryFee;
  final String? fareError;
  final bool hasValidPickupLocation;
  final bool hasValidDropoffLocation;

  CheckoutState({
    this.order,

    this.isLoading = false,

    this.error,

    this.selectedPaymentMethod,

    this.createdOrderId,

    this.dropoffLat = BookingGeoUtils.defaultLat,

    this.dropoffLng = BookingGeoUtils.defaultLng,

    this.pickupLat = BookingGeoUtils.defaultLat,

    this.pickupLng = BookingGeoUtils.defaultLng,

    this.estimatedDistanceM = 5000,

    this.isLoadingFare = false,

    this.isValidatingVoucher = false,

    this.voucherError,
    this.hasValidDeliveryFee = false,
    this.fareError,
    this.hasValidPickupLocation = false,
    this.hasValidDropoffLocation = false,
  });

  CheckoutState copyWith({
    Order? order,

    bool? isLoading,

    String? error,

    String? selectedPaymentMethod,

    int? createdOrderId,

    double? dropoffLat,

    double? dropoffLng,

    double? pickupLat,

    double? pickupLng,

    int? estimatedDistanceM,

    bool? isLoadingFare,

    bool? isValidatingVoucher,

    String? voucherError,

    bool clearVoucherError = false,
    bool? hasValidDeliveryFee,
    String? fareError,
    bool clearFareError = false,
    bool? hasValidPickupLocation,
    bool? hasValidDropoffLocation,
  }) {
    return CheckoutState(
      order: order ?? this.order,

      isLoading: isLoading ?? this.isLoading,

      error: error,

      selectedPaymentMethod:
          selectedPaymentMethod ?? this.selectedPaymentMethod,

      createdOrderId: createdOrderId ?? this.createdOrderId,

      dropoffLat: dropoffLat ?? this.dropoffLat,

      dropoffLng: dropoffLng ?? this.dropoffLng,

      pickupLat: pickupLat ?? this.pickupLat,

      pickupLng: pickupLng ?? this.pickupLng,

      estimatedDistanceM: estimatedDistanceM ?? this.estimatedDistanceM,

      isLoadingFare: isLoadingFare ?? this.isLoadingFare,

      isValidatingVoucher: isValidatingVoucher ?? this.isValidatingVoucher,

      voucherError: clearVoucherError
          ? null
          : (voucherError ?? this.voucherError),
      hasValidDeliveryFee: hasValidDeliveryFee ?? this.hasValidDeliveryFee,
      fareError: clearFareError ? null : (fareError ?? this.fareError),
      hasValidPickupLocation:
          hasValidPickupLocation ?? this.hasValidPickupLocation,
      hasValidDropoffLocation:
          hasValidDropoffLocation ?? this.hasValidDropoffLocation,
    );
  }
}

class CheckoutNotifier extends StateNotifier<CheckoutState> {
  final Ref ref;

  final OrderRemoteDataSource _orderDataSource = getIt<OrderRemoteDataSource>();

  final VoucherRemoteDataSource _voucherDataSource =
      getIt<VoucherRemoteDataSource>();

  int _fareRequestId = 0;
  int _voucherRequestId = 0;
  int _cartRevision = 0;
  int _initializeRequestId = 0;

  CheckoutNotifier(this.ref) : super(CheckoutState());

  /// Initialize order from cart data using the latest saved delivery address.

  Future<void> initializeFromCart(String restaurantName) async {
    if (state.isLoading) return;
    final requestId = ++_initializeRequestId;
    _cartRevision++;
    _voucherRequestId++;
    final previousVoucher = state.order?.voucherCode;
    final profileState = ref.read(profileProvider);
    final userId = profileState.user?.id ?? 0;
    if (userId > 0) {
      await ref.read(addressProvider.notifier).loadAddresses(userId);
    }
    if (!mounted || requestId != _initializeRequestId) return;

    final restaurantState = ref.read(restaurantDetailProvider);
    final cartItems = restaurantState.cartItems
        .map(
          (item) => item.restaurantName == null
              ? item.copyWith(restaurantName: restaurantName)
              : item,
        )
        .toList();
    final addressState = ref.read(addressProvider);
    final subtotal = cartItems.fold<double>(0, (sum, item) => sum + item.total);
    var dropoffLat = BookingGeoUtils.defaultLat;
    var dropoffLng = BookingGeoUtils.defaultLng;
    var deliveryAddress =
        profileState.user?.addressLine1 ?? 'Brgy 6, Claveria, Cagayan';
    final deliveryAddr = addressState.deliveryAddress;
    if (deliveryAddr != null) {
      dropoffLat = deliveryAddr.latitude;
      dropoffLng = deliveryAddr.longitude;
      deliveryAddress = deliveryAddr.addressLine1;
    }
    final order = Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      restaurantName: restaurantName,
      deliveryAddress: deliveryAddress,
      items: List<OrderItem>.from(cartItems),
      subtotal: subtotal,
      deliveryFee: 0,
      voucherCode: previousVoucher,
    );
    state = state.copyWith(
      order: order,
      selectedPaymentMethod: state.selectedPaymentMethod ?? 'cash',
      dropoffLat: dropoffLat,
      dropoffLng: dropoffLng,
      isValidatingVoucher: false,
      hasValidDeliveryFee: false,
      hasValidPickupLocation: false,
      hasValidDropoffLocation: BookingGeoUtils.hasValidCoords(
        deliveryAddr?.latitude,
        deliveryAddr?.longitude,
      ),
      clearVoucherError: true,
      clearFareError: true,
    );
    await _resolvePickupCoordinates(
      restaurantState.activeRestaurantId,
      requestId,
    );
    if (!mounted || requestId != _initializeRequestId) return;
    await refreshDeliveryFee();
  }

  Future<void> _resolvePickupCoordinates(
    String? partnerIdStr,
    int requestId,
  ) async {
    if (!mounted || requestId != _initializeRequestId) return;
    if (partnerIdStr == null || partnerIdStr.isEmpty) {
      state = state.copyWith(
        hasValidPickupLocation: false,
        fareError:
            'Restaurant location is unavailable. Please contact the restaurant.',
      );
      return;
    }
    try {
      final partnerId = int.parse(partnerIdStr);
      final partner = await getIt<PartnerRemoteDataSource>().getPartner(
        partnerId,
      );
      if (!mounted || requestId != _initializeRequestId) return;
      if (BookingGeoUtils.hasValidCoords(partner.latitude, partner.longitude)) {
        state = state.copyWith(
          pickupLat: partner.latitude!,
          pickupLng: partner.longitude!,
          hasValidPickupLocation: true,
          clearFareError: true,
        );
        return;
      }
    } catch (_) {
      // Checkout remains blocked because a fallback coordinate could misprice delivery.
    }
    if (mounted && requestId == _initializeRequestId) {
      state = state.copyWith(
        hasValidPickupLocation: false,
        fareError:
            'Restaurant location is unavailable. Please contact the restaurant.',
      );
    }
  }

  Future<void> refreshDeliveryFee() async {
    final current = state.order;
    if (current == null) return;
    final requestId = ++_fareRequestId;
    // A retry must re-fetch the store pin, including after the merchant has
    // completed pickup setup. Reusing the invalid snapshot never recovers.
    if (!state.hasValidPickupLocation) {
      state = state.copyWith(isLoadingFare: true, clearFareError: true);
      await _resolvePickupCoordinates(
        ref.read(restaurantDetailProvider).activeRestaurantId,
        _initializeRequestId,
      );
      if (!mounted || requestId != _fareRequestId) return;
    }
    if (!state.hasValidPickupLocation) {
      state = state.copyWith(
        hasValidDeliveryFee: false,
        isLoadingFare: false,
        fareError: 'This restaurant has not set its pickup location yet. '
            'Please contact the restaurant or choose another store.',
      );
      return;
    }
    if (!state.hasValidPickupLocation ||
        !state.hasValidDropoffLocation ||
        !BookingGeoUtils.hasValidCoords(state.pickupLat, state.pickupLng) ||
        !BookingGeoUtils.hasValidCoords(state.dropoffLat, state.dropoffLng)) {
      state = state.copyWith(
        hasValidDeliveryFee: false,
        isLoadingFare: false,
        fareError:
            'Select a valid restaurant and delivery location before checkout.',
      );
      return;
    }
    ++_voucherRequestId;
    final distanceM = BookingGeoUtils.distanceMeters(
      lat1: state.pickupLat,
      lng1: state.pickupLng,
      lat2: state.dropoffLat,
      lng2: state.dropoffLng,
    ).clamp(500, 25000);
    state = state.copyWith(
      isLoadingFare: true,
      hasValidDeliveryFee: false,
      isValidatingVoucher: false,
      estimatedDistanceM: distanceM,
      clearFareError: true,
      order: state.order?.copyWith(discount: 0),
    );
    try {
      final fee = await _orderDataSource.getFareEstimateRaw(
        serviceId: 3,
        estimatedDistanceM: distanceM,
        pickupLat: state.pickupLat,
        pickupLng: state.pickupLng,
        dropoffLat: state.dropoffLat,
        dropoffLng: state.dropoffLng,
      );
      if (!mounted || requestId != _fareRequestId) return;
      final normalized = _normalizeDeliveryFee(fee);
      if (normalized == null) {
        state = state.copyWith(
          isLoadingFare: false,
          fareError: 'Could not calculate a valid delivery fee. Please retry.',
        );
        return;
      }
      final latest = state.order;
      if (latest == null) return;
      state = state.copyWith(
        order: latest.copyWith(deliveryFee: normalized),
        isLoadingFare: false,
        hasValidDeliveryFee: true,
        clearFareError: true,
      );
      final code = state.order?.voucherCode;
      if (code != null && code.isNotEmpty) {
        _startVoucherRevalidation(code);
      }
    } catch (e) {
      if (!mounted || requestId != _fareRequestId) return;
      state = state.copyWith(
        isLoadingFare: false,
        hasValidDeliveryFee: false,
        fareError: ApiErrorMapper.message(
          e,
          fallbackEn: 'Could not calculate delivery fee. Please retry.',
          fallbackTl: 'Hindi makalkula ang delivery fee. Subukan muli.',
        ),
      );
    }
  }

  void updateItemQuantity(String itemId, int quantity) {
    if (state.isLoading || state.order == null) return;
    if (quantity <= 0) {
      removeItem(itemId);
      return;
    }
    if (!state.order!.items.any((item) => item.id == itemId)) return;
    ref
        .read(restaurantDetailProvider.notifier)
        .updateCartItemQuantity(itemId, quantity);
    final updatedItems = state.order!.items
        .map(
          (item) =>
              item.id == itemId ? item.copyWith(quantity: quantity) : item,
        )
        .toList();
    _updateCartSnapshot(updatedItems);
  }

  void removeItem(String itemId) {
    if (state.isLoading ||
        state.order == null ||
        !state.order!.items.any((item) => item.id == itemId)) {
      return;
    }
    ref.read(restaurantDetailProvider.notifier).removeFromCart(itemId);
    _updateCartSnapshot(
      state.order!.items.where((item) => item.id != itemId).toList(),
    );
  }

  void _updateCartSnapshot(List<OrderItem> items) {
    final subtotal = items.fold<double>(0, (sum, item) => sum + item.total);
    final code = state.order?.voucherCode;
    final updated = state.order!.copyWith(
      items: items,
      subtotal: subtotal,
      discount: 0,
    );
    ++_cartRevision;
    ++_voucherRequestId;
    state = state.copyWith(
      order: updated,
      isValidatingVoucher: false,
      clearVoucherError: true,
    );
    if (code != null &&
        code.isNotEmpty &&
        state.hasValidDeliveryFee &&
        !state.isLoadingFare) {
      _startVoucherRevalidation(code);
    }
  }

  void resetCheckout() {
    ++_initializeRequestId;
    ++_fareRequestId;
    state = CheckoutState();
  }

  Future<String?> applyVoucher(String voucherCode) async {
    final order = state.order;
    if (order == null || order.items.isEmpty) return 'Cart is empty';
    final code = voucherCode.trim().toUpperCase();
    if (code.isEmpty) return 'Enter a voucher code';
    if (state.isLoading) return 'Checkout is already in progress.';
    if (state.isLoadingFare || !state.hasValidDeliveryFee)
      return state.fareError ??
          'Wait for the delivery fee to finish calculating.';
    final money = order.money;
    if (!money.isValid) return money.error;
    final requestId = ++_voucherRequestId;
    final revision = _cartRevision;
    state = state.copyWith(isValidatingVoucher: true, clearVoucherError: true);
    try {
      final quote = await _requestVoucherQuote(code, order, money);
      if (!mounted ||
          requestId != _voucherRequestId ||
          revision != _cartRevision)
        return 'Cart changed; please retry the voucher.';
      if (!quote.valid) {
        state = state.copyWith(
          isValidatingVoucher: false,
          voucherError: quote.error,
        );
        return quote.error;
      }
      state = state.copyWith(
        order: state.order!.copyWith(
          discount: quote.discount!,
          voucherCode: code,
        ),
        isValidatingVoucher: false,
        clearVoucherError: true,
      );
      return null;
    } catch (e) {
      final msg = ApiErrorMapper.message(
        e,
        fallbackEn: 'Could not apply voucher. Please try again.',
        fallbackTl: 'Hindi ma-apply ang voucher. Subukan muli.',
      );
      if (mounted &&
          requestId == _voucherRequestId &&
          revision == _cartRevision) {
        state = state.copyWith(isValidatingVoucher: false, voucherError: msg);
      }
      return msg;
    }
  }

  void _startVoucherRevalidation(String code) {
    if (state.isLoading || !state.hasValidDeliveryFee || state.isLoadingFare)
      return;
    final order = state.order;
    if (order == null) return;
    final money = order.copyWith(discount: 0).money;
    if (!money.isValid) {
      state = state.copyWith(
        order: order.copyWith(discount: 0, clearVoucherCode: true),
        isValidatingVoucher: false,
        voucherError: 'Voucher removed: ${money.error}',
      );
      return;
    }
    final requestId = ++_voucherRequestId;
    final revision = _cartRevision;
    state = state.copyWith(isValidatingVoucher: true, clearVoucherError: true);
    unawaited(() async {
      try {
        final quote = await _requestVoucherQuote(
          code,
          order.copyWith(discount: 0),
          money,
        );
        if (!_voucherResponseIsCurrent(requestId, revision, code)) return;
        if (quote.valid) {
          state = state.copyWith(
            order: state.order!.copyWith(discount: quote.discount!),
            isValidatingVoucher: false,
            clearVoucherError: true,
          );
        } else {
          state = state.copyWith(
            order: state.order!.copyWith(discount: 0, clearVoucherCode: true),
            isValidatingVoucher: false,
            voucherError: 'Voucher removed: ${quote.error}',
          );
        }
      } catch (e) {
        if (!_voucherResponseIsCurrent(requestId, revision, code)) return;
        final msg = ApiErrorMapper.message(
          e,
          fallbackEn:
              'Voucher removed because it could not be revalidated. Please apply it again.',
          fallbackTl:
              'Inalis ang voucher dahil hindi ito ma-validate. I-apply muli.',
        );
        state = state.copyWith(
          order: state.order!.copyWith(discount: 0, clearVoucherCode: true),
          isValidatingVoucher: false,
          voucherError: msg,
        );
      }
    }());
  }

  bool _voucherResponseIsCurrent(int requestId, int revision, String code) =>
      mounted &&
      requestId == _voucherRequestId &&
      revision == _cartRevision &&
      state.order?.voucherCode == code;

  Future<_VoucherQuote> _requestVoucherQuote(
    String code,
    Order order,
    OrderMoney money,
  ) async {
    final response = await _voucherDataSource.validateVoucher(
      ValidateVoucherRequestDto(
        voucherCode: code,
        orderValue: money.validatedSubtotal + money.validatedDeliveryFee,
        serviceId: 3,
        deliveryFee: money.validatedDeliveryFee,
        items: order.items
            .map(
              (item) => {
                'name': item.name,
                'estimated_price': (item.price * 100).round() / 100,
                'quantity': item.quantity,
              },
            )
            .toList(),
      ),
    );
    final data = response.data;
    if (!data.valid)
      return _VoucherQuote.invalid(data.error ?? response.message);
    final discount = data.discountAmount;
    if (discount == null || !discount.isFinite || discount < 0) {
      return _VoucherQuote.invalid(
        'Voucher returned an invalid discount amount.',
      );
    }
    final cents = (discount * 100).round();
    final grossCents =
        (money.validatedSubtotal * 100).round() +
        (money.validatedDeliveryFee * 100).round();
    if ((discount * 100 - cents).abs() > 0.000001 || cents > grossCents) {
      return _VoucherQuote.invalid(
        'Voucher discount exceeds the order amount.',
      );
    }
    if (data.newTotal != null &&
        (!data.newTotal!.isFinite ||
            (data.newTotal! * 100).round() != grossCents - cents)) {
      return _VoucherQuote.invalid(
        'Voucher total does not match the validated order.',
      );
    }
    return _VoucherQuote.success(cents / 100);
  }

  void removeVoucher() {
    if (state.order == null || state.isLoading) return;
    ++_voucherRequestId;
    state = state.copyWith(
      order: state.order!.copyWith(discount: 0, clearVoucherCode: true),
      isValidatingVoucher: false,
      clearVoucherError: true,
    );
  }

  void selectPaymentMethod(String method) {
    state = state.copyWith(selectedPaymentMethod: method);
  }

  void updateDeliveryAddress(
    String address,

    double lat,

    double lng,

    String contactName,

    String contactPhone,
  ) {
    if (state.order == null || state.isLoading) return;

    final updatedOrder = state.order!.copyWith(deliveryAddress: address);

    state = state.copyWith(
      order: updatedOrder.copyWith(discount: 0),
      dropoffLat: lat,
      dropoffLng: lng,
      hasValidDeliveryFee: false,
      hasValidDropoffLocation: BookingGeoUtils.hasValidCoords(lat, lng),
    );

    refreshDeliveryFee();
  }

  Future<bool> placeOrder(BuildContext context) async {
    // Double-tap guard: prevent duplicate order creation
    if (state.isLoading) return false;
    if (state.order == null) return false;

    // Claim the checkout synchronously before the first await. This closes the
    // window where two taps both pass the guard while network checks are in
    // flight, and immediately disables the checkout button.
    state = state.copyWith(isLoading: true, error: null);

    try {
      if (!await NetworkGuard.ensureOnline(context)) {
        state = state.copyWith(isLoading: false);
        return false;
      }
      if (!context.mounted) {
        state = state.copyWith(isLoading: false);
        return false;
      }
      if (!await ActiveOrderLimitGuard.ensureCanBook(context)) {
        state = state.copyWith(isLoading: false);
        return false;
      }
      if (!context.mounted) {
        state = state.copyWith(isLoading: false);
        return false;
      }

      final serviceArea = await ServiceAreaChecker.checkCoordinates(
        latitude: state.dropoffLat,
        longitude: state.dropoffLng,
      );
      if (!context.mounted) {
        state = state.copyWith(isLoading: false);
        return false;
      }
      if (!serviceArea.isAvailable) {
        state = state.copyWith(
          isLoading: false,
          error: '${serviceArea.messageEn}\n${serviceArea.messageTl}',
        );
        return false;
      }

      if (state.isLoadingFare || !state.hasValidDeliveryFee) {
        state = state.copyWith(
          isLoading: false,
          error: state.fareError ?? 'Delivery fee is not ready. Please retry.',
        );
        return false;
      }
      if (state.isValidatingVoucher) {
        state = state.copyWith(
          isLoading: false,
          error: 'Please wait while the voucher is revalidated.',
        );
        return false;
      }
      var order = state.order!;
      if (order.items.isEmpty) {
        state = state.copyWith(isLoading: false, error: 'Cart is empty.');
        return false;
      }
      var money = order.money;
      if (!money.isValid) {
        state = state.copyWith(isLoading: false, error: money.error);
        return false;
      }
      final voucherCode = order.voucherCode;
      if (voucherCode != null && voucherCode.isNotEmpty) {
        final quote = await _requestVoucherQuote(voucherCode, order, money);
        if (!mounted) return false;
        if (!quote.valid) {
          state = state.copyWith(
            isLoading: false,
            order: order.copyWith(discount: 0, clearVoucherCode: true),
            voucherError: 'Voucher removed: ${quote.error}',
            error:
                'The voucher is no longer valid. Review your total and place the order again.',
          );
          return false;
        }
        order = order.copyWith(discount: quote.discount!);
        money = order.money;
        if (!money.isValid) {
          state = state.copyWith(isLoading: false, error: money.error);
          return false;
        }
        state = state.copyWith(order: order);
      }
      if (isDigitalPaymentMethod(state.selectedPaymentMethod ?? 'cash') &&
          money.finalTotal == 0) {
        state = state.copyWith(
          isLoading: false,
          error: 'This order has no amount to charge. Choose Cash or LesPay.',
        );
        return false;
      }

      final profileState = ref.read(profileProvider);

      final user = profileState.user;

      final restaurantNames = _restaurantNames(order);

      final restaurantLabel = restaurantNames.isEmpty
          ? order.restaurantName
          : restaurantNames.join(', ');

      final partnerId =
          order.items.isNotEmpty && order.items.first.restaurantId != null
          ? int.tryParse(order.items.first.restaurantId!)
          : null;

      final createOrderRequest = CreateOrderRequestDto(
        serviceId: 3,

        partnerId: partnerId,

        estimatedDistanceM: state.estimatedDistanceM,

        pickup: OrderAddressDto(
          address: restaurantLabel,

          lat: state.pickupLat,

          lng: state.pickupLng,

          contactName: restaurantLabel,

          contactPhone: '+639123456789',
        ),

        dropoff: OrderAddressDto(
          address: order.deliveryAddress,

          lat: state.dropoffLat,

          lng: state.dropoffLng,

          contactName: user?.name ?? 'Customer',

          contactPhone: user?.phone ?? '+639123456789',
        ),

        notes: 'LesEat order: ${order.items.length} items',

        paymentMethod: state.selectedPaymentMethod ?? 'cash',

        items: order.items
            .map(
              (item) => OrderItemDto(
                name: item.name,
                quantity: item.quantity,
                estimatedPrice: item.price,
                notes: item.optionsDisplay,
                menuItemId: int.tryParse(item.menuItemId ?? ''),
                selectedOptions: item.selectedOptions.isEmpty
                    ? null
                    : item.selectedOptions.toApiMap(),
              ),
            )
            .toList(),

        voucherCode: order.voucherCode,

        discountAmount: money.validatedDiscount,

        meta: {
          'restaurant_name': restaurantLabel,

          'restaurants': restaurantNames,

          'subtotal': money.validatedSubtotal,

          'delivery_fee': money.validatedDeliveryFee,

          'discount': money.validatedDiscount,

          'voucher_code': order.voucherCode,

          'total': money.finalTotal,

          'grand_total': money.finalTotal,

          'order_type': 'leseat',

          'items': order.items
              .map(
                (item) => {
                  'name': item.name,
                  'price': item.price,
                  'quantity': item.quantity,
                  'total': item.total,
                  'restaurant_id': item.restaurantId,
                  'restaurant_name':
                      item.restaurantName ?? order.restaurantName,
                  if (item.menuItemId != null) 'menu_item_id': item.menuItemId,
                  if (!item.selectedOptions.isEmpty)
                    'selected_options': item.selectedOptions.toApiMap(),
                  if (item.optionsDisplay != null)
                    'options_display': item.optionsDisplay,
                },
              )
              .toList(),
        },
      );

      // Pre-check: fetch LIVE wallet balance so stale cache never lets through
      // a payment the server will reject.
      if ((state.selectedPaymentMethod ?? 'cash') == 'wallet') {
        try {
          final wallet = await getIt<WalletRemoteDataSource>().getMyWallet();
          // Sync provider with fresh balance so the UI is up-to-date.
          ref.read(lespayProvider.notifier).refreshBalance();
          if (wallet.balance < money.finalTotal!) {
            state = state.copyWith(
              isLoading: false,
              error:
                  'Insufficient LesPay balance. '
                  'Balance: ₱${wallet.balance.toStringAsFixed(2)}, '
                  'required: ₱${order.total.toStringAsFixed(2)}. '
                  'Please top up your wallet first.',
            );
            return false;
          }
        } on DioException catch (e) {
          final serverMsg = _extractErrorMessage(e, '');
          state = state.copyWith(
            isLoading: false,
            error: serverMsg.isNotEmpty
                ? serverMsg
                : 'Unable to verify your LesPay balance. '
                      'Please try again or use Cash on Delivery.',
          );
          return false;
        } catch (_) {
          state = state.copyWith(
            isLoading: false,
            error:
                'Unable to verify your LesPay balance. '
                'Please try again or use Cash on Delivery.',
          );
          return false;
        }
      }

      final response = await _orderDataSource.createOrder(createOrderRequest);

      final payAmount = response.data.effectiveTotalAmount > 0
          ? response.data.effectiveTotalAmount
          : money.finalTotal!;

      if (!context.mounted) {
        state = state.copyWith(isLoading: false);
        return false;
      }

      final paid = await completeBookingPayment(
        context: context,
        ref: ref,
        orderId: response.data.id,
        amount: payAmount,
        paymentMethod: state.selectedPaymentMethod ?? 'cash',
        serviceLabel: 'LesEat',
      );

      if (!paid) {
        state = state.copyWith(
          isLoading: false,
          error: 'Payment was not completed.',
        );
        return false;
      }

      await ref.read(restaurantDetailProvider.notifier).clearCart();

      state = state.copyWith(
        isLoading: false,
        createdOrderId: response.data.id,
      );

      return true;
    } catch (e) {
      // Strip the Dart 'Exception: ' wrapper so the message is user-friendly.
      final raw = e.toString();
      final msg = raw.startsWith('Exception: ') ? raw.substring(11) : raw;
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    }
  }

  List<String> _restaurantNames(Order order) {
    final names = <String>[];

    for (final item in order.items) {
      final name = item.restaurantName?.trim().isNotEmpty == true
          ? item.restaurantName!.trim()
          : order.restaurantName;

      if (!names.contains(name)) {
        names.add(name);
      }
    }

    return names;
  }

  double? _normalizeDeliveryFee(double? fee) {
    if (fee == null || !fee.isFinite || fee < 0 || fee > 500) return null;
    final cents = (fee * 100).round();
    if ((fee * 100 - cents).abs() > 0.000001) return null;
    return cents / 100;
  }

  /// Safely extract error message from various response formats
  String _extractErrorMessage(dynamic error, String fallback) {
    try {
      if (error is DioException && error.response?.data is Map) {
        final responseData = error.response!.data as Map;
        if (responseData['message'] is String &&
            (responseData['message'] as String).isNotEmpty) {
          return responseData['message'] as String;
        }
        if (responseData['error'] is String &&
            (responseData['error'] as String).isNotEmpty) {
          return responseData['error'] as String;
        }
      }
      return fallback;
    } catch (_) {
      return fallback;
    }
  }
}

class _VoucherQuote {
  final bool valid;
  final double? discount;
  final String error;

  const _VoucherQuote._(this.valid, this.discount, this.error);

  factory _VoucherQuote.success(double discount) =>
      _VoucherQuote._(true, discount, '');

  factory _VoucherQuote.invalid(String error) =>
      _VoucherQuote._(false, null, error);
}

final checkoutProvider = StateNotifierProvider<CheckoutNotifier, CheckoutState>(
  (ref) {
    ref.watch(userSessionEpochProvider);
    return CheckoutNotifier(ref);
  },
);
