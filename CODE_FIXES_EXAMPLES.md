# Code Fix Examples - Copy-Paste Ready

## Fix #1: Safe Price Parsing

### Before (BUGGY):
```dart
// FRONTEND/lib/data/data_source/dto/order/order_dto.dart
double _parseDouble(dynamic value) {
  if (value == null) return 0.0;  // ❌ Silent failure
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}
```

### After (FIXED):
```dart
import 'package:flutter/foundation.dart';

double _parseDouble(dynamic value, {String? fieldName, bool required = false}) {
  if (value == null) {
    if (required) {
      final error = 'Required numeric field ${fieldName ?? 'unknown'} is null';
      debugPrint('⚠️ PARSE ERROR: $error');
      throw FormatException(error);
    }
    return 0.0;
  }
  
  if (value is num) {
    return value.toDouble();
  }
  
  if (value is String) {
    final parsed = double.tryParse(value);
    if (parsed == null) {
      final error = 'Failed to parse ${fieldName ?? 'field'}: "$value"';
      debugPrint('⚠️ PARSE ERROR: $error');
      if (required) {
        throw FormatException(error);
      }
    }
    return parsed ?? 0.0;
  }
  
  final error = 'Unexpected type for ${fieldName ?? 'field'}: ${value.runtimeType}';
  debugPrint('⚠️ PARSE ERROR: $error');
  if (required) {
    throw FormatException(error);
  }
  return 0.0;
}

// Usage in OrderDto:
@JsonKey(name: 'total_amount', fromJson: _parseTotalAmount)
final double? totalAmount;

static double? _parseTotalAmount(dynamic value) {
  return _parseDoubleNullable(value, fieldName: 'total_amount', required: true);
}
```

---

## Fix #2: API Path Building

### Before (BUGGY):
```dart
// FRONTEND/lib/core/constants/api_constants.dart
class ApiConstants {
  static const String chatConversationByOrder = '/v1/chat/conversations/order/{order_id}';
  static const String chatMessages = '/v1/chat/conversations/{id}/messages';
  
  // Used like:
  // ApiConstants.chatMessages.replaceAll('{id}', conversationId.toString())
  // ❌ Fragile string replacement
}
```

### After (FIXED):
```dart
// FRONTEND/lib/core/constants/api_constants.dart
class ApiConstants {
  // Chat endpoints - now functions
  static String chatConversationByOrder(int orderId) => 
      '/v1/chat/conversations/order/$orderId';
  
  static String chatMessages(int conversationId) => 
      '/v1/chat/conversations/$conversationId/messages';
  
  static String chatSendMessage(int conversationId) => 
      '/v1/chat/conversations/$conversationId/messages';
  
  static String chatMarkAsRead(int conversationId) => 
      '/v1/chat/conversations/$conversationId/read';
}

// Updated usage in chat_remote_datasource.dart:
Future<ConversationDto> getOrCreateConversation(int orderId) async {
  final response = await _dioClient.dio.get(
    ApiConstants.chatConversationByOrder(orderId),  // ✅ Type-safe
  );
  // ...
}

Future<List<MessageDto>> getMessages(int conversationId, {int page = 1, int limit = 50}) async {
  final response = await _dioClient.dio.get(
    ApiConstants.chatMessages(conversationId),  // ✅ Type-safe
    queryParameters: {
      'page': page,
      'per_page': limit,
    },
  );
  // ...
}
```

---

## Fix #3: Wallet Validation Race Condition

### Before (BUGGY):
```dart
// FRONTEND/lib/presentation/provider/main/booking/checkout_provider.dart
if ((state.selectedPaymentMethod ?? 'cash') == 'wallet') {
  try {
    final wallet = await getIt<WalletRemoteDataSource>().getMyWallet();
    ref.read(lespayProvider.notifier).refreshBalance();  // ❌ Race condition
    if (wallet.balance < order.total) {
      // Show error
    }
  } catch (_) { }  // ❌ Swallows all errors
}
```

### After (FIXED):
```dart
// FRONTEND/lib/presentation/provider/main/booking/checkout_provider.dart
Future<void> _validateWalletBalance() async {
  if ((state.selectedPaymentMethod ?? 'cash') != 'wallet') {
    return; // Not using wallet
  }

  try {
    final walletDataSource = getIt<WalletRemoteDataSource>();
    
    // Atomic validation endpoint (add to backend)
    final validation = await walletDataSource.validateBalanceForAmount(
      state.order!.total,
    );
    
    if (!validation.sufficient) {
      state = state.copyWith(
        error: 'Insufficient wallet balance. '
               'Available: ₱${validation.currentBalance.toStringAsFixed(2)}, '
               'Required: ₱${state.order!.total.toStringAsFixed(2)}',
        isLoading: false,
      );
      return;
    }
    
    // Balance is sufficient, proceed with order creation
    AppLogger.info('Wallet validation passed: ${validation.currentBalance} >= ${state.order!.total}');
    
  } on DioException catch (e) {
    final errorMsg = ApiErrorMapper.mapDioException(e);
    state = state.copyWith(
      error: 'Wallet validation failed: $errorMsg',
      isLoading: false,
    );
    AppLogger.error('Wallet validation error', error: e);
    return;
  } catch (e) {
    state = state.copyWith(
      error: 'Unexpected error during wallet validation',
      isLoading: false,
    );
    AppLogger.error('Wallet validation unexpected error', error: e);
    return;
  }
}

// Backend endpoint to add:
// GET /v1/wallets/my/validate?amount=100.00
// Response: { "sufficient": true, "current_balance": 250.00, "required": 100.00 }
```

