# RIDER FEATURES - NEXT STEPS FOR INTEGRATION

**Date**: June 17, 2026  
**Status**: 🟡 Awaiting Integration  
**Feature Branch**: Bug_Fix (commit ae4a8ce)

---

## SUMMARY

The Quick Stats Dashboard and Wallet & Payout features are now fully implemented and routed. They're ready to be integrated into the rider app's existing navigation and UI flows.

---

## IMMEDIATE NEXT STEPS

### 1. ✅ COMPLETED: Core Implementation
- [x] Quick Stats Dashboard provider & screen
- [x] Wallet & Payout provider & screen
- [x] Route constants defined
- [x] Routes registered in router
- [x] APK builds successfully

### 2. 🔲 TODO: Add Navigation Buttons

The new screens won't be accessible until we add navigation buttons in existing screens.

**Where to Add Buttons**:

#### Option A: Rider Profile Screen
- Add "Quick Stats" button in earnings section
- Add "Wallet & Payouts" button in payment section

**File**: `RIDERSIDE/lib/presentation/screens/main/riderside/views/rider_profile_view.dart` (or similar)

**Navigation Code Example**:
```dart
ElevatedButton(
  onPressed: () => Navigator.pushNamed(context, MainRoutes.riderQuickStats),
  child: const Text('View Today\'s Stats'),
),

ElevatedButton(
  onPressed: () => Navigator.pushNamed(context, MainRoutes.riderPayout),
  child: const Text('Wallet & Payouts'),
),
```

#### Option B: Rider Dashboard/Home Screen
- Add card in main dashboard for quick stats
- Add section for wallet balance

**File**: Identify the rider home/dashboard screen and add cards

#### Option C: Add Tab Navigation
- Add new tab in bottom navigation for earnings/stats
- Or add tab within existing profile/earnings section

---

### 3. 🔲 TODO: Verify Backend APIs

The providers make calls to these endpoints. **Verify they exist on the backend**:

#### Quick Stats Provider Endpoints
```
GET /v1/drivers/me/earnings?period=today
GET /v1/drivers/me/earnings?period=week
GET /v1/drivers/me/earnings?period=month
GET /v1/drivers/me/earnings?period=all
```

**Expected Response Format**:
```json
{
  "data": {
    "today_earnings": 2500.50,
    "trips_completed": 8,
    "online_hours": 6.5,
    "weekly_breakdown": [
      { "day": "Mon", "earnings": 1800 },
      { "day": "Tue", "earnings": 2100 },
      ...
    ]
  }
}
```

#### Payout Provider Endpoints
```
GET /v1/wallets/my/wallet
GET /v1/wallets/my/payouts
POST /v1/wallets/my/withdraw
POST /v1/wallets/my/linked-accounts
```

**GET /v1/wallets/my/wallet Response**:
```json
{
  "data": {
    "balance": 15500.00,
    "pending_balance": 5200.00
  }
}
```

**GET /v1/wallets/my/payouts Response**:
```json
{
  "data": [
    {
      "id": "payout_123",
      "amount": 5000.00,
      "status": "completed",
      "payment_method": "gcash",
      "account_number": "09175551234",
      "requested_at": "2026-06-15T10:30:00Z",
      "completed_at": "2026-06-16T14:45:00Z"
    },
    ...
  ]
}
```

**POST /v1/wallets/my/withdraw Request**:
```json
{
  "amount": 5000.00,
  "payment_method": "gcash",
  "account_number": "09175551234"
}
```

---

### 4. 🔲 TODO: Test API Integration

Once APIs are verified:

```bash
# Clear build cache
flutter clean

# Run the app
flutter run

# Test flows:
# 1. Navigate to Quick Stats Dashboard
#    - Verify earnings display
#    - Verify weekly trend chart loads
#    - Test pull-to-refresh
#
# 2. Navigate to Wallet & Payouts
#    - Verify balance displays
#    - Test withdrawal flow
#    - Verify payout history loads
#    - Test status indicators
```

---

### 5. 🔲 TODO: Handle Edge Cases

Test these scenarios:

**Quick Stats**:
- [ ] No earnings data (zero earnings day)
- [ ] Partial week data (first days of week)
- [ ] Network error during load
- [ ] Null/empty API response

**Wallet & Payouts**:
- [ ] Zero balance
- [ ] Only pending balance
- [ ] No payout history
- [ ] Invalid withdrawal amounts
- [ ] Duplicate withdrawal attempts
- [ ] Failed withdrawal status

---

## CODE LOCATIONS FOR REFERENCE

**New Routes** (Navigation endpoints):
```
MainRoutes.riderQuickStats = '/rider/quick-stats'
MainRoutes.riderPayout = '/rider/payout'
```

