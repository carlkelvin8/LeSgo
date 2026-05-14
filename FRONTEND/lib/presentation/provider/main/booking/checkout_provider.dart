import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/booking/leseat/order.dart';
import '../../../../domain/entities/booking/leseat/order_item.dart';
import '../../../../data/data_source/order_remote_datasource.dart';
import '../../../../data/data_source/dto/order/create_order_request_dto.dart';
import '../../../../data/data_source/dto/order/order_response_dto.dart';
import '../../../../data/data_source/dto/order/estimate_request_dto.dart';
import '../../../../core/di/injection.dart';
import 'restaurant_detail_provider.dart';
import '../profile/profile_provider.dart';

class CheckoutState {
  final Order? order;
  final bool isLoading;
  final String? error;
  final String? selectedPaymentMethod;
  final int? createdOrderId; // Add this to track the created order

  CheckoutState({
    this.order,
    this.isLoading = false,
    this.error,
    this.selectedPaymentMethod,
    this.createdOrderId,
  });

  CheckoutState copyWith({
    Order? order,
    bool? isLoading,
    String? error,
    String? selectedPaymentMethod,
    int? createdOrderId,
  }) {
    return CheckoutState(
      order: order ?? this.order,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedPaymentMethod:
          selectedPaymentMethod ?? this.selectedPaymentMethod,
      createdOrderId: createdOrderId ?? this.createdOrderId,
    );
  }
}

class CheckoutNotifier extends StateNotifier<CheckoutState> {
  final Ref ref;
  final OrderRemoteDataSource _orderDataSource = getIt<OrderRemoteDataSource>();

  CheckoutNotifier(this.ref) : super(CheckoutState());

  /// Initialize order from cart data
  void initializeFromCart(String restaurantName) {
    final restaurantState = ref.read(restaurantDetailProvider);
    final cartItems = restaurantState.cartItems;
    final profileState = ref.read(profileProvider);

    final subtotal = cartItems.fold<double>(0, (sum, item) => sum + item.total);

    // Get user address from profile or use default
    final userAddress = profileState.user?.addressLine1 ?? 'Brgy 6, Claveria, Cagayan';

    final order = Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      restaurantName: restaurantName,
      deliveryAddress: userAddress,
      items: List<OrderItem>.from(cartItems),
      subtotal: subtotal,
      deliveryFee: 0.00, // Will be updated by _fetchDeliveryFee
    );

    state = state.copyWith(order: order);

    // Fetch real delivery fee from estimate API
    _fetchDeliveryFee();
  }

  /// Fetch delivery fee from the fare estimate API
  Future<void> _fetchDeliveryFee() async {
    try {
      final deliveryFee = await _orderDataSource.getFareEstimateRaw(
        serviceId: 3,
        estimatedDistanceM: 5000,
        pickupLat: 8.4542,
        pickupLng: 124.6319,
        dropoffLat: 8.4542,
        dropoffLng: 124.6319,
      );

      if (state.order != null && deliveryFee != null) {
        final updatedOrder = state.order!.copyWith(deliveryFee: deliveryFee);
        state = state.copyWith(order: updatedOrder);
        print('🟢 Checkout: Delivery fee fetched: PHP $deliveryFee');
      }
    } catch (e) {
      print('⚠️ Checkout: Could not fetch delivery fee, using default PHP 50: $e');
      if (state.order != null) {
        final updatedOrder = state.order!.copyWith(deliveryFee: 50.00);
        state = state.copyWith(order: updatedOrder);
      }
    }
  }

  void updateItemQuantity(String itemId, int quantity) {
    if (state.order == null) return;

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

    final updatedItems = state.order!.items
        .where((item) => item.id != itemId)
        .toList();

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

  void applyVoucher(String voucherCode) {
    if (state.order == null) return;

    // Mock voucher logic
    double discount = 0;
    if (voucherCode.toUpperCase() == 'SAVE10') {
      discount = state.order!.subtotal * 0.1;
    }

    final updatedOrder = state.order!.copyWith(discount: discount);
    state = state.copyWith(order: updatedOrder);
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

    final updatedOrder = state.order!.copyWith(
      deliveryAddress: address,
    );

    state = state.copyWith(order: updatedOrder);
  }

  Future<bool> placeOrder() async {
    if (state.order == null) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final order = state.order!;
      final profileState = ref.read(profileProvider);
      final user = profileState.user;

      // Create order request DTO
      final createOrderRequest = CreateOrderRequestDto(
        serviceId: 3, // LesEat service ID
        estimatedDistanceM: 5000, // 5km default, TODO: calculate actual distance
        pickup: OrderAddressDto(
          address: order.restaurantName, // Restaurant address
          lat: 8.4542, // Default Cagayan de Oro coordinates
          lng: 124.6319,
          contactName: order.restaurantName,
          contactPhone: '+639123456789', // Default restaurant phone
        ),
        dropoff: OrderAddressDto(
          address: order.deliveryAddress,
          lat: 8.4542, // TODO: Get actual coordinates from user address
          lng: 124.6319,
          contactName: user?.name ?? 'Customer',
          contactPhone: user?.phone ?? '+639123456789',
        ),
        notes: 'LesEat order: ${order.items.length} items',
        paymentMethod: 'cash', // Use 'cash' instead of 'cod'
        items: order.items.map((item) => OrderItemDto(
          name: item.name,
          quantity: item.quantity,
          estimatedPrice: item.price,
          notes: null, // OrderItem doesn't have specialInstructions
        )).toList(),
        meta: {
          'restaurant_name': order.restaurantName,
          'subtotal': order.subtotal,
          'delivery_fee': order.deliveryFee,
          'total': order.total,
          'grand_total': order.total, // food subtotal + delivery fee
          'order_type': 'leseat',
          'items': order.items.map((item) => {
            'name': item.name,
            'price': item.price,
            'quantity': item.quantity,
            'total': item.total,
          }).toList(),
        },
      );

      print('🔵 Checkout: Creating order with API...');
      final response = await _orderDataSource.createOrder(createOrderRequest);
      
      print('🟢 Checkout: Order created successfully - ID: ${response.data.id}');
      
      state = state.copyWith(
        isLoading: false,
        createdOrderId: response.data.id,
      );
      
      return true;
    } catch (e) {
      print('🔴 Checkout: Error creating order - $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final checkoutProvider = StateNotifierProvider<CheckoutNotifier, CheckoutState>(
  (ref) {
    return CheckoutNotifier(ref);
  },
);
