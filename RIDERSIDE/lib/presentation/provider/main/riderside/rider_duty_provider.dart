import 'dart:ui' show VoidCallback;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/app_localization.dart';
import '../../auth/rider_auth_provider.dart';
import 'rider_location_provider.dart';

class RiderDutyNotifier extends StateNotifier<bool> {
  final Ref _ref;
  final String? _dutyPrefKey;
  late final Future<void> _initialization;
  bool _changing = false;
  VoidCallback? _onDutyChanged;

  RiderDutyNotifier(this._ref)
    : _dutyPrefKey = _ref.read(riderAuthProvider).user == null
          ? null
          : 'rider_on_duty_${_ref.read(riderAuthProvider).user!.id}',
      super(false) {
    _initialization = _initialize();
  }

  /// Allows external coordination without circular dependency.
  set onDutyChanged(VoidCallback? callback) => _onDutyChanged = callback;

  Future<void> _initialize() async {
    if (_dutyPrefKey == null) return;
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getBool(_dutyPrefKey);
    final onDuty = stored ?? false;
    if (!mounted || !onDuty) return;
    final error = await _syncAvailability(true);
    if (!mounted || error != null) return;
    state = true;
    await _applySideEffects(true);
  }

  Future<String?> setOnDuty(bool onDuty) async {
    await _initialization;
    if (!mounted) return 'Duty screen is no longer active.';
    if (_changing) return 'A duty update is already in progress.';
    if (state == onDuty) return null;
    _changing = true;
    try {
      return await _commitDuty(onDuty);
    } catch (e) {
      return ApiService.extractError(e);
    } finally {
      _changing = false;
    }
  }

  Future<String?> _commitDuty(bool onDuty) async {
    final error = await _syncAvailability(onDuty);
    if (error != null) return error;
    if (!mounted) return 'Duty screen is no longer active.';
    state = onDuty;
    final prefs = await SharedPreferences.getInstance();
    if (_dutyPrefKey != null) await prefs.setBool(_dutyPrefKey, onDuty);
    if (mounted) await _applySideEffects(onDuty);
    return null;
  }

  /// Requires attendance photo before going on duty.
  /// Returns an error message on failure, null on success.
  Future<String?> goOnDutyWithPhoto(XFile photo) async {
    await _initialization;
    if (!mounted) return 'Duty screen is no longer active.';
    if (_changing) return 'A duty update is already in progress.';
    if (state) return null;
    _changing = true;

    try {
      final driverProfileId = await _ref
          .read(riderAuthProvider.notifier)
          .ensureDriverProfileId();
      if (!mounted) return 'Duty screen is no longer active.';
      if (driverProfileId == null) {
        return AppLocalization.translate(
          'driver_profile_not_found',
          AppLanguage.english,
        );
      }

      final location = _ref.read(riderLocationProvider);
      await ApiService.submitDutyAttendance(
        driverProfileId,
        photo,
        latitude: location.latitude,
        longitude: location.longitude,
      );
      if (!mounted) return 'Duty screen is no longer active.';

      return await _commitDuty(true);
    } catch (e) {
      return ApiService.extractError(e);
    } finally {
      _changing = false;
    }
  }

  Future<void> _applySideEffects(bool onDuty) async {
    final locationNotifier = _ref.read(riderLocationProvider.notifier);
    try {
      if (onDuty) {
        await locationNotifier.startTracking();
      } else {
        await locationNotifier.stopTracking();
      }
    } catch (e) {
      AppLogger.error('Location tracking update failed', e);
    }
    if (mounted) _onDutyChanged?.call();
  }

  Future<String?> _syncAvailability(bool onDuty) async {
    try {
      final driverProfileId = await _ref
          .read(riderAuthProvider.notifier)
          .ensureDriverProfileId();
      if (!mounted) return 'Duty screen is no longer active.';
      if (driverProfileId == null) {
        return 'Driver profile not found. Please sign in again.';
      }

      await ApiService.updateDriverAvailability(driverProfileId, onDuty);
      AppLogger.debug(
        '✅ Driver availability synced: ${onDuty ? "online" : "offline"}',
      );
      return null;
    } catch (e) {
      final errorMsg = 'Failed to sync driver availability: $e';
      AppLogger.error('❌ $errorMsg');
      return errorMsg;
    }
  }
}

final riderDutyProvider = StateNotifierProvider<RiderDutyNotifier, bool>((ref) {
  ref.watch(riderAuthProvider.select((auth) => auth.user?.id));
  return RiderDutyNotifier(ref);
});