**Location**: `RIDERSIDE/lib/core/constants/routers/main/main_routes.dart`

**Screen Implementation**:
```
Quick Stats: RIDERSIDE/lib/presentation/screens/main/riderside/rider_quick_stats_screen.dart
Payouts: RIDERSIDE/lib/presentation/screens/main/riderside/rider_payout_screen.dart
```

**Provider Implementation**:
```
Stats: RIDERSIDE/lib/presentation/provider/main/riderside/rider_stats_provider.dart
Payouts: RIDERSIDE/lib/presentation/provider/main/riderside/rider_payout_provider.dart
```

---

## SAMPLE NAVIGATION IMPLEMENTATION

### In a Rider Profile/Dashboard Screen

```dart
// Import route constants
import '../../../../core/constants/routers/main/main_routes.dart';

// In your build method, add these widgets:

// Quick Stats Card
Card(
  child: ListTile(
    leading: const Icon(Icons.trending_up),
    title: const Text('Today\'s Stats'),
    subtitle: const Text('View earnings & performance'),
    trailing: const Icon(Icons.arrow_forward),
    onTap: () => Navigator.pushNamed(context, MainRoutes.riderQuickStats),
  ),
),

// Wallet & Payouts Card
Card(
  child: ListTile(
    leading: const Icon(Icons.wallet),
    title: const Text('Wallet & Payouts'),
    subtitle: const Text('Manage withdrawals'),
    trailing: const Icon(Icons.arrow_forward),
    onTap: () => Navigator.pushNamed(context, MainRoutes.riderPayout),
  ),
),
```

---

## TESTING SCENARIOS

### Quick Stats Dashboard
1. **First Load**: Should show loading spinner
2. **Success**: Display earnings, trips, hours, weekly chart
3. **Error**: Show error message with retry button
4. **Refresh**: Pull-to-refresh should reload data
5. **Empty Data**: Handle zero earnings gracefully

### Wallet & Payouts
1. **Load Balance**: Display available and pending amounts
2. **Withdrawal Flow**:
   - Click withdraw button
   - Enter amount (validate min/max)
   - Select payment method
   - Enter account number
   - Submit and wait for confirmation
3. **History**: Display past withdrawals with status
4. **Status Updates**: Show pending/processing/completed/failed

---

## MOCK DATA (FOR TESTING WITHOUT BACKEND)

If backend is not ready yet, you can use mock data by modifying the providers:

### Mock Stats Data
```dart
// In rider_stats_provider.dart, in the loadData() method:
state = state.copyWith(
  todayEarnings: 2500.50,
  tripsCompleted: 8,
  onlineHours: 6.5,
  weeklyEarnings: [1800, 2100, 1950, 2200, 2500, 1800, 1900],
  isLoading: false,
);
```

### Mock Payout Data
```dart
// In rider_payout_provider.dart, in loadPayoutData() method:
state = state.copyWith(
  availableBalance: 15500.0,
  pendingBalance: 5200.0,
  isLoading: false,
);
```

---

## CHECKLIST FOR INTEGRATION

- [ ] Backend APIs verified
- [ ] API response formats confirmed
- [ ] Navigation buttons added to UI
- [ ] Routes accessible from app
- [ ] Screens load without errors
- [ ] Data displays correctly
- [ ] Error handling tested
- [ ] Refresh functionality works
- [ ] Withdrawal flow tested
- [ ] Status indicators display correctly
- [ ] Pull-to-refresh works
- [ ] Navigation back button works
- [ ] Responsive design verified on different screen sizes
- [ ] Performance acceptable (no lag)
- [ ] Error messages clear and helpful

---

## POTENTIAL ISSUES & SOLUTIONS

### Issue: Routes not accessible
**Solution**: Check `main_router.dart` - ensure routes are in `_routes` map

### Issue: Data not loading
**Solution**: Verify API endpoints exist, check network logs, enable debug logging

### Issue: Withdrawal fails
**Solution**: Validate account number format, check payment method availability

### Issue: Screen appears blank
**Solution**: Check for null values in data, verify AsyncValue handling

---

## ESTIMATED EFFORT

- **Navigation Integration**: 1-2 hours
- **API Verification**: 1-2 hours
- **Testing & Bug Fixes**: 2-3 hours
- **Total**: 4-7 hours

---

## ROLLBACK PLAN

If issues occur, you can safely revert by:

```bash
git checkout <previous-commit-hash>
```

Current features are isolated and don't affect existing functionality.

---

## QUESTIONS & SUPPORT

For issues, check:
1. Backend API documentation
2. Provider error logs (use AppLogger)
3. Navigator console for routing errors
4. Network tab in debug tools

---

**Status**: Ready for integration team  
**Last Updated**: June 17, 2026  
**Commit**: ae4a8ce
