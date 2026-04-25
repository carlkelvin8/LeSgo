# Rider Booking Process - Quick Reference

## 🎯 Complete Flow with Real API Data

### 1️⃣ **View Available Orders**
```
Screen: rider_bookings_view.dart
Widget: rider_bookings_list.dart
API: GET /api/v1/orders?per_page=50
```

**Shows:**
- All pending orders (status: 'pending' or 'searching_driver')
- No driver assigned yet (driverId: null)
- Auto-refreshes every 10 seconds

**Data Displayed:**
- Service name (LesEat, LesBuy, LesRide)
- Pickup address
- Dropoff address
- Distance (km)
- Fare (PHP)
- Payment method

---

### 2️⃣ **Accept Order**
```
Action: Tap "Accept Order" button
API: PUT /api/v1/orders/{id}/status
Body: { "status": "accepted" }
```

**Backend Process:**
1. Validates driver authentication
2. Checks order availability
3. Updates status to 'accepted'
4. Assigns driver_id to current driver
5. Sends notification to customer

**UI Update:**
- Order removed from available list
- Order added to active order (green card at top)
- Success message shown

---

### 3️⃣ **View Active Order Details**
```
Screen: rider_booking_detail_screen.dart
Widgets: 
  - rider_booking_detail_info.dart (order info)
  - rider_booking_status_grid.dart (status buttons)
```

**Shows:**
- Restaurant/Store logo
- Booking info (address)
- Billing (amount + method)
- Status buttons grid (service-specific)

**Status Workflows:**

**LesEat (serviceId: 3):**
```
Pending → Cooking → For Pick Up → For Delivery → Delivered
```

**LesBuy (serviceId: 4):**
```
Pending → To Buy → For Delivery → Delivered
```

**LesRide (serviceId: 2):**
```
On The Way → On The Way (Going) → Driver Arrived → In Progress → Complete
```

---

### 4️⃣ **Update Order Status**
```
Action: Tap status button
API: PUT /api/v1/orders/{id}/status
```

**Status Mappings:**

| UI Button | API Status | Description |
|-----------|-----------|-------------|
| For Pick Up | picked_up | Ready to collect |
| On The Way | picked_up | Going to pickup |
| For Delivery | picked_up | On way to customer |
| Delivered | completed | Order delivered |
| Complete | completed | Trip finished |

**Implementation:**
```dart
// Mark as picked up
await markPickedUp(orderId);
// API: PUT /api/v1/orders/{id}/status with status: 'picked_up'

// Mark as completed
await markCompleted(orderId);
// API: PUT /api/v1/orders/{id}/status with status: 'completed'
// → Removes from active order
// → Moves to history
// → Navigates back to main screen
```

---

### 5️⃣ **Map View (Waze-style)**
```
Screen: rider_bookings_map_view.dart
Features: Google Maps + Real-time tracking
```

**Markers:**
- 🔵 **Blue** = Your current location
- 🟢 **Green** = Active order pickup
- 🔴 **Red** = Active order dropoff
- 🟠 **Orange** = Available orders (first 5)

**Location Updates:**
```dart
// Every 30 seconds
API: PUT /api/v1/driver-profiles/{id}/location
Body: { "latitude": lat, "longitude": lng }
```

**Features:**
- Tap marker → Show info window
- Navigation button → Opens Google Maps
- Draggable bottom sheet with order list
- Accept orders directly from map

---

### 6️⃣ **View History**
```
Screen: rider_history_view.dart
Provider: rider_history_provider.dart
API: GET /api/v1/orders?per_page=100
```

**Filters:**
- All orders
- Completed (status: 'completed')
- Processing (status: 'picked_up')
- Cancelled (status: 'cancelled')

**Analytics:**
- Total bookings count
- Performance stars (based on completion rate)
- Chart showing order distribution

**Performance Stars:**
```
≥95% completion = 5 stars ⭐⭐⭐⭐⭐
≥85% completion = 4 stars ⭐⭐⭐⭐
≥75% completion = 3 stars ⭐⭐⭐
≥60% completion = 2 stars ⭐⭐
<60% completion = 1 star  ⭐
```

---

## 📊 Data Models

### RiderOrder (from API)
```dart
{
  id: 406,
  serviceId: 3,                    // 1=LesGo, 2=LesRide, 3=LesEat, 4=LesBuy
  status: "accepted",              // pending, accepted, picked_up, completed
  pickupAddress: "Jollibee, Manila",
  pickupLat: 14.5995,
  pickupLng: 120.9842,
  dropoffAddress: "Customer Home",
  dropoffLat: 14.6042,
  dropoffLng: 120.9822,
  estimatedFare: 340.00,
  estimatedDistanceM: 5000,        // 5 km
  paymentMethod: "cash",
  notes: "Extra rice please",
  driverId: 74
}
```

