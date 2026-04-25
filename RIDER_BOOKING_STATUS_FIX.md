# Rider Booking Status Display Fix

## Problem
The booking detail screen was not showing dynamic content based on the order status. The screen content should change based on the current status:
- **Cooking/Accepted** → Status bar only
- **For Delivery/On The Way** → Map view
- **For Pickup/Delivered/Complete** → Upload picture section

## Root Cause
When creating `RiderBooking` entities from `RiderOrder` API data, the `currentStatus` field was always set to the default value `BookingStatus.pending` instead of being mapped from the API status string.

The `RiderBooking` entity has a `currentStatus` field that defaults to `BookingStatus.pending`:
```dart
final BookingStatus currentStatus;

const RiderBooking({
  // ... other fields
  this.currentStatus = BookingStatus.pending, // ❌ Always pending by default
});
```

## Solution
Created a status mapping function `_mapApiStatusToBookingStatus()` that converts API status strings to the correct `BookingStatus` enum values based on the service type:

### Status Mapping Logic

#### LesRide (serviceId: 2)
- `accepted` → `BookingStatus.onTheWay`
- `picked_up` → `BookingStatus.onTheWayGoing`
- `completed` → `BookingStatus.complete`

#### LesEat (serviceId: 3)
- `pending` → `BookingStatus.pending`
- `accepted` → `BookingStatus.cooking`
- `picked_up` → `BookingStatus.forPickUp`
- `completed` → `BookingStatus.delivered`

#### LesBuy (serviceId: 4)
- `pending` → `BookingStatus.pending`
- `accepted` → `BookingStatus.toBuy`
- `picked_up` → `BookingStatus.forDelivery`
- `completed` → `BookingStatus.delivered`

## Files Modified

### 1. `rider_bookings_list.dart`
- ✅ Added `_mapApiStatusToBookingStatus()` function
- ✅ Applied mapping when creating `RiderBooking` from available orders (line 91)
- ✅ Applied mapping when creating `RiderBooking` from active order (line 234)

### 2. `rider_bookings_map_view.dart`
- ✅ Added `_mapApiStatusToBookingStatus()` function (copied from rider_bookings_list.dart)
- ✅ Applied mapping when creating `RiderBooking` from active order (line 444)

### 3. `rider_booking_detail_screen.dart`
- ✅ Already has `_buildStatusContent()` method that displays different content based on `_currentStatus`
- ✅ Already has debug logging to track status changes
- ✅ No changes needed - will now receive correct status from parent widgets

## How It Works Now

1. **API Response**: Backend returns order with status string (e.g., "accepted", "picked_up")
2. **Order Parsing**: `RiderOrder.fromJson()` parses the API response
3. **Status Mapping**: When creating `RiderBooking` from `RiderOrder`, the mapping function converts:
   - API status string → `BookingStatus` enum
   - Service ID → Determines which mapping rules to use
4. **UI Display**: `RiderBookingDetailScreen` receives `RiderBooking` with correct `currentStatus`
5. **Dynamic Content**: `_buildStatusContent()` shows appropriate content:
   - **Cooking/Accepted** → Empty space (status bar only)
   - **On The Way/For Delivery** → Map placeholder
   - **For Pickup/Delivered/Complete** → Upload section

## Testing Instructions

1. **Start the rider app**: `flutter run -d chrome --web-port=8080` (in RIDERSIDE folder)
2. **Login as test rider**: `testrider@lesgo.com` / `password`
3. **Accept an order** from the available orders list
4. **Open the order details** by tapping "View Details & Track"
5. **Verify initial status**:
   - For LesRide: Should show "On The Way" status
   - For LesEat: Should show "Cooking" status
   - For LesBuy: Should show "To Buy" status
6. **Tap status buttons** to change status:
   - Should see appropriate content (map or upload section)
   - Debug logs should show: `🎨 Building status content for: [Status Name]`
7. **Check console logs**:
   - Should see: `📦 Received X orders from API`
   - Should see: `Order #XXX: status=accepted, driverId=74`
   - Should NOT see: `⚪ Showing empty space` for all statuses

## Expected Behavior

### LesRide Order (Service ID: 2)
- **Status: accepted** → Shows "On The Way" → Map view
- **Status: picked_up** → Shows "On The Way (Going)" → Map view
- **Status: completed** → Shows "Complete" → Upload section

### LesEat Order (Service ID: 3)
- **Status: accepted** → Shows "Cooking" → Empty space
- **Status: picked_up** → Shows "For Pick Up" → Upload section
- **Status: completed** → Shows "Delivered" → Upload section

### LesBuy Order (Service ID: 4)
- **Status: accepted** → Shows "To Buy" → Upload section
- **Status: picked_up** → Shows "For Delivery" → Map view
- **Status: completed** → Shows "Delivered" → Upload section

## Debug Logs to Watch

When opening booking detail screen:
```
🎨 Building status content for: [Status Name] (API: [api_status])
🗺️ Showing map section          // For delivery/on-the-way statuses
📤 Showing upload section        // For pickup/delivered/complete statuses
⚪ Showing empty space           // For cooking/pending statuses
```

When tapping status buttons:
```
🔘 Status button tapped: [Status Name]
✅ Calling onTap handler
🎯 _handleStatusChange called with: [Status Name]
📡 Will update to API status: [api_status]
📋 Current API status from widget: [current_status]
📋 Target order ID: XXX, target status: [target_status]
✅ Status is different (old → new), proceeding with update
```

## Notes

- The mapping function is duplicated in both `rider_bookings_list.dart` and `rider_bookings_map_view.dart` because both files create `RiderBooking` objects independently
- The `currentApiStatus` parameter is passed to `RiderBookingDetailScreen` to track the actual API status and prevent duplicate status updates
- Debug print statements are left in place to help with troubleshooting - they can be removed once everything is confirmed working
