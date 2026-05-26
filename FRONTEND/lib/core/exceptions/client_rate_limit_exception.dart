/// Thrown when the client-side rate limiter blocks a request.
class ClientRateLimitException implements Exception {
  final int retryAfterSeconds;

  const ClientRateLimitException(this.retryAfterSeconds);

  @override
  String toString() =>
      'ClientRateLimitException(retryAfterSeconds: $retryAfterSeconds)';
}
