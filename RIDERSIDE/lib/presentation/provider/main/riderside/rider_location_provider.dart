import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/location_permission_utils.dart';
import '../../auth/rider_auth_provider.dart';
import 'rider_duty_provider.dart';

class RiderLocationState {
  final double? latitude;
  final double? longitude;
  final bool isLoading;
  final bool isUpdating;
  final bool isTracking;
  final String? error;
  final bool needsLocationSettings;
  final DateTime? lastUpdated;
  final int? activeOrderId;

  const RiderLocationState({
    this.latitude,
    this.longitude,
    this.isLoading = false,
    this.isUpdating = false,
    this.isTracking = false,
    this.error,
    this.needsLocationSettings = false,
    this.lastUpdated,
    this.activeOrderId,
  });

  RiderLocationState copyWith({
    double? latitude,
    double? longitude,
    bool? isLoading,
    bool? isUpdating,
    bool? isTracking,
    String? error,
    bool? needsLocationSettings,
    DateTime? lastUpdated,
    int? activeOrderId,
    bool clearError = false,
    bool clearActiveOrderId = false,
  }) {
    return RiderLocationState(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isLoading: isLoading ?? this.isLoading,
      isUpdating: isUpdating ?? this.isUpdating,
      isTracking: isTracking ?? this.isTracking,
      error: clearError ? null : (error ?? this.error),
      needsLocationSettings:
          clearError ? false : (needsLocationSettings ?? this.needsLocationSettings),
      lastUpdated: lastUpdated ?? this.lastUpdated,
      activeOrderId:
          clearActiveOrderId ? null : (activeOrderId ?? this.activeOrderId),
    );
  }

  bool get hasLocation => latitude != null && longitude != null;
}

class RiderLocationNotifier extends StateNotifier<RiderLocationState> {
  RiderLocationNotifier(this._ref) : super(const RiderLocationState());

  final Ref _ref;
  StreamSubscription<Position>? _positionStream;
  bool _starting = false;
  bool _isDisposed = false;

  void setActiveOrderId(int? orderId) {
    state = state.copyWith(
      activeOrderId: orderId,
      clearActiveOrderId: orderId == null,
    );
  }

  Future<void> startTracking({int? orderId}) async {
    if (orderId != null) {
      setActiveOrderId(orderId);
    }
    if (state.isTracking || _starting) return;
    _starting = true;

    final granted = await _requestPermissions();
    if (!granted) {
      _starting = false;
      return;
    }

    await _getCurrentLocation();
    await _startPositionStream();
    state = state.copyWith(isTracking: true);
    AppLogger.debug('✅ Location tracking started');
    _starting = false;
  }

  Future<void> stopTracking() async {
    if (_isDisposed) return;
    
    await _positionStream?.cancel();
    _positionStream = null;
    state = state.copyWith(isTracking: false, clearActiveOrderId: true);
    
    // Only send offline status if we still have a valid location and haven't disposed
    if (!_isDisposed && state.hasLocation) {
      await _sendOfflineStatus();
    }
  }

  Future<bool> _requestPermissions() async {
    var whenInUse = await Permission.locationWhenInUse.status;
    if (!whenInUse.isGranted) {
      whenInUse = await Permission.locationWhenInUse.request();
    }
    if (!whenInUse.isGranted) {
      final needsSettings = permissionNeedsSettings(whenInUse);
      state = state.copyWith(
        error: needsSettings
            ? 'Location access is blocked. Open Settings to enable it for deliveries.'
            : 'Location permission is required for deliveries.',
        needsLocationSettings: needsSettings,
      );
      return false;
    }

    state = state.copyWith(clearError: true);

    // Request background location permission on Android (required for active deliveries)
    if (!kIsWeb && Platform.isAndroid) {
      final always = await Permission.locationAlways.request();
      if (!always.isGranted) {
        AppLogger.error(
          '❌ Background location permission denied. This is required for accurate delivery tracking.',
          null,
        );
        state = state.copyWith(
          error: 'Background location permission is required for deliveries. '
              'Open Settings to grant "Allow all the time" location access.',
          needsLocationSettings: true,
        );
        return false;
      }
      AppLogger.debug('✅ Background location permission granted');
    }

    return true;
  }

