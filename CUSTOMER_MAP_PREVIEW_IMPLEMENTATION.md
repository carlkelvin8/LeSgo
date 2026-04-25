# Customer Side Map Preview Implementation - ACTUAL ROUTE DATA

## Overview
Implemented Google Maps preview on customer side order screens with **ACTUAL ROAD ROUTES** from Google Maps Directions API. The map preview fetches real route data from the backend and displays it on the map, not just straight lines.

## Implementation Date
April 23, 2026

## Key Features
✅ **Actual Road Routes** - Uses Google Maps Directions API via backend
✅ **Real-time Route Loading** - Fetches route when map is displayed
✅ **Fallback Support** - Shows straight line if API fails
✅ **Visual Distinction** - Solid line for actual routes, dashed for fallback
✅ **Loading Indicator** - Shows spinner while fetching route data
✅ **Status-based Display** - Only shows for active orders

## Changes Made

### 1. Order Card Widget (`FRONTEND/lib/presentation/widgets/orders/order_card.dart`)

#### Changed from StatelessWidget to StatefulWidget
- Now maintains state for route data
- Manages loading state

#### Added State Variables
```dart
List<LatLng> _routePolyline = [];  // Stores actual route points
bool _isLoadingRoute = false;       // Loading indicator
```

#### Added Imports
- `tracking_remote_datasource.dart` - For API calls
- `core/di/injection.dart` - For dependency injection

#### New Lifecycle Method
```dart
@override
void initState() {
  super.initState();
  if (_shouldShowMap(widget.order.status)) {
    _loadRoute();
  }
}
```

#### New Method: `_loadRoute()`
```dart
Future<void> _loadRoute() async
```
- Calls backend API `/v1/tracking/route`
- Passes pickup and dropoff coordinates
- Parses polyline data from response
- Updates state with route points
- Handles errors gracefully (fallback to straight line)

**API Call:**
```dart
final result = await trackingDataSource.getRoute(
  widget.order.pickupLat,
  widget.order.pickupLng,
  widget.order.dropoffLat,
  widget.order.dropoffLng,
);
```

**Response Parsing:**
```dart
final polylineData = result['data']['polyline'];
if (polylineData is List && polylineData.isNotEmpty) {
  final points = polylineData.map((point) {
    return LatLng(
      (point['lat'] as num).toDouble(),
      (point['lng'] as num).toDouble(),
    );
  }).toList();
}
```

#### Updated `_buildMapPolylines()`
```dart
Set<Polyline> _buildMapPolylines()
```
- Uses `_routePolyline` if available (actual route)
- Falls back to straight line if route not loaded
- **Solid line** for actual routes
- **Dashed line** for fallback straight line

**Visual Distinction:**
```dart
patterns: _routePolyline.isEmpty 
    ? [PatternItem.dash(15), PatternItem.gap(8)]  // Fallback
    : [],                                          // Actual route
```

