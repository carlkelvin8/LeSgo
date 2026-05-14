import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Order model (minimal, from API)
// ─────────────────────────────────────────────────────────────────────────────

class RiderOrder {
  final int id;
  final int serviceId;
  final String status;
  final String pickupAddress;
  final double pickupLat;
  final double pickupLng;
  final String pickupContactName;
  final String pickupContactPhone;
  final String dropoffAddress;
  final double dropoffLat;
  final double dropoffLng;
  final String dropoffContactName;
  final String dropoffContactPhone;
  final double estimatedFare;
  final double? driverShare; // Driver's actual earnings
  final int estimatedDistanceM;
  final String paymentMethod;
  final String? notes;
  final int? driverId;
  final double? totalAmount;
  final double itemsTotal;
  final List<String> parsedItems;

  RiderOrder({
    required this.id,
    required this.serviceId,
    required this.status,
    required this.pickupAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.pickupContactName,
    required this.pickupContactPhone,
    required this.dropoffAddress,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.dropoffContactName,
    required this.dropoffContactPhone,
    required this.estimatedFare,
    this.driverShare,
    required this.estimatedDistanceM,
    required this.paymentMethod,
    this.notes,
    this.driverId,
    this.totalAmount,
    this.itemsTotal = 0.0,
    this.parsedItems = const [],
  });

  // Get the price to display (always show full fare so customer and rider see same price)
  double get displayEarnings => estimatedFare;
  
  // Get the total amount including items
  double get displayTotalAmount => (totalAmount != null && totalAmount! > 0 ? totalAmount! : estimatedFare) + itemsTotal;

  // Get the actual driver earnings (what driver will receive after commission)
  double get driverEarnings => driverShare ?? (estimatedFare * 0.85); // 85% if not calculated yet

  String get serviceName {
    switch (serviceId) {
      case 1: return 'LesGo';
      case 2: return 'LesRide';
      case 3: return 'LesEat';
      case 4: return 'LesBuy';
      case 5: return 'LesTransport';
      default: return 'Order';
    }
  }

  double get distanceKm => estimatedDistanceM / 1000.0;

