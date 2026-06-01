import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/services/api_service.dart';
import '../../auth/rider_auth_provider.dart';
import 'rider_duty_provider.dart';

class RiderLocationState {
  final double? latitude;
  final double? longitude;
  final bool isLoading;
  final bool isUpdating;
  final bool isTracking;
  final String? error;
  final DateTime? lastUpdated;

  const RiderLocationState({
    this.latitude,
    this.longitude,
    this.isLoading = false,
    this.isUpdating = false,
    this.isTracking = false,
    this.error,
    this.lastUpdated,
  });

  RiderLocationState copyWith({
    double? latitude,
    double? longitude,
    bool? isLoading,
    bool? isUpdating,
    bool? isTracking,
    String? error,
    DateTime? lastUpdated,
    bool clearError = false,
  }) {
    return RiderLocationState(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isLoading: isLoading ?? this.isLoading,
      isUpdating: isUpdating ?? this.isUpdating,
      isTracking: isTracking ?? this.isTracking,
      error: clearError ? null : (error ?? this.error),
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  bool get hasLocation => latitude != null && longitude != null;
}

class RiderLocationNotifier extends StateNotifier<RiderLocationState> {
  final Ref _ref;

  RiderLocationNotifier(this._ref) : super(const RiderLocationState());

  Timer? _updateTimer;
  bool _starting = false;

  Future<void> startTracking() async {
    if (state.isTracking || _starting) return;
    _starting = true;

    await _requestPermission();
    await _getCurrentLocation();
    _startPeriodicUpdates();
    state = state.copyWith(isTracking: true);
    _starting = false;
  }

  void stopTracking() {
    _updateTimer?.cancel();
    _updateTimer = null;
    state = state.copyWith(isTracking: false);
    _sendOfflineStatus();
  }

  Future<void> _requestPermission() async {
    final status = await Permission.locationWhenInUse.request();
    if (!status.isGranted) {
      state = state.copyWith(error: 'Location permission denied');
    }
  }

  Future<void> _getCurrentLocation() async {
    if (!_ref.read(riderDutyProvider)) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
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
    );
  }

  Future<void> _sendOfflineStatus() async {
    try {
      final authState = _ref.read(riderAuthProvider);
      final driverProfileId = authState.user?.driverProfileId;
      if (driverProfileId == null) return;

      if (state.hasLocation) {
        await ApiService.updateDriverLocation(
          driverProfileId,
          state.latitude!,
          state.longitude!,
          status: 'offline',
        );
      }
    } catch (e) {
      print('Error sending offline status: $e');
    }
  }

  void _startPeriodicUpdates() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!_ref.read(riderDutyProvider) || !state.isTracking) return;
      if (state.isUpdating) return;

      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation,
        );

        if (position.accuracy > 30.0) return;

        if (state.hasLocation) {
          final distance = Geolocator.distanceBetween(
            state.latitude!,
            state.longitude!,
            position.latitude,
            position.longitude,
          );
          if (distance < 2.0) return;
        }

        await _sendLocationToBackend(position.latitude, position.longitude);

        state = state.copyWith(
          latitude: position.latitude,
          longitude: position.longitude,
          lastUpdated: DateTime.now(),
        );
      } catch (e) {
        print('Periodic location update failed: $e');
      }
    });
  }

  Future<void> refreshLocation() async {
    if (!_ref.read(riderDutyProvider)) return;
    await _getCurrentLocation();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }
}

final riderLocationProvider =
    StateNotifierProvider<RiderLocationNotifier, RiderLocationState>(
  (ref) => RiderLocationNotifier(ref),
);
