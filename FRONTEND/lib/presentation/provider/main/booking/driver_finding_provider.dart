import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/data_source/order_remote_datasource.dart';
import '../../../../data/data_source/dto/order/order_dto.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/api_error_mapper.dart';
import '../../../../core/utils/driver_display_utils.dart';

class DriverFindingState {
  final bool isSearching;
  final bool driverFound;
  final String? driverName;
  final String? driverId;
  final String? driverPhotoUrl;
  final String? driverPlateNumber;
  final String? driverPhone;
  final double? driverRating;
  final String? error;
  final String? orderId;

  DriverFindingState({
    this.isSearching = false,
    this.driverFound = false,
    this.driverName,
    this.driverId,
    this.driverPhotoUrl,
    this.driverPlateNumber,
    this.driverPhone,
    this.driverRating,
    this.error,
    this.orderId,
  });

  DriverInfo? get driverInfo {
    if (!driverFound || driverName == null) return null;
    return DriverInfo(
      name: driverName!,
      phone: driverPhone,
      vehicleNumber: driverPlateNumber,
      photoUrl: driverPhotoUrl,
      rating: driverRating,
    );
  }

  DriverFindingState copyWith({
    bool? isSearching,
    bool? driverFound,
    String? driverName,
    String? driverId,
    String? driverPhotoUrl,
    String? driverPlateNumber,
    String? driverPhone,
    double? driverRating,
    String? error,
    String? orderId,
    bool clearError = false,
  }) {
    return DriverFindingState(
      isSearching: isSearching ?? this.isSearching,
      driverFound: driverFound ?? this.driverFound,
      driverName: driverName ?? this.driverName,
      driverId: driverId ?? this.driverId,
      driverPhotoUrl: driverPhotoUrl ?? this.driverPhotoUrl,
      driverPlateNumber: driverPlateNumber ?? this.driverPlateNumber,
      driverPhone: driverPhone ?? this.driverPhone,
      driverRating: driverRating ?? this.driverRating,
      error: clearError ? null : (error ?? this.error),
      orderId: orderId ?? this.orderId,
    );
  }
}

/// Pure status rules for the driver search (unit-testable).
class DriverFindingRules {
  DriverFindingRules._();

  /// Statuses where no driver is working the order yet.
  static const _waiting = {
    '',
    'pending',
    'scheduled',
    'searching_driver',
    'searching',
    'finding_driver',
  };

  static const _dead = {'cancelled', 'canceled', 'failed', 'expired', 'rejected'};

  static bool isCancelled(String? status) =>
      _dead.contains((status ?? '').toLowerCase());

  /// A driver is considered found for any non-waiting, non-dead status
  /// (accepted, assigned, driver_arrived_at_pickup, in_progress, picked_up...)
  /// as long as the order carries a driver.
  static bool isDriverFound(String? status, int? driverId) {
    if (driverId == null) return false;
    final s = (status ?? '').toLowerCase();
    return !_waiting.contains(s) && !_dead.contains(s);
  }
}

class DriverFindingNotifier extends StateNotifier<DriverFindingState> {
  final OrderRemoteDataSource _orderDataSource;
  final Duration _pollInterval;

  /// Bumped on every start/cancel/reset; a poll loop only keeps writing state
  /// while its own token is still current.
  int _pollToken = 0;

  DriverFindingNotifier({
    OrderRemoteDataSource? orderDataSource,
    Duration pollInterval = const Duration(seconds: 3),
  })  : _orderDataSource = orderDataSource ?? getIt<OrderRemoteDataSource>(),
        _pollInterval = pollInterval,
        super(DriverFindingState());

  bool _isCurrent(int token) => mounted && token == _pollToken;

  @override
  void dispose() {
    _pollToken++;
    super.dispose();
  }

  Future<void> startFindingDriver(String orderId, String orderType) async {
    final token = ++_pollToken;
    // Fresh state: nothing from a previous order may leak through.
    state = DriverFindingState(isSearching: true, orderId: orderId);

    try {
      final parsedId = int.parse(orderId);
      final orderResponse = await _orderDataSource.getOrder(parsedId);
      if (!_isCurrent(token)) return;
      final order = orderResponse.data;

      if (DriverFindingRules.isCancelled(order.status)) {
        _markCancelled();
        return;
      }

      if (DriverFindingRules.isDriverFound(order.status, order.driverId)) {
        _markDriverFound(orderId, order.driverId!, order);
        return;
      }

      await _pollForDriverAssignment(orderId, token);
    } catch (e) {
      if (!_isCurrent(token)) return;
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

  void _markCancelled() {
    state = DriverFindingState(
      orderId: state.orderId,
      error: 'Order was cancelled.',
    );
  }

  void _markDriverFound(
    String orderId,
    int driverId,
    OrderDto order,
  ) {
    final driver = DriverInfo.fromOrder(order) ??
        DriverInfo(name: 'Driver #$driverId');

    // Build a new state rather than copyWith so no field of a previous
    // order's driver survives when this one has none.
    state = DriverFindingState(
      isSearching: false,
      driverFound: true,
      driverName: driver.name,
      driverId: driverId.toString(),
      driverPhotoUrl: driver.photoUrl,
      driverPlateNumber: driver.vehicleNumber,
      driverPhone: driver.phone,
      driverRating: driver.rating,
      orderId: orderId,
    );
  }

  Future<void> _pollForDriverAssignment(String orderId, int token) async {
    const maxAttempts = 20;
    var attempts = 0;
    var pollErrors = 0;

    while (attempts < maxAttempts) {
      await Future.delayed(_pollInterval);
      if (!_isCurrent(token)) return;
      attempts++;

      try {
        final orderResponse =
            await _orderDataSource.getOrder(int.parse(orderId));
        if (!_isCurrent(token)) return;
        final order = orderResponse.data;

        if (DriverFindingRules.isCancelled(order.status)) {
          _markCancelled();
          return;
        }

        if (DriverFindingRules.isDriverFound(order.status, order.driverId)) {
          _markDriverFound(orderId, order.driverId!, order);
          return;
        }

        pollErrors = 0;
      } catch (e) {
        if (!_isCurrent(token)) return;
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

    if (!_isCurrent(token)) return;
    state = state.copyWith(
      isSearching: false,
      driverFound: false,
      error: 'No driver available at the moment. Please try again later.',
    );
  }

  Future<bool> cancelOrder(
    String orderId, {
    String reason = 'Cancelled by customer',
  }) async {
    // Stop any running poll loop first so it cannot rewrite state.
    _pollToken++;
    try {
      await _orderDataSource.cancelOrder(int.parse(orderId), reason);
      if (!mounted) return true;
      state = DriverFindingState();
      return true;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isSearching: false,
          error: ApiErrorMapper.message(
            e,
            fallbackEn: 'Failed to cancel order. Please try again.',
            fallbackTl: 'Hindi makansela ang order.',
          ),
        );
      }
      return false;
    }
  }

  void reset() {
    _pollToken++;
    state = DriverFindingState();
  }
}

final driverFindingProvider =
    StateNotifierProvider<DriverFindingNotifier, DriverFindingState>(
  (ref) => DriverFindingNotifier(),
);