  static double _d(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  factory RiderOrder.fromJson(Map<String, dynamic> j) {
    // Helper to extract address string from nested object or string
    String _extractAddress(dynamic addressData, String fallback) {
      if (addressData == null) return fallback;
      if (addressData is String) {
        // Check if it's the problematic "Instance of" string
        if (addressData.startsWith('Instance of ')) {
          return fallback;
        }
        return addressData;
      }
      if (addressData is Map<String, dynamic>) {
        return addressData['address_line1'] as String? ?? 
               addressData['address'] as String? ?? 
               addressData['name'] as String? ??
               fallback;
      }
      // Handle any other object types
      final stringValue = addressData.toString();
      return stringValue.startsWith('Instance of ') ? fallback : stringValue;
    }

    // Helper to extract lat/lng from nested address object
    double _extractLat(Map<String, dynamic> j, String prefix) {
      // First try direct field
      final directLat = j['${prefix}_lat'];
      if (directLat != null) return _d(directLat);
      
      // Then try nested address object
      final addressObj = j['${prefix}_address'];
      if (addressObj is Map<String, dynamic>) {
        return _d(addressObj['latitude']);
      }
      return 0.0;
    }

    double _extractLng(Map<String, dynamic> j, String prefix) {
      // First try direct field
      final directLng = j['${prefix}_lng'];
      if (directLng != null) return _d(directLng);
      
      // Then try nested address object
      final addressObj = j['${prefix}_address'];
      if (addressObj is Map<String, dynamic>) {
        return _d(addressObj['longitude']);
      }
      return 0.0;
    }

    List<String> extractedItems = [];
    double calculatedItemsTotal = 0.0;
    
    if (j['lesbuy_items'] is List && (j['lesbuy_items'] as List).isNotEmpty) {
      for (var item in j['lesbuy_items']) {
        final name = item['name'] ?? 'Item';
        final qtyStr = item['quantity']?.toString() ?? '1';
        final qty = int.tryParse(qtyStr) ?? 1;
        final price = item['actual_price'] ?? item['estimated_price'] ?? item['price'];
        final double priceVal = _d(price);
        calculatedItemsTotal += (priceVal * qty);
        if (priceVal > 0) {
          extractedItems.add('${qty}x $name (PHP ${(priceVal * qty).toStringAsFixed(2)})');
        } else {
          extractedItems.add('${qty}x $name');
        }
      }
    } else if (j['meta'] is Map && j['meta']['items'] is List && (j['meta']['items'] as List).isNotEmpty) {
      for (var item in j['meta']['items']) {
        final name = item['name'] ?? 'Item';
        final qtyStr = item['quantity']?.toString() ?? '1';
        final qty = int.tryParse(qtyStr) ?? 1;
        final price = item['actual_price'] ?? item['estimated_price'] ?? item['price'];
        final double priceVal = _d(price);
        calculatedItemsTotal += (priceVal * qty);
        if (priceVal > 0) {
          extractedItems.add('${qty}x $name (PHP ${(priceVal * qty).toStringAsFixed(2)})');
        } else {
          extractedItems.add('${qty}x $name');
        }
      }
    } else if (j['item_description'] != null && j['item_description'].toString().isNotEmpty) {
      extractedItems.add(j['item_description'].toString());
    } else if (j['notes'] != null && j['notes'].toString().isNotEmpty) {
      extractedItems.add(j['notes'].toString());
    }

    return RiderOrder(
      id: j['id'] as int,
      serviceId: j['service_id'] as int? ?? 1,
      status: j['status'] as String? ?? 'pending',
      pickupAddress: _extractAddress(j['pickup_address'], 'Pickup location'),
      pickupLat: _extractLat(j, 'pickup'),
      pickupLng: _extractLng(j, 'pickup'),
      pickupContactName: j['pickup_contact_name'] as String? ?? '',
      pickupContactPhone: j['pickup_contact_phone'] as String? ?? '',
      dropoffAddress: _extractAddress(j['dropoff_address'], 'Dropoff location'),
      dropoffLat: _extractLat(j, 'dropoff'),
      dropoffLng: _extractLng(j, 'dropoff'),
      dropoffContactName: j['dropoff_contact_name'] as String? ?? '',
      dropoffContactPhone: j['dropoff_contact_phone'] as String? ?? '',
      estimatedFare: _d(j['estimated_fare']),
      driverShare: j['driver_share'] != null ? _d(j['driver_share']) : null,
      estimatedDistanceM: j['estimated_distance_m'] as int? ?? 0,
      paymentMethod: j['payment_method'] as String? ?? 'cash',
      notes: j['notes'] as String?,
      driverId: j['driver_id'] as int?,
      totalAmount: j['total_amount'] != null ? _d(j['total_amount']) : null,
      itemsTotal: calculatedItemsTotal,
      parsedItems: extractedItems,
    );
  }

  RiderOrder copyWith({String? status, int? driverId}) {
    return RiderOrder(
      id: id,
      serviceId: serviceId,
      status: status ?? this.status,
      pickupAddress: pickupAddress,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      pickupContactName: pickupContactName,
      pickupContactPhone: pickupContactPhone,
      dropoffAddress: dropoffAddress,
      dropoffLat: dropoffLat,
      dropoffLng: dropoffLng,
      dropoffContactName: dropoffContactName,
      dropoffContactPhone: dropoffContactPhone,
      estimatedFare: estimatedFare,
      driverShare: driverShare,
      estimatedDistanceM: estimatedDistanceM,
      paymentMethod: paymentMethod,
      notes: notes,
      driverId: driverId ?? this.driverId,
      totalAmount: totalAmount,
      itemsTotal: itemsTotal,
      parsedItems: parsedItems,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

enum RiderOrderAction { none, accepting, updatingStatus }

class RiderOrdersState {
  final List<RiderOrder> availableOrders;
  final RiderOrder? activeOrder;
  final bool isLoading;
  final bool isRefreshing;
  final RiderOrderAction action;
  final int? actionOrderId; // which order is being acted on
  final String? error;
  final String? successMessage;

  RiderOrdersState({
    this.availableOrders = const [],
    this.activeOrder,
    this.isLoading = false,
    this.isRefreshing = false,
    this.action = RiderOrderAction.none,
    this.actionOrderId,
    this.error,
    this.successMessage,
  });

  bool get hasActiveOrder => activeOrder != null;

  RiderOrdersState copyWith({
    List<RiderOrder>? availableOrders,
    RiderOrder? activeOrder,
    bool? isLoading,
    bool? isRefreshing,
    RiderOrderAction? action,
    int? actionOrderId,
    String? error,
    String? successMessage,
    bool clearActiveOrder = false,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return RiderOrdersState(
      availableOrders: availableOrders ?? this.availableOrders,
      activeOrder: clearActiveOrder ? null : (activeOrder ?? this.activeOrder),
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      action: action ?? this.action,
      actionOrderId: actionOrderId ?? this.actionOrderId,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class RiderOrdersNotifier extends StateNotifier<RiderOrdersState> {
  Timer? _autoRefreshTimer;
  
  RiderOrdersNotifier() : super(RiderOrdersState()) {
    // Don't auto-load on construction — wait for explicit loadOrders() call
    // after the user is authenticated (called from RiderMainScreen.initState)
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    // Auto-refresh every 10 seconds to check for new orders
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      loadOrders(silent: true);
    });
  }

  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  void resumeAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _startAutoRefresh();
  }

  /// Reset state and stop timer (called on logout)
  void reset() {
    stopAutoRefresh();
    state = RiderOrdersState();
  }

  Future<void> loadOrders({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, clearError: true);
    } else {
      state = state.copyWith(isRefreshing: true, clearError: true);
    }

    try {
      print('🔄 Fetching orders from API...');
      
      // Fetch all orders visible to this driver
      final allRaw = await ApiService.getOrders(perPage: 50);
      print('📦 Received ${allRaw.length} orders from API');
      
      final all = allRaw
          .map((j) => RiderOrder.fromJson(j as Map<String, dynamic>))
          .toList();

      // Debug: Print all orders
      for (var order in all) {
        print('Order #${order.id}: status=${order.status}, driverId=${order.driverId}');
      }

      // Available = pending/searching_driver with no driver assigned
      // Backend returns these for all drivers to see
      final available = all
          .where((o) => 
            (o.status == 'pending' || o.status == 'searching_driver') && 
            o.driverId == null
          )
          .toList();

      print('✅ Available orders: ${available.length}');

      // Active = accepted or picked_up (assigned to this driver)
      // Backend only returns orders where driver_id matches the logged-in driver
      final active = all
          .where((o) => 
            (o.status == 'accepted' || o.status == 'picked_up') && 
            o.driverId != null
          )
          .toList();

      print('🚗 Active orders: ${active.length}');

      state = state.copyWith(
        availableOrders: available,
        activeOrder: active.isNotEmpty ? active.first : null,
        isLoading: false,
        isRefreshing: false,
        clearActiveOrder: active.isEmpty,
      );

      // Start auto-refresh after first successful load
      if (_autoRefreshTimer == null || !_autoRefreshTimer!.isActive) {
        _startAutoRefresh();
      }
    } catch (e) {
      print('❌ Error loading orders: $e');
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: ApiService.extractError(e),
      );
    }
  }

  Future<bool> acceptOrder(int orderId) async {
    print('🎯 Attempting to accept order #$orderId');
    
    state = state.copyWith(
      action: RiderOrderAction.accepting,
      actionOrderId: orderId,
      clearError: true,
    );
    
    try {
      print('📡 Calling API to update order status to "accepted"...');
      final data = await ApiService.updateOrderStatus(orderId, 'accepted');
      
      // Debug: Check the response structure
      print('✅ Accept order response: $data');
      
      final updated = _parseOrder(data);
      if (updated != null) {
        print('✅ Order #$orderId accepted successfully!');
        print('   Status: ${updated.status}, DriverId: ${updated.driverId}');
        
        // Remove from available orders and set as active
        final newAvailable = state.availableOrders.where((o) => o.id != orderId).toList();
        
        state = state.copyWith(
          availableOrders: newAvailable,
          activeOrder: updated,
          action: RiderOrderAction.none,
          actionOrderId: null,
          successMessage: 'Order #$orderId accepted!',
        );
        
        // Reload orders to ensure we have the latest state
        print('🔄 Reloading orders to sync state...');
        await loadOrders(silent: true);
        
        return true;
      }
      
      print('❌ Failed to parse order from response');
      state = state.copyWith(
        action: RiderOrderAction.none,
        actionOrderId: null,
        error: 'Failed to accept order - invalid response',
      );
      return false;
    } catch (e) {
      print('❌ Error accepting order: $e');
      state = state.copyWith(
        action: RiderOrderAction.none,
        actionOrderId: null,
        error: ApiService.extractError(e),
      );
      return false;
    }
  }

  Future<bool> markPickedUp(int orderId) async {
    return _updateStatus(orderId, 'picked_up', 'Marked as picked up!');
  }

  Future<bool> markDriverArrived(int orderId) async {
    return _updateStatus(orderId, 'driver_arrived_at_pickup', 'Driver has arrived at pickup!');
  }

  Future<bool> markInProgress(int orderId) async {
    return _updateStatus(orderId, 'in_progress', 'Order is now in progress!');
  }

  Future<bool> markCompleted(int orderId) async {
    final ok = await _updateStatus(orderId, 'completed', 'Order delivered!');
    if (ok) {
      state = state.copyWith(clearActiveOrder: true);
      await loadOrders(silent: true);
    }
    return ok;
  }

  Future<bool> _updateStatus(
      int orderId, String status, String msg) async {
    state = state.copyWith(
      action: RiderOrderAction.updatingStatus,
      actionOrderId: orderId,
      clearError: true,
    );
    try {
      final data = await ApiService.updateOrderStatus(orderId, status);
      final updated = _parseOrder(data);
      if (updated != null) {
        state = state.copyWith(
          activeOrder: updated,
          action: RiderOrderAction.none,
          actionOrderId: null,
          successMessage: msg,
        );
        return true;
      }
      state = state.copyWith(
        action: RiderOrderAction.none,
        actionOrderId: null,
        error: 'Failed to update status',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        action: RiderOrderAction.none,
        actionOrderId: null,
        error: ApiService.extractError(e),
      );
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  RiderOrder? _parseOrder(Map<String, dynamic> data) {
    try {
      final orderData = data['data'] ?? data['order'];
      if (orderData is Map<String, dynamic>) {
        return RiderOrder.fromJson(orderData);
      }
    } catch (_) {}
    return null;
  }
}

final riderOrdersProvider =
    StateNotifierProvider<RiderOrdersNotifier, RiderOrdersState>(
        (ref) => RiderOrdersNotifier());
