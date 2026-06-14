import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../network/offline_request_queue.dart';
import '../utils/app_logger.dart';

class ConnectivityService {
  final StreamController<bool> _controller =
      StreamController<bool>.broadcast();
  bool _isConnected = true;
  Timer? _timer;
  Dio? _dioForQueueFlush;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  final List<void Function(int replayedCount)> _flushListeners = [];

  Stream<bool> get connectivityStream => _controller.stream;
  bool get isConnected => _isConnected;

  ConnectivityService() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((_) {
      _checkConnectivity();
    });
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      _checkConnectivity();
    });
    _checkConnectivity();
  }

  void attachDio(Dio dio) {
    _dioForQueueFlush = dio;
  }

  void addOnOfflineQueueFlushedListener(
    void Function(int replayedCount) listener,
  ) {
    _flushListeners.add(listener);
  }

  void removeOnOfflineQueueFlushedListener(
    void Function(int replayedCount) listener,
  ) {
    _flushListeners.remove(listener);
  }

  Future<void> _checkConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      final hasNetwork = _hasNetworkInterface(results);
      if (!hasNetwork) {
        _setConnected(false);
        return;
      }

      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      await dio.get(ApiConstants.baseUrl);
      await _setConnected(true);
    } catch (e) {
      AppLogger.debug('API reachability check failed: $e');
      await _setConnected(false);
    }
  }

  bool _hasNetworkInterface(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return !results.every((r) => r == ConnectivityResult.none);
  }

  Future<void> _setConnected(bool connected) async {
    if (connected == _isConnected) return;
    _isConnected = connected;
    _controller.add(connected);
    if (connected) {
      await _flushOfflineQueue();
    }
  }

  Future<void> _flushOfflineQueue() async {
    final dio = _dioForQueueFlush;
    if (dio == null) return;
    final replayed = await offlineRequestQueue.flush(dio);
    if (replayed > 0) {
      _notifyFlushListeners(replayed);
    }
  }

  void _notifyFlushListeners(int replayed) {
    for (final listener in List<void Function(int)>.from(_flushListeners)) {
      try {
        listener(replayed);
      } catch (e) {
        AppLogger.warn('Offline flush listener error: $e');
      }
    }
  }

  Future<bool> checkConnection() async {
    await _checkConnectivity();
    if (_isConnected) {
      await _flushOfflineQueue();
    }
    return _isConnected;
  }

  void dispose() {
    _timer?.cancel();
    _connectivitySub?.cancel();
    _controller.close();
  }
}

final connectivityService = ConnectivityService();