---

## Fix #4: Error Handling Pattern

### Before (BUGGY):
```dart
try {
  final deliveryFee = await _orderDataSource.getFareEstimateRaw(...);
  final normalizedFee = _normalizeDeliveryFee(deliveryFee);
} catch (_) {  // ❌ Catches everything
  if (state.order != null) {
    final updatedOrder = state.order!.copyWith(deliveryFee: 50.00);  // ❌ Hardcoded
  }
}
```

### After (FIXED):
```dart
Future<void> refreshDeliveryFee() async {
  if (state.order == null) return;
  
  state = state.copyWith(isLoadingFare: true, error: null);
  
  const maxRetries = 2;
  int retryCount = 0;
  
  while (retryCount <= maxRetries) {
    try {
      final deliveryFee = await _orderDataSource.getFareEstimateRaw(
        serviceId: 3, // LesEat
        estimatedDistanceM: state.estimatedDistanceM,
        pickupLat: state.pickupLat,
        pickupLng: state.pickupLng,
        dropoffLat: state.dropoffLat,
        dropoffLng: state.dropoffLng,
      );
      
      final normalizedFee = _normalizeDeliveryFee(deliveryFee);
      final updatedOrder = state.order!.copyWith(deliveryFee: normalizedFee);
      
      state = state.copyWith(
        order: updatedOrder,
        isLoadingFare: false,
      );
      
      AppLogger.info('Delivery fee updated: ₱$normalizedFee');
      return; // Success
      
    } on DioException catch (e) {
      AppLogger.warning('Fare estimation attempt ${retryCount + 1} failed', error: e);
      
      if (e.response?.statusCode == 401) {
        // Token expired - try refresh
        try {
          await ref.read(authProvider.notifier).refreshToken();
          retryCount++;
          continue; // Retry with new token
        } catch (refreshError) {
          state = state.copyWith(
            error: 'Session expired. Please login again.',
            isLoadingFare: false,
          );
          return;
        }
      }
      
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        if (retryCount < maxRetries) {
          retryCount++;
          await Future.delayed(Duration(seconds: retryCount * 2));
          continue; // Retry after delay
        }
        state = state.copyWith(
          error: 'Network timeout. Please check your connection.',
          isLoadingFare: false,
        );
        return;
      }
      
      // Other errors - don't retry
      state = state.copyWith(
        error: 'Unable to calculate delivery fee: ${e.message}',
        isLoadingFare: false,
      );
      return;
      
    } catch (e) {
      AppLogger.error('Fare estimation unexpected error', error: e);
      state = state.copyWith(
        error: 'Unexpected error calculating delivery fee',
        isLoadingFare: false,
      );
      return;
    }
  }
  
  // All retries exhausted
  state = state.copyWith(
    error: 'Failed to calculate delivery fee after $maxRetries attempts',
    isLoadingFare: false,
  );
}
```

---

## Fix #5: Tracking Null Return

### Before (BUGGY):
```dart
try {
  final response = await dio.get(ApiConstants.trackingLive(orderId));
  // Parse response
} catch (_) {
  return null;  // ❌ Can't tell what went wrong
}
```

### After (FIXED):
```dart
Future<TrackingData?> getOrderTracking(int orderId) async {
  try {
    final response = await dio.get(ApiConstants.trackingLive(orderId));
    
    if (response.data == null) {
      AppLogger.warning('Tracking response is null for order $orderId');
      return null;
    }
    
    if (response.data['success'] != true) {
      AppLogger.warning('Tracking not available: ${response.data['message']}');
      return null;
    }
    
    final data = response.data['data'];
    if (data == null) {
      AppLogger.info('No tracking data yet for order $orderId');
      return null; // Legitimate - order hasn't started tracking yet
    }
    
    return TrackingData.fromJson(data);
    
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) {
      AppLogger.info('Tracking not found for order $orderId (may not have started)');
      return null; // Legitimate - order doesn't have tracking yet
    }
    
    if (e.response?.statusCode == 401) {
      AppLogger.error('Auth error fetching tracking for order $orderId');
      throw UnauthorizedException('Please login again');
    }
    
    if (e.type == DioExceptionType.connectionTimeout) {
      AppLogger.error('Timeout fetching tracking for order $orderId');
      throw TimeoutException('Network timeout while fetching tracking');
    }
    
    AppLogger.error('Error fetching tracking for order $orderId', error: e);
    rethrow; // Let caller decide how to handle
  }
}

// Custom exceptions for better error handling:
class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
}
```

