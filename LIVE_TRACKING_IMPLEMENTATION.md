# Live Tracking Implementation - LeSGo App

**Feature:** Real-time driver location tracking  
**Platform:** Customer App + Rider App  
**Technology:** Laravel Reverb (WebSocket) + Polling

---

## 🎯 HOW IT WORKS

### Customer Side (Tracking the Driver)
1. Customer books an order (LesGo/LesRide)
2. Driver accepts the order
3. Customer opens tracking screen
4. Map shows:
   - 🟣 Purple marker = Pickup location (fixed)
   - 🔴 Red marker = Destination (fixed)
   - 🔵 Blue marker = Driver's live location (moving)
5. Driver marker updates every 5-10 seconds
6. Shows ETA (estimated time of arrival)

### Rider Side (Sending Location)
1. Rider accepts an order
2. App starts tracking rider's GPS location
3. Location sent to backend every 5-10 seconds
4. Backend broadcasts location to customer
5. Customer sees driver moving on map in real-time

---

## 🔧 TECHNICAL IMPLEMENTATION

### 1. Backend APIs (Already Implemented ✅)

#### Update Driver Location
```
POST /api/v1/tracking/driver/location
```

**Request:**
```json
{
  "latitude": 14.5995,
  "longitude": 120.9842,
  "heading": 45.0,
  "speed": 25.5,
  "accuracy": 10.0
}
```

**Response:**
```json
{
  "success": true,
  "message": "Location updated"
}
```

#### Get Driver Location
```
GET /api/v1/tracking/order/{order_id}/live
```

**Response:**
```json
{
  "success": true,
  "data": {
    "order_id": 443,
    "driver": {
      "id": 5,
      "name": "Juan Rider",
      "latitude": 14.5995,
      "longitude": 120.9842,
      "heading": 45.0,
      "speed": 25.5,
      "updated_at": "2026-05-02T10:30:00Z"
    },
    "pickup": {
      "latitude": 14.5995,
      "longitude": 120.9842,
      "address": "123 Rizal St"
    },
    "destination": {
      "latitude": 14.6090,
      "longitude": 121.0000,
      "address": "456 Mabini Ave"
    },
    "eta_minutes": 8,
    "distance_to_pickup_km": 1.2
  }
}
```

---

### 2. Rider App Implementation

#### A. Location Permission (Already Configured ✅)

**Android:** `RIDERSIDE/android/app/src/main/AndroidManifest.xml`
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
```

**iOS:** `RIDERSIDE/ios/Runner/Info.plist`
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show your position to customers</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>We need your location to track deliveries in the background</string>
```

#### B. Start Tracking (When Order Accepted)

**File:** `RIDERSIDE/lib/presentation/provider/main/riderside/rider_location_provider.dart`

```dart
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class RiderLocationProvider extends StateNotifier<RiderLocationState> {
  Timer? _locationTimer;
  
  // Start tracking when order is accepted
  Future<void> startTracking(int orderId) async {
    // Check permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    // Start periodic location updates (every 5 seconds)
    _locationTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        
        // Send to backend
        await _updateLocationToBackend(
          orderId: orderId,
          latitude: position.latitude,
          longitude: position.longitude,
          heading: position.heading,
          speed: position.speed,
          accuracy: position.accuracy,
        );
        
        // Update local state
        state = state.copyWith(
          currentLocation: LatLng(position.latitude, position.longitude),
          lastUpdated: DateTime.now(),
        );
      } catch (e) {
        print('Error getting location: $e');
      }
    });
  }
  
  // Stop tracking when order is completed/cancelled
  void stopTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }
  
  Future<void> _updateLocationToBackend({
    required int orderId,
    required double latitude,
    required double longitude,
    required double heading,
    required double speed,
    required double accuracy,
  }) async {
    try {
      await dioClient.post(
        '/tracking/driver/location',
        data: {
          'order_id': orderId,
          'latitude': latitude,
          'longitude': longitude,
          'heading': heading,
          'speed': speed,
          'accuracy': accuracy,
        },
      );
    } catch (e) {
      print('Error updating location: $e');
    }
  }
  
  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}
```

