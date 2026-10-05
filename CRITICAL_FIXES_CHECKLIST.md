# Critical Fixes Checklist - Quick Reference

## 🚨 TOP 5 MUST-FIX IMMEDIATELY

### 1. ✅ Silent Pricing Errors
**File:** `FRONTEND/lib/data/data_source/dto/order/order_dto.dart`
**Line:** 10-32
**Action:** Add exception throwing for critical price fields
```dart
// Change _parseDouble to throw on failure for price fields
// Add logging for all parse failures
```

### 2. ✅ Chat Endpoints Broken
**File:** `FRONTEND/lib/data/data_source/chat_remote_datasource.dart`
**Lines:** 27, 39, 55
**Action:** Replace `.replaceAll()` with proper path building
```dart
// Convert ApiConstants to use functions instead of string templates
static String chatConversationByOrder(int orderId) => 
    '/v1/chat/conversations/order/$orderId';
```

### 3. ✅ Wallet Payment Race Condition
**File:** `FRONTEND/lib/presentation/provider/main/booking/checkout_provider.dart`
**Line:** 408-433
**Action:** Implement atomic balance check-and-reserve
```dart
// Add wallet.reserveBalance() endpoint
// Remove dual fetch-then-refresh pattern
```

### 4. ✅ Wrong Distance Pricing
**File:** `FRONTEND/lib/presentation/provider/main/booking/checkout_provider.dart`
**Line:** 143-156
**Action:** Use Google Maps route distance instead of Haversine
```dart
// Remove .clamp(500, 25000)
// Use route.distance from Directions API
```

### 5. ✅ Error Swallowing in Fare Estimation
**File:** `FRONTEND/lib/presentation/provider/main/booking/checkout_provider.dart`
**Line:** 157-171
**Action:** Add specific error handling and retry logic
```dart
// Don't catch all with catch (_)
// Add DioException handling with retry
```

---

## 📋 TESTING BEFORE DEPLOYMENT

### Order Creation
```bash
# Test these scenarios:
□ Create order with wallet payment (exact balance)
□ Create order with wallet payment (insufficient)
□ Create order with 100m distance
□ Create order with 50km distance
□ Create order during network timeout
□ Verify fare matches backend calculation
```

### Chat
```bash
□ Send message in active order
□ Send message with WebSocket disconnected
□ Verify chat history loads
□ Test mark-as-read functionality
```

### Location Tracking
```bash
□ Rider location updates every 5-10 seconds
□ Customer sees accurate rider position
□ Driver offline status reflects correctly
□ Location accuracy shown in UI
```

---

## 🛠️ DEVELOPMENT STANDARDS (Going Forward)

### 1. Error Handling Rules
```dart
// ✅ DO: Specific error types
on DioException catch (e) {
  if (e.response?.statusCode == 401) {
    // Handle auth error
  } else if (e.type == DioExceptionType.connectionTimeout) {
    // Handle timeout
  }
}

// ❌ DON'T: Catch all
catch (_) {
  // Silent failure
}
```

### 2. API Call Pattern
```dart
// ✅ DO: With logging and retry
Future<T> apiCall<T>() async {
  try {
    final response = await dio.get(endpoint);
    AppLogger.info('API success: $endpoint');
    return parse(response);
  } on DioException catch (e) {
    AppLogger.error('API failed: $endpoint', error: e);
    if (shouldRetry(e)) {
      await Future.delayed(retryDelay);
      return apiCall(); // Retry once
    }
    rethrow;
  }
}
```

### 3. Data Parsing Pattern
```dart
// ✅ DO: With validation
double parsePrice(dynamic value, String fieldName) {
  if (value == null) {
    throw Exception('Required field $fieldName is null');
  }
  if (value is num) return value.toDouble();
  if (value is String) {
    final parsed = double.tryParse(value);
    if (parsed == null) {
      AppLogger.error('Invalid price: $fieldName = $value');
      throw Exception('Invalid price format: $fieldName');
    }
    return parsed;
  }
  throw Exception('Unexpected type for $fieldName');
}
```

