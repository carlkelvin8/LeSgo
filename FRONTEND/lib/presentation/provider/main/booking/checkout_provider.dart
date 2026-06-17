import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/booking/leseat/order.dart';

import '../../../../domain/entities/booking/leseat/order_item.dart';

import 'package:dio/dio.dart';

import '../../../../data/data_source/order_remote_datasource.dart';

import '../../../../data/data_source/wallet_remote_datasource.dart';

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

      voucherError:

          clearVoucherError ? null : (voucherError ?? this.voucherError),

    );

  }

}



class CheckoutNotifier extends StateNotifier<CheckoutState> {

  final Ref ref;

  final OrderRemoteDataSource _orderDataSource = getIt<OrderRemoteDataSource>();

  final VoucherRemoteDataSource _voucherDataSource =

      getIt<VoucherRemoteDataSource>();



  CheckoutNotifier(this.ref) : super(CheckoutState());



  /// Initialize order from cart data using the latest saved delivery address.

  Future<void> initializeFromCart(String restaurantName) async {
    final profileState = ref.read(profileProvider);
    final userId = profileState.user?.id ?? 0;
    if (userId > 0) {
      await ref.read(addressProvider.notifier).loadAddresses(userId);
    }

    final restaurantState = ref.read(restaurantDetailProvider);

    final cartItems = restaurantState.cartItems.map((item) {

      return item.restaurantName == null

          ? item.copyWith(restaurantName: restaurantName)

          : item;

    }).toList();

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

      deliveryAddress = deliveryAddr.addressLine1 ?? deliveryAddress;

    }



    final order = Order(

      id: DateTime.now().millisecondsSinceEpoch.toString(),

      restaurantName: restaurantName,

      deliveryAddress: deliveryAddress,

      items: List<OrderItem>.from(cartItems),

      subtotal: subtotal,

      deliveryFee: 0.00,

    );



    state = state.copyWith(

      order: order,

      selectedPaymentMethod: state.selectedPaymentMethod ?? 'cash',

      dropoffLat: dropoffLat,

      dropoffLng: dropoffLng,

      clearVoucherError: true,

    );



    _resolvePickupCoordinates(restaurantState.activeRestaurantId);

