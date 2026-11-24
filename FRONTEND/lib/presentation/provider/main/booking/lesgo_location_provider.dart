import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/utils/address_text_utils.dart';
import '../../../../domain/models/location/location_address.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/address_geocoder.dart';
import '../../../../core/utils/ph_address.dart';
import '../../../../core/utils/booking_geo_utils.dart';
import '../../../../core/utils/directions_route_service.dart';

class LesgoLocationState {
  final LatLng? currentLocation;
  final LatLng? selectedLocation;
  final LatLng? pickupLocation;
  final LatLng? destinationLocation;
  final LocationAddress? address;
  final LocationAddress? pickupAddress;
  final LocationAddress? destinationAddress;
  final Set<Polyline> routePolylines;
  final double? distanceInKm; // Distance in kilometers
  final int? durationInSeconds; // Duration in seconds
  final bool isLoading;
  final bool isLoadingRoute;
  final String? error;

  LesgoLocationState({
    this.currentLocation,
    this.selectedLocation,
    this.pickupLocation,
    this.destinationLocation,
    this.address,
    this.pickupAddress,
    this.destinationAddress,
    Set<Polyline>? routePolylines,
    this.distanceInKm,
    this.durationInSeconds,
    this.isLoading = false,
    this.isLoadingRoute = false,
    this.error,
  }) : routePolylines = routePolylines ?? <Polyline>{};

  LesgoLocationState copyWith({
    LatLng? currentLocation,
    LatLng? selectedLocation,
    LatLng? pickupLocation,
    LatLng? destinationLocation,
    LocationAddress? address,
    LocationAddress? pickupAddress,
    LocationAddress? destinationAddress,
    Set<Polyline>? routePolylines,
    double? distanceInKm,
    int? durationInSeconds,
    bool? isLoading,
    bool? isLoadingRoute,
    String? error,
    // `distanceInKm ?? this.distanceInKm` can never clear the value, so
    // callers that invalidate the route pass this flag (clears distance and
    // duration together, they always belong to the same route).
    bool clearDistance = false,
  }) {
    return LesgoLocationState(
      currentLocation: currentLocation ?? this.currentLocation,
      selectedLocation: selectedLocation ?? this.selectedLocation,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      destinationLocation: destinationLocation ?? this.destinationLocation,
      address: address ?? this.address,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      routePolylines: routePolylines ?? this.routePolylines,
      distanceInKm: clearDistance ? null : (distanceInKm ?? this.distanceInKm),
      durationInSeconds: clearDistance
          ? null
          : (durationInSeconds ?? this.durationInSeconds),
      isLoading: isLoading ?? this.isLoading,
      isLoadingRoute: isLoadingRoute ?? this.isLoadingRoute,
      error: error,
    );
  }
}

class LesgoLocationNotifier extends StateNotifier<LesgoLocationState> {
  LesgoLocationNotifier() : super(LesgoLocationState());

  /// Incremented whenever the route is invalidated or a new fetch starts, so
  /// an older directions response cannot overwrite a newer one.
  int _routeSeq = 0;

  void reset() {
    _routeSeq++;
    state = LesgoLocationState(
      routePolylines: {},
      distanceInKm: null,
      durationInSeconds: null,
      // Clear all locations to force fresh initialization
      currentLocation: null,
      selectedLocation: null,
      pickupLocation: null,
      destinationLocation: null,
      address: null,
      pickupAddress: null,
      destinationAddress: null,
    );
  }