### RiderBooking (UI Entity)
```dart
{
  id: "406",
  restaurantName: "LesEat",
  address: "Customer Home",
  pickupAddress: "Jollibee, Manila",
  deliveryAddress: "Customer Home",
  distance: "5.0 km",
  estimatedTime: "10 min",
  earnings: "PHP 340.00",
  paymentMethod: "CASH",
  billingAmount: "PHP 340.00",
  billingMethod: "Cash on Delivery",
  category: BookingCategory.lesEat,
  currentStatus: BookingStatus.cooking
}
```

---

## 🔄 Auto-Refresh System

### Orders Refresh
```dart
Timer.periodic(Duration(seconds: 10), (_) {
  loadOrders(silent: true);  // Background refresh
});
```

### Location Updates
```dart
Timer.periodic(Duration(seconds: 30), (_) {
  _getCurrentLocation();
  _sendLocationToBackend(position);
});
```

---

## 🎨 UI Components

### Available Order Card
```
┌─────────────────────────────────┐
│ [LesEat] Order #406  PHP 340.00 │
│ 📏 5.0 km  💳 CASH              │
│ 📍 Jollibee, Manila             │
│ 🚩 Customer Home                │
│ [Accept Order Button]           │
└─────────────────────────────────┘
```

### Active Order Card (Green)
```
┌─────────────────────────────────┐
│ [ACTIVE] Order #406  PHP 340.00 │
│ 📍 Jollibee, Manila             │
│ 🚩 Customer Home                │
│ [View Details & Track Button]   │
└─────────────────────────────────┘
```

### Status Grid (LesEat)
```
┌──────────┬──────────┐
│ Cooking  │ For      │
│ (Active) │ Pickup   │
├──────────┼──────────┤
│ For      │ Delivered│
│ Delivery │          │
└──────────┴──────────┘
```

---

## 🚀 Testing

### Test Account
```
Email: testrider@lesgo.com
Password: password
Driver Profile ID: 74
```

### Test Flow
1. ✅ Login as test rider
2. ✅ View available orders (auto-refreshing)
3. ✅ Accept an order
4. ✅ View order details
5. ✅ Update status (picked_up)
6. ✅ Update status (completed)
7. ✅ View in history

### Create Test Order (Customer Side)
1. Login as customer (testcustomer@lesgo.com)
2. Create LesEat/LesBuy/LesRide order
3. Order appears in rider's available list within 10 seconds
4. Rider accepts → Customer sees driver assigned
5. Rider updates status → Customer sees real-time updates

---

## 📁 Key Files

### Screens
- `rider_bookings_view.dart` - Main bookings tab
- `rider_bookings_map_view.dart` - Map view
- `rider_booking_detail_screen.dart` - Order details
- `rider_history_detail_screen.dart` - History details

### Widgets
- `rider_bookings_list.dart` - Orders list
- `rider_booking_card.dart` - Order card
- `rider_booking_detail_info.dart` - Order info
- `rider_booking_status_grid.dart` - Status buttons grid
- `rider_booking_status_button.dart` - Individual status button

### Providers
- `rider_orders_provider.dart` - Orders state management
- `rider_history_provider.dart` - History state management

### Entities
- `rider_booking.dart` - Booking entity with enums

### Services
- `api_service.dart` - API calls

---

## ✨ Features Summary

✅ **Real-time order fetching** (every 10 seconds)  
✅ **Accept orders** (API integration)  
✅ **Update order status** (picked_up, completed)  
✅ **Service-specific workflows** (LesEat, LesBuy, LesRide)  
✅ **Map view with markers** (Google Maps)  
✅ **Location tracking** (every 30 seconds)  
✅ **Navigation integration** (Google Maps directions)  
✅ **Order history** (completed/cancelled)  
✅ **Analytics** (performance stars, charts)  
✅ **Auto-refresh** (background updates)  
✅ **No mock data** (100% real API)  
✅ **Existing UI** (no new screens created)

---

## 🎯 Status Color Guide

| Status | Color | Gradient |
|--------|-------|----------|
| Pending | Gray | #F0F0F0 → #DDDDDD |
| Cooking | Red | #FF6B6B → #FFB3B3 |
| For Pick Up | Yellow | #FFE57F → #FFF3B0 |
| To Buy | Purple | #9B59F0 → #5F2D82 |
| For Delivery | Yellow | #FFD740 → #FFF176 |
| On The Way | Blue | #42A5F5 → #90CAF9 |
| Delivered | Green | #81C784 → #C8E6C9 |
| Complete | Green | #81C784 → #C8E6C9 |

---

**All booking process screens and widgets are integrated with real API data!** 🎉
