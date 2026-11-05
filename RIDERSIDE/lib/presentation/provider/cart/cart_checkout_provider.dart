import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/constants/app_config.dart';
import '../../../../core/services/api_service.dart';
import '../auth/rider_auth_provider.dart';
import '../main/merchantside/merchant_profile_provider.dart';
import 'cart_provider.dart';

class CartCheckoutState {
  final bool isSubmitting;
  final String? errorMessage;
  final int? orderId;

  const CartCheckoutState({
    this.isSubmitting = false,
    this.errorMessage,
    this.orderId,
  });

  CartCheckoutState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    int? orderId,
    bool clearError = false,
  }) {
    return CartCheckoutState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      orderId: orderId ?? this.orderId,
    );
  }
}

/// Delivery fee quoted by the server for the pinned location; null until pinned.
final bookFeeEstimateProvider = StateProvider<double?>((ref) => null);

class CartCheckoutNotifier extends StateNotifier<CartCheckoutState> {
  final Ref _ref;

  CartCheckoutNotifier(this._ref) : super(const CartCheckoutState());

  /// Asks the server for the fee, so it follows the rates set in the admin panel.
  Future<double?> estimateFee({
    required double deliveryLat,
    required double deliveryLng,
  }) async {
    try {
      double pickupLat = 8.4542;
      double pickupLng = 124.6319;
      if (await Permission.locationWhenInUse.isGranted) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        );
        pickupLat = position.latitude;
        pickupLng = position.longitude;
      }
      final response = await ApiService.dio.post('/v1/orders/estimate', data: {
        'service_id': AppConfig.leseatServiceId,
        'pickup': {'lat': pickupLat, 'lng': pickupLng},
        'dropoff': {'lat': deliveryLat, 'lng': deliveryLng},
        'order_value': _ref.read(cartProvider).subtotal,
      });
      final data = response.data['data'] ?? response.data;
      return double.tryParse('${data['estimated_fare']}');
    } catch (_) {
      return null;
    }
  }

  Future<bool> checkout({
    required String deliveryAddress,
    required String paymentMethod,
    double? deliveryLat,
    double? deliveryLng,
  }) async {
    final cart = _ref.read(cartProvider);
    if (cart.items.isEmpty) {
      state = state.copyWith(errorMessage: 'Cart is empty');
      return false;
    }

    if (deliveryLat == null || deliveryLng == null) {
      state = state.copyWith(
        errorMessage: 'Pin the delivery location so the delivery fee can be calculated.',
      );
      return false;
    }

    final auth = _ref.read(riderAuthProvider);
    final partnerId = auth.user?.partnerId;
    if (partnerId == null) {
      state = state.copyWith(errorMessage: 'Partner account not found');
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final partner = await _ref.read(merchantProfileProvider.future);
      final pickupAddress = partner?.name ?? 'Store pickup';

      double pickupLat = 8.4542;
      double pickupLng = 124.6319;
      final locationStatus = await Permission.locationWhenInUse.request();
      if (locationStatus.isGranted) {
        try {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
          );
          pickupLat = position.latitude;
          pickupLng = position.longitude;
        } catch (_) {}
      }

      final items = cart.items
          .map(
            (item) => {
              'name': item.name,
              'quantity': item.quantity,
              'estimated_price': item.unitPrice,
              'notes': item.size,
              if (item.menuItemId != null) 'menu_item_id': item.menuItemId,
              if (item.selectedOptions != null) 'selected_options': item.selectedOptions,
            },
          )
          .toList();

      // Use pinned delivery coordinates if available, otherwise fallback to merchant location
      final dropLat = deliveryLat ?? pickupLat;
      final dropLng = deliveryLng ?? pickupLng;

      final response = await ApiService.createOrder({
        'service_id': AppConfig.leseatServiceId,
        'partner_id': partnerId,
        'payment_method': paymentMethod,
        'notes': 'Merchant self-order from app cart',
        'pickup': {
          'address': pickupAddress,
          'lat': pickupLat,
          'lng': pickupLng,
          'contact_name': auth.user?.name,
          'contact_phone': auth.user?.phone,
        },
        'dropoff': {
          'address': deliveryAddress,
          'lat': dropLat,
          'lng': dropLng,
          'contact_name': auth.user?.name,
          'contact_phone': auth.user?.phone,
        },
        'items': items,
      });

      final orderData = response['data'];
      final orderId = orderData is Map ? orderData['id'] as int? : null;

      _ref.read(cartProvider.notifier).clearCart();
      _ref.read(bookFeeEstimateProvider.notifier).state = null;
      state = state.copyWith(isSubmitting: false, orderId: orderId);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: ApiService.extractError(e),
      );
      return false;
    }
  }
}

final cartCheckoutStateProvider =
    StateNotifierProvider<CartCheckoutNotifier, CartCheckoutState>((ref) {
  return CartCheckoutNotifier(ref);
});

final cartCheckoutProvider = Provider<CartCheckoutSummary>((ref) {
  final cartState = ref.watch(cartProvider);
  final partnerAsync = ref.watch(merchantProfileProvider);

  final estimate = ref.watch(bookFeeEstimateProvider);
  final double deliveryFee = estimate ??
      partnerAsync.maybeWhen<double>(
        data: (partner) => partner?.deliveryFee ?? 50.0,
        orElse: () => 50.0,
      );

  return CartCheckoutSummary(
    subtotal: cartState.subtotal,
    itemCount: cartState.itemCount,
    deliveryFee: deliveryFee,
  );
});

class CartCheckoutSummary {
  final double subtotal;
  final int itemCount;
  final double deliveryFee;

  const CartCheckoutSummary({
    required this.subtotal,
    required this.itemCount,
    required this.deliveryFee,
  });

  double get total => subtotal + deliveryFee;
}
