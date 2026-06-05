import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  final StreamController<bool> _controller =
      StreamController<bool>.broadcast();
  bool _isConnected = true;
  Timer? _timer;

  Stream<bool> get connectivityStream => _controller.stream;
  bool get isConnected => _isConnected;

  ConnectivityService() {
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkConnectivity();
    });
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    try {
      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 5);
      dio.options.receiveTimeout = const Duration(seconds: 5);
      await dio.get('https://www.google.com');
      if (!_isConnected) {
        _isConnected = true;
        _controller.add(true);
      }
    } catch (_) {
      if (_isConnected) {
        _isConnected = false;
        _controller.add(false);
      }
    }
  }

  Future<bool> checkConnection() async {
    await _checkConnectivity();
    return _isConnected;
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}

final connectivityService = ConnectivityService();
