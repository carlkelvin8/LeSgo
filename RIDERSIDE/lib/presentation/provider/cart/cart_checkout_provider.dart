import 'package:flutter_riverpod/flutter_riverpod.dart';
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

/// Error for the current pin quote; checkout must not use a guessed fee.
final bookFeeEstimateErrorProvider = StateProvider<String?>((ref) => null);

class CartCheckoutNotifier extends StateNotifier<CartCheckoutState> {
  final Ref _ref;

  CartCheckoutNotifier(this._ref) : super(const CartCheckoutState());

  /// Asks the server for the fee, so it follows the rates set in the admin panel.
  Future<double?> estimateFee({
    required double deliveryLat,
    required double deliveryLng,
  }) async {
    _ref.read(bookFeeEstimateErrorProvider.notifier).state = null;
    try {
      final pickup = await _resolvePickupCoordinates();
      final response = await ApiService.dio.post(
        '/v1/orders/estimate',
        data: {
          'service_id': AppConfig.leseatServiceId,
          'pickup': {'lat': pickup[0], 'lng': pickup[1]},
          'dropoff': {'lat': deliveryLat, 'lng': deliveryLng},
          'order_value': _ref.read(cartProvider).subtotal,
        },
      );
      final data = response.data['data'] ?? response.data;
      return double.tryParse('${data['estimated_fare']}');
    } catch (e) {
      _ref.read(bookFeeEstimateErrorProvider.notifier).state =
          ApiService.extractError(e);
      return null;
    }
  }

  /// The order API uses the merchant's primary branch as pickup. Quote against
  /// that same location so the cart never prices a different route from the
  /// one the server will create.
  Future<List<double>> _resolvePickupCoordinates() async {
    final partnerId = _ref.read(riderAuthProvider).user?.partnerId;
    if (partnerId == null) {
      throw Exception('Partner account not found');
    }

    final response = await ApiService.dio.get('/v1/partners/$partnerId');
    final root = response.data;
    final partner = root is Map ? (root['data'] ?? root) : null;
    if (partner is! Map) {
      throw Exception('Merchant pickup location unavailable');
    }

    final branches = partner['branches'];
    if (branches is List && branches.isNotEmpty) {
      final branch = branches.cast<Map>().firstWhere(
        (item) =>
            item['is_primary'] == true ||
            item['is_primary'] == 1 ||
            item['is_primary'] == '1' ||
            item['is_primary'] == 'true',
        orElse: () => branches.first as Map,
      );
      final lat = double.tryParse('${branch['latitude']}');
      final lng = double.tryParse('${branch['longitude']}');
      if (lat != null && lng != null) {
        return [lat, lng];
      }
    }

    // Partner accessors expose the primary branch coordinates as latitude and
    // longitude for older records without a serialized branches list.
    final lat = double.tryParse('${partner['latitude']}');
    final lng = double.tryParse('${partner['longitude']}');
    if (lat != null && lng != null) return [lat, lng];
    throw Exception('Merchant pickup location is missing map coordinates');
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
        errorMessage:
            'Pin the delivery location so the delivery fee can be calculated.',
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

      final pickup = await _resolvePickupCoordinates();
      final pickupLat = pickup[0];
      final pickupLng = pickup[1];

      final items = cart.items
          .map(
            (item) => {
              'name': item.name,
              'quantity': item.quantity,
              'estimated_price': item.unitPrice,
              'notes': item.size,
              if (item.menuItemId != null) 'menu_item_id': item.menuItemId,
              if (item.selectedOptions != null)
                'selected_options': item.selectedOptions,
            },
          )
          .toList();

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
          'lat': deliveryLat,
          'lng': deliveryLng,
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
  final estimate = ref.watch(bookFeeEstimateProvider);

  return CartCheckoutSummary(
    subtotal: cartState.subtotal,
    itemCount: cartState.itemCount,
    deliveryFee: estimate,
  );
});

class CartCheckoutSummary {
  final double subtotal;
  final int itemCount;
  final double? deliveryFee;

  const CartCheckoutSummary({
    required this.subtotal,
    required this.itemCount,
    required this.deliveryFee,
  });

  double? get total => deliveryFee == null ? null : subtotal + deliveryFee!;
}