---

## Fix #6: WebSocket Polling Backoff

### Before (BUGGY):
```dart
_pollTimer = Timer.periodic(PollingIntervals.chatMessages, (_) {
  if (mounted && !ChatWebSocketService.instance.isConnected) {
    loadMessages(silent: true);  // ❌ Fixed interval forever
  }
});
```

### After (FIXED):
```dart
class ChatProvider extends StateNotifier<ChatState> {
  Timer? _pollTimer;
  int _consecutiveFailures = 0;
  static const _maxFailures = 5;
  static const _baseInterval = Duration(seconds: 5);
  
  void _startPolling() {
    _pollTimer?.cancel();
    _schedulePoll();
  }
  
  void _schedulePoll() {
    final interval = _calculateInterval();
    
    _pollTimer = Timer(interval, () async {
      if (!mounted || ChatWebSocketService.instance.isConnected) {
        return; // Stop polling
      }
      
      try {
        await loadMessages(silent: true);
        _consecutiveFailures = 0; // Reset on success
        _schedulePoll(); // Schedule next poll
        
      } catch (e) {
        _consecutiveFailures++;
        AppLogger.warning(
          'Chat polling failed (attempt $_consecutiveFailures/$_maxFailures)',
          error: e,
        );
        
        if (_consecutiveFailures >= _maxFailures) {
          // Circuit breaker - stop polling and notify user
          _stopPolling();
          state = state.copyWith(
            connectionStatus: ConnectionStatus.disconnected,
            error: 'Unable to connect to chat. Please check your connection.',
          );
          _showConnectionError();
        } else {
          // Exponential backoff and retry
          _schedulePoll();
        }
      }
    });
  }
  
  Duration _calculateInterval() {
    if (_consecutiveFailures == 0) {
      return _baseInterval; // 5 seconds
    }
    
    // Exponential backoff: 5s, 10s, 20s, 40s, 60s (max)
    final backoffSeconds = min(
      _baseInterval.inSeconds * pow(2, _consecutiveFailures),
      60,
    );
    
    return Duration(seconds: backoffSeconds.toInt());
  }
  
  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }
  
  void _showConnectionError() {
    // Show user-friendly error with retry option
    // This should be handled in the UI layer
    AppLogger.error('Chat connection failed after $_maxFailures attempts');
  }
  
  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}
```

---

## Fix #7: Location Accuracy Check

### Before (BUGGY):
```dart
if (position.accuracy > 50.0) {  // ❌ 50m is too lenient
  AppLogger.debug('⚠️ Skipping position with poor accuracy');
  return;
}
```

### After (FIXED):
```dart
Future<void> _updateLocation(Position position) async {
  // Check staleness first
  final age = DateTime.now().difference(position.timestamp);
  if (age > Duration(minutes: 2)) {
    AppLogger.warning(
      'Location is stale: ${age.inSeconds}s old, accuracy: ${position.accuracy}m'
    );
    state = state.copyWith(locationIsStale: true);
    return;
  }
  
  // Tiered accuracy system
  if (position.accuracy > 100.0) {
    AppLogger.error('GPS accuracy too poor: ${position.accuracy}m - discarding');
    state = state.copyWith(
      locationAccuracy: LocationAccuracy.poor,
      locationError: 'Poor GPS signal',
    );
    return;
  }
  
  LocationAccuracy accuracyLevel;
  if (position.accuracy <= 10.0) {
    accuracyLevel = LocationAccuracy.excellent;
  } else if (position.accuracy <= 20.0) {
    accuracyLevel = LocationAccuracy.good;
  } else if (position.accuracy <= 50.0) {
    accuracyLevel = LocationAccuracy.fair;
  } else {
    accuracyLevel = LocationAccuracy.poor;
    AppLogger.warning('GPS accuracy degraded: ${position.accuracy}m');
  }
  
  // Send to server with accuracy metadata
  try {
    await _driverLocationDataSource.updateLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      timestamp: position.timestamp.toIso8601String(),
    );
    
    state = state.copyWith(
      latitude: position.latitude,
      longitude: position.longitude,
      locationAccuracy: accuracyLevel,
      locationIsStale: false,
      locationError: null,
      lastLocationUpdate: DateTime.now(),
    );
    
    AppLogger.debug(
      'Location updated: ${position.latitude},${position.longitude} '
      '(accuracy: ${position.accuracy}m, level: $accuracyLevel)'
    );
    
  } catch (e) {
    AppLogger.error('Failed to send location update', error: e);
    state = state.copyWith(
      locationError: 'Failed to update location',
    );
  }
}

enum LocationAccuracy {
  excellent, // 0-10m
  good,      // 10-20m
  fair,      // 20-50m
  poor;      // 50-100m
  
  String get displayText {
    switch (this) {
      case LocationAccuracy.excellent:
        return 'Precise';
      case LocationAccuracy.good:
        return 'Accurate';
      case LocationAccuracy.fair:
        return 'Approximate';
      case LocationAccuracy.poor:
        return 'Poor Signal';
    }
  }
  
  Color get indicatorColor {
    switch (this) {
      case LocationAccuracy.excellent:
      case LocationAccuracy.good:
        return Colors.green;
      case LocationAccuracy.fair:
        return Colors.orange;
      case LocationAccuracy.poor:
        return Colors.red;
    }
  }
}
```