#### C. Usage in Rider Booking Screen

```dart
// When rider accepts order
void onAcceptOrder(int orderId) async {
  // Accept order via API
  await acceptOrder(orderId);
  
  // Start location tracking
  ref.read(riderLocationProvider.notifier).startTracking(orderId);
}

// When order is completed
void onCompleteOrder(int orderId) async {
  // Complete order via API
  await completeOrder(orderId);
  
  // Stop location tracking
  ref.read(riderLocationProvider.notifier).stopTracking();
}
```

---

### 3. Customer App Implementation

#### A. Tracking Screen with Live Updates

**File:** `FRONTEND/lib/presentation/screens/main/booking/order_tracking_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final int orderId;
  
  const OrderTrackingScreen({required this.orderId});
  
  @override
  ConsumerState<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  GoogleMapController? _mapController;
  Timer? _trackingTimer;
  
  // Markers
  BitmapDescriptor? _pickupMarker;
  BitmapDescriptor? _destinationMarker;
  BitmapDescriptor? _driverMarker;
  
  @override
  void initState() {
    super.initState();
    _loadMarkers();
    _startTracking();
  }
  
  @override
  void dispose() {
    _trackingTimer?.cancel();
    super.dispose();
  }
  
  Future<void> _loadMarkers() async {
    _pickupMarker = await MarkerUtils.violetMarker; // Purple
    _destinationMarker = await MarkerUtils.redMarker; // Red
    _driverMarker = await MarkerUtils.blueMarker; // Blue for driver
    setState(() {});
  }
  
  void _startTracking() {
    // Poll driver location every 5 seconds
    _trackingTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      _fetchDriverLocation();
    });
    
    // Initial fetch
    _fetchDriverLocation();
  }
  
  Future<void> _fetchDriverLocation() async {
    try {
      final response = await dioClient.get(
        '/tracking/order/${widget.orderId}/live',
      );
      
      if (response.data['success']) {
        final data = response.data['data'];
        
        // Update state with driver location
        setState(() {
          _driverLocation = LatLng(
            data['driver']['latitude'],
            data['driver']['longitude'],
          );
          _eta = data['eta_minutes'];
          _distanceToPickup = data['distance_to_pickup_km'];
        });
        
        // Move camera to show driver
        _updateCamera();
      }
    } catch (e) {
      print('Error fetching driver location: $e');
    }
  }
  
  void _updateCamera() {
    if (_mapController != null && _driverLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(_driverLocation!),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final markers = <Marker>{};
    
    // Pickup marker (purple)
    if (_pickupLocation != null && _pickupMarker != null) {
      markers.add(Marker(
        markerId: MarkerId('pickup'),
        position: _pickupLocation!,
        icon: _pickupMarker!,
        infoWindow: InfoWindow(title: 'Pickup'),
      ));
    }
    
    // Destination marker (red)
    if (_destinationLocation != null && _destinationMarker != null) {
      markers.add(Marker(
        markerId: MarkerId('destination'),
        position: _destinationLocation!,
        icon: _destinationMarker!,
        infoWindow: InfoWindow(title: 'Destination'),
      ));
    }
    
    // Driver marker (blue, moving)
    if (_driverLocation != null && _driverMarker != null) {
      markers.add(Marker(
        markerId: MarkerId('driver'),
        position: _driverLocation!,
        icon: _driverMarker!,
        infoWindow: InfoWindow(title: 'Driver'),
        rotation: _driverHeading ?? 0, // Rotate marker based on direction
      ));
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Track Order #${widget.orderId}'),
      ),
      body: Stack(
        children: [
          // Map
          GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: CameraPosition(
              target: _pickupLocation ?? LatLng(14.5995, 120.9842),
              zoom: 15,
            ),
            markers: markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          
          // ETA Card
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Driver arriving in',
                      style: TextStyle(fontSize: 14),
                    ),
                    Text(
                      '$_eta minutes',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_distanceToPickup.toStringAsFixed(1)} km away',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

### 4. Real-time Updates (WebSocket - Optional)

For even faster updates, use Laravel Reverb (WebSocket):

#### Backend Broadcasting

**File:** `BACKEND/lesgo-api/app/Events/DriverLocationUpdated.php`

```php
<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class DriverLocationUpdated implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $orderId;
    public $latitude;
    public $longitude;
    public $heading;
    public $speed;

    public function __construct($orderId, $latitude, $longitude, $heading, $speed)
    {
        $this->orderId = $orderId;
        $this->latitude = $latitude;
        $this->longitude = $longitude;
        $this->heading = $heading;
        $this->speed = $speed;
    }

    public function broadcastOn()
    {
        return new Channel('order.' . $this->orderId);
    }

    public function broadcastAs()
    {
        return 'driver.location.updated';
    }
}
```

#### Frontend WebSocket Listener

```dart
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