### 4. State Management Pattern
```dart
// ✅ DO: With loading states
Future<void> loadData() async {
  state = state.copyWith(isLoading: true, error: null);
  try {
    final data = await fetchData();
    state = state.copyWith(data: data, isLoading: false);
  } catch (e) {
    state = state.copyWith(
      error: e.toString(), 
      isLoading: false,
    );
    AppLogger.error('Load failed', error: e);
  }
}
```

---

## 🔍 CODE REVIEW CHECKLIST

Before merging any PR, verify:

### Error Handling
- [ ] No `catch (_)` or `catch (e) {}` without logging
- [ ] All API calls have specific error handling
- [ ] Network errors show user-friendly messages
- [ ] Errors logged with context

### Data Validation
- [ ] All price fields validated (no silent 0.0)
- [ ] Required fields throw if null/invalid
- [ ] Optional fields have safe defaults
- [ ] Type conversions are safe

### API Integration
- [ ] Endpoint URLs match backend routes
- [ ] Request/response DTOs match backend
- [ ] Auth token included in headers
- [ ] Retry logic for transient failures

### State Management
- [ ] Loading states set before async calls
- [ ] Error states handle all failure paths
- [ ] Race conditions avoided (no parallel state mutations)
- [ ] Providers disposed properly

### Testing
- [ ] Unit tests for data parsing
- [ ] Integration tests for API calls
- [ ] E2E tests for critical flows
- [ ] Error cases tested

---

## 📞 ESCALATION PATH

If you encounter these during development:

### 🔴 Critical Issues (Stop Development)
- Data corruption in production
- Payment processing failures
- Security vulnerabilities
- Complete feature outages

**Action:** Alert team lead immediately

### 🟡 Blocking Issues (Need Help)
- API contract mismatches
- Complex race conditions
- Performance degradation
- Unclear requirements

**Action:** Request pair programming session

### 🟢 Questions (Document and Continue)
- Code style preferences
- Architecture decisions
- Testing strategies

**Action:** Document decision and proceed

---

## 📚 REFERENCE DOCS

### Backend API
- Endpoint documentation: `BACKEND/lesgo-api/routes/api.php`
- Controllers: `BACKEND/lesgo-api/app/Http/Controllers/Api/`
- Models: `BACKEND/lesgo-api/app/Models/`

### Frontend
- API constants: `FRONTEND/lib/core/constants/api_constants.dart`
- DTOs: `FRONTEND/lib/data/data_source/dto/`
- Providers: `FRONTEND/lib/presentation/provider/`

### Common Patterns
- Error handling: See `api_error_mapper.dart`
- Data parsing: See `order_dto.dart` (after fixes)
- State management: See `checkout_provider.dart` (after fixes)

---

## 🎯 SUCCESS METRICS

Track these after fixes:

### Error Rates
- API error rate < 1%
- Parse error rate = 0%
- Payment failure rate < 0.5%

### Performance
- P95 API latency < 500ms
- App crash rate < 0.1%
- ANR rate < 0.05%

### User Experience
- Order completion rate > 95%
- Chat message delivery success > 99%
- Location accuracy within 20m for 90% of updates

---

## 💡 TIPS

1. **Always test with production-like data**
   - Include null values, empty strings, malformed data
   - Test with slow network (use Chrome DevTools throttling)

2. **Use type-safe parsing libraries**
   - Consider `freezed` for immutable DTOs
   - Use `json_serializable` correctly

3. **Log everything (with levels)**
   ```dart
   AppLogger.debug('User flow step');    // Development only
   AppLogger.info('API success');         // Production
   AppLogger.warning('Degraded state');   // Production
   AppLogger.error('Failure', error: e);  // Production + alert
   ```

4. **Write tests first for bug fixes**
   - Reproduce the bug in a test
   - Fix the code
   - Verify test passes

5. **Monitor production**
   - Set up Firebase Crashlytics
   - Add custom error logging
   - Create dashboards for key metrics

---

## Last Updated
June 23, 2026

## Next Review
After critical fixes deployed (1-2 weeks)
