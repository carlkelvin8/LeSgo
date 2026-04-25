# Test Status Mapping - Step by Step Guide

## Current Test Data
Based on the logs, we have these orders:
- **Order #407**: status=pending, driverId=null (Available)
- **Order #406**: status=completed, driverId=74 (Completed)
- **Order #405**: status=completed, driverId=74 (Completed)
- **Order #404**: status=picked_up, driverId=74 (Active)
- **Order #403**: status=accepted, driverId=74 (Active)

## Test Steps

### Test 1: View Order #403 (Status: accepted)
1. Open rider app at http://localhost:8080
2. Login with `testrider@lesgo.com` / `password`
3. Go to Bookings tab
4. Find Order #403 in the active orders section
5. Tap "View Details & Track"
6. **Expected Result**:
   - Console should show: `🎨 Building status content for: On The Way (API: accepted)`
   - Screen should show: **Map view** (not empty space)
   - Status bar should highlight "On The Way"

### Test 2: View Order #404 (Status: picked_up)
1. From bookings list, find Order #404
2. Tap "View Details & Track"
3. **Expected Result**:
   - Console should show: `🎨 Building status content for: On The Way (Going) (API: picked_up)`
   - Screen should show: **Map view**
   - Status bar should highlight "On The Way (Going)"

### Test 3: Change Status from accepted → picked_up
1. Open Order #403 details
2. Tap "On The Way (Going)" status button
3. **Expected Result**:
   - Console should show:
     ```
     🔘 Status button tapped: On The Way (Going)
     ✅ Calling onTap handler
     🎯 _handleStatusChange called with: On The Way (Going)
     📡 Will update to API status: picked_up
     📋 Current API status from widget: accepted
     📋 Target order ID: 403, target status: picked_up
     ✅ Status is different (accepted → picked_up), proceeding with update
     ```
   - Screen should update to show map view
   - Green snackbar: "Status updated to On The Way (Going)"

### Test 4: Change Status from picked_up → completed
1. Open Order #404 details (or Order #403 after Test 3)
2. Tap "Complete" status button
3. **Expected Result**:
   - Console should show:
     ```
     🔘 Status button tapped: Complete
     ✅ Calling onTap handler
     🎯 _handleStatusChange called with: Complete
     📡 Will update to API status: completed
     📋 Current API status from widget: picked_up
     📋 Target order ID: 404, target status: completed
     ✅ Status is different (picked_up → completed), proceeding with update
     ```
   - Screen should show upload section before navigating back
   - Green snackbar: "Status updated to Complete"
   - Should navigate back to bookings list

### Test 5: Try to Update Same Status (Should Show Warning)
1. Open Order #404 details (status: picked_up)
2. Tap "On The Way (Going)" button (which maps to picked_up)
3. **Expected Result**:
   - Console should show:
     ```
     🔘 Status button tapped: On The Way (Going)
     ✅ Calling onTap handler
     🎯 _handleStatusChange called with: On The Way (Going)
     📡 Will update to API status: picked_up
     📋 Current API status from widget: picked_up
     📋 Target order ID: 404, target status: picked_up
     ⚠️ Status is already picked_up, showing warning
     ```
   - Orange snackbar: "Order is already picked up. Tap Complete to finish the order."
   - No API call should be made

## What to Look For

### ✅ Success Indicators
- Status content changes based on current status
- Map view appears for "On The Way" and "On The Way (Going)" statuses
- Upload section appears for "Complete" status
- Status updates work correctly
- Duplicate status updates show warning instead of making API call

### ❌ Failure Indicators
- Always shows empty space regardless of status
- Console shows: `⚪ Showing empty space` for all statuses
- Status content doesn't change when tapping status buttons
- No map or upload section appears

## Database Verification

To check the actual order statuses in the database:
```bash
cd BACKEND/lesgo-api
php artisan tinker
```

Then run:
```php
\App\Models\Order::whereIn('id', [403, 404, 405, 406, 407])
    ->get(['id', 'status', 'driver_id', 'service_id'])
    ->toArray();
```

Expected output:
```php
[
  ['id' => 403, 'status' => 'accepted', 'driver_id' => 74, 'service_id' => 2],
  ['id' => 404, 'status' => 'picked_up', 'driver_id' => 74, 'service_id' => 2],
  ['id' => 405, 'status' => 'completed', 'driver_id' => 74, 'service_id' => 2],
  ['id' => 406, 'status' => 'completed', 'driver_id' => 74, 'service_id' => 2],
  ['id' => 407, 'status' => 'pending', 'driver_id' => null, 'service_id' => 2],
]
```

## Service Type Testing

To test different service types (LesEat, LesBuy), create test orders:

### Create LesEat Order (Service ID: 3)
```bash
cd BACKEND/lesgo-api
php artisan tinker
```

```php
$order = \App\Models\Order::create([
    'user_id' => 925, // testcustomer
    'service_id' => 3, // LesEat
    'status' => 'pending',
    'pickup_address' => 'Jollibee Makati',
    'pickup_lat' => 14.5547,
    'pickup_lng' => 121.0244,
    'pickup_contact_name' => 'Jollibee',
    'pickup_contact_phone' => '09123456789',
    'dropoff_address' => 'Customer Address',
    'dropoff_lat' => 14.5995,
    'dropoff_lng' => 120.9842,
    'dropoff_contact_name' => 'Test Customer',
    'dropoff_contact_phone' => '09123456789',
    'estimated_fare' => 150.00,
    'estimated_distance_m' => 5000,
    'payment_method' => 'cash',
    'notes' => '1x Chickenjoy, 1x Jolly Spaghetti',
]);
echo "Created LesEat Order #{$order->id}\n";
```

Then test:
1. Accept the order (status: accepted)
   - Should show: "Cooking" status
   - Should show: Empty space (no map, no upload)
2. Update to picked_up
   - Should show: "For Pick Up" status
   - Should show: Upload section
3. Update to completed
   - Should show: "Delivered" status
   - Should show: Upload section

## Troubleshooting

### Issue: Status content not changing
**Solution**: Check console logs for `🎨 Building status content for:` message. If it shows the wrong status, the mapping function is not being applied.

### Issue: Always shows "Pending" status
**Solution**: Verify that `_mapApiStatusToBookingStatus()` is being called when creating `RiderBooking` objects. Check that `currentStatus` parameter is being passed.

### Issue: Map/Upload section not appearing
**Solution**: Check the `_buildStatusContent()` method conditions. Verify that the status enum matches the expected values.

### Issue: Hot reload not working
**Solution**: Stop and restart the Flutter app to ensure all changes are compiled.
