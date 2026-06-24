import 'package:dio/dio.dart';

/// Pass-through interceptor — offline queue disabled to avoid false "you're offline"
/// on login and auth. Delivery retries are handled in the UI when needed.
class OfflineInterceptor extends Interceptor {}
