import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/data_source/tracking_remote_datasource.dart';
import '../../../data/data_source/dto/tracking/tracking_dto.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/booking_geo_utils.dart';

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
      final response = await trackingDataSource.getOrderTracking(orderId);

      if (response.success) {
        state = state.copyWith(tracking: response.data, isLoading: false);

        // Also load ETA
        await loadEta(orderId);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to track order',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load ETA
  Future<void> loadEta(int orderId) async {
    try {
      final trackingDataSource = getIt<TrackingRemoteDataSource>();
      final response = await trackingDataSource.getEta(orderId);

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        state = state.copyWith(
          eta: EtaDto(
            estimatedArrival:
                data['estimated_arrival']?.toString() ??
                data['estimatedArrival']?.toString() ??
                '15 minutes',
            minutesRemaining:
                (data['minutes_remaining'] ??
                        data['estimatedArrivalMinutes'] ??
                        15)
                    as int,
            distanceRemainingM:
                (data['distance_remaining_m'] ??
                        ((data['distanceKm'] as num?) ?? 2.5) * 1000)
                    .round(),
            currentLatitude:
                ((data['current_latitude'] ?? data['currentLatitude'] ?? BookingGeoUtils.defaultLat)
                        as num)
                    .toDouble(),
            currentLongitude:
                ((data['current_longitude'] ??
                            data['currentLongitude'] ??
                            BookingGeoUtils.defaultLng)
                        as num)
                    .toDouble(),
          ),
        );
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
        fromLat,
        fromLng,
        toLat,
        toLng,
      );

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        final rawPoints = data['polyline'] as List? ?? [];
        final points = rawPoints.map((point) {
          final map = point as Map<String, dynamic>;
          return RoutePointDto(
            latitude: ((map['latitude'] ?? map['lat']) as num).toDouble(),
            longitude: ((map['longitude'] ?? map['lng']) as num).toDouble(),
          );
        }).toList();

        state = state.copyWith(
          route: RouteDto(
            points: points,
            distanceM: ((data['distance']?['value'] ?? 0) as num).round(),
            durationS: ((data['duration']?['value'] ?? 0) as num).round(),
          ),
        );
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

final trackingProvider = StateNotifierProvider<TrackingNotifier, TrackingState>(
  (ref) {
    return TrackingNotifier();
  },
);