#### Added Loading Indicator
- Shows circular progress indicator while fetching route
- Overlays on map with semi-transparent background
- Uses brand color (#5F2D82)

### 2. Order Detail Screen (`FRONTEND/lib/presentation/screens/main/orders/order_detail_screen.dart`)

#### Added State Variables
```dart
List<LatLng> _routePolyline = [];
bool _isLoadingRoute = false;
```

#### Added Imports
- `tracking_remote_datasource.dart`
- `core/di/injection.dart`

#### New Lifecycle Method
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final order = _order;
    if (order != null && _shouldShowMap(order.status)) {
      _loadRoute(order);
    }
  });
}
```

#### New Method: `_loadRoute(OrderDto order)`
- Same implementation as OrderCard
- Fetches actual route from backend
- Updates polyline state
- Handles errors with fallback

#### Updated `_buildMapPolylines(OrderDto order)`
- Uses actual route if available
- Falls back to straight line
- **Solid line (4px)** for actual routes
- **Dashed line (4px)** for fallback

#### Added Loading Indicator
- Shows on map while fetching route
- Larger map (200px) shows loading better

## Backend Integration

### API Endpoint
**GET** `/v1/tracking/route`

**Query Parameters:**
- `origin_lat` - Pickup latitude
- `origin_lng` - Pickup longitude
- `dest_lat` - Dropoff latitude
- `dest_lng` - Dropoff longitude

**Response Format:**
```json
{
  "success": true,
  "data": {
    "distance": {
      "value": 2500,
      "text": "2.5 km"
    },
    "duration": {
      "value": 900,
      "text": "15 mins"
    },
    "polyline": [
      {"lat": 8.4542, "lng": 124.6319},
      {"lat": 8.4545, "lng": 124.6322},
      {"lat": 8.4548, "lng": 124.6325},
      ...
    ]
  }
}
```

### Backend Implementation
**File:** `BACKEND/lesgo-api/app/Http/Controllers/Api/LiveTrackingController.php`

**Method:** `getRoute()`
- Calls Google Maps Directions API
- Decodes polyline from Google response
- Returns array of lat/lng points
- Includes distance and duration data

## User Experience Flow

### Order Card (Transactions Screen)
1. User opens transactions screen
2. Active order cards show map preview
3. **Loading spinner appears** on map
4. **Backend API called** to fetch actual route
5. **Route polyline rendered** on map (solid purple line)
6. If API fails, shows dashed straight line
7. User taps map → opens live tracking

### Order Detail Screen
1. User opens order details
2. Larger map preview appears
3. **Loading spinner shows** while fetching route
4. **Actual road route displayed** with solid line
5. Status badge overlays on map
6. User taps map → opens live tracking with real-time updates

## Visual Indicators

### Route Line Styles
| Condition | Line Style | Width | Color | Pattern |
|-----------|-----------|-------|-------|---------|
| **Actual Route Loaded** | Solid | 3px (card)<br>4px (detail) | #5F2D82 | None |
| **Fallback/Loading** | Dashed | 3px (card)<br>4px (detail) | #5F2D82 | 15px dash, 8px gap |

### Loading States
- **Loading**: Circular progress indicator over map
- **Loaded**: Route displayed, no indicator
- **Failed**: Dashed line (fallback), no indicator

## Technical Details

### Route Data Flow
```
1. Widget mounts → initState()
2. Check if should show map → _shouldShowMap()
3. Call _loadRoute()
4. Get TrackingRemoteDataSource from DI
5. Call API: getRoute(pickupLat, pickupLng, dropoffLat, dropoffLng)
6. Backend calls Google Maps Directions API
7. Backend decodes polyline
8. Backend returns array of LatLng points
9. Frontend parses response
10. Frontend updates _routePolyline state
11. Map re-renders with actual route
```

### Error Handling
```dart
try {
  // Fetch route from API
  final result = await trackingDataSource.getRoute(...);
  // Parse and update state
} catch (e) {
  print('Error loading route: $e');
  // Fallback: _routePolyline remains empty
  // Map will show dashed straight line
}
```

### Performance Optimization
- Route loaded only once per widget lifecycle
- Loading state prevents duplicate API calls
- Fallback ensures map always displays something
- No blocking - UI remains responsive during load

## API Integration Details

### TrackingRemoteDataSource
**File:** `FRONTEND/lib/data/data_source/tracking_remote_datasource.dart`

**Method:** `getRoute()`
```dart
Future<Map<String, dynamic>> getRoute(
  double originLat,
  double originLng,
  double destLat,
  double destLng,
) async
```

**Returns:**
```dart
{
  'success': true,
  'data': {
    'distance': {...},
    'duration': {...},
    'polyline': [...]  // Array of {lat, lng} objects
  }
}
```

### Dependency Injection
Uses `getIt` service locator:
```dart
final trackingDataSource = getIt<TrackingRemoteDataSource>();
```

## Testing Checklist

- [x] Map displays on order cards for active orders
- [x] Map displays on order detail screen for active orders
- [x] **Loading indicator shows while fetching route**
- [x] **Actual route displays as solid line**
- [x] **Fallback shows dashed line if API fails**
- [x] Pickup marker shows in green
- [x] Dropoff marker shows in red
- [x] Tap on map opens live tracking screen
- [x] Map hidden for pending/completed/cancelled orders
- [x] Status badge shows on detail screen map
- [x] Camera centers between pickup and dropoff
- [x] Map gestures disabled (non-interactive)
- [x] **Route follows actual roads, not straight line**
- [x] **No performance issues during route loading**

## Comparison: Before vs After

### Before (Initial Implementation)
- ❌ Straight line between pickup and dropoff
- ❌ Dashed line always
- ❌ No API integration
- ❌ Static display

### After (Current Implementation)
- ✅ **Actual road routes from Google Maps**
- ✅ **Solid line for real routes**
- ✅ **Backend API integration**
- ✅ **Dynamic route loading**
- ✅ **Loading indicators**
- ✅ **Graceful fallback**

## Future Enhancements

### Potential Improvements
1. **Route Caching**: Cache routes to avoid repeated API calls
2. **Driver Position**: Show driver's current location on route
3. **Route Animation**: Animate route drawing
4. **Traffic Layer**: Show traffic conditions on route
5. **Alternative Routes**: Show multiple route options
6. **Route Updates**: Refresh route if driver deviates
7. **Distance Display**: Show route distance on map
8. **ETA Display**: Show estimated time on map overlay

## Related Implementations

### Backend
1. **LiveTrackingController.php**
   - `getRoute()` method
   - Google Maps Directions API integration
   - Polyline decoding

### Frontend
1. **Live Tracking Screens**
   - Uses same route API
   - Real-time updates
   - Driver location tracking

2. **Rider Side**
   - Similar map preview
   - Same route API
   - Consistent UX

## Notes

- **Actual routes** use Google Maps Directions API
- **Solid line** indicates real road route
- **Dashed line** indicates fallback (straight line)
- Route loaded **once per widget lifecycle**
- **Non-blocking** - UI remains responsive
- **Graceful degradation** - always shows something
- **Consistent** with live tracking implementation

## Success Criteria

✅ Customer sees **actual road routes** on map preview
✅ Routes follow **real roads**, not straight lines
✅ **Loading indicator** shows during fetch
✅ **Solid line** for actual routes
✅ **Dashed line** for fallback
✅ **No performance issues**
✅ **Graceful error handling**
✅ **Consistent with backend implementation**
✅ **Same route data** as live tracking screens

### 1. Order Card Widget (`FRONTEND/lib/presentation/widgets/orders/order_card.dart`)

#### Added Imports
- `google_maps_flutter` package for map display
- `live_tracking_screen.dart` for navigation to full tracking

#### New Features
- **Map Preview Section**: Shows interactive Google Maps preview for active orders
- **Status-based Display**: Map only shows for orders with status:
  - `accepted`
  - `picked_up`
  - `in_transit`
  - `driver_arrived_at_pickup`
  - `in_progress`

#### Helper Methods Added
```dart
bool _shouldShowMap(String status)
```
- Determines if map should be displayed based on order status
- Returns true for active orders only

```dart
Set<Marker> _buildMapMarkers()
```
- Creates pickup marker (green) at pickup location
- Creates dropoff marker (red) at dropoff location

```dart
Set<Polyline> _buildMapPolylines()
```
- Creates dashed purple line between pickup and dropoff
- Uses brand color (#5F2D82)
- Pattern: 15px dash, 8px gap

#### Map Features
- **Height**: 140px
- **Interactive**: Tap to open full tracking screen
- **Markers**: Green (pickup), Red (dropoff)
- **Route Line**: Dashed purple line
- **Overlay Hint**: "Tap to track" button in bottom-right
- **Disabled Gestures**: Map is non-interactive (tap opens full screen)

### 2. Order Detail Screen (`FRONTEND/lib/presentation/screens/main/orders/order_detail_screen.dart`)

#### Added Imports
- `google_maps_flutter` package

#### New Features
- **Larger Map Preview**: 200px height for better visibility
- **Status Badge Overlay**: Shows current order status on map
- **Enhanced Tap Hint**: "Tap to track live" message

#### Helper Methods Added
```dart
bool _shouldShowMap(String status)
```
- Same logic as OrderCard

```dart
Widget _buildMapPreview(OrderDto order)
```
- Builds complete map preview widget
- Includes status badge overlay
- Includes tap hint overlay
- Tappable to open live tracking

```dart
Set<Marker> _buildMapMarkers(OrderDto order)
```
- Creates markers with info windows
- Green marker: "Pickup Location"
- Red marker: "Dropoff Location"

```dart
Set<Polyline> _buildMapPolylines(OrderDto order)
```
- Creates dashed route line
- Thicker line (4px) for better visibility
- Pattern: 20px dash, 10px gap

#### Map Features
- **Height**: 200px (larger than card view)
- **Status Badge**: Top-left overlay showing order status
- **Info Windows**: Markers show location labels on tap
- **Tap Hint**: Bottom-right "Tap to track live" button
- **Camera Position**: Centered between pickup and dropoff
- **Zoom Level**: 13 (good overview of route)

## User Experience

### Order Card (Transactions Screen)
1. User sees order card with map preview
2. Map shows pickup (green) and dropoff (red) markers
3. Dashed line shows route between locations
4. User taps anywhere on map
5. Opens full live tracking screen

### Order Detail Screen
1. User opens order details
2. Larger map preview appears below status card
3. Status badge shows on map (e.g., "On The Way")
4. User can see route overview
5. Tap opens live tracking with real-time updates

## Technical Details

### Map Configuration
- **Initial Camera**: Centered between pickup and dropoff
- **Zoom Level**: 13 (card), 13 (detail)
- **Disabled Features**:
  - My location button
  - Zoom controls
  - Map toolbar
  - Compass
  - All gestures (rotate, scroll, tilt, zoom)

### Marker Colors
- **Pickup**: Green (BitmapDescriptor.hueGreen)
- **Dropoff**: Red (BitmapDescriptor.hueRed)

### Route Line Style
- **Color**: #5F2D82 (brand purple)
- **Width**: 3px (card), 4px (detail)
- **Pattern**: Dashed line
- **Card**: 15px dash, 8px gap
- **Detail**: 20px dash, 10px gap

### Status Filtering
Map shows only for active delivery statuses:
- ✅ `accepted` - Driver accepted order
- ✅ `driver_arrived_at_pickup` - Driver at pickup location
- ✅ `in_progress` - Order being prepared/picked up
- ✅ `picked_up` - Driver has the order
- ✅ `in_transit` - On the way to dropoff
- ❌ `pending` - No driver yet
- ❌ `completed` - Already delivered
- ❌ `cancelled` - Order cancelled
- ❌ `failed` - Order failed

## Integration with Existing Features

### Live Tracking Integration
- Tapping map opens `LiveTrackingScreen`
- Passes `orderId` for real-time tracking
- Shows actual road routes (from previous implementation)
- Real-time driver location updates
- ETA calculations

### Order Status Polling
- Works with existing 5-second status polling
- Map updates when status changes
- Map disappears when order completes/cancels

### Coordinate Handling
- Uses `OrderDto` properties:
  - `pickupLat`, `pickupLng`
  - `dropoffLat`, `dropoffLng`
  - `pickupAddress`, `dropoffAddress`

## Files Modified

1. **FRONTEND/lib/presentation/widgets/orders/order_card.dart**
   - Added Google Maps preview
   - Added helper methods for markers and polylines
   - Added status-based map display logic

2. **FRONTEND/lib/presentation/screens/main/orders/order_detail_screen.dart**
   - Added larger map preview
   - Added status badge overlay
   - Added helper methods for map rendering

## Dependencies

### Required Packages
- `google_maps_flutter` - Already in project
- `flutter/material.dart` - Standard Flutter
- `intl` - Date formatting (already used)

### API Integration
- Uses existing `OrderDto` data structure
- No new API calls required
- Coordinates from order creation

## Testing Checklist

- [x] Map displays on order cards for active orders
- [x] Map displays on order detail screen for active orders
- [x] Pickup marker shows in green
- [x] Dropoff marker shows in red
- [x] Dashed route line displays correctly
- [x] Tap on map opens live tracking screen
- [x] Map hidden for pending/completed/cancelled orders
- [x] Status badge shows on detail screen map
- [x] Camera centers between pickup and dropoff
- [x] Map gestures disabled (non-interactive)
- [x] Tap hint overlay displays correctly

## Future Enhancements

### Potential Improvements
1. **Driver Location**: Show driver's current position on map preview
2. **Animated Route**: Animate route line drawing
3. **Distance Display**: Show distance on map overlay
4. **ETA Display**: Show estimated time on map
5. **Traffic Layer**: Show traffic conditions
6. **Custom Markers**: Use custom icons for pickup/dropoff
7. **Route Polyline**: Use actual road route instead of straight line

### Performance Optimizations
1. **Lazy Loading**: Load map only when visible
2. **Static Map**: Use static map image for completed orders
3. **Caching**: Cache map tiles for offline viewing
4. **Lite Mode**: Use Google Maps Lite mode for better performance

## Related Implementations

### Previous Work
1. **Google Maps Directions API** (Backend)
   - `LiveTrackingController.php`
   - Real road routes calculation
   - ETA calculation

2. **Live Tracking Screens** (Frontend)
   - `live_tracking_screen.dart`
   - `lesbuy_order_tracking_screen.dart`
   - `leseat_order_tracking_screen.dart`
   - `simple_order_tracking_screen.dart`

3. **Real-time Status Updates**
   - 5-second polling
   - Status change notifications
   - Automatic UI updates

4. **Rider Side Map Preview**
   - `rider_booking_detail_screen.dart`
   - Reference implementation

## Notes

- Map preview uses straight line between pickup/dropoff
- Full tracking screen uses actual road routes from Google Directions API
- Map is non-interactive to prevent accidental gestures
- Tap anywhere on map opens full tracking
- Status badge only shows on detail screen (not on card)
- Map automatically hides when order completes/cancels

## Success Criteria

✅ Customer can see map preview on order cards
✅ Customer can see larger map on order detail screen
✅ Map shows pickup and dropoff locations clearly
✅ Tapping map opens live tracking
✅ Map only shows for active orders
✅ Consistent with rider side implementation
✅ No performance issues
✅ Smooth navigation to tracking screen
