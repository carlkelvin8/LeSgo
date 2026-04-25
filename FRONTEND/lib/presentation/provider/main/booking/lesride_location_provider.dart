import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import '../../../../domain/models/location/location_address.dart';
import '../../../../core/constants/api_constants.dart';

class LesrideLocationState {
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

  LesrideLocationState({
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

  LesrideLocationState copyWith({
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
  }) {
    return LesrideLocationState(
      currentLocation: currentLocation ?? this.currentLocation,
      selectedLocation: selectedLocation ?? this.selectedLocation,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      destinationLocation: destinationLocation ?? this.destinationLocation,
      address: address ?? this.address,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      routePolylines: routePolylines ?? this.routePolylines,
      distanceInKm: distanceInKm ?? this.distanceInKm,
      durationInSeconds: durationInSeconds ?? this.durationInSeconds,
      isLoading: isLoading ?? this.isLoading,
      isLoadingRoute: isLoadingRoute ?? this.isLoadingRoute,
      error: error,
    );
  }
}

class LesrideLocationNotifier extends StateNotifier<LesrideLocationState> {
  LesrideLocationNotifier() : super(LesrideLocationState());

  void reset() {
    state = LesrideLocationState(
      routePolylines: {},
      distanceInKm: null,
      durationInSeconds: null,
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

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final location = LatLng(position.latitude, position.longitude);

      final address = await _getAddressFromLocation(location);

      state = state.copyWith(
        currentLocation: location,
        selectedLocation: location,
        pickupLocation: location,
        pickupAddress: address,
        address: address,
        isLoading: false,
      );

      // Fetch route if destination is already set
      if (state.destinationLocation != null) {
        await fetchRoute(location, state.destinationLocation!);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateSelectedLocation(LatLng location) async {
    state = state.copyWith(selectedLocation: location, isLoading: true);

    final address = await _getAddressFromLocation(location);
    state = state.copyWith(address: address, isLoading: false);
  }

  Future<void> updatePickup(LatLng location) async {
    state = state.copyWith(selectedLocation: location, isLoading: true);
    final address = await _getAddressFromLocation(location);
    state = state.copyWith(
      pickupLocation: location,
      pickupAddress: address,
      address: address,
      isLoading: false,
    );
    // Fetch route if destination is already set
    if (state.destinationLocation != null) {
      await fetchRoute(location, state.destinationLocation!);
    } else {
      // Clear route if destination is removed
      state = state.copyWith(
        routePolylines: {},
        distanceInKm: null,
        durationInSeconds: null,
      );
    }
  }

  Future<void> updateDestination(LatLng location) async {
    state = state.copyWith(selectedLocation: location, isLoading: true);
    final address = await _getAddressFromLocation(location);
    state = state.copyWith(
      destinationLocation: location,
      destinationAddress: address,
      address: address,
      isLoading: false,
    );
    // Fetch route if pickup is already set
    if (state.pickupLocation != null) {
      await fetchRoute(state.pickupLocation!, location);
    }
  }

  Future<void> updateDestinationWithAddress(
    LatLng location,
    String? formattedAddress,
    Map<String, String>? addressComponents,
  ) async {
    state = state.copyWith(selectedLocation: location, isLoading: true);
    LocationAddress? address;

    if (addressComponents != null && addressComponents.isNotEmpty) {
      // Use structured address components from Google Places API
      address = _parseAddressComponents(addressComponents);
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
      destinationLocation: location,
      destinationAddress: address,
      address: address,
      isLoading: false,
    );
    // Fetch route if pickup is already set
    if (state.pickupLocation != null) {
      await fetchRoute(state.pickupLocation!, location);
    }
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
      address = _parseAddressComponents(addressComponents);
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
    // Fetch route if destination is already set
    if (state.destinationLocation != null) {
      await fetchRoute(location, state.destinationLocation!);
    } else {
      // Clear route if destination is removed
      state = state.copyWith(
        routePolylines: {},
        distanceInKm: null,
        durationInSeconds: null,
      );
    }
  }

  LocationAddress? _parseAddressComponents(Map<String, String> components) {
    final houseNumber = components['houseNumber'] ?? '';
    final streetName = components['streetName'] ?? '';
    final houseNumberStreet = houseNumber.isNotEmpty && streetName.isNotEmpty
        ? '$houseNumber $streetName'
        : streetName.isNotEmpty
        ? streetName
        : houseNumber;

    final barangay = components['barangay'] ?? '';
    final city = components['city'] ?? '';
    final province = components['province'] ?? '';
    final cityProvince = city.isNotEmpty && province.isNotEmpty
        ? '$city, $province'
        : city.isNotEmpty
        ? city
        : province;

    final zipCode = components['zipCode'] ?? '';

    return LocationAddress(
      houseNumberStreet: houseNumberStreet.isNotEmpty
          ? houseNumberStreet
          : null,
      subdivisionBarangay: barangay.isNotEmpty ? barangay : null,
      cityProvince: cityProvince.isNotEmpty ? cityProvince : null,
      zipCode: zipCode.isNotEmpty ? zipCode : null,
    );
  }

  LocationAddress? _parseFormattedAddress(String formattedAddress) {
    // Parse formatted address like "Malolos, Bulacan, Philippines"
    // Split by comma and assign to appropriate fields
    final parts = formattedAddress.split(',').map((e) => e.trim()).toList();

    if (parts.isEmpty) return null;

    // For city/region names like "Malolos, Bulacan, Philippines"
    // We'll use the first part as subdivisionBarangay and combine city/province
    String? subdivisionBarangay;
    String? cityProvince;

    if (parts.isEmpty) {
      subdivisionBarangay = parts[0];
    }

    if (parts.length >= 2) {
      // Combine city and province (e.g., "Bulacan, Philippines" -> "Bulacan, Philippines")
      cityProvince = parts.sublist(1).join(', ');
    } else if (parts.length == 1) {
      // If only one part, use it as cityProvince
      cityProvince = parts[0];
      subdivisionBarangay = null;
    }

    return LocationAddress(
      houseNumberStreet: null, // Not available from formatted address
      subdivisionBarangay: subdivisionBarangay,
      cityProvince: cityProvince,
      zipCode: null, // Not available from formatted address
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
  Future<void> fetchRouteIfBothSet() async {
    if (state.pickupLocation != null && state.destinationLocation != null) {
      await fetchRoute(state.pickupLocation!, state.destinationLocation!);
    }
  }

  Future<void> fetchRoute(LatLng origin, LatLng destination) async {
    if (origin == destination) {
      state = state.copyWith(routePolylines: {}, isLoadingRoute: false);
      return;
    }

    state = state.copyWith(isLoadingRoute: true, error: null);

    try {
      // Check if API key is configured
      if (ApiConstants.googleMapsApiKey.isEmpty) {
        state = state.copyWith(
          isLoadingRoute: false,
          error: 'Google Maps API key not configured',
        );
        return;
      }

      // Temporarily disable directions API to avoid CORS issues
      // TODO: Implement proper directions API integration
      
      // For now, just calculate straight-line distance
      final double distanceInKm = Geolocator.distanceBetween(
        origin.latitude,
        origin.longitude,
        destination.latitude,
        destination.longitude,
      ) / 1000.0;

      // Create a simple straight line polyline
      final polyline = Polyline(
        polylineId: const PolylineId('route'),
        points: [origin, destination],
        color: const Color(0xFF7C3AED),
        width: 6,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)], // Dashed line to indicate it's not a real route
        geodesic: true,
      );

      state = state.copyWith(
        routePolylines: {polyline},
        distanceInKm: distanceInKm,
        durationInSeconds: (distanceInKm * 180).round(), // Rough estimate: 3 min per km = 180 sec per km
        isLoadingRoute: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoadingRoute: false, error: e.toString());
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    if (encoded.isEmpty) return points;

    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      // Decode latitude
      int shift = 0;
      int result = 0;
      int b;
      do {
        if (index >= len) break;
        b = encoded.codeUnitAt(index++) - 63;
        result += (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20 && index < len);
      int dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      // Decode longitude
      shift = 0;
      result = 0;
      do {
        if (index >= len) break;
        b = encoded.codeUnitAt(index++) - 63;
        result += (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20 && index < len);
      int dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  Future<LocationAddress?> _getAddressFromLocation(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        final streetName = place.thoroughfare ?? place.street ?? '';
        final houseNumber = place.subThoroughfare ?? '';
        final houseNumberStreet =
            houseNumber.isNotEmpty && streetName.isNotEmpty
            ? '$houseNumber $streetName'
            : streetName;

        final address = LocationAddress(
          houseNumberStreet: houseNumberStreet,
          subdivisionBarangay: place.subLocality ?? place.locality ?? '',
          cityProvince:
              '${place.locality ?? ''}, ${place.administrativeArea ?? ''}'
                  .trim(),
          zipCode: place.postalCode ?? '',
        );

        return address;
      }
    } catch (e) {
      // Handle geocoding errors silently
    }
    return null;
  }
}

final lesrideLocationProvider =
    StateNotifierProvider<LesrideLocationNotifier, LesrideLocationState>((ref) {
      return LesrideLocationNotifier();
    });
