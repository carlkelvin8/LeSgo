import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// Monitors device network (Wi‑Fi / mobile data).
///
/// Defaults to online. Only marks offline after the OS repeatedly reports no
/// active interface. API timeouts are server issues, not "no internet".
@lazySingleton
class ConnectivityService {
  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();
  late final Stream<bool> _connectivityStream = _createConnectivityStream();

  bool _isConnected = true;
  int _offlineStreak = 0;
  Timer? _checkTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  Stream<bool> get connectivityStream => _connectivityStream;

  bool get isConnected => _isConnected;

  ConnectivityService() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((_) {
      _checkConnectivity();
    });
    _startMonitoring();
  }

  Stream<bool> _createConnectivityStream() async* {
    yield _isConnected;
    yield* _connectivityController.stream;
  }

  void _startMonitoring() {
    _checkTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      _checkConnectivity();
    });
    _checkConnectivity();
  }

  Future<void> _checkConnectivity({bool immediate = false}) async {
    try {
      final results = await Connectivity().checkConnectivity();
      if (_hasDeviceNetwork(results)) {
        _offlineStreak = 0;
        _setConnected(true);
        return;
      }

      _offlineStreak++;
      if (immediate || _offlineStreak >= 5) {
        _setConnected(false);
      }
    } catch (e) {
      debugPrint('Connectivity check failed: $e');
    }
  }

  static bool _hasDeviceNetwork(List<ConnectivityResult> results) {
    if (results.isEmpty) return true;
    return results.any(
      (result) =>
          result != ConnectivityResult.none &&
          result != ConnectivityResult.bluetooth,
    );
  }

  void _setConnected(bool connected) {
    if (_isConnected == connected) return;
    _isConnected = connected;
    _connectivityController.add(connected);
    debugPrint(connected ? '✅ Network available' : '❌ No network connection');
  }

  Future<bool> checkConnection() async {
    await _checkConnectivity(immediate: true);
    return _isConnected;
  }

  @disposeMethod
  void dispose() {
    _checkTimer?.cancel();
    _connectivitySub?.cancel();
    _connectivityController.close();
  }
}
