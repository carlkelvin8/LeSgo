import 'package:flutter/material.dart';
import '../di/injection.dart';
import '../services/session_timeout_service.dart';
import '../services/secure_storage_service.dart';
import '../constants/routers/auth/auth_routes.dart';

/// Widget that observes app lifecycle and manages session timeout
class AppLifecycleObserver extends StatefulWidget {
  final Widget child;

  const AppLifecycleObserver({
    super.key,
    required this.child,
  });

  @override
  State<AppLifecycleObserver> createState() => _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends State<AppLifecycleObserver>
    with WidgetsBindingObserver {
  late final SessionTimeoutService _sessionTimeoutService;
  late final SecureStorageService _secureStorageService;

  @override
  void initState() {
    super.initState();
    _sessionTimeoutService = getIt<SessionTimeoutService>();
    _secureStorageService = getIt<SecureStorageService>();
    
    WidgetsBinding.instance.addObserver(this);
    
    // Only start monitoring if user is logged in - don't check expiration on startup
    if (_secureStorageService.isLoggedIn()) {
      // Update activity timestamp SYNCHRONOUSLY before monitoring starts
      // This prevents immediate expiration when app is reopened after being killed
      _secureStorageService.updateSessionActivitySync();
      
      // Start monitoring after activity is updated
      _sessionTimeoutService.startMonitoring(
        onExpired: _handleSessionExpired,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessionTimeoutService.stopMonitoring();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground
        debugPrint('📱 App resumed');
        
        // Update activity synchronously BEFORE any check can fire
        if (_secureStorageService.isLoggedIn()) {
          _secureStorageService.updateSessionActivitySync();
          _sessionTimeoutService.updateActivity();
        }
        break;
        
      case AppLifecycleState.paused:
        // App went to background
        debugPrint('📱 App paused');
        break;
        
      case AppLifecycleState.inactive:
        // App is inactive (e.g., phone call)
        debugPrint('📱 App inactive');
        break;
        
      case AppLifecycleState.detached:
        // App is detached
        debugPrint('📱 App detached');
        break;
        
      case AppLifecycleState.hidden:
        // App is hidden
        debugPrint('📱 App hidden');
        break;
    }
  }

  void _handleSessionExpired() {
    debugPrint('⏱️ Session expired - redirecting to login');
    
    // Navigate to login screen only if mounted and Navigator is available
    if (mounted && context.mounted) {
      // Check if Navigator is available in the context
      final navigator = Navigator.maybeOf(context);
      if (navigator != null) {
        navigator.pushNamedAndRemoveUntil(
          LoginRoutes.login,
          (route) => false,
        );
        
        // Show session expired message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Your session has expired. Please login again.',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: Color(0xFFE74C3C),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        debugPrint('⏱️ Navigator not available yet, skipping redirect');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
