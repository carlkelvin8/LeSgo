import 'dart:ui' show VoidCallback;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/app_localization.dart';
import '../../auth/rider_auth_provider.dart';
import 'rider_location_provider.dart';

const _dutyPrefKey = 'rider_on_duty';

class RiderDutyNotifier extends StateNotifier<bool> {
  final Ref _ref;
  bool _initialized = false;
  VoidCallback? _onDutyChanged;

  RiderDutyNotifier(this._ref) : super(false) {
    _initialize();
  }

  /// Allows external coordination without circular dependency.
  set onDutyChanged(VoidCallback? callback) => _onDutyChanged = callback;

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getBool(_dutyPrefKey);
    final onDuty = stored ?? false;
    state = onDuty;
    _initialized = true;
    _applySideEffects(onDuty, syncApi: true);
  }

  Future<void> setOnDuty(bool onDuty) async {
    if (!_initialized) {
      await _initialize();
    }
    if (state == onDuty) return;

    state = onDuty;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dutyPrefKey, onDuty);
    await _applySideEffects(onDuty, syncApi: true);
  }

  /// Requires attendance photo before going on duty.
  /// Returns an error message on failure, null on success.
  Future<String?> goOnDutyWithPhoto(XFile photo) async {
    if (!_initialized) {
      await _initialize();
    }
    if (state) return null;

    try {
      final authState = _ref.read(riderAuthProvider);
      final driverProfileId = authState.user?.driverProfileId;
      if (driverProfileId == null) {
        return AppLocalization.translate('driver_profile_not_found', 'en');
      }

      final location = _ref.read(riderLocationProvider);
      await ApiService.submitDutyAttendance(
        driverProfileId,
        photo,
        latitude: location.latitude,
        longitude: location.longitude,
      );

      state = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_dutyPrefKey, true);
      await _applySideEffects(true, syncApi: true);
      return null;
    } catch (e) {
      return ApiService.extractError(e);
    }
  }

  Future<void> _applySideEffects(bool onDuty, {required bool syncApi}) async {
    if (syncApi) {
      final syncError = await _syncAvailability(onDuty);
      if (syncError != null && _onDutyChanged != null) {
        // Notify UI of sync failure through callback if available
        AppLogger.error('❌ Duty sync failed: $syncError');
      }
    }

    final locationNotifier = _ref.read(riderLocationProvider.notifier);

    if (onDuty) {
      await locationNotifier.startTracking();
    } else {
      await locationNotifier.stopTracking();
    }

    _onDutyChanged?.call();
  }

  Future<String?> _syncAvailability(bool onDuty) async {
    try {
      final authState = _ref.read(riderAuthProvider);
      final driverProfileId = authState.user?.driverProfileId;
      if (driverProfileId == null) return null;

      await ApiService.updateDriverAvailability(driverProfileId, onDuty);
      AppLogger.debug('✅ Driver availability synced: ${onDuty ? "online" : "offline"}');
      return null;
    } catch (e) {
      final errorMsg = 'Failed to sync driver availability: $e';
      AppLogger.error('❌ $errorMsg');
      return errorMsg;
    }
  }
}

final riderDutyProvider =
    StateNotifierProvider<RiderDutyNotifier, bool>((ref) {
  return RiderDutyNotifier(ref);
});
