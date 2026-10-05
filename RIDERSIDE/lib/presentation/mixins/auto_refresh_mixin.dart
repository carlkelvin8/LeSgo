import 'dart:async';

import 'package:flutter/material.dart';

mixin AutoRefreshMixin<T extends StatefulWidget> on State<T>, WidgetsBindingObserver {
  Timer? _autoRefreshTimer;
  bool _isPaused = false;

  Duration get autoRefreshInterval;

  void onAutoRefresh();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    if (_isPaused) return;
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(autoRefreshInterval, (_) {
      if (mounted) onAutoRefresh();
    });
  }

  void _stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _isPaused = false;
        onAutoRefresh();
        _startAutoRefresh();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _isPaused = true;
        _stopAutoRefresh();
        break;
    }
  }

  @override
  void dispose() {
    _stopAutoRefresh();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
