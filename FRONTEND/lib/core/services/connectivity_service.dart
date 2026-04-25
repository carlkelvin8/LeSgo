import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:dio/dio.dart';

/// Service to monitor network connectivity
@lazySingleton
class ConnectivityService {
  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();
  
  bool _isConnected = true;
  Timer? _checkTimer;

  /// Stream of connectivity status
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Current connectivity status
  bool get isConnected => _isConnected;

  ConnectivityService() {
    _startMonitoring();
  }

  void _startMonitoring() {
    // Check connectivity every 10 seconds
    _checkTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkConnectivity();
    });

    // Initial check
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    try {
      // Try to make a simple request to check connectivity
      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 5);
      dio.options.receiveTimeout = const Duration(seconds: 5);
      
      await dio.get('https://www.google.com');
      
      if (!_isConnected) {
        _isConnected = true;
        _connectivityController.add(true);
        debugPrint('✅ Network connection restored');
      }
    } catch (e) {
      if (_isConnected) {
        _isConnected = false;
        _connectivityController.add(false);
        debugPrint('❌ Network connection lost');
      }
    }
  }

  /// Manually check connectivity
  Future<bool> checkConnection() async {
    await _checkConnectivity();
    return _isConnected;
  }

  @disposeMethod
  void dispose() {
    _checkTimer?.cancel();
    _connectivityController.close();
  }
}
