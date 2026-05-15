import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/services/api_service.dart';
import '../../auth/rider_auth_provider.dart';

class RiderLocationState {
  final double? latitude;
  final double? longitude;
  final bool isLoading;
  final bool isUpdating;
  final String? error;
  final DateTime? lastUpdated;

  const RiderLocationState({
    this.latitude,
    this.longitude,
    this.isLoading = false,
    this.isUpdating = false,
    this.error,
    this.lastUpdated,
  });

  RiderLocationState copyWith({
    double? latitude,
    double? longitude,
    bool? isLoading,
    bool? isUpdating,
    String? error,
    DateTime? lastUpdated,
    bool clearError = false,
  }) {
    return RiderLocationState(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isLoading: isLoading ?? this.isLoading,
      isUpdating: isUpdating ?? this.isUpdating,
      error: clearError ? null : (error ?? this.error),
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  bool get hasLocation => latitude != null && longitude != null;
}

class RiderLocationNotifier extends StateNotifier<RiderLocationState> {
  final Ref _ref;
  
  RiderLocationNotifier(this._ref) : super(const RiderLocationState()) {
    _initialize();
  }

  Timer? _updateTimer;

  Future<void> _initialize() async {
    await _requestPermission();
    await _getCurrentLocation();
    _startPeriodicUpdates();
  }

  Future<void> _requestPermission() async {
    final status = await Permission.locationWhenInUse.request();
    if (!status.isGranted) {
      state = state.copyWith(
        error: 'Location permission denied',
        clearError: false,
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    state = state.copyWith(isLoading: true);
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
    try {
      // Get driver profile ID from auth provider
      final authState = _ref.read(riderAuthProvider);
      final driverProfileId = authState.user?.driverProfileId;
      
      if (driverProfileId != null) {
        await ApiService.updateDriverLocation(
          driverProfileId,
          latitude,
          longitude,
        );
      }
    } catch (e) {
      print('Error sending location to backend: $e');
      // Don't update state error here - this is a background operation
    }
  }

  void _startPeriodicUpdates() {
    // Update location every 5 seconds for real-time tracking
    _updateTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!state.isUpdating) {
        try {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.bestForNavigation,
          );
          
          // Smart GPS Filtering: Ignore inaccurate locations (> 30m accuracy)
          if (position.accuracy > 30.0) {
            print('⚠️ Ignored inaccurate GPS reading: accuracy ${position.accuracy.toStringAsFixed(1)}m');
            return;
          }
          
          // Smart GPS Filtering: Ignore tiny jitter movements
          if (state.hasLocation) {
            final distance = Geolocator.distanceBetween(
              state.latitude!, state.longitude!,
              position.latitude, position.longitude,
            );
            
            // Only update if moved more than 2 meters
            if (distance < 2.0) {
              return;
            }
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
      }
    });
  }

  Future<void> refreshLocation() async {
    await _getCurrentLocation();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _updateTimer = null;
    super.dispose();
  }
}

final riderLocationProvider = StateNotifierProvider<RiderLocationNotifier, RiderLocationState>(
  (ref) => RiderLocationNotifier(ref),
);