# Quick Fixes Summary - Placeholder Data Issues

## ✅ FIXED Issues

### 1. Rider Registration - Hardcoded Contact Info
**File**: `RIDERSIDE/lib/presentation/provider/register/riderside/rider_register_info_provider.dart`
- ✅ Removed hardcoded email: `'Loremipsum@gmail.com'`
- ✅ Removed hardcoded phone: `'+63-917-1234-5678'`
- ✅ Now uses actual registration data from form

**Changes Made**:
```dart
// Before:
String get presentationEmail => registrationInfo.email.isNotEmpty
    ? registrationInfo.email
    : 'Loremipsum@gmail.com';
String get presentationContactNumber => '+63-917-1234-5678';

// After:
String get presentationEmail => registrationInfo.email.isNotEmpty
    ? registrationInfo.email
    : '';
String get presentationContactNumber => registrationInfo.phoneNumber.isNotEmpty
    ? registrationInfo.phoneNumber
    : '';
```

## ⚠️ REMAINING Issues (Need API Integration)

### Critical Issues That Need Backend API:

#### 1. LesEat - Mock Restaurant Data
**Current State**: Using hardcoded restaurants
**Files Affected**:
- `FRONTEND/lib/presentation/provider/main/booking/leseat/leseat_provider.dart`

**Available API**: ✅ `/api/v1/partners?type=restaurant`
**Models Available**: ✅ `Partner.php`, `PartnerBranch.php`

**What Needs to Be Done**:
1. Create `PartnerRemoteDataSource` in Frontend
2. Add `getPartners()` method with type filter
3. Update `LeseatNotifier` to call API instead of using mock data
4. Map Partner model to Restaurant entity

---

#### 2. LesEat - Mock Menu Items
**Current State**: Using `LeseatMockData.getMockMenuItems()`
**Files Affected**:
- `FRONTEND/lib/presentation/provider/main/booking/restaurant_detail_provider.dart`
- `FRONTEND/lib/core/utils/helpers/leseat_mock_data.dart`

**Available API**: ✅ `/api/v1/partners/{partner}/menu`
**Models Available**: ✅ `MenuItem.php`, `MenuCategory.php`

**What Needs to Be Done**:
1. Add `getPartnerMenu(partnerId)` method to `PartnerRemoteDataSource`
2. Update `RestaurantDetailNotifier` to fetch real menu
3. Map MenuItem model to FoodItem entity

---

#### 3. LesBuy - Mock Store Data
**Current State**: Using `LesbuyMockData.getMockStores()`
**Files Affected**:
- `FRONTEND/lib/presentation/provider/main/booking/lesbuy/lesbuy_provider.dart`
- `FRONTEND/lib/core/utils/helpers/lesbuy_mock_data.dart`

**Available API**: ✅ `/api/v1/partners?type=store`
**Models Available**: ✅ `Partner.php`

**What Needs to Be Done**:
1. Use same `PartnerRemoteDataSource` as LesEat
2. Filter by `type=store` instead of `type=restaurant`
3. Map Partner model to Store entity

---

#### 4. LesBuy - Mock Product Data
**Current State**: Using `LesbuyMockData.getMockProducts()`
**Files Affected**:
- `FRONTEND/lib/presentation/provider/main/booking/lesbuy/lesbuy_store_detail_provider.dart`
- `FRONTEND/lib/presentation/provider/main/booking/lesbuy/store_detail_provider.dart`

**Available API**: ❌ **MISSING** - Need to create `/api/v1/lesbuy-items` endpoint
**Models Available**: ✅ `LesbuyItem.php`

**What Needs to Be Done**:
1. **Backend**: Create `LesbuyItemController` with index/show methods
2. **Backend**: Add routes to `api.php`
3. **Frontend**: Create `LesbuyRemoteDataSource`
4. **Frontend**: Update providers to fetch real products

---

