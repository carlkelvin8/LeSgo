# Price Display Fix - Customer vs Driver

## Issue
Iba yung price na nakikita ng customer at driver. Both were showing `estimated_fare` which is the total customer payment, pero dapat yung driver ay makikita lang yung `driver_share` which is their actual earnings.

## Root Cause
The `RiderOrder` class was only using `estimated_fare` field and displaying it as earnings. Hindi kasama yung `driver_share` field from the backend.

## Solution

### Backend Fields (Already Exists)
The `orders` table has these price-related fields:
- `estimated_fare` - Total amount customer pays
- `actual_fare` - Final amount after adjustments
- `driver_share` - Driver's earnings (after platform fee and partner share)
- `partner_share` - Partner's share (for restaurant/store orders)
- `platform_fee` - Platform's commission
- `discount_amount` - Discount applied

### Frontend Changes

#### 1. Updated `RiderOrder` Class
**File**: `RIDERSIDE/lib/presentation/provider/main/riderside/rider_orders_provider.dart`

Added new fields:
```dart
class RiderOrder {
  // ... existing fields
  final double estimatedFare;      // Customer's total payment
  final double? driverShare;       // Driver's actual earnings
  
  // Getter to display correct earnings
  double get displayEarnings => driverShare ?? estimatedFare;
}
```

#### 2. Updated JSON Parsing
Added `driver_share` parsing from API response:
```dart
driverShare: j['driver_share'] != null ? _d(j['driver_share']) : null,
```

#### 3. Updated Display Logic
Changed all earnings displays to use `displayEarnings` instead of `estimatedFare`:

**Files Updated**:
- `RIDERSIDE/lib/presentation/widgets/main/riderside/bookings/rider_bookings_list.dart`
- `RIDERSIDE/lib/presentation/screens/main/riderside/views/rider_bookings_map_view.dart`

Changed from:
```dart
earnings: 'PHP ${order.estimatedFare.toStringAsFixed(2)}'
```

To:
```dart
earnings: 'PHP ${order.displayEarnings.toStringAsFixed(2)}'
```

## How It Works

### Customer Side (FRONTEND)
- Shows `estimated_fare` - This is the total amount they need to pay
- Includes: base fare + distance fee + partner share + platform fee

### Driver Side (RIDERSIDE)
- Shows `driver_share` - This is their actual earnings
- Calculated as: `estimated_fare - platform_fee - partner_share`
- Falls back to `estimated_fare` if `driver_share` is not set (for backward compatibility)

## Example

For a PHP 400 order:
- **Customer sees**: PHP 400.00 (estimated_fare)
- **Driver sees**: PHP 320.00 (driver_share, after 15% platform fee + partner share)
- **Platform gets**: PHP 60.00 (platform_fee, 15%)
- **Partner gets**: PHP 20.00 (partner_share, if applicable)

## Backend Requirements

The backend should calculate and return `driver_share` in the order response. If not already implemented, it should be calculated as:

```php
$order->driver_share = $order->estimated_fare - $order->platform_fee - $order->partner_share;
```

## Testing

1. **Customer App**:
   - Create an order
   - Check that the displayed price matches `estimated_fare`
   - Verify in transactions that the total is correct

2. **Driver App**:
   - Accept an order
   - Check that earnings show `driver_share` (lower than customer's payment)
   - Verify in history that earnings are consistent

3. **Backend**:
   - Verify that `driver_share` is calculated correctly
   - Check that it's included in API responses for orders

## Notes

- The `billingAmount` still shows `estimated_fare` because that's the amount the customer is paying (for reference)
- The `earnings` field now correctly shows `driver_share` which is what the driver actually receives
- If `driver_share` is null (old orders), it falls back to `estimated_fare` for backward compatibility
