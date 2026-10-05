import 'package:dio/dio.dart';

import '../exceptions/client_rate_limit_exception.dart';
import '../services/rate_limiter_service.dart';

/// Blocks bursts of requests per endpoint before they hit the server.
class RateLimitInterceptor extends Interceptor {
  final RateLimiterService _rateLimiter;

  RateLimitInterceptor(this._rateLimiter);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final key = options.path;
    if (!_rateLimiter.isRequestAllowed(key)) {
      final retryAfter = _rateLimiter.getTimeUntilReset(key).clamp(1, 120);
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.cancel,
          error: ClientRateLimitException(retryAfter),
        ),
      );
      return;
    }
    handler.next(options);
  }
}
