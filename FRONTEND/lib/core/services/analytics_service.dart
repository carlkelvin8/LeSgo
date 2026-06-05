import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

import '../constants/api_constants.dart';
import '../network/dio_client.dart';

/// Fire-and-forget analytics event tracking for the customer app.
@lazySingleton
class AnalyticsService {
  final DioClient _dioClient;

  AnalyticsService(this._dioClient);

  Future<void> trackEvent(
    String eventType, {
    Map<String, dynamic>? properties,
  }) async {
    try {
      await _dioClient.dio.post(
        ApiConstants.analyticsTrackEvent,
        data: {
          'event_type': eventType,
          if (properties != null) 'properties': properties,
        },
      );
    } catch (e) {
      debugPrint('Analytics track skipped: $e');
    }
  }

  Future<void> trackScreenView(String screenName) {
    return trackEvent(
      'screen_view',
      properties: {'screen': screenName},
    );
  }
}

/// Tracks named routes for analytics.
class AnalyticsRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  AnalyticsRouteObserver(this._analytics);

  final AnalyticsService _analytics;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _track(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) _track(newRoute);
  }

  void _track(Route<dynamic> route) {
    final name = route.settings.name;
    if (name == null || name.isEmpty) return;
    _analytics.trackScreenView(name);
  }
}
