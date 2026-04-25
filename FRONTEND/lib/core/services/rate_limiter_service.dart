import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// Service for rate limiting API requests
/// Prevents abuse and excessive API calls
@lazySingleton
class RateLimiterService {
  final Map<String, List<DateTime>> _requestHistory = {};
  
  /// Maximum requests per endpoint per time window
  static const int _maxRequestsPerWindow = 60;
  
  /// Time window in seconds
  static const int _timeWindowSeconds = 60;

  /// Check if request is allowed for the given endpoint
  bool isRequestAllowed(String endpoint) {
    final now = DateTime.now();
    
    // Get request history for this endpoint
    if (!_requestHistory.containsKey(endpoint)) {
      _requestHistory[endpoint] = [];
    }
    
    final history = _requestHistory[endpoint]!;
    
    // Remove old requests outside the time window
    history.removeWhere((timestamp) {
      final difference = now.difference(timestamp).inSeconds;
      return difference > _timeWindowSeconds;
    });
    
    // Check if limit exceeded
    if (history.length >= _maxRequestsPerWindow) {
      debugPrint('⚠️ Rate limit exceeded for endpoint: $endpoint');
      debugPrint('   Requests: ${history.length}/$_maxRequestsPerWindow in last $_timeWindowSeconds seconds');
      return false;
    }
    
    // Add current request to history
    history.add(now);
    
    return true;
  }

  /// Get remaining requests for endpoint
  int getRemainingRequests(String endpoint) {
    final now = DateTime.now();
    
    if (!_requestHistory.containsKey(endpoint)) {
      return _maxRequestsPerWindow;
    }
    
    final history = _requestHistory[endpoint]!;
    
    // Remove old requests
    history.removeWhere((timestamp) {
      final difference = now.difference(timestamp).inSeconds;
      return difference > _timeWindowSeconds;
    });
    
    return _maxRequestsPerWindow - history.length;
  }

  /// Get time until rate limit resets (in seconds)
  int getTimeUntilReset(String endpoint) {
    if (!_requestHistory.containsKey(endpoint)) {
      return 0;
    }
    
    final history = _requestHistory[endpoint]!;
    
    if (history.isEmpty) {
      return 0;
    }
    
    final now = DateTime.now();
    final oldestRequest = history.first;
    final timeSinceOldest = now.difference(oldestRequest).inSeconds;
    
    return _timeWindowSeconds - timeSinceOldest;
  }

  /// Clear rate limit history for endpoint
  void clearHistory(String endpoint) {
    _requestHistory.remove(endpoint);
    debugPrint('🗑️ Cleared rate limit history for: $endpoint');
  }

  /// Clear all rate limit history
  void clearAllHistory() {
    _requestHistory.clear();
    debugPrint('🗑️ Cleared all rate limit history');
  }

  /// Get rate limit info for debugging
  Map<String, dynamic> getRateLimitInfo(String endpoint) {
    return {
      'endpoint': endpoint,
      'maxRequests': _maxRequestsPerWindow,
      'timeWindow': _timeWindowSeconds,
      'remainingRequests': getRemainingRequests(endpoint),
      'timeUntilReset': getTimeUntilReset(endpoint),
    };
  }
}
