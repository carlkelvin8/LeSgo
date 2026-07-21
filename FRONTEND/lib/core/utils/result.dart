import '../exceptions/app_exception.dart';

/// A simple Result type for operations that can succeed or fail.
/// Use this instead of try/catch in providers for cleaner error handling.
///
/// Example usage:
/// ```dart
/// final result = await Result.guard(() => repository.getOrders());
/// result.when(
///   success: (orders) => state = state.copyWith(orders: orders),
///   failure: (error) => state = state.copyWith(error: error.userMessage),
/// );
/// ```
sealed class Result<T> {
  const Result._();

  /// Create a success result.
  const factory Result.success(T data) = Success<T>;

  /// Create a failure result.
  const factory Result.failure(AppException error) = Failure<T>;

  /// Execute an async operation and wrap the result.
  /// Automatically maps exceptions to [AppException].
  static Future<Result<T>> guard<T>(
    Future<T> Function() operation, {
    String? context,
  }) async {
    try {
      final data = await operation();
      return Result.success(data);
    } catch (e) {
      return Result.failure(AppExceptionMapper.from(e, context: context));
    }
  }

  /// Execute a synchronous operation and wrap the result.
  static Result<T> guardSync<T>(
    T Function() operation, {
    String? context,
  }) {
    try {
      final data = operation();
      return Result.success(data);
    } catch (e) {
      return Result.failure(AppExceptionMapper.from(e, context: context));
    }
  }

  /// Pattern match on the result.
  R when<R>({
    required R Function(T data) success,
    required R Function(AppException error) failure,
  });

  /// Get the data if success, or null if failure.
  T? get dataOrNull;

  /// Get the error if failure, or null if success.
  AppException? get errorOrNull;

  /// True if this is a success result.
  bool get isSuccess;

  /// True if this is a failure result.
  bool get isFailure;
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data) : super._();

  @override
  R when<R>({
    required R Function(T data) success,
    required R Function(AppException error) failure,
  }) => success(data);

  @override
  T? get dataOrNull => data;
  @override
  AppException? get errorOrNull => null;
  @override
  bool get isSuccess => true;
  @override
  bool get isFailure => false;
}

class Failure<T> extends Result<T> {
  final AppException error;
  const Failure(this.error) : super._();

  @override
  R when<R>({
    required R Function(T data) success,
    required R Function(AppException error) failure,
  }) => failure(error);

  @override
  T? get dataOrNull => null;
  @override
  AppException? get errorOrNull => error;
  @override
  bool get isSuccess => false;
  @override
  bool get isFailure => true;
}
