import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/constants/app_config.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/location_permission_utils.dart';
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

class CartCheckoutNotifier extends StateNotifier<CartCheckoutState> {
  final Ref _ref;

  CartCheckoutNotifier(this._ref) : super(const CartCheckoutState());

  Future<bool> checkout({
    required String deliveryAddress,
    required String paymentMethod,
  }) async {
    final cart = _ref.read(cartProvider);
    if (cart.items.isEmpty) {
      state = state.copyWith(errorMessage: 'Cart is empty');
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
            },
          )
          .toList();

      final response = await ApiService.createOrder({
        'service_id': AppConfig.leseatServiceId,
        'partner_id': partnerId,
        'estimated_distance_m': AppConfig.defaultEstimatedDistanceM,
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
          'lat': pickupLat,
          'lng': pickupLng,
          'contact_name': auth.user?.name,
          'contact_phone': auth.user?.phone,
        },
        'items': items,
      });

      final orderData = response['data'];
      final orderId = orderData is Map ? orderData['id'] as int? : null;

      _ref.read(cartProvider.notifier).clearCart();
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

  final deliveryFee = partnerAsync.maybeWhen(
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
