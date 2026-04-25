import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'secure_storage_service.dart';

/// Service for monitoring session timeout
/// Automatically logs out users after inactivity
@lazySingleton
class SessionTimeoutService {
  final SecureStorageService _secureStorage;
  Timer? _timeoutTimer;
  
  /// Timeout duration in minutes (default: 30 minutes)
  static const int _timeoutMinutes = 30;
  
  /// Callback when session expires
  VoidCallback? onSessionExpired;

  SessionTimeoutService(this._secureStorage);

  /// Start monitoring session timeout
  void startMonitoring({VoidCallback? onExpired}) {
    if (onExpired != null) {
      onSessionExpired = onExpired;
    }
    
    debugPrint('⏱️ Starting session timeout monitoring ($_timeoutMinutes minutes)');
    
    // Don't check immediately on startup - give the app time to initialize
    // Check after 1 second to allow Navigator to be ready
    Future.delayed(const Duration(seconds: 1), () {
      _checkSession();
    });
    
    // Check every minute
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkSession(),
    );
  }

  /// Stop monitoring session timeout
  void stopMonitoring() {
    debugPrint('⏱️ Stopping session timeout monitoring');
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }

  /// Check if session has expired
  void _checkSession() {
    if (!_secureStorage.isLoggedIn()) {
      return;
    }

    if (_secureStorage.isSessionExpired(timeoutMinutes: _timeoutMinutes)) {
      debugPrint('⏱️ Session expired - logging out');
      _handleSessionExpired();
    }
  }

  /// Handle session expiration
  void _handleSessionExpired() {
    stopMonitoring();
    
    // Clear auth data
    _secureStorage.clearAuthData();
    
    // Trigger callback
    onSessionExpired?.call();
  }

  /// Update session activity (call on user interaction)
  Future<void> updateActivity() async {
    await _secureStorage.updateSessionActivity();
  }

  /// Get remaining time before session expires (in minutes)
  int getRemainingTime() {
    final lastActivity = _secureStorage.getLastActivity();
    if (lastActivity == null) return 0;

    final now = DateTime.now();
    final difference = now.difference(lastActivity);
    final remaining = _timeoutMinutes - difference.inMinutes;

    return remaining > 0 ? remaining : 0;
  }

  /// Check if session is about to expire (within 5 minutes)
  bool isSessionAboutToExpire() {
    final remaining = getRemainingTime();
    return remaining > 0 && remaining <= 5;
  }

  /// Extend session (reset timeout)
  Future<void> extendSession() async {
    debugPrint('⏱️ Extending session');
    await updateActivity();
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
  }
}