  LocationSettings _buildLocationSettings() {
    final hasActiveOrder = state.activeOrderId != null;
    final distanceFilter = hasActiveOrder ? 5 : 20;
    final intervalDuration = hasActiveOrder
        ? const Duration(seconds: 5)
        : const Duration(seconds: 30);

    if (!kIsWeb && Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: distanceFilter,
        intervalDuration: intervalDuration,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText:
              'LeSgo is sharing your location for active deliveries.',
          notificationTitle: 'Location tracking active',
          enableWakeLock: true,
        ),
      );
    }

    if (!kIsWeb && Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: distanceFilter,
        activityType: ActivityType.automotiveNavigation,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    }

    return LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: distanceFilter,
    );
  }

  Future<void> _getCurrentLocation() async {
    if (!_ref.read(riderDutyProvider)) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final position = await GeolocatorPlatform.instance.getCurrentPosition(
        locationSettings: _buildLocationSettings(),
      );

      state = state.copyWith(
        latitude: position.latitude,
        longitude: position.longitude,
        lastUpdated: DateTime.now(),
        isLoading: false,
      );

      await _sendLocationToBackend(position.latitude, position.longitude);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to get location: $e',
      );
    }
  }

  Future<void> _startPositionStream() async {
    await _positionStream?.cancel();

    _positionStream = Geolocator.getPositionStream(
      locationSettings: _buildLocationSettings(),
    ).listen(
      (position) async {
        if (!_ref.read(riderDutyProvider) || !state.isTracking) return;
        
        // Allow positions with accuracy up to 50m (more lenient for urban areas)
        // In areas with poor GPS (urban canyons, tunnels), positions with up to 50m accuracy are still valuable
        if (position.accuracy > 50.0) {
          AppLogger.debug('⚠️ Skipping position with poor accuracy: ${position.accuracy.toStringAsFixed(1)}m');
          return;
        }

        if (state.hasLocation) {
          final distance = Geolocator.distanceBetween(
            state.latitude!,
            state.longitude!,
            position.latitude,
            position.longitude,
          );
          // Skip if distance is less than 2m (no significant movement)
          if (distance < 2.0) return;
        }

        state = state.copyWith(
          latitude: position.latitude,
          longitude: position.longitude,
          lastUpdated: DateTime.now(),
        );

        await _sendLocationToBackend(position.latitude, position.longitude);
      },
      onError: (Object e) {
        AppLogger.warn('Position stream error: $e');
      },
    );
  }

  Future<void> updateLocation(double latitude, double longitude) async {
    if (!_ref.read(riderDutyProvider)) return;

    state = state.copyWith(isUpdating: true);
    try {
      await _sendLocationToBackend(latitude, longitude);
      state = state.copyWith(
        latitude: latitude,
        longitude: longitude,
        lastUpdated: DateTime.now(),
        isUpdating: false,
      );
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: 'Failed to update location: $e',
      );
    }
  }

  Future<void> _sendLocationToBackend(double latitude, double longitude) async {
    if (!_ref.read(riderDutyProvider)) return;

    final authState = _ref.read(riderAuthProvider);
    final driverProfileId = authState.user?.driverProfileId;
    if (driverProfileId == null) return;

    await ApiService.updateDriverLocation(
      driverProfileId,
      latitude,
      longitude,
      status: 'online',
      orderId: state.activeOrderId,
    );
  }

  Future<void> _sendOfflineStatus() async {
    if (_isDisposed || !state.hasLocation) return;
    
    try {
      final authState = _ref.read(riderAuthProvider);
      final driverProfileId = authState.user?.driverProfileId;
      if (driverProfileId == null) return;

      await ApiService.updateDriverLocation(
        driverProfileId,
        state.latitude!,
        state.longitude!,
        status: 'offline',
        orderId: state.activeOrderId,
      );
    } catch (e) {
      debugPrint('Error sending offline status: $e');
    }
  }

  Future<void> refreshLocation() async {
    if (!_ref.read(riderDutyProvider)) return;
    await _getCurrentLocation();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _positionStream?.cancel();
    _positionStream = null;
    super.dispose();
  }
}

final riderLocationProvider =
    StateNotifierProvider<RiderLocationNotifier, RiderLocationState>(
  (ref) => RiderLocationNotifier(ref),
);
