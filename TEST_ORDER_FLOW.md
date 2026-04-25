# Test Order Flow

## Prerequisites
1. Backend API is running: `php artisan serve`
2. Cache is cleared: `php artisan cache:clear`
3. Frontend app is running
4. Rider app is running
5. Test rider is logged in (testrider@lesgo.com / password)

## Test Steps

### Step 1: Clear Cache (Backend)
```bash
cd BACKEND/lesgo-api
php artisan cache:clear
```

### Step 2: Verify Test Rider Exists
```bash
cd BACKEND/lesgo-api
php artisan tinker
```
Then run:
```php
$rider = App\Models\User::where('email', 'testrider@lesgo.com')->first();
echo "Rider: " . $rider->name . " (ID: " . $rider->id . ")\n";
echo "Driver Profile ID: " . $rider->driverProfile->id . "\n";
echo "Status: " . $rider->driverProfile->status . "\n";
exit
```

### Step 3: Create Order (Customer Side)
1. Open customer app
2. Login as customer
3. Go to LesGo service
4. Select pickup and dropoff locations
5. Click "Book Now"
6. Wait on "Finding driver..." screen

**Expected:**
- Should show "Finding driver..." with animation
- Should poll API every 3 seconds
- Should NOT show "Jose Rizal" or any hardcoded name

### Step 4: Check Order in Database
```bash
cd BACKEND/lesgo-api
php artisan tinker
```
Then run:
```php
$order = App\Models\Order::latest()->first();
echo "Order ID: " . $order->id . "\n";
echo "Status: " . $order->status . "\n";
echo "Driver ID: " . ($order->driver_id ?? 'null') . "\n";
echo "Customer ID: " . $order->customer_id . "\n";
exit
```

**Expected:**
- Order exists with status "pending"
- driver_id is null
- customer_id matches logged in customer

### Step 5: Check Rider Side
1. Open rider app
2. Login as test rider (testrider@lesgo.com)
3. Turn ON DUTY
4. Click "Map View" tab

**Expected:**
- Should see the new order in "Available Orders" section
- Should see orange marker on map for the order
- Order card should show:
  - Order #[ID]
  - Fare amount
  - Distance
  - Pickup and dropoff addresses
  - "Accept Order" button

### Step 6: Accept Order (Rider Side)
1. Click "Accept Order" on the available order
2. Wait for acceptance to complete

**Expected:**
- Button shows loading spinner
- Order moves to "Active" section with green highlight
- Map shows green (pickup) and red (dropoff) markers
- "Navigate" buttons appear for pickup and dropoff

### Step 7: Verify Customer Side
1. Go back to customer app
2. Check "Finding driver..." screen

**Expected:**
- Should show "Driver found!"
- Should show real driver name: "Test Rider"
- Should NOT show "Jose Rizal"
- Should show driver details

### Step 8: Verify in Database
```bash
cd BACKEND/lesgo-api
php artisan tinker
```
Then run:
```php
$order = App\Models\Order::latest()->first();
echo "Order ID: " . $order->id . "\n";
echo "Status: " . $order->status . "\n";
echo "Driver ID: " . $order->driver_id . "\n";
echo "Driver Name: " . $order->driverProfile->user->name . "\n";
exit
```

**Expected:**
- Status is "accepted"
- driver_id is set to test rider's driver profile ID (73)
- Driver name is "Test Rider"

## Troubleshooting

### Issue: Orders not appearing in rider side
**Possible causes:**
1. Cache not cleared
2. Rider not ON DUTY
3. Order status is not "pending"
4. API connection issue

**Solutions:**
```bash
# Clear cache
php artisan cache:clear

# Check order status
php artisan tinker
App\Models\Order::latest()->first()->status

# Check if rider is logged in
# In rider app, check if token is saved
```

### Issue: Still showing "Jose Rizal"
**Possible causes:**
1. Frontend not rebuilt after code changes
2. Old cached data in app
3. driver_finding_provider not updated

**Solutions:**
```bash
# Rebuild frontend
cd FRONTEND
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# Restart app completely
# Clear app data if needed
```

### Issue: Driver name not showing
**Possible causes:**
1. OrderDto doesn't have driverProfile field
2. API not returning driver_profile in response
3. JSON serialization not regenerated

**Solutions:**
```bash
# Regenerate JSON serialization
cd FRONTEND
flutter pub run build_runner build --delete-conflicting-outputs

# Check API response
# In browser/Postman:
GET https://lesgo-api-feature-auth-secmes.free.laravel.cloud/api/v1/orders/[ORDER_ID]
# Should include "driver_profile" with "user" nested object
```

### Issue: Cache not clearing
**Possible causes:**
1. CacheService::forgetByPattern not working
2. Cache driver issue

**Solutions:**
```bash
# Clear all cache
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear

# Restart Laravel server
php artisan serve
```

## Expected API Responses

### GET /api/v1/orders (Rider Side)
```json
{
  "success": true,
  "data": [
    {
      "id": 123,
      "status": "pending",
      "driver_id": null,
      "pickup_address": {
        "id": 20,
        "address_line1": "123 Main St",
        "latitude": 14.5995,
        "longitude": 120.9842
      },
      "dropoff_address": {
        "id": 21,
        "address_line1": "456 Oak Ave",
        "latitude": 14.6090,
        "longitude": 121.0000
      },
      "estimated_fare": 150.00,
      "estimated_distance_m": 5000
    }
  ]
}
```

### GET /api/v1/orders/123 (After Accept)
```json
{
  "success": true,
  "data": {
    "id": 123,
    "status": "accepted",
    "driver_id": 73,
    "driver_profile": {
      "id": 73,
      "user_id": 922,
      "status": "active",
      "rating": 5.0,
      "total_trips": 0,
      "user": {
        "id": 922,
        "name": "Test Rider",
        "email": "testrider@lesgo.com",
        "phone_number": "+639171234567"
      }
    },
    "pickup_address": {...},
    "dropoff_address": {...}
  }
}
```

## Success Criteria

✅ Customer creates order
✅ Order appears in rider side within 10 seconds
✅ Rider can accept order
✅ Customer sees "Test Rider" (not "Jose Rizal")
✅ Map shows correct markers
✅ Navigation buttons work
✅ Order status updates correctly

## Files Changed

1. `BACKEND/lesgo-api/app/Http/Controllers/Api/OrderController.php` - Cache busting
2. `FRONTEND/lib/presentation/provider/main/booking/driver_finding_provider.dart` - Real driver polling
3. `FRONTEND/lib/data/data_source/dto/order/order_dto.dart` - Added driverProfile field
4. `RIDERSIDE/lib/presentation/provider/main/riderside/rider_orders_provider.dart` - Fixed address parsing
5. `RIDERSIDE/lib/presentation/screens/main/riderside/views/rider_bookings_map_view.dart` - New map view
6. `RIDERSIDE/lib/presentation/screens/main/riderside/views/rider_bookings_view.dart` - View toggle
