import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import '../../../../domain/models/location/location_address.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/directions_route_service.dart';
import '../../../../core/utils/booking_geo_utils.dart';

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
    bool clearRouteMetrics = false,
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
      distanceInKm: clearRouteMetrics
          ? null
          : (distanceInKm ?? this.distanceInKm),
      durationInSeconds: clearRouteMetrics
          ? null
          : (durationInSeconds ?? this.durationInSeconds),
      isLoading: isLoading ?? this.isLoading,
      isLoadingRoute: isLoadingRoute ?? this.isLoadingRoute,
      error: error,
    );
  }
}

class LesrideLocationNotifier extends StateNotifier<LesrideLocationState> {
  Timer? _routeDebounceTimer;
  int _pickupRequestId = 0;
  int _destinationRequestId = 0;
  int _routeRequestId = 0;

  LesrideLocationNotifier() : super(LesrideLocationState());

  @override
  void dispose() {
    _routeDebounceTimer?.cancel();
    super.dispose();
  }

  void reset() {
    _pickupRequestId++;
    _destinationRequestId++;
    _routeRequestId++;
    state = LesrideLocationState(
      routePolylines: <Polyline>{}, // Explicitly clear polylines
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
    print('🔄 LesRide: State reset - all polylines cleared');
  }

  Future<void> getCurrentLocation() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
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

      final Position position =
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 15), // Increased timeout
            ),
          ).timeout(
            const Duration(
              seconds: 15,
            ), // Increased timeout for better detection
            onTimeout: () {
              // Use default location (Manila) if timeout
              throw Exception('Location request timed out');
            },
          );

      final location = LatLng(position.latitude, position.longitude);

      // Check if location is in Philippines (rough bounds check)
      final isInPhilippines =
          (location.latitude >= 4.0 && location.latitude <= 21.0) &&
          (location.longitude >= 116.0 && location.longitude <= 127.0);

      if (!isInPhilippines) {
        print(
          '⚠️ Lesride: Detected location outside Philippines: $location, using Manila default',
        );
        throw Exception('Location outside Philippines bounds');
      }

      print('✅ Lesride: Detected Philippines location: $location');

      final address = await _getAddressFromLocation(location);

      state = state.copyWith(
        currentLocation: location,
        selectedLocation: location,
        pickupLocation: location,
        pickupAddress: address,
        address: address,
        routePolylines: {},
        clearRouteMetrics: true,
        isLoadingRoute: false,
        isLoading: false,
      );

      // DON'T fetch route here - only fetch when user confirms location
    } catch (e) {
      print('⚠️ Lesride: Error getting location, using Manila default: $e');
      // Use default location (Manila, Philippines) - more central location
      final defaultLocation = BookingGeoUtils.defaultLatLng;
      final address = await _getAddressFromLocation(defaultLocation);

      state = state.copyWith(
        currentLocation: defaultLocation,
        selectedLocation: defaultLocation,
        pickupLocation: defaultLocation,
        pickupAddress: address,
        address: address,
        routePolylines: {},
        clearRouteMetrics: true,
        isLoadingRoute: false,
        isLoading: false,
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
    final requestId = ++_pickupRequestId;
    _routeRequestId++;
    state = state.copyWith(selectedLocation: location, isLoading: true);
    final address = await _getAddressFromLocation(location);
    if (requestId != _pickupRequestId) return;
    state = state.copyWith(
      pickupLocation: location,
      pickupAddress: address,
      address: address,
      isLoading: false,
      // IMPORTANT: Clear route data when pickup changes
      routePolylines: {},
      clearRouteMetrics: true,
      isLoadingRoute: false,
    );
    // DON'T fetch route here - only fetch when user confirms location
    print(
      '🚗 Lesride: Pickup updated, route cleared. User must confirm to calculate route.',
    );
  }

  Future<void> updateDestination(LatLng location) async {
    print('🚗 Lesride: updateDestination called with: $location');
    print('🚗 Lesride: Stack trace: ${StackTrace.current}');

    // Cancel any pending route calculations to prevent loops
    _routeDebounceTimer?.cancel();
    final requestId = ++_destinationRequestId;
    _routeRequestId++;

    state = state.copyWith(selectedLocation: location, isLoading: true);
    final address = await _getAddressFromLocation(location);
    if (requestId != _destinationRequestId) return;
    state = state.copyWith(
      destinationLocation: location,
      destinationAddress: address,
      address: address,
      isLoading: false,
      // IMPORTANT: Clear route data when destination changes
      routePolylines: {},
      clearRouteMetrics: true,
      isLoadingRoute: false,
    );
    // DON'T fetch route here - only fetch when user confirms location
    print(
      '🚗 Lesride: Destination updated, route cleared. User must confirm to calculate route.',
    );
  }

  Future<void> updateDestinationWithAddress(
    LatLng location,
    String? formattedAddress,
    Map<String, String>? addressComponents,
  ) async {
    print('🚗 updateDestinationWithAddress called with: $location');

    // Cancel any pending route calculations to prevent loops
    _routeDebounceTimer?.cancel();
    final requestId = ++_destinationRequestId;
    _routeRequestId++;

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

    if (requestId != _destinationRequestId) return;

    state = state.copyWith(
      destinationLocation: location,
      destinationAddress: address,
      address: address,
      isLoading: false,
      // Clear route data when destination changes
      routePolylines: {},
      clearRouteMetrics: true,
      isLoadingRoute: false,
    );
    // DON'T fetch route here - only fetch when user confirms location
    // Route will be fetched in confirmSelection() or when explicitly called
    print('🚗 Lesride: Destination updated with address, route cleared.');
  }

  Future<void> updatePickupWithAddress(
    LatLng location,
    String? formattedAddress,
    Map<String, String>? addressComponents,
  ) async {
    final requestId = ++_pickupRequestId;
    _routeRequestId++;
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

    if (requestId != _pickupRequestId) return;

    state = state.copyWith(
      pickupLocation: location,
      pickupAddress: address,
      address: address,
      isLoading: false,
    );
    // DON'T fetch route here - only fetch when user confirms location
    // Clear route since pickup changed
    state = state.copyWith(routePolylines: {}, clearRouteMetrics: true);
  }

  LocationAddress? _parseAddressComponents(Map<String, String> components) {
    final houseNumber =
        components['houseNumber'] ?? components['street_number'] ?? '';
    final streetName = components['streetName'] ?? components['route'] ?? '';
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
    final requestId = ++_pickupRequestId;
    _routeRequestId++;
    state = state.copyWith(
      pickupLocation: location,
      routePolylines: {},
      clearRouteMetrics: true,
      isLoadingRoute: false,
    );

    // Perform reverse geocoding to get address
    final address = await _getAddressFromLocation(location);
    if (requestId == _pickupRequestId &&
        state.pickupLocation == location &&
        address != null) {
      state = state.copyWith(pickupAddress: address);
    }
  }

  void setDestinationLocation(LatLng location) async {
    final requestId = ++_destinationRequestId;
    _routeRequestId++;
    state = state.copyWith(
      destinationLocation: location,
      routePolylines: {},
      clearRouteMetrics: true,
      isLoadingRoute: false,
    );

    // Perform reverse geocoding to get address
    final address = await _getAddressFromLocation(location);
    if (requestId == _destinationRequestId &&
        state.destinationLocation == location &&
        address != null) {
      state = state.copyWith(destinationAddress: address);
    }
  }

  /// Debug method to test route calculation with Manila locations
  Future<void> testRouteWithManilaLocations() async {
    print('🧪 Testing route with Manila locations...');

    // Set test locations in Manila
    final pickup = BookingGeoUtils.defaultLatLng;
    const destination = LatLng(14.6042, 120.9822); // Intramuros

    print('🧪 Setting pickup: $pickup');
    print('🧪 Setting destination: $destination');

    state = state.copyWith(
      pickupLocation: pickup,
      destinationLocation: destination,
      pickupAddress: LocationAddress(
        houseNumberStreet: null,
        subdivisionBarangay: 'Ermita',
        cityProvince: 'Manila, Metro Manila',
        zipCode: '1000',
      ),
      destinationAddress: LocationAddress(
        houseNumberStreet: null,
        subdivisionBarangay: 'Intramuros',
        cityProvince: 'Manila, Metro Manila',
        zipCode: '1002',
      ),
    );

    // Force route calculation
    print('🧪 Forcing route calculation...');
    await fetchRoute(pickup, destination, forceAllow: true);

    // Debug result
    print('🧪 Test complete - polylines: ${state.routePolylines.length}');
    if (state.routePolylines.isNotEmpty) {
      final polyline = state.routePolylines.first;
      print(
        '🧪 Polyline color: ${polyline.color}, points: ${polyline.points.length}',
      );
    }
  }

  /// Fetches route between current pickup and destination if both are set
  Future<void> fetchRouteIfBothSet({bool forceAllow = false}) async {
    print(
      '🔍 Lesride: fetchRouteIfBothSet called with forceAllow: $forceAllow',
    );
    print('🔍 Lesride: Stack trace: ${StackTrace.current}');

    if (state.pickupLocation != null && state.destinationLocation != null) {
      await fetchRoute(
        state.pickupLocation!,
        state.destinationLocation!,
        forceAllow: forceAllow,
      );
    } else {
      print(
        '🔍 Lesride: Missing locations - pickup: ${state.pickupLocation != null}, destination: ${state.destinationLocation != null}',
      );
    }
  }

  Future<void> fetchRoute(
    LatLng origin,
    LatLng destination, {
    bool forceAllow = false,
  }) async {
    // STRICT: ONLY allow route fetching if explicitly forced AND not from automatic triggers
    if (!forceAllow) {
      print(
        '🚫 Lesride: Route fetch BLOCKED - must be from manual confirmation only',
      );
      return;
    }

    print('✅ Lesride: Route fetch ALLOWED from manual confirmation');

    // Cancel any existing debounce timer
    _routeDebounceTimer?.cancel();

    final requestId = ++_routeRequestId;

    if (origin == destination) {
      state = state.copyWith(
        routePolylines: {},
        distanceInKm: 0,
        durationInSeconds: 0,
        isLoadingRoute: false,
        error: 'Pickup and destination must be different.',
      );
      return;
    }

    await _performRouteCalculation(origin, destination, requestId);
  }

  Future<void> _performRouteCalculation(
    LatLng origin,
    LatLng destination,
    int requestId,
  ) async {
    state = state.copyWith(
      isLoadingRoute: true,
      error: null,
      routePolylines: {},
      clearRouteMetrics: true,
    );

    try {
      // Check if API key is configured
      if (!ApiConstants.isGoogleMapsConfigured) {
        if (!_isCurrentRoute(requestId, origin, destination)) return;
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

      if (!_isCurrentRoute(requestId, origin, destination)) return;

      if (directions != null &&
          directions.points.isNotEmpty &&
          (directions.distanceMeters ?? 0) > 0) {
        final polyline = Polyline(
          polylineId: const PolylineId('route'),
          points: directions.points,
          color: const Color(0xFF1976D2),
          width: 6,
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
          color: const Color(0xFF1976D2),
          width: 6,
          geodesic: true,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
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
      print('Error fetching route: $e');

      if (!_isCurrentRoute(requestId, origin, destination)) return;

      // Fallback to straight line on error
      final double distanceInKm =
          Geolocator.distanceBetween(
            origin.latitude,
            origin.longitude,
            destination.latitude,
            destination.longitude,
          ) /
          1000.0;

      // Fallback: Use straight line on error
      final polyline = Polyline(
        polylineId: const PolylineId('route'),
        points: [origin, destination],
        color: const Color(0xFF1976D2), // Blue color
        width: 6, // Medium thickness
        geodesic: true, // Enable geodesic
        patterns: [
          PatternItem.dash(20),
          PatternItem.gap(10),
        ], // Dashed for error
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

  bool _isCurrentRoute(int requestId, LatLng origin, LatLng destination) {
    return requestId == _routeRequestId &&
        state.pickupLocation == origin &&
        state.destinationLocation == destination;
  }

  Future<LocationAddress?> _getAddressFromLocation(LatLng location) async {
    try {
      print('🔍 LesrideLocation: Reverse geocoding for: $location');

      // Try Google Geocoding API first (more reliable and detailed)
      final googleAddress = await _getAddressFromGoogleAPI(location);
      if (googleAddress != null) {
        return googleAddress;
      }

      // Fallback to geocoding package
      final placemarks = await placemarkFromCoordinates(
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
      print('🔴 LesrideLocation: Geocoding error: $e');
    }
    return null;
  }

  Future<LocationAddress?> _getAddressFromGoogleAPI(LatLng location) async {
    try {
      // Check if we have a Google Maps API key
      if (!ApiConstants.isGoogleMapsConfigured) {
        print('🔴 LesrideLocation: No Google Maps API key configured');
        return null;
      }

      final url =
          'https://maps.googleapis.com/maps/api/geocode/json'
          '?latlng=${location.latitude},${location.longitude}'
          '&key=${ApiConstants.googleMapsApiKey}';

      print('🔍 LesrideLocation: Calling Google Geocoding API...');

      final response = await http
          .get(Uri.parse(url))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('🔴 LesrideLocation: Google API timeout');
              throw Exception('Timeout');
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        print(
          '🔍 LesrideLocation: Google API response status: ${data['status']}',
        );

        if (data['status'] == 'OK' &&
            data['results'] != null &&
            data['results'].isNotEmpty) {
          final results = data['results'] as List<dynamic>;

          // Try to find the most detailed result (with route/street information)
          dynamic bestResult;
          int bestScore = 0;

          for (var result in results) {
            final types = result['types'] as List<dynamic>?;
            final addressComponents =
                result['address_components'] as List<dynamic>?;
            int score = 0;

            // Prioritize results with street/route information
            if (types != null) {
              if (types.contains('street_address')) score += 100;
              if (types.contains('premise')) score += 90;
              if (types.contains('route')) score += 80;
              if (types.contains('sublocality')) score += 70;
              if (types.contains('locality')) score += 50;
              // Deprioritize plus_code only results
              if (types.contains('plus_code') && types.length == 1) score -= 50;
            }

            // Check if it has route/street in address components
            if (addressComponents != null) {
              for (var component in addressComponents) {
                final componentTypes = component['types'] as List<dynamic>?;
                if (componentTypes != null) {
                  if (componentTypes.contains('route')) score += 30;
                  if (componentTypes.contains('street_number')) score += 20;
                  if (componentTypes.contains('sublocality_level_1')) {
                    score += 15;
                  }
                  if (componentTypes.contains('sublocality_level_2')) {
                    score += 10;
                  }
                }
              }
            }

            if (score > bestScore) {
              bestScore = score;
              bestResult = result;
            }
          }

          // Use the best result found
          if (bestResult != null) {
            final formattedAddress = bestResult['formatted_address'] as String?;

            print(
              '🔍 LesrideLocation: Using best result with score $bestScore: $formattedAddress',
            );

            // Use formatted address parsing
            if (formattedAddress != null && formattedAddress.isNotEmpty) {
              // Use the most detailed part of the formatted address
              final addressParts = formattedAddress
                  .split(',')
                  .map((e) => e.trim())
                  .toList();

              // Remove "Philippines" if it's the last part
              if (addressParts.isNotEmpty &&
                  addressParts.last.toLowerCase().contains('philippines')) {
                addressParts.removeLast();
              }

              // Take the first 2-3 most specific parts
              String detailedAddress;
              if (addressParts.length >= 3) {
                detailedAddress = addressParts.take(3).join(', ');
              } else if (addressParts.length >= 2) {
                detailedAddress = addressParts.take(2).join(', ');
              } else {
                detailedAddress = addressParts.isNotEmpty
                    ? addressParts[0]
                    : formattedAddress;
              }

              print(
                '🔍 LesrideLocation: Using detailed address: $detailedAddress',
              );

              return LocationAddress(
                houseNumberStreet: null,
                subdivisionBarangay: null,
                cityProvince: detailedAddress,
                zipCode: null,
              );
            }
          }
        } else {
          print('🔴 LesrideLocation: Google API error: ${data['status']}');
        }
      } else {
        print(
          '🔴 LesrideLocation: Google API HTTP error: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('🔴 LesrideLocation: Google API exception: $e');
    }

    return null;
  }
}

final lesrideLocationProvider =
    StateNotifierProvider<LesrideLocationNotifier, LesrideLocationState>((ref) {
      return LesrideLocationNotifier();
    });