class OrderTrackingProvider extends StateNotifier<OrderTrackingState> {
  PusherChannelsFlutter? _pusher;
  
  Future<void> subscribeToDriverLocation(int orderId) async {
    _pusher = PusherChannelsFlutter.getInstance();
    
    await _pusher!.init(
      apiKey: '8cwrfdifchs4011diljr',
      cluster: 'mt1',
      onEvent: (event) {
        if (event.eventName == 'driver.location.updated') {
          final data = jsonDecode(event.data);
          
          // Update driver location immediately
          state = state.copyWith(
            driverLocation: LatLng(
              data['latitude'],
              data['longitude'],
            ),
            driverHeading: data['heading'],
            lastUpdated: DateTime.now(),
          );
        }
      },
    );
    
    await _pusher!.subscribe(channelName: 'order.$orderId');
    await _pusher!.connect();
  }
  
  void unsubscribe() {
    _pusher?.disconnect();
  }
}
```

---

## 📊 COMPARISON: Polling vs WebSocket

### Polling (Current Implementation ✅)
**How it works:** Customer app requests driver location every 5 seconds

**Pros:**
- ✅ Simple to implement
- ✅ Works everywhere
- ✅ No additional setup needed
- ✅ Already implemented

**Cons:**
- ⚠️ Slight delay (up to 5 seconds)
- ⚠️ More API calls
- ⚠️ Higher battery usage

**Best for:** MVP, testing, small scale

---

### WebSocket (Laravel Reverb)
**How it works:** Backend pushes location updates to customer instantly

**Pros:**
- ✅ Real-time (instant updates)
- ✅ Less API calls
- ✅ Lower battery usage
- ✅ Better user experience

**Cons:**
- ⚠️ More complex setup
- ⚠️ Requires WebSocket server
- ⚠️ Need to handle reconnections

**Best for:** Production, large scale

---

## 🎨 UI/UX Features

### 1. Driver Marker Animation
```dart
// Smooth marker movement
void _animateDriverMarker(LatLng newPosition) {
  // Animate from old position to new position
  final oldPosition = _driverLocation;
  
  if (oldPosition != null) {
    // Calculate steps for smooth animation
    final steps = 20;
    final latStep = (newPosition.latitude - oldPosition.latitude) / steps;
    final lngStep = (newPosition.longitude - oldPosition.longitude) / steps;
    
    int currentStep = 0;
    Timer.periodic(Duration(milliseconds: 50), (timer) {
      if (currentStep >= steps) {
        timer.cancel();
        return;
      }
      
      setState(() {
        _driverLocation = LatLng(
          oldPosition.latitude + (latStep * currentStep),
          oldPosition.longitude + (lngStep * currentStep),
        );
      });
      
      currentStep++;
    });
  } else {
    setState(() {
      _driverLocation = newPosition;
    });
  }
}
```

### 2. Auto-zoom to Show All Markers
```dart
void _fitMarkersInView() {
  if (_mapController == null) return;
  
  final bounds = LatLngBounds(
    southwest: LatLng(
      min(_pickupLocation!.latitude, _destinationLocation!.latitude, _driverLocation!.latitude),
      min(_pickupLocation!.longitude, _destinationLocation!.longitude, _driverLocation!.longitude),
    ),
    northeast: LatLng(
      max(_pickupLocation!.latitude, _destinationLocation!.latitude, _driverLocation!.latitude),
      max(_pickupLocation!.longitude, _destinationLocation!.longitude, _driverLocation!.longitude),
    ),
  );
  
  _mapController!.animateCamera(
    CameraUpdate.newLatLngBounds(bounds, 100), // 100px padding
  );
}
```

### 3. ETA Calculation
```dart
String _formatETA(int minutes) {
  if (minutes < 1) return 'Arriving now';
  if (minutes == 1) return '1 minute';
  if (minutes < 60) return '$minutes minutes';
  
  final hours = minutes ~/ 60;
  final mins = minutes % 60;
  return '$hours hr ${mins} min';
}
```

---

## 🔋 Battery Optimization

### Rider App (Sending Location)

```dart
// Adjust update frequency based on order status
Duration _getUpdateInterval(OrderStatus status) {
  switch (status) {
    case OrderStatus.accepted:
      return Duration(seconds: 10); // Slower when not moving
    case OrderStatus.pickedUp:
      return Duration(seconds: 5); // Faster when delivering
    case OrderStatus.nearDestination:
      return Duration(seconds: 3); // Very fast near destination
    default:
      return Duration(seconds: 10);
  }
}