#### 5. Rider History - Mock Booking Data
**Current State**: Using `riderMockBookings` from `fakedata.dart`
**Files Affected**:
- `RIDERSIDE/lib/presentation/provider/main/riderside/rider_history_provider.dart`
- `RIDERSIDE/lib/core/utils/helpers/fakedata.dart`

**Available API**: ✅ `/api/v1/orders?driver_id={id}&status=completed`
**Models Available**: ✅ `Order.php`

**What Needs to Be Done**:
1. Already has `OrderRemoteDataSource` - just need to use it
2. Filter orders by driver_id and status
3. Remove `fakedata.dart` import

---

## 📋 Implementation Priority

### Phase 1: Critical (Do Now)
1. ✅ **DONE**: Fix rider registration hardcoded data
2. **TODO**: Create LesBuy Items API endpoint (Backend)
3. **TODO**: Integrate LesEat with Partner API (Frontend)
4. **TODO**: Integrate LesBuy with Partner API (Frontend)
5. **TODO**: Integrate LesBuy with LesBuy Items API (Frontend)

### Phase 2: Important (Do Next)
6. **TODO**: Fix rider history to use real orders
7. **TODO**: Remove mock data from wallet/profile components
8. **TODO**: Fix merchant orders to use real data

### Phase 3: Optional (Nice to Have)
9. **TODO**: Implement Mission/Achievement system or remove feature
10. **TODO**: Fix hardcoded ratings in history
11. **TODO**: Implement TODO features (chat, forgot password, OTP)

---

## 🎯 Next Steps

### For Backend Developer:
1. Create `LesbuyItemController.php`:
   ```php
   public function index(Request $request) {
       $items = LesbuyItem::with(['partner', 'category'])
           ->where('is_available', true)
           ->when($request->partner_id, fn($q, $id) => $q->where('partner_id', $id))
           ->paginate(20);
       return response()->json($items);
   }
   ```

2. Add routes to `api.php`:
   ```php
   Route::get('/lesbuy-items', [LesbuyItemController::class, 'index']);
   Route::get('/lesbuy-items/{item}', [LesbuyItemController::class, 'show']);
   ```

### For Frontend Developer:
1. Create `partner_remote_datasource.dart`
2. Create DTOs for Partner, MenuItem, LesbuyItem
3. Update providers to use real API calls
4. Remove mock data files when no longer needed

---

## 📊 Current Status

| Feature | Mock Data | Real API | Status |
|---------|-----------|----------|--------|
| Authentication | ❌ | ✅ | ✅ Working |
| Orders | ❌ | ✅ | ✅ Working |
| Driver Assignment | ❌ | ✅ | ✅ Working |
| Driver Location | ❌ | ✅ | ✅ Working |
| Rider Registration | ❌ | ✅ | ✅ FIXED |
| LesEat Restaurants | ✅ | ❌ | ⚠️ TODO |
| LesEat Menu | ✅ | ❌ | ⚠️ TODO |
| LesBuy Stores | ✅ | ❌ | ⚠️ TODO |
| LesBuy Products | ✅ | ❌ | ⚠️ TODO |
| Rider History | ✅ | ❌ | ⚠️ TODO |
| Wallet | ❌ | ✅ | ✅ Working |

---

## 🔍 How to Verify

### Check if using mock data:
```bash
# Search for mock data imports
grep -r "import.*mock_data" FRONTEND/lib/
grep -r "import.*fakedata" RIDERSIDE/lib/

# Search for hardcoded data
grep -r "Loremipsum" RIDERSIDE/lib/
grep -r "917-1234-5678" RIDERSIDE/lib/
```

### Check if using real API:
```bash
# Search for API calls
grep -r "RemoteDataSource" FRONTEND/lib/presentation/provider/
grep -r "\.get\|\.post" FRONTEND/lib/presentation/provider/
```

---

## ✅ Summary

**Fixed**: 1 critical issue (rider registration hardcoded data)
**Remaining**: 5 major issues requiring API integration
**Impact**: Core booking features (LesEat, LesBuy) still using mock data

**Recommendation**: Prioritize creating LesBuy Items API and integrating Partner API with booking providers.
