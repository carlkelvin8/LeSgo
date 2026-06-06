import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/booking_workflow.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/utils/rider_commission_utils.dart';
import '../../../../core/utils/menu_item_options.dart';
import 'rider_duty_provider.dart';
import 'rider_history_provider.dart';
import 'rider_wallet_provider.dart';
import '../../auth/rider_auth_provider.dart';

int? _extractDriverId(Map<String, dynamic> json) {
  final direct = json['driver_id'];
  if (direct is num) return direct.toInt();
  if (direct is String) return int.tryParse(direct);

  final driverProfile = json['driver_profile'];
  if (driverProfile is Map) {
    final id = driverProfile['id'];
    if (id is num) return id.toInt();
    if (id is String) return int.tryParse(id);
  }
  return null;
}

bool _isActiveForDriver(RiderOrder order, int? driverProfileId) {
  if (!BookingWorkflow.isActiveApiStatus(order.status)) return false;
  if (order.driverId == null) return false;
  if (driverProfileId == null) return true;
  return order.driverId == driverProfileId;
}

// ─────────────────────────────────────────────────────────────────────────────
// Order model (minimal, from API)
// ─────────────────────────────────────────────────────────────────────────────

String? _formatItemOptions(dynamic item) {
  if (item is! Map) return null;

  final display = item['options_display']?.toString();
  if (display != null && display.trim().isNotEmpty) return display.trim();

  final notes = item['notes']?.toString();
  if (notes != null && notes.trim().isNotEmpty) return notes.trim();

  final selectedRaw = item['selected_options'];
  if (selectedRaw is Map) {
    final selected = SelectedMenuOptions.fromApiMap(
      Map<String, dynamic>.from(selectedRaw),
    );
    if (!selected.isEmpty) return selected.formatDisplay();
  }

  final legacyOptions = item['options']?.toString();
  if (legacyOptions != null && legacyOptions.trim().isNotEmpty) {
    return legacyOptions.trim();
  }
  return null;
}

