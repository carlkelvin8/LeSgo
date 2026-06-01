import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/api_service.dart';
import '../../auth/rider_auth_provider.dart';
import 'rider_location_provider.dart';
import 'rider_orders_provider.dart';

const _dutyPrefKey = 'rider_on_duty';

class RiderDutyNotifier extends StateNotifier<bool> {
  final Ref _ref;
  bool _initialized = false;

  RiderDutyNotifier(this._ref) : super(true) {
    _initialize();
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getBool(_dutyPrefKey);
    final onDuty = stored ?? true;
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

  Future<void> _applySideEffects(bool onDuty, {required bool syncApi}) async {
    if (syncApi) {
      await _syncAvailability(onDuty);
    }

    final locationNotifier = _ref.read(riderLocationProvider.notifier);
    final ordersNotifier = _ref.read(riderOrdersProvider.notifier);

    if (onDuty) {
      await locationNotifier.startTracking();
      ordersNotifier.resumeAutoRefresh();
      await ordersNotifier.loadOrders(silent: true);
    } else {
      locationNotifier.stopTracking();
      ordersNotifier.stopAutoRefresh();
    }
  }

  Future<void> _syncAvailability(bool onDuty) async {
    try {
      final authState = _ref.read(riderAuthProvider);
      final driverProfileId = authState.user?.driverProfileId;
      if (driverProfileId == null) return;

      await ApiService.updateDriverAvailability(driverProfileId, onDuty);
    } catch (e) {
      print('⚠️ Failed to sync driver availability: $e');
    }
  }
}

final riderDutyProvider =
    StateNotifierProvider<RiderDutyNotifier, bool>((ref) {
  return RiderDutyNotifier(ref);
});
