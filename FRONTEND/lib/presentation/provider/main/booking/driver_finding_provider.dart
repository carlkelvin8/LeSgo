import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/data_source/order_remote_datasource.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/notification_helper.dart';

class DriverFindingState {
  final bool isSearching;
  final bool driverFound;
  final String? driverName;
  final String? driverId;
  final String? error;
  final String? orderId;

  DriverFindingState({
    this.isSearching = false,
    this.driverFound = false,
    this.driverName,
    this.driverId,
    this.error,
    this.orderId,
  });

  DriverFindingState copyWith({
    bool? isSearching,
    bool? driverFound,
    String? driverName,
    String? driverId,
    String? error,
    String? orderId,
  }) {
    return DriverFindingState(
      isSearching: isSearching ?? this.isSearching,
      driverFound: driverFound ?? this.driverFound,
      driverName: driverName ?? this.driverName,
      driverId: driverId ?? this.driverId,
      error: error,
      orderId: orderId ?? this.orderId,
    );
  }
}

class DriverFindingNotifier extends StateNotifier<DriverFindingState> {
  final OrderRemoteDataSource _orderDataSource = getIt<OrderRemoteDataSource>();
  BuildContext? _context;

  DriverFindingNotifier() : super(DriverFindingState());

  void setContext(BuildContext context) {
    _context = context;
  }

  Future<void> startFindingDriver(String orderId, String orderType) async {
    print('🔵 DriverFinding: Starting search for order $orderId ($orderType)');
    
    state = state.copyWith(
      isSearching: true,
      driverFound: false,
      error: null,
      orderId: orderId,
    );

    try {
      // Simulate driver finding process
      await Future.delayed(const Duration(seconds: 3));
      
      // Try to get order details to check if driver is assigned
      try {
        final orderResponse = await _orderDataSource.getOrder(int.parse(orderId));
        final order = orderResponse.data;
        
        if (order.driverId != null) {
          // Driver already assigned
          final driverName = 'Driver #${order.driverId}';
          state = state.copyWith(
            isSearching: false,
            driverFound: true,
            driverName: driverName,
            driverId: order.driverId.toString(),
          );
          print('🟢 DriverFinding: Driver already assigned - $driverName');
          
          // Show driver assigned notification
          if (_context != null && _context!.mounted) {
            NotificationHelper.showDriverAssigned(
              _context!,
              orderId: orderId,
              driverName: driverName,
            );
          }
        } else {
          // Simulate finding a driver (in real app, this would be handled by backend)
          await _simulateDriverAssignment(orderId);
        }
      } catch (e) {
        print('🔴 DriverFinding: Error getting order details - $e');
        // Fallback to simulation
        await _simulateDriverAssignment(orderId);
      }
    } catch (e) {
      print('🔴 DriverFinding: Error - $e');
      state = state.copyWith(
        isSearching: false,
        driverFound: false,
        error: 'Failed to find driver. Please check your connection and try again.',
      );
    }
  }

  Future<void> _simulateDriverAssignment(String orderId) async {
    // Poll the order to check if a driver has been assigned
    int attempts = 0;
    const maxAttempts = 20; // Poll for up to 60 seconds (3 seconds each)
    
    while (attempts < maxAttempts) {
      await Future.delayed(const Duration(seconds: 3));
      attempts++;
      
      try {
        print('🔄 DriverFinding: Polling attempt $attempts/$maxAttempts for order $orderId');
        final orderResponse = await _orderDataSource.getOrder(int.parse(orderId));
        final order = orderResponse.data;
        
        print('📦 DriverFinding: Order status=${order.status}, driverId=${order.driverId}');
        
        // Check if driver has been assigned (status changed to 'accepted' and driver_id is set)
        if (order.driverId != null && order.status == 'accepted') {
          // Driver has been assigned!
          String driverName = 'Driver #${order.driverId}';
          
          // Try to get driver name from driver profile if available
          if (order.driverProfile != null && order.driverProfile!.user != null) {
            driverName = order.driverProfile!.user!.name ?? driverName;
          }
          
          state = state.copyWith(
            isSearching: false,
            driverFound: true,
            driverName: driverName,
            driverId: order.driverId.toString(),
          );
          print('🟢 DriverFinding: Driver assigned - $driverName (status: ${order.status})');
          
          // Show driver assigned notification
          if (_context != null && _context!.mounted) {
            NotificationHelper.showDriverAssigned(
              _context!,
              orderId: orderId,
              driverName: driverName,
            );
          }
          return;
        }
        
        // Check if order was cancelled
        if (order.status == 'cancelled') {
          state = state.copyWith(
            isSearching: false,
            driverFound: false,
            error: 'Order was cancelled.',
          );
          print('🔴 DriverFinding: Order was cancelled');
          return;
        }
      } catch (e) {
        print('🔴 DriverFinding: Polling error - $e');
      }
    }
    
    // No driver found after polling
    state = state.copyWith(
      isSearching: false,
      driverFound: false,
      error: 'No driver available at the moment. Please try again later.',
    );
    print('🔴 DriverFinding: No driver found after ${maxAttempts * 3} seconds');
  }

  Future<void> cancelOrder(String orderId) async {
    print('🔵 DriverFinding: Cancelling order $orderId');
    
    try {
      // Call API to cancel order
      await _orderDataSource.cancelOrder(int.parse(orderId), 'Cancelled by customer');
      
      // Reset state
      state = DriverFindingState();
      print('🟢 DriverFinding: Order cancelled successfully');
    } catch (e) {
      print('🔴 DriverFinding: Cancel error - $e');
      state = state.copyWith(
        error: 'Failed to cancel order. Please try again.',
      );
    }
  }

  void reset() {
    state = DriverFindingState();
  }
}

final driverFindingProvider = StateNotifierProvider<DriverFindingNotifier, DriverFindingState>(
  (ref) => DriverFindingNotifier(),
);