  Future<void> getCurrentLocation() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      Position position =
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
            ),
          ).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              // Use default location if timeout
              throw Exception('Location request timed out');
            },
          );

      final location = LatLng(position.latitude, position.longitude);
      print(
        '🔍 LesgoLocation: Got current location: $location, fetching address...',
      );

      final address = await _getAddressFromLocation(location);
      print('🔍 LesgoLocation: Address fetched: ${address?.toString()}');

      state = state.copyWith(
        currentLocation: location,
        selectedLocation: location,
        pickupLocation: location,
        pickupAddress: address,
        address: address,
        isLoading: false,
        routePolylines: {},
        clearDistance: true,
        isLoadingRoute: false,
      );
      _routeSeq++;

      // DON'T fetch route here - only fetch when user confirms location
    } catch (e) {
      print('⚠️ LesgoLocation: Error getting location, using default: $e');
      // Use default location (Claveria, Cagayan)
      final defaultLocation = BookingGeoUtils.defaultLatLng;
      final address = await _getAddressFromLocation(defaultLocation);

      state = state.copyWith(
        currentLocation: defaultLocation,
        selectedLocation: defaultLocation,
        pickupLocation: defaultLocation,
        pickupAddress: address,
        address: address,
        isLoading: false,
        routePolylines: {},
        clearDistance: true,
        isLoadingRoute: false,
        error: null, // Clear error to allow user to continue
      );
    }
  }

  Future<void> updateSelectedLocation(LatLng location) async {
    state = state.copyWith(selectedLocation: location, isLoading: true);

    final address = await _getAddressFromLocation(location);
    state = state.copyWith(address: address, isLoading: false);
  }

  Future<void> updatePickup(LatLng location) async {
    print('🔍 LesgoLocation: updatePickup called with: $location');
    state = state.copyWith(selectedLocation: location, isLoading: true);
    final address = await _getAddressFromLocation(location);
    print('🔍 LesgoLocation: Pickup address fetched: ${address?.toString()}');
    state = state.copyWith(
      pickupLocation: location,
      pickupAddress: address,
      address: address,
      isLoading: false,
    );
    print(
      '🔍 LesgoLocation: Pickup updated - pickupLocation: ${state.pickupLocation}, pickupAddress: ${state.pickupAddress}',
    );
    // DON'T fetch route here - only fetch when user confirms location
    // Clear route since pickup changed
    _routeSeq++;
    state = state.copyWith(
      routePolylines: {},
      clearDistance: true,
      isLoadingRoute: false,
    );
  }

  Future<void> updateDestination(LatLng location) async {
    print('🔍 LesgoLocation: updateDestination called with: $location');
    state = state.copyWith(selectedLocation: location, isLoading: true);
    print('🔍 LesgoLocation: Fetching address for destination...');
    final address = await _getAddressFromLocation(location);
    print(
      '🔍 LesgoLocation: Destination address fetched: ${address?.toString()}',
    );
    _routeSeq++;
    state = state.copyWith(
      destinationLocation: location,
      destinationAddress: address,
      address: address,
      isLoading: false,
      // IMPORTANT: Clear route data when destination changes
      routePolylines: {},
      clearDistance: true,
      isLoadingRoute: false,
    );
    print(
      '🔍 LesgoLocation: Destination updated - destinationLocation: ${state.destinationLocation}',
    );
    // DON'T fetch route here - only fetch when user confirms location
    print(
      '🔍 LesGo: Destination updated, route cleared. User must confirm to calculate route.',
    );
  }

  Future<void> updateDestinationWithAddress(
    LatLng location,
    String? formattedAddress,
    Map<String, String>? addressComponents,
  ) async {
    print(
      '🔍 LesgoLocation: updateDestinationWithAddress called with: $location, $formattedAddress',
    );
    state = state.copyWith(selectedLocation: location, isLoading: true);
    LocationAddress? address;

    if (addressComponents != null && addressComponents.isNotEmpty) {
      // Use structured address components from Google Places API
      address = _parseAddressComponents(
        addressComponents,
        formattedAddress: formattedAddress,
      );
    } else if (formattedAddress != null && formattedAddress.isNotEmpty) {
      // Use formatted address from Google Places API
      address = _parseFormattedAddress(formattedAddress);
    }

    // Fallback to reverse geocoding if formatted address parsing fails
    if (address == null ||
        (address.houseNumberStreet == null &&
            address.subdivisionBarangay == null)) {
      address = await _getAddressFromLocation(location);
    }

    _routeSeq++;
    state = state.copyWith(
      destinationLocation: location,
      destinationAddress: address,
      address: address,
      isLoading: false,
      routePolylines: {},
      clearDistance: true,
      isLoadingRoute: false,
    );
    print(
      '🔍 LesgoLocation: After setting state, destinationLocation: ${state.destinationLocation}',
    );
    print('🔍 LesgoLocation: Pickup location: ${state.pickupLocation}');
    // DON'T fetch route here - only fetch when user confirms location
    // Route will be fetched in confirmSelection() or when explicitly called
  }

  Future<void> updatePickupWithAddress(
    LatLng location,
    String? formattedAddress,
    Map<String, String>? addressComponents,
  ) async {
    state = state.copyWith(selectedLocation: location, isLoading: true);
    LocationAddress? address;

    if (addressComponents != null && addressComponents.isNotEmpty) {
      // Use structured address components from Google Places API
      address = _parseAddressComponents(
        addressComponents,
        formattedAddress: formattedAddress,
      );
    } else if (formattedAddress != null && formattedAddress.isNotEmpty) {
      // Use formatted address from Google Places API
      address = _parseFormattedAddress(formattedAddress);
    }

    // Fallback to reverse geocoding if formatted address parsing fails
    if (address == null ||
        (address.houseNumberStreet == null &&
            address.subdivisionBarangay == null)) {
      address = await _getAddressFromLocation(location);
    }

    state = state.copyWith(
      pickupLocation: location,
      pickupAddress: address,
      address: address,
      isLoading: false,
    );
    // DON'T fetch route here - only fetch when user confirms location
    // Clear route since pickup changed
    _routeSeq++;
    state = state.copyWith(
      routePolylines: {},
      clearDistance: true,
      isLoadingRoute: false,
    );
  }

  LocationAddress? _parseAddressComponents(
    Map<String, String> components, {
    String? formattedAddress,
  }) {
    final ph = PhAddressParser.fromComponentMap(
      components,
      formattedAddress: formattedAddress,
    );
    return ph.isEmpty ? null : LocationAddress.fromPh(ph);
  }

  LocationAddress? _parseFormattedAddress(String formattedAddress) {
    // Parse formatted address like "Malolos, Bulacan, Philippines"
    // Split by comma and assign to appropriate fields
    final parts = stripPlusCode(
      formattedAddress,
    ).split(',').map((e) => e.trim()).toList();

    if (parts.isEmpty) {
      return null; // No parts to parse
    }

    // For single part (e.g., just "Malolos")
    if (parts.length == 1) {
      return LocationAddress(
        houseNumberStreet: null,
        subdivisionBarangay: null,
        cityProvince: parts[0],
        zipCode: null,
      );
    }

    // For multiple parts (e.g., "Malolos, Bulacan, Philippines")
    // First part is subdivision/barangay, rest is city/province
    return LocationAddress(
      houseNumberStreet: null,
      subdivisionBarangay: parts[0],
      cityProvince: parts.sublist(1).join(', '),
      zipCode: null,
    );
  }

  void setSelectedLocation(LatLng location) {
    state = state.copyWith(selectedLocation: location);
  }

  void setPickupAddress(LocationAddress address) {
    state = state.copyWith(pickupAddress: address, address: address);
  }

  void setDestinationAddress(LocationAddress address) {
    state = state.copyWith(destinationAddress: address, address: address);
  }

  void setAddress(LocationAddress address) {
    state = state.copyWith(address: address);
  }

  void setPickupLocation(LatLng location) async {
    state = state.copyWith(pickupLocation: location);

    // Perform reverse geocoding to get address
    final address = await _getAddressFromLocation(location);
    if (address != null) {
      state = state.copyWith(pickupAddress: address);
    }
  }

  void setDestinationLocation(LatLng location) async {
    state = state.copyWith(destinationLocation: location);

    // Perform reverse geocoding to get address
    final address = await _getAddressFromLocation(location);
    if (address != null) {
      state = state.copyWith(destinationAddress: address);
    }
  }

  /// Fetches route between current pickup and destination if both are set
  Future<void> fetchRouteIfBothSet({bool forceAllow = false}) async {
    if (state.pickupLocation != null && state.destinationLocation != null) {
      await fetchRoute(
        state.pickupLocation!,
        state.destinationLocation!,
        forceAllow: forceAllow,
      );
    }
  }

  Future<void> fetchRoute(
    LatLng origin,
    LatLng destination, {
    bool forceAllow = false,
  }) async {
    // ONLY allow route fetching if explicitly forced (from confirmSelection)
    if (!forceAllow) {
      print('🚫 Lesgo: Route fetch blocked - not from confirmation');
      print('🚫 Lesgo: Stack trace: ${StackTrace.current}');
      return;
    }

    print('✅ Lesgo: Route fetch ALLOWED - forceAllow=$forceAllow');

    final seq = ++_routeSeq;

    if (origin == destination) {
      state = state.copyWith(
        routePolylines: {},
        clearDistance: true,
        isLoadingRoute: false,
      );
      return;
    }

    state = state.copyWith(isLoadingRoute: true, error: null);

    try {
      // Check if API key is configured
      if (!ApiConstants.isGoogleMapsConfigured) {
        state = state.copyWith(
          isLoadingRoute: false,
          error: 'Google Maps API key not configured',
        );
        return;
      }

      final directions = await DirectionsRouteService.fetchRoute(
        originLat: origin.latitude,
        originLng: origin.longitude,
        destLat: destination.latitude,
        destLng: destination.longitude,
      );
      // A newer route request (or an invalidation) superseded this one.
      if (seq != _routeSeq) return;

      if (directions != null && directions.points.isNotEmpty) {
        final polyline = Polyline(
          polylineId: const PolylineId('route'),
          points: directions.points,
          color: const Color(0xFF5F2D82),
          width: 8,
          geodesic: true,
        );

        state = state.copyWith(
          routePolylines: {polyline},
          distanceInKm: (directions.distanceMeters ?? 0) / 1000.0,
          durationInSeconds: directions.durationSeconds,
          isLoadingRoute: false,
          error: directions.error,
        );
      } else {
        final distanceInKm =
            Geolocator.distanceBetween(
              origin.latitude,
              origin.longitude,
              destination.latitude,
              destination.longitude,
            ) /
            1000.0;

        final polyline = Polyline(
          polylineId: const PolylineId('route'),
          points: [origin, destination],
          color: const Color(0xFF5F2D82),
          width: 8,
          geodesic: true,
        );

        state = state.copyWith(
          routePolylines: {polyline},
          distanceInKm: distanceInKm,
          durationInSeconds: (distanceInKm * 180).round(),
          isLoadingRoute: false,
          error: directions?.error ?? 'Using estimated straight-line route',
        );
      }
    } catch (e) {
      if (seq != _routeSeq) return;
      print('🔴 Lesgo: Error fetching route: $e');

      // Fallback to straight line on error
      final double distanceInKm =
          Geolocator.distanceBetween(
            origin.latitude,
            origin.longitude,
            destination.latitude,
            destination.longitude,
          ) /
          1000.0;

      final polyline = Polyline(
        polylineId: const PolylineId('route'),
        points: [origin, destination],
        color: const Color(0xFF5F2D82),
        width: 8, // Thicker line
        geodesic: true,
      );

      state = state.copyWith(
        routePolylines: {polyline},
        distanceInKm: distanceInKm,
        durationInSeconds: (distanceInKm * 180).round(),
        isLoadingRoute: false,
        error: e.toString(),
      );
    }
  }

  final _geocoder = AddressGeocoder();

  Future<LocationAddress?> _getAddressFromLocation(LatLng location) async {
    final ph = await _geocoder.reverse(location);
    if (ph == null || ph.isEmpty) return null;
    return LocationAddress.fromPh(ph);
  }

  /// Replaces the pin's address with the customer's confirmed details.
  void setAddressDetails({required bool destination, required PhAddress details}) {
    final address = LocationAddress.fromPh(details);
    state = destination
        ? state.copyWith(destinationAddress: address, address: address)
        : state.copyWith(pickupAddress: address, address: address);
  }
}

final lesgoLocationProvider =
    StateNotifierProvider<LesgoLocationNotifier, LesgoLocationState>((ref) {
      return LesgoLocationNotifier();
    });
