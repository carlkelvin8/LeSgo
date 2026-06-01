import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/data_source/order_remote_datasource.dart';
import '../../../../data/data_source/dto/order/order_dto.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/api_error_mapper.dart';
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
    bool clearError = false,
  }) {
    return DriverFindingState(
      isSearching: isSearching ?? this.isSearching,
      driverFound: driverFound ?? this.driverFound,
      driverName: driverName ?? this.driverName,
      driverId: driverId ?? this.driverId,
      error: clearError ? null : (error ?? this.error),
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
    state = state.copyWith(
      isSearching: true,
      driverFound: false,
      clearError: true,
      orderId: orderId,
    );

    try {
      final parsedId = int.parse(orderId);
      final orderResponse = await _orderDataSource.getOrder(parsedId);
      final order = orderResponse.data;

      if (order.driverId != null) {
        _markDriverFound(orderId, order.driverId!, order);
        return;
      }

      await _pollForDriverAssignment(orderId);
    } catch (e) {
      state = state.copyWith(
        isSearching: false,
        driverFound: false,
        error: ApiErrorMapper.message(
          e,
          fallbackEn: 'Could not load your order. Check your connection and try again.',
          fallbackTl: 'Hindi ma-load ang order. Subukan muli.',
        ),
      );
    }
  }

  Future<void> retry(String orderId, String orderType) {
    return startFindingDriver(orderId, orderType);
  }

  void _markDriverFound(
    String orderId,
    int driverId,
    OrderDto order,
  ) {
    final driverName = order.driverProfile?.user?.name?.isNotEmpty == true
        ? order.driverProfile!.user!.name
        : 'Driver #$driverId';

    state = state.copyWith(
      isSearching: false,
      driverFound: true,
      driverName: driverName,
      driverId: driverId.toString(),
    );

    if (_context != null && _context!.mounted) {
      NotificationHelper.showDriverAssigned(
        _context!,
        orderId: orderId,
        driverName: driverName,
      );
    }
  }

  Future<void> _pollForDriverAssignment(String orderId) async {
    const maxAttempts = 20;
    var attempts = 0;
    var pollErrors = 0;

    while (attempts < maxAttempts) {
      await Future.delayed(const Duration(seconds: 3));
      attempts++;

      try {
        final orderResponse =
            await _orderDataSource.getOrder(int.parse(orderId));
        final order = orderResponse.data;

        if (order.driverId != null &&
            (order.status == 'accepted' || order.status == 'assigned')) {
          _markDriverFound(orderId, order.driverId!, order);
          return;
        }

        if (order.status == 'cancelled') {
          state = state.copyWith(
            isSearching: false,
            driverFound: false,
            error: 'Order was cancelled.',
          );
          return;
        }

        pollErrors = 0;
      } catch (e) {
        pollErrors++;
        if (pollErrors >= 3) {
          state = state.copyWith(
            isSearching: false,
            driverFound: false,
            error: ApiErrorMapper.message(
              e,
              fallbackEn: 'Lost connection while finding a driver. Please retry.',
              fallbackTl: 'Nawala ang koneksyon habang naghahanap ng driver.',
            ),
          );
          return;
        }
      }
    }

    state = state.copyWith(
      isSearching: false,
      driverFound: false,
      error: 'No driver available at the moment. Please try again later.',
    );
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      await _orderDataSource.cancelOrder(
        int.parse(orderId),
        'Cancelled by customer',
      );
      state = DriverFindingState();
    } catch (e) {
      state = state.copyWith(
        error: ApiErrorMapper.message(
          e,
          fallbackEn: 'Failed to cancel order. Please try again.',
          fallbackTl: 'Hindi makansela ang order.',
        ),
      );
    }
  }

  void reset() {
    state = DriverFindingState();
  }
}

final driverFindingProvider =
    StateNotifierProvider<DriverFindingNotifier, DriverFindingState>(
  (ref) => DriverFindingNotifier(),
);