double _itemLineTotal(dynamic item, int qty) {
  if (item is! Map) return 0;
  final explicitTotal = item['total'];
  if (explicitTotal != null) {
    final totalVal = RiderOrder._d(explicitTotal);
    if (totalVal > 0) return totalVal;
  }
  final actual = item['actual_price'];
  if (actual != null) {
    final actualVal = RiderOrder._d(actual);
    if (actualVal > 0) return actualVal;
  }
  final unit = RiderOrder._d(item['estimated_price'] ?? item['price']);
  return unit * qty;
}

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
  final double discount;
  final double shippingFee;
  final double? commissionRate;
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
    this.discount = 0.0,
    this.shippingFee = 0.0,
    this.commissionRate,
    this.parsedItems = const [],
  });

  // Delivery / shipping fee shown to rider (wallet deduction basis).
  double get displayShippingFee =>
      shippingFee > 0 ? shippingFee : estimatedFare;

  /// Wallet hold on accept — shipping fee only, not item subtotal.
  double get walletDeductionAmount => displayShippingFee;

  /// Full customer order total (items + shipping - discount).
  double get displayTotalAmount {
    if (totalAmount != null && totalAmount! > 0) return totalAmount!;
    if (itemsTotal > 0) {
      return itemsTotal + displayShippingFee - discount;
    }
    return displayShippingFee > 0 ? displayShippingFee : estimatedFare;
  }

  static double _d(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

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

  double estimatedEarningsFor(String? packageTier) {
    return RiderCommissionUtils.earningsFromShipping(
      shippingFee: displayShippingFee,
      driverShare: driverShare,
      packageTier: packageTier,
    );
  }

  factory RiderOrder.fromJson(Map<String, dynamic> j) {
    // Helper to extract address string from nested object or string
    String extractAddress(dynamic addressData, String fallback) {
      if (addressData == null) return fallback;
      if (addressData is String) {
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
      final stringValue = addressData.toString();
      return stringValue.startsWith('Instance of ') ? fallback : stringValue;
    }

    double extractLat(Map<String, dynamic> json, String prefix) {
      final directLat = json['${prefix}_lat'];
      if (directLat != null) return _d(directLat);

      final addressObj = json['${prefix}_address'];
      if (addressObj is Map<String, dynamic>) {
        return _d(addressObj['latitude']);
      }
      return 0.0;
    }

    double extractLng(Map<String, dynamic> json, String prefix) {
      final directLng = json['${prefix}_lng'];
      if (directLng != null) return _d(directLng);

      final addressObj = json['${prefix}_address'];
      if (addressObj is Map<String, dynamic>) {
        return _d(addressObj['longitude']);
      }
      return 0.0;
    }

    List<String> extractedItems = [];
    double calculatedItemsTotal = 0.0;

    void addItemLine(dynamic item) {
      if (item is! Map) return;
      final name = item['name'] ?? 'Item';
      final qtyStr = item['quantity']?.toString() ?? '1';
      final qty = int.tryParse(qtyStr) ?? 1;
      final lineTotal = _itemLineTotal(item, qty);
      calculatedItemsTotal += lineTotal;
      final optionsText = _formatItemOptions(item);
      var line = '${qty}x $name';
      if (lineTotal > 0) {
        line += ' (PHP ${lineTotal.toStringAsFixed(2)})';
      }
      if (optionsText != null && optionsText.isNotEmpty) {
        line += '\n   $optionsText';
      }
      extractedItems.add(line);
    }

    if (j['lesbuy_items'] is List && (j['lesbuy_items'] as List).isNotEmpty) {
      for (final item in j['lesbuy_items']) {
        addItemLine(item);
      }
    } else if (j['meta'] is Map &&
        j['meta']['items'] is List &&
        (j['meta']['items'] as List).isNotEmpty) {
      for (final item in j['meta']['items']) {
        addItemLine(item);
      }
    } else if (j['item_description'] != null &&
        j['item_description'].toString().isNotEmpty) {
      extractedItems.add(j['item_description'].toString());
    } else if (j['notes'] != null && j['notes'].toString().isNotEmpty) {
      extractedItems.add(j['notes'].toString());
    }

    double extractedDiscount = 0.0;
    if (j['discount_amount'] != null) {
      extractedDiscount = _d(j['discount_amount']);
    } else if (j['meta'] is Map && j['meta']['discount'] != null) {
      extractedDiscount = _d(j['meta']['discount']);
    }

    double? extractedTotal;
    double extractedShipping = _d(j['estimated_fare']);
    double? extractedCommissionRate;
    if (j['meta'] is Map) {
      final meta = j['meta'] as Map<String, dynamic>;
      if (calculatedItemsTotal <= 0 && meta['subtotal'] != null) {
        calculatedItemsTotal = _d(meta['subtotal']);
      }
      if (meta['grand_total'] != null) {
        extractedTotal = _d(meta['grand_total']);
      } else if (meta['total'] != null) {
        extractedTotal = _d(meta['total']);
      }
      if (meta['shipping_fee'] != null) {
        extractedShipping = _d(meta['shipping_fee']);
      } else if (meta['delivery_fee'] != null) {
        extractedShipping = _d(meta['delivery_fee']);
      }
      if (meta['driver_commission_rate'] != null) {
        extractedCommissionRate = _d(meta['driver_commission_rate']);
      }
    }

    final user = j['user'] is Map<String, dynamic>
        ? j['user'] as Map<String, dynamic>
        : (j['customer'] is Map<String, dynamic>
            ? j['customer'] as Map<String, dynamic>
            : null);

    var dropoffName = j['dropoff_contact_name']?.toString().trim() ?? '';
    var dropoffPhone = j['dropoff_contact_phone']?.toString().trim() ?? '';
    if (user != null) {
      if (dropoffName.isEmpty) {
        dropoffName = user['name']?.toString().trim() ?? '';
      }
      if (dropoffPhone.isEmpty) {
        dropoffPhone = user['phone_number']?.toString().trim() ??
            user['phone']?.toString().trim() ??
            '';
      }
    }

    return RiderOrder(
      id: j['id'] as int,
      serviceId: j['service_id'] as int? ?? 1,
      status: j['status'] as String? ?? 'pending',
      pickupAddress: extractAddress(j['pickup_address'], 'Pickup location'),
      pickupLat: extractLat(j, 'pickup'),
      pickupLng: extractLng(j, 'pickup'),
      pickupContactName: j['pickup_contact_name'] as String? ?? '',
      pickupContactPhone: j['pickup_contact_phone'] as String? ?? '',
      dropoffAddress: extractAddress(j['dropoff_address'], 'Dropoff location'),
      dropoffLat: extractLat(j, 'dropoff'),
      dropoffLng: extractLng(j, 'dropoff'),
      dropoffContactName: dropoffName,
      dropoffContactPhone: dropoffPhone,
      estimatedFare: _d(j['estimated_fare']),
      driverShare: j['driver_share'] != null ? _d(j['driver_share']) : null,
      estimatedDistanceM: j['estimated_distance_m'] as int? ?? 0,
      paymentMethod: j['payment_method'] as String? ?? 'cash',
      notes: j['notes'] as String?,
      driverId: _extractDriverId(j),
      totalAmount: extractedTotal ??
          (j['total_amount'] != null ? _d(j['total_amount']) : null),
      itemsTotal: calculatedItemsTotal,
      discount: extractedDiscount,
      shippingFee: extractedShipping,
      commissionRate: extractedCommissionRate,
      parsedItems: extractedItems,
    );
  }

  double earningsFor({String? packageTier, double? riderCommissionRate}) {
    if (driverShare != null && driverShare! > 0) return driverShare!;
    final rate = commissionRate ??
        riderCommissionRate ??
        RiderCommissionUtils.rateForPackage(packageTier);
    return displayShippingFee * rate;
  }

  double get displayEarnings => displayShippingFee;

  double driverEarningsFor(String? packageTier, {double? riderCommissionRate}) =>
      earningsFor(
        packageTier: packageTier,
        riderCommissionRate: riderCommissionRate,
      );

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
      discount: discount,
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
  final List<RiderOrder> activeOrders;
  final RiderOrder? activeOrder;
  final bool isLoading;
  final bool isRefreshing;
  final RiderOrderAction action;
  final int? actionOrderId; // which order is being acted on
  final String? error;
  final String? successMessage;

  RiderOrdersState({
    this.availableOrders = const [],
    this.activeOrders = const [],
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
    List<RiderOrder>? activeOrders,
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
      activeOrders: clearActiveOrder
          ? const []
          : (activeOrders ?? this.activeOrders),
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
  final Ref _ref;
  Timer? _autoRefreshTimer;
  Set<int> _knownAvailableOrderIds = {};
  String? _lastActiveStatus;

  RiderOrdersNotifier(this._ref) : super(RiderOrdersState());

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_ref.read(riderDutyProvider)) {
        loadOrders(silent: true);
      }
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
    _knownAvailableOrderIds = {};
    _lastActiveStatus = null;
    state = RiderOrdersState();
  }

  Future<void> loadOrders({bool silent = false}) async {
    if (!_ref.read(riderDutyProvider) && silent) {
      return;
    }
    if (!silent) {
      state = state.copyWith(isLoading: true, clearError: true);
    } else {
      state = state.copyWith(isRefreshing: true, clearError: true);
    }

    try {
      print('🔄 Fetching orders from API...');
      
      // Fetch all orders visible to this driver
      final allRaw = await ApiService.getOrders(perPage: 100);
      print('📦 Received ${allRaw.length} orders from API');
      
      final all = allRaw
          .map((j) => RiderOrder.fromJson(j as Map<String, dynamic>))
          .toList();

      // Debug: Print all orders
      for (var order in all) {
        print('Order #${order.id}: status=${order.status}, driverId=${order.driverId}');
      }

      // Available = unassigned orders drivers can still accept
      final available = all
          .where((o) =>
              (o.status == 'pending' ||
                  o.status == 'searching_driver' ||
                  o.status == 'ready_for_pickup') &&
              o.driverId == null)
          .toList();

      print('✅ Available orders: ${available.length}');

      // Active = in-progress orders assigned to this driver
      final driverProfileId =
          _ref.read(riderAuthProvider).user?.driverProfileId;
      final active = all.where((o) => _isActiveForDriver(o, driverProfileId)).toList();

      // Keep current active order if API temporarily omits it after accept.
      final currentActive = state.activeOrder;
      if (currentActive != null &&
          _isActiveForDriver(currentActive, driverProfileId) &&
          !active.any((o) => o.id == currentActive.id)) {
        active.insert(0, currentActive);
      }

      active.sort((a, b) => b.id.compareTo(a.id));

      print('🚗 Active orders: ${active.length}');
      if (active.isNotEmpty) {
        print('   Primary active: #${active.first.id} (${active.first.status})');
      }

      _notifyOrderChanges(available, active.isNotEmpty ? active.first : null);

      state = state.copyWith(
        availableOrders: available,
        activeOrders: active,
        activeOrder: active.isNotEmpty ? active.first : null,
        isLoading: false,
        isRefreshing: false,
        clearActiveOrder: active.isEmpty,
      );

      // Start auto-refresh after first successful load when on duty
      if (_ref.read(riderDutyProvider) &&
          (_autoRefreshTimer == null || !_autoRefreshTimer!.isActive)) {
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

    await _ref.read(riderWalletProvider.notifier).loadWallet();
    final wallet = _ref.read(riderWalletProvider);
    if (!wallet.canAcceptBooking) {
      final message = wallet.acceptBlockedMessage;
      print('🚫 Accept blocked — wallet balance: ${wallet.balance}');
      state = state.copyWith(
        action: RiderOrderAction.none,
        actionOrderId: null,
        error: message,
      );
      return false;
    }
    
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
        await _ref.read(riderWalletProvider.notifier).loadWallet();
        await _ref.read(riderHistoryProvider.notifier).loadHistory(silent: true);

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
        await loadOrders(silent: true);
        await _ref.read(riderHistoryProvider.notifier).loadHistory(silent: true);
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

  void _notifyOrderChanges(List<RiderOrder> available, RiderOrder? active) {
    final currentIds = available.map((o) => o.id).toSet();
    final newOrders = currentIds.difference(_knownAvailableOrderIds);
    if (_knownAvailableOrderIds.isNotEmpty && newOrders.isNotEmpty) {
      for (final id in newOrders) {
        final order = available.firstWhere((o) => o.id == id);
        PushNotificationService.show(
          title: 'New order available',
          body: '${order.serviceName} • ${order.pickupAddress}',
          payload: 'order_$id',
        );
      }
    }
    _knownAvailableOrderIds = currentIds;

    if (active != null) {
      if (_lastActiveStatus != null && _lastActiveStatus != active.status) {
        PushNotificationService.show(
          title: 'Order #${active.id} updated',
          body: 'Status changed to ${active.status.replaceAll('_', ' ')}',
          payload: 'order_${active.id}',
        );
      }
      _lastActiveStatus = active.status;
    } else {
      _lastActiveStatus = null;
    }
  }

  RiderOrder? _enrichAcceptedOrder(RiderOrder? order) {
    if (order == null) return null;
    if (order.driverId != null) return order;
    if (!BookingWorkflow.isActiveApiStatus(order.status)) return order;

    final profileId = _ref.read(riderAuthProvider).user?.driverProfileId;
    if (profileId == null) return order;
    return order.copyWith(driverId: profileId);
  }

  RiderOrder? _parseOrder(Map<String, dynamic> data) {
    try {
      final orderData = data['data'] ?? data['order'];
      if (orderData is Map<String, dynamic>) {
        final parsed = RiderOrder.fromJson(orderData);
        return _enrichAcceptedOrder(parsed);
      }
    } catch (_) {}
    return null;
  }
}

final riderOrdersProvider =
    StateNotifierProvider<RiderOrdersNotifier, RiderOrdersState>(
        (ref) => RiderOrdersNotifier(ref));
