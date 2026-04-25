import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/data_source/tracking_remote_datasource.dart';
import '../../../data/data_source/dto/tracking/tracking_dto.dart';
import '../../../core/di/injection.dart';

class TrackingState {
  final TrackingDto? tracking;
  final EtaDto? eta;
  final RouteDto? route;
  final bool isLoading;
  final String? error;

  TrackingState({
    this.tracking,
    this.eta,
    this.route,
    this.isLoading = false,
    this.error,
  });

  TrackingState copyWith({
    TrackingDto? tracking,
    EtaDto? eta,
    RouteDto? route,
    bool? isLoading,
    String? error,
  }) {
    return TrackingState(
      tracking: tracking ?? this.tracking,
      eta: eta ?? this.eta,
      route: route ?? this.route,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class TrackingNotifier extends StateNotifier<TrackingState> {
  TrackingNotifier() : super(TrackingState());

  /// Track an order
  Future<void> trackOrder(int orderId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final trackingDataSource = getIt<TrackingRemoteDataSource>();
      final response = await trackingDataSource.trackOrder(orderId);

      if (response.success) {
        state = state.copyWith(
          tracking: response.data,
          isLoading: false,
        );

        // Also load ETA
        await loadEta(orderId);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to track order',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load ETA
  Future<void> loadEta(int orderId) async {
    try {
      final trackingDataSource = getIt<TrackingRemoteDataSource>();
      final response = await trackingDataSource.getEta(orderId);

      if (response.success) {
        state = state.copyWith(eta: response.data);
      }
    } catch (e) {
      // Silently fail for ETA
    }
  }

  /// Load route
  Future<void> loadRoute({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    try {
      final trackingDataSource = getIt<TrackingRemoteDataSource>();
      final response = await trackingDataSource.getRoute(
        fromLat: fromLat,
        fromLng: fromLng,
        toLat: toLat,
        toLng: toLng,
      );

      if (response.success) {
        state = state.copyWith(route: response.data);
      }
    } catch (e) {
      // Silently fail for route
    }
  }

  /// Refresh tracking data
  Future<void> refresh(int orderId) async {
    await trackOrder(orderId);
  }
}

final trackingProvider =
    StateNotifierProvider<TrackingNotifier, TrackingState>((ref) {
  return TrackingNotifier();
});