    refreshDeliveryFee();

  }



  void _resolvePickupCoordinates(String? partnerIdStr) {

    // Restaurant pickup hub — use service default until partner branches expose coords.

    state = state.copyWith(

      pickupLat: BookingGeoUtils.defaultLat,

      pickupLng: BookingGeoUtils.defaultLng,

    );

  }



  Future<void> refreshDeliveryFee() async {

    if (state.order == null) return;



    final distanceM = BookingGeoUtils.distanceMeters(

      lat1: state.pickupLat,

      lng1: state.pickupLng,

      lat2: state.dropoffLat,

      lng2: state.dropoffLng,

    ).clamp(500, 25000);



    state = state.copyWith(isLoadingFare: true, estimatedDistanceM: distanceM);



    try {

      final deliveryFee = await _orderDataSource.getFareEstimateRaw(

        serviceId: 3,

        estimatedDistanceM: distanceM,

        pickupLat: state.pickupLat,

        pickupLng: state.pickupLng,

        dropoffLat: state.dropoffLat,

        dropoffLng: state.dropoffLng,

      );



      final normalizedFee = _normalizeDeliveryFee(deliveryFee);



      if (state.order != null && normalizedFee != null) {

        final updatedOrder = state.order!.copyWith(deliveryFee: normalizedFee);

        state = state.copyWith(order: updatedOrder, isLoadingFare: false);

      } else {

        state = state.copyWith(isLoadingFare: false);

      }

    } catch (_) {

      if (state.order != null) {

        final updatedOrder = state.order!.copyWith(deliveryFee: 50.00);

        state = state.copyWith(order: updatedOrder, isLoadingFare: false);

      } else {

        state = state.copyWith(isLoadingFare: false);

      }

    }

  }



  void updateItemQuantity(String itemId, int quantity) {
    if (state.order == null) return;

    if (quantity <= 0) {
      removeItem(itemId);
      return;
    }

    ref.read(restaurantDetailProvider.notifier).updateCartItemQuantity(
          itemId,
          quantity,
        );

    final updatedItems = state.order!.items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();

    final subtotal = updatedItems.fold<double>(
      0,
      (sum, item) => sum + item.total,
    );

    final updatedOrder = state.order!.copyWith(
      items: updatedItems,
      subtotal: subtotal,
    );

    state = state.copyWith(order: updatedOrder);
  }

  void removeItem(String itemId) {
    if (state.order == null) return;

    ref.read(restaurantDetailProvider.notifier).removeFromCart(itemId);

    final updatedItems =
        state.order!.items.where((item) => item.id != itemId).toList();

    final subtotal = updatedItems.fold<double>(
      0,
      (sum, item) => sum + item.total,
    );

    final updatedOrder = state.order!.copyWith(
      items: updatedItems,
      subtotal: subtotal,
    );

    state = state.copyWith(order: updatedOrder);
  }

  void resetCheckout() {
    state = CheckoutState();
  }



  Future<String?> applyVoucher(String voucherCode) async {

    if (state.order == null) return 'Cart is empty';



    final trimmed = voucherCode.trim();

    if (trimmed.isEmpty) return 'Enter a voucher code';



    state = state.copyWith(isValidatingVoucher: true, clearVoucherError: true);



    try {

      final orderValue = state.order!.subtotal + state.order!.deliveryFee;

      final response = await _voucherDataSource.validateVoucher(

        ValidateVoucherRequestDto(

          voucherCode: trimmed,

          orderValue: orderValue,

        ),

      );



      final data = response.data;

      if (!data.valid) {

        final msg = data.error ?? response.message;

        state = state.copyWith(

          isValidatingVoucher: false,

          voucherError: msg,

        );

        return msg;

      }



      final discount = data.discountAmount ?? 0;

      final updatedOrder = state.order!.copyWith(

        discount: discount,

        voucherCode: trimmed.toUpperCase(),

      );

      state = state.copyWith(

        order: updatedOrder,

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

      state = state.copyWith(

        isValidatingVoucher: false,

        voucherError: msg,

      );

      return msg;

    }

  }



  void removeVoucher() {

    if (state.order == null) return;



    final updatedOrder = state.order!.copyWith(

      discount: 0,

      voucherCode: null,

    );

    state = state.copyWith(order: updatedOrder, clearVoucherError: true);

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

    if (state.order == null) return;



    final updatedOrder = state.order!.copyWith(deliveryAddress: address);



    state = state.copyWith(

      order: updatedOrder,

      dropoffLat: lat,

      dropoffLng: lng,

    );

    refreshDeliveryFee();

  }



  Future<bool> placeOrder(BuildContext context) async {
    if (!await NetworkGuard.ensureOnline(context)) return false;
    if (!await ActiveOrderLimitGuard.ensureCanBook(context)) return false;

    if (state.order == null) return false;



    state = state.copyWith(isLoading: true, error: null);



    try {
      final serviceArea = await ServiceAreaChecker.checkCoordinates(
        latitude: state.dropoffLat,
        longitude: state.dropoffLng,
      );
      if (!serviceArea.isAvailable) {
        state = state.copyWith(
          isLoading: false,
          error: '${serviceArea.messageEn}\n${serviceArea.messageTl}',
        );
        return false;
      }

      final order = state.order!;

      final profileState = ref.read(profileProvider);

      final user = profileState.user;

      final restaurantNames = _restaurantNames(order);

      final restaurantLabel = restaurantNames.isEmpty

          ? order.restaurantName

          : restaurantNames.join(', ');



      final partnerId = order.items.isNotEmpty &&

              order.items.first.restaurantId != null

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

        discountAmount: order.discount,

        meta: {

          'restaurant_name': restaurantLabel,

          'restaurants': restaurantNames,

          'subtotal': order.subtotal,

          'delivery_fee': order.deliveryFee,

          'discount': order.discount,

          'voucher_code': order.voucherCode,

          'total': order.total,

          'grand_total': order.total,

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
          if (wallet.balance < order.total) {
            state = state.copyWith(
              isLoading: false,
              error: 'Insufficient LesPay balance. '
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
            error: 'Unable to verify your LesPay balance. '
                'Please try again or use Cash on Delivery.',
          );
          return false;
        }
      }

      final response = await _orderDataSource.createOrder(createOrderRequest);

      final payAmount = response.data.effectiveTotalAmount > 0
          ? response.data.effectiveTotalAmount
          : order.total;

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
    if (fee == null) return null;
    if (fee.isNaN || fee.isInfinite || fee < 0 || fee > 500) {
      return 49.0;
    }
    return fee;
  }

  /// Safely extract error message from various response formats
  String _extractErrorMessage(dynamic error, String fallback) {
    try {
      if (error is DioException && error.response?.data is Map) {
        final responseData = error.response!.data as Map;
        if (responseData['message'] is String && (responseData['message'] as String).isNotEmpty) {
          return responseData['message'] as String;
        }
        if (responseData['error'] is String && (responseData['error'] as String).isNotEmpty) {
          return responseData['error'] as String;
        }
      }
      return fallback;
    } catch (_) {
      return fallback;
    }
  }

}



final checkoutProvider = StateNotifierProvider<CheckoutNotifier, CheckoutState>(

  (ref) {

    return CheckoutNotifier(ref);

  },

);