// Stop tracking when app is in background (optional)
void _handleAppLifecycle(AppLifecycleState state) {
  if (state == AppLifecycleState.paused) {
    // Reduce frequency or stop tracking
    _locationTimer?.cancel();
  } else if (state == AppLifecycleState.resumed) {
    // Resume tracking
    startTracking(_currentOrderId);
  }
}
```

### Customer App (Receiving Location)

```dart
// Stop polling when screen is not visible
@override
void deactivate() {
  _trackingTimer?.cancel();
  super.deactivate();
}

@override
void activate() {
  _startTracking();
  super.activate();
}
```

---

## 📱 Required Packages

### pubspec.yaml (Both Apps)

```yaml
dependencies:
  google_maps_flutter: ^2.5.0
  geolocator: ^10.1.0
  permission_handler: ^11.0.1
  
  # Optional: For WebSocket
  pusher_channels_flutter: ^2.2.1
```

---

## ✅ IMPLEMENTATION CHECKLIST

### Rider App:
- [x] Location permission configured
- [ ] Location tracking provider created
- [ ] Start tracking on order accept
- [ ] Stop tracking on order complete
- [ ] Send location to backend every 5 seconds
- [ ] Handle permission denied
- [ ] Battery optimization

### Customer App:
- [x] Tracking screen created
- [ ] Poll driver location every 5 seconds
- [ ] Show 3 markers (pickup, destination, driver)
- [ ] Display ETA
- [ ] Display distance
- [ ] Auto-zoom to fit markers
- [ ] Smooth marker animation
- [ ] Stop polling when screen closed

### Backend:
- [x] API endpoints created
- [x] Database tables ready
- [ ] WebSocket events (optional)
- [ ] Location validation
- [ ] ETA calculation

---

## 🚀 NEXT STEPS

1. **Implement Rider Location Tracking**
   - Create `RiderLocationProvider`
   - Start tracking on order accept
   - Send location every 5 seconds

2. **Implement Customer Tracking Screen**
   - Create polling mechanism
   - Display driver marker
   - Show ETA and distance

3. **Test End-to-End**
   - Rider accepts order
   - Customer sees driver location
   - Driver moves, customer sees update

4. **Optimize (Optional)**
   - Add WebSocket for real-time updates
   - Smooth marker animations
   - Battery optimization

---

**Status:** Backend ✅ Ready | Frontend ⚠️ Needs Implementation  
**Priority:** High (Core feature)  
**Estimated Time:** 4-6 hours
