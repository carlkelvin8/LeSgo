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

/// Branch the merchant is booking from. Null means the primary branch.
final cartBranchIdProvider = StateProvider<int?>((ref) => null);

/// A pickup branch the merchant can book from.
class CartBranch {
  final int id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final bool isPrimary;
  final bool isOpen;

  const CartBranch({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.isPrimary,
    required this.isOpen,
  });
}

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
          // Priced from the chosen branch, so the per-km rate follows where
          // the order is actually picked up.
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

  /// Branches of this merchant that have a map pin.
  Future<List<CartBranch>> loadBranches() async {
    final partnerId = _ref.read(riderAuthProvider).user?.partnerId;
    if (partnerId == null) return const [];

    final response = await ApiService.dio.get('/v1/partners/$partnerId');
    final root = response.data;
    final partner = root is Map ? (root['data'] ?? root) : null;
    if (partner is! Map) return const [];

    final raw = partner['branches'];
    final result = <CartBranch>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is! Map) continue;
        final lat = double.tryParse('${item['latitude']}');
        final lng = double.tryParse('${item['longitude']}');
        final id = int.tryParse('${item['id']}');
        if (id == null || lat == null || lng == null) continue;
        if (lat == 0 && lng == 0) continue;
        final address = [
          item['address_line1'],
          item['address_line2'],
          item['city'],
        ].where((e) => e != null && '$e'.trim().isNotEmpty).join(', ');
        result.add(CartBranch(
          id: id,
          name: '${item['name'] ?? 'Branch'}',
          address: address,
          lat: lat,
          lng: lng,
          isPrimary: item['is_primary'] == true ||
              item['is_primary'] == 1 ||
              item['is_primary'] == '1',
          isOpen: !(item['is_open'] == false ||
              item['is_open'] == 0 ||
              item['is_open'] == '0'),
        ));
      }
    }
    return result;
  }

  /// Pickup = the branch picked in the cart (primary by default). The server
  /// re-derives the pickup from the branch too, so quote and order agree.
  Future<List<double>> _resolvePickupCoordinates() async {
    final branches = await loadBranches();
    if (branches.isNotEmpty) {
      final selectedId = _ref.read(cartBranchIdProvider);
      final branch = branches.firstWhere(
        (b) => b.id == selectedId,
        orElse: () => branches.firstWhere(
          (b) => b.isPrimary,
          orElse: () => branches.first,
        ),
      );
      return [branch.lat, branch.lng];
    }

    // Older records without a serialized branches list.
    final partnerId = _ref.read(riderAuthProvider).user?.partnerId;
    if (partnerId == null) {
      throw Exception('Partner account not found');
    }
    final response = await ApiService.dio.get('/v1/partners/$partnerId');
    final root = response.data;
    final partner = root is Map ? (root['data'] ?? root) : null;
    final lat = partner is Map ? double.tryParse('${partner['latitude']}') : null;
    final lng = partner is Map ? double.tryParse('${partner['longitude']}') : null;
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
        if (_ref.read(cartBranchIdProvider) != null)
          'partner_branch_id': _ref.read(cartBranchIdProvider),
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