---

## Fix #8: Provider Disposal

### Before (BUGGY):
```dart
@override
void dispose() {
  _pollTimer?.cancel();
  _chatRealtime.removeListener(_realtimeRefresh);
  _chatRealtime.release();  // ❌ May not be initialized
  super.dispose();
}
```

### After (FIXED):
```dart
class ChatProvider extends StateNotifier<ChatState> {
  ChatProvider(this.ref) : super(ChatState()) {
    _initialize();
  }
  
  bool _initialized = false;
  Timer? _pollTimer;
  
  Future<void> _initialize() async {
    try {
      _chatRealtime = ref.read(chatRealtimeProvider);
      _chatRealtime.addListener(_realtimeRefresh);
      _initialized = true;
    } catch (e) {
      AppLogger.error('Failed to initialize chat provider', error: e);
      _initialized = false;
    }
  }
  
  @override
  void dispose() {
    // Cancel timer first
    _pollTimer?.cancel();
    _pollTimer = null;
    
    // Clean up realtime only if initialized
    if (_initialized) {
      try {
        _chatRealtime.removeListener(_realtimeRefresh);
        _chatRealtime.release();
      } catch (e) {
        AppLogger.warning('Error during chat provider disposal', error: e);
      }
    }
    
    super.dispose();
  }
}
```

---

## Testing Helpers

### 1. Mock Server Responses
```dart
// test/helpers/mock_responses.dart
class MockApiResponses {
  static Map<String, dynamic> orderWithInvalidPrice() => {
    'success': true,
    'data': {
      'id': 1,
      'total_amount': 'invalid',  // Should throw, not return 0.0
      'delivery_fee': null,
      // ...
    }
  };
  
  static Map<String, dynamic> walletInsufficientBalance() => {
    'success': false,
    'message': 'Insufficient balance',
    'data': {
      'current_balance': 25.00,
      'required': 100.00,
    }
  };
}
```

### 2. Integration Test
```dart
// integration_test/order_creation_test.dart
void main() {
  testWidgets('Order creation with wallet payment', (tester) async {
    // Setup
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();
    
    // Navigate to checkout
    // ...
    
    // Select wallet payment
    await tester.tap(find.text('Wallet'));
    await tester.pumpAndSettle();
    
    // Tap place order
    await tester.tap(find.text('Place Order'));
    await tester.pumpAndSettle();
    
    // Verify error message for insufficient balance
    expect(find.text('Insufficient wallet balance'), findsOneWidget);
  });
}
```

---

## Logging Setup

```dart
// lib/core/utils/app_logger.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class AppLogger {
  static void debug(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      debugPrint('🔵 DEBUG: $message');
      if (error != null) debugPrint('  Error: $error');
    }
  }
  
  static void info(String message) {
    debugPrint('ℹ️ INFO: $message');
    // Log to analytics
    FirebaseAnalytics.instance.logEvent(
      name: 'app_log_info',
      parameters: {'message': message},
    );
  }
  
  static void warning(String message, {Object? error}) {
    debugPrint('⚠️ WARNING: $message');
    if (error != null) debugPrint('  Error: $error');
    
    // Log to Crashlytics (non-fatal)
    FirebaseCrashlytics.instance.log('WARNING: $message');
    if (error != null) {
      FirebaseCrashlytics.instance.recordError(
        error,
        null,
        reason: message,
        fatal: false,
      );
    }
  }
  
  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    debugPrint('❌ ERROR: $message');
    if (error != null) debugPrint('  Error: $error');
    
    // Log to Crashlytics
    FirebaseCrashlytics.instance.log('ERROR: $message');
    if (error != null) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: message,
        fatal: false,
      );
    }
  }
}
```

---

## Last Updated
June 23, 2026
