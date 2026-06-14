import 'package:dio/dio.dart';

import '../services/connectivity_service.dart';
import 'offline_exceptions.dart';
import 'offline_request_queue.dart';

/// Blocks or queues mutating requests while offline.
class OfflineInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (connectivityService.isConnected) {
      handler.next(options);
      return;
    }

    if (offlineRequestQueue.canQueue(options)) {
      await offlineRequestQueue.enqueue(options);
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: const OfflineQueuedException(),
        ),
      );
      return;
    }

    handler.reject(
      DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        message: 'No internet connection',
      ),
    );
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (_isConnectionFailure(err) &&
        offlineRequestQueue.canQueue(err.requestOptions)) {
      await offlineRequestQueue.enqueue(err.requestOptions);
      handler.next(
        DioException(
          requestOptions: err.requestOptions,
          type: DioExceptionType.connectionError,
          error: const OfflineQueuedException(),
        ),
      );
      return;
    }
    handler.next(err);
  }

  bool _isConnectionFailure(DioException err) {
    return err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout;
  }
}
