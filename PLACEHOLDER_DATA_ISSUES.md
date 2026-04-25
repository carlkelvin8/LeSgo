# Placeholder Data & Mock Data Issues

## 🔴 Critical Issues (Affecting Core Functionality)

### 1. ❌ FIXED: Rider Registration - Hardcoded Contact Info
**File**: `RIDERSIDE/lib/presentation/provider/register/riderside/rider_register_info_provider.dart`
- ~~Line 103: `'Loremipsum@gmail.com'` - Hardcoded email placeholder~~
- ~~Line 106: `'+63-917-1234-5678'` - Hardcoded phone number~~
- **Status**: ✅ FIXED - Now uses actual registration data

### 2. ⚠️ LesEat - Using Mock Restaurant Data
**File**: `FRONTEND/lib/presentation/provider/main/booking/leseat/leseat_provider.dart`
- Lines 26-85: Hardcoded restaurant list
- Restaurants: "Bella Italia Pizzeria", "Jollibee - Claveria", "Sun Sets Cafe"
- **Impact**: Not showing real restaurants from database
- **Fix Needed**: Integrate with Partner API (`/api/v1/partners`)

### 3. ⚠️ LesEat - Mock Menu Items
**File**: `FRONTEND/lib/presentation/provider/main/booking/restaurant_detail_provider.dart`
- Lines 86-94: Using `LeseatMockData.getMockMenuItems()`
- **Impact**: Not showing real menu items from database
- **Fix Needed**: Integrate with Menu Items API (`/api/v1/partners/{id}/menu-items`)

### 4. ⚠️ LesBuy - Mock Store Data
**File**: `FRONTEND/lib/presentation/provider/main/booking/lesbuy/lesbuy_provider.dart`
- Line 18: Using `LesbuyMockData.getMockStores()`
- **Impact**: Not showing real stores from database
- **Fix Needed**: Integrate with Partner API filtered by type

### 5. ⚠️ LesBuy - Mock Product Data
**Files**: 
- `FRONTEND/lib/presentation/provider/main/booking/lesbuy/lesbuy_store_detail_provider.dart` (Line 65)
- `FRONTEND/lib/presentation/provider/main/booking/lesbuy/store_detail_provider.dart` (Line 69)
- **Impact**: Not showing real products from database
- **Fix Needed**: Integrate with LesBuy Items API (`/api/v1/lesbuy-items`)

## 🟡 Medium Priority Issues

### 6. Rider Side - Mock Booking History
**File**: `RIDERSIDE/lib/presentation/provider/main/riderside/rider_history_provider.dart`
- Line 3: Imports `fakedata.dart`
- Using `riderMockBookings` for history
- **Fix Needed**: Integrate with Orders API (`/api/v1/orders?driver_id={id}`)

### 7. Rider Side - Mock Mission Data
**Files**:
- `RIDERSIDE/lib/presentation/screens/main/riderside/views/rider_mission_view.dart` (Line 4)
- `RIDERSIDE/lib/presentation/screens/main/merchantside/views/merchant_mission_view.dart` (Line 4)
- Using `riderMissions` from `fakedata.dart`
- **Fix Needed**: Create Missions/Achievements API or remove feature

### 8. Rider Side - Mock Wallet Data
**File**: `RIDERSIDE/lib/presentation/widgets/main/riderside/wallet/rider_wallet_card.dart`
- Line 4: Imports `fakedata.dart`
- **Fix Needed**: Already has API integration, just remove mock import

### 9. Merchant Side - Mock Orders
**File**: `RIDERSIDE/lib/presentation/provider/main/merchantside/merchant_orders_provider.dart`
- Line 2: Imports `fakedata.dart`
- Using mock merchant orders
- **Fix Needed**: Integrate with Orders API filtered by partner

### 10. Rider Profile - Mock Data
**Files**:
- `RIDERSIDE/lib/presentation/screens/main/riderside/views/rider_profile_view.dart`
- `RIDERSIDE/lib/presentation/widgets/main/riderside/profile/rider_profile_info_section.dart`
- Using `fakedata.dart` for profile display
- **Fix Needed**: Use real user data from auth state

## 🟢 Low Priority Issues (UI/Demo Features)

### 11. Hardcoded Rating in History Detail
**File**: `RIDERSIDE/lib/presentation/screens/main/riderside/rider_history_detail_screen.dart`
- Line 37: `rating: 5` - Hardcoded rating
- **Fix**: Use actual order rating from API

### 12. TODO Comments (Not Implemented Features)
- Chat functionality (LesRide tracking)
- Forgot password (Rider & Merchant login)
- OTP verification (Registration)
- FCM Push Notifications
- SSL Certificate Pinning
- Payment integration

## 📊 Mock Data Files to Review

### Core Mock Data Files:
1. `RIDERSIDE/lib/core/utils/helpers/fakedata.dart`
   - Contains: `riderMockBookings`, `riderMissions`, mock profile data
   
2. `FRONTEND/lib/core/utils/helpers/leseat_mock_data.dart`
   - Contains: Menu categories, menu items for restaurants
   
3. `FRONTEND/lib/core/utils/helpers/lesbuy_mock_data.dart`
   - Contains: Stores, products, categories

## ✅ Already Using Real Data

### Working API Integrations:
1. ✅ **Authentication** - Login/Register using real API
2. ✅ **Orders** - Create, list, update orders from database
3. ✅ **Driver Assignment** - Real driver assignment via queue
4. ✅ **Driver Location** - Real-time location updates
5. ✅ **Rider Orders** - Fetching real orders for riders
6. ✅ **Wallet** - Real wallet balance from database
7. ✅ **User Profile** - Real user data from auth

## 🎯 Recommended Fix Priority

### Phase 1 (Critical - Do First):
1. ✅ Fix hardcoded rider registration data (DONE)
2. Integrate LesEat with real Partner/Restaurant API
3. Integrate LesEat menu items with real Menu Items API
4. Integrate LesBuy with real Partner/Store API
5. Integrate LesBuy products with real LesBuy Items API

### Phase 2 (Important):
6. Fix rider history to use real orders
7. Fix merchant orders to use real data
8. Remove mock data imports from wallet/profile components

### Phase 3 (Nice to Have):
9. Implement or remove Mission/Achievement feature
10. Fix hardcoded ratings
11. Implement TODO features (chat, forgot password, etc.)

## 🛠️ How to Fix

### Example: Converting LesEat to Real API

**Current (Mock)**:
```dart
static final List<Restaurant> _defaultRestaurants = [
  Restaurant(id: '1', name: 'Bella Italia', ...),
  // ...
];
```

**Should Be (Real API)**:
```dart
Future<void> loadRestaurants() async {
  state = state.copyWith(isLoading: true);
  try {
    final response = await _partnerDataSource.getPartners(
      type: 'restaurant',
      status: 'active',
    );
    final restaurants = response.data.map((p) => 
      Restaurant.fromPartner(p)
    ).toList();
    state = state.copyWith(
      restaurants: restaurants,
      filteredRestaurants: restaurants,
      isLoading: false,
    );
  } catch (e) {
    state = state.copyWith(error: e.toString(), isLoading: false);
  }
}
```

## 📝 Notes

- Most core functionality (orders, drivers, auth) is already using real data
- Main issue is the booking screens (LesEat, LesBuy) still using mock data
- Rider side has more mock data usage than customer side
- Some features (missions, achievements) may need to be removed if not in scope
