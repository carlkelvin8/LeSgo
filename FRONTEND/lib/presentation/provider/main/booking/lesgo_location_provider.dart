import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import '../../../../domain/models/location/location_address.dart';
import '../../../../core/constants/api_constants.dart';
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
      distanceInKm: distanceInKm ?? this.distanceInKm,
      durationInSeconds: durationInSeconds ?? this.durationInSeconds,
      isLoading: isLoading ?? this.isLoading,
      isLoadingRoute: isLoadingRoute ?? this.isLoadingRoute,
      error: error,
    );
  }
}

class LesgoLocationNotifier extends StateNotifier<LesgoLocationState> {
  LesgoLocationNotifier() : super(LesgoLocationState());

  void reset() {
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

      Position position = await Geolocator.getCurrentPosition(
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
      print('🔍 LesgoLocation: Got current location: $location, fetching address...');

      final address = await _getAddressFromLocation(location);
      print('🔍 LesgoLocation: Address fetched: ${address?.toString()}');

      state = state.copyWith(
        currentLocation: location,
        selectedLocation: location,
        pickupLocation: location,
        pickupAddress: address,
        address: address,
        isLoading: false,
      );

      // DON'T fetch route here - only fetch when user confirms location
    } catch (e) {
      print('⚠️ LesgoLocation: Error getting location, using default: $e');
      // Use default location (Cagayan de Oro City)
      final defaultLocation = BookingGeoUtils.defaultLatLng;
      final address = await _getAddressFromLocation(defaultLocation);
      
      state = state.copyWith(
        currentLocation: defaultLocation,
        selectedLocation: defaultLocation,
        pickupLocation: defaultLocation,
        pickupAddress: address,
        address: address,
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
    print('🔍 LesgoLocation: Pickup updated - pickupLocation: ${state.pickupLocation}, pickupAddress: ${state.pickupAddress}');
    // DON'T fetch route here - only fetch when user confirms location
    // Clear route since pickup changed
    state = state.copyWith(
      routePolylines: {},
      distanceInKm: null,
      durationInSeconds: null,
    );
  }

  Future<void> updateDestination(LatLng location) async {
    print('🔍 LesgoLocation: updateDestination called with: $location');
    state = state.copyWith(selectedLocation: location, isLoading: true);
    print('🔍 LesgoLocation: Fetching address for destination...');
    final address = await _getAddressFromLocation(location);
    print('🔍 LesgoLocation: Destination address fetched: ${address?.toString()}');
    state = state.copyWith(
      destinationLocation: location,
      destinationAddress: address,
      address: address,
      isLoading: false,
      // IMPORTANT: Clear route data when destination changes
      routePolylines: {},
      distanceInKm: null,
      durationInSeconds: null,
      isLoadingRoute: false,
    );
    print('🔍 LesgoLocation: Destination updated - destinationLocation: ${state.destinationLocation}');
    // DON'T fetch route here - only fetch when user confirms location
    print('🔍 LesGo: Destination updated, route cleared. User must confirm to calculate route.');
  }

  Future<void> updateDestinationWithAddress(
    LatLng location,
    String? formattedAddress,
    Map<String, String>? addressComponents,
  ) async {
    print('🔍 LesgoLocation: updateDestinationWithAddress called with: $location, $formattedAddress');
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
    print('🔍 LesgoLocation: After setting state, destinationLocation: ${state.destinationLocation}');
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
    // DON'T fetch route here - only fetch when user confirms location
    // Clear route since pickup changed
    state = state.copyWith(
      routePolylines: {},
      distanceInKm: null,
      durationInSeconds: null,
    );
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
      await fetchRoute(state.pickupLocation!, state.destinationLocation!, forceAllow: forceAllow);
    }
  }

  Future<void> fetchRoute(LatLng origin, LatLng destination, {bool forceAllow = false}) async {
    // ONLY allow route fetching if explicitly forced (from confirmSelection)
    if (!forceAllow) {
      print('🚫 Lesgo: Route fetch blocked - not from confirmation');
      print('🚫 Lesgo: Stack trace: ${StackTrace.current}');
      return;
    }
    
    print('✅ Lesgo: Route fetch ALLOWED - forceAllow=$forceAllow');
    
    if (origin == destination) {
      state = state.copyWith(routePolylines: {}, isLoadingRoute: false);
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
        final distanceInKm = Geolocator.distanceBetween(
          origin.latitude,
          origin.longitude,
          destination.latitude,
          destination.longitude,
        ) / 1000.0;

        final polyline = Polyline(
          polylineId: const PolylineId('route'),
          points: [origin, destination],
          color: const Color(0xFF5F2D82),
          width: 8,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
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
      print('🔴 Lesgo: Error fetching route: $e');
      
      // Fallback to straight line on error
      final double distanceInKm = Geolocator.distanceBetween(
        origin.latitude,
        origin.longitude,
        destination.latitude,
        destination.longitude,
      ) / 1000.0;

      final polyline = Polyline(
        polylineId: const PolylineId('route'),
        points: [origin, destination],
        color: const Color(0xFF5F2D82),
        width: 8, // Thicker line
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
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



  Future<LocationAddress?> _getAddressFromLocation(LatLng location) async {
    try {
      print('🔍 LesgoLocation: Reverse geocoding for: $location');
      
      // Try Google Geocoding API first (more reliable for web)
      final googleAddress = await _getAddressFromGoogleAPI(location);
      if (googleAddress != null) {
        return googleAddress;
      }
      
      // Fallback to geocoding package
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('🔴 LesgoLocation: Geocoding timeout');
          return <Placemark>[];
        },
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        print('🔍 LesgoLocation: Placemark data: ${place.toString()}');

        // Try to build a detailed address with street info
        List<String> addressParts = [];
        
        // Add house/building number and street
        if (place.subThoroughfare != null && place.subThoroughfare!.isNotEmpty) {
          if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
            addressParts.add('${place.subThoroughfare} ${place.thoroughfare}');
          } else {
            addressParts.add(place.subThoroughfare!);
          }
        } else if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
          addressParts.add(place.thoroughfare!);
        }
        
        // Add sub-locality (barangay/subdivision)
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          addressParts.add(place.subLocality!);
        }
        
        // Add locality (city/municipality)
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        } else if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          addressParts.add(place.administrativeArea!);
        }
        
        // If we have detailed parts, combine them
        if (addressParts.isNotEmpty) {
          final detailedAddress = addressParts.join(', ');
          print('🔍 LesgoLocation: Using detailed address: $detailedAddress');
          return LocationAddress(
            houseNumberStreet: addressParts.isNotEmpty ? addressParts[0] : null,
            subdivisionBarangay: addressParts.length > 1 ? addressParts[1] : null,
            cityProvince: addressParts.length > 2 ? addressParts.sublist(2).join(', ') : 
                         addressParts.length > 1 ? addressParts[1] : 
                         addressParts.isNotEmpty ? addressParts[0] : null,
            zipCode: place.postalCode,
          );
        }
        
        // Fallback to just locality/city if no street info
        String addressText = '';
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressText = place.locality!;
        } else if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          addressText = place.administrativeArea!;
        } else if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) {
          addressText = place.subAdministrativeArea!;
        }
        
        if (addressText.isNotEmpty) {
          print('🔍 LesgoLocation: Using basic address: $addressText');
          return LocationAddress(
            houseNumberStreet: null,
            subdivisionBarangay: null,
            cityProvince: addressText,
            zipCode: place.postalCode,
          );
        }
      }
      
      print('🔍 LesgoLocation: Using fallback address');
      
    } catch (e) {
      print('🔴 LesgoLocation: Geocoding error: $e');
    }
    
    // Always return a user-friendly fallback
    return LocationAddress(
      houseNumberStreet: null,
      subdivisionBarangay: null,
      cityProvince: 'Selected Location',
      zipCode: null,
    );
  }

  Future<LocationAddress?> _getAddressFromGoogleAPI(LatLng location) async {
    try {
      // Check if we have a Google Maps API key
      if (!ApiConstants.isGoogleMapsConfigured) {
        print('🔴 LesgoLocation: No Google Maps API key configured');
        return null;
      }

      final url = 'https://maps.googleapis.com/maps/api/geocode/json'
          '?latlng=${location.latitude},${location.longitude}'
          '&key=${ApiConstants.googleMapsApiKey}';

      print('🔍 LesgoLocation: Calling Google Geocoding API...');
      
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('🔴 LesgoLocation: Google API timeout');
          throw Exception('Timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        print('🔍 LesgoLocation: Google API response status: ${data['status']}');
        
        if (data['status'] == 'OK' && data['results'] != null && data['results'].isNotEmpty) {
          final results = data['results'] as List<dynamic>;
          
          // Try to find the most detailed result (with route/street information)
          dynamic bestResult;
          int bestScore = 0;
          
          for (var result in results) {
            final types = result['types'] as List<dynamic>?;
            final addressComponents = result['address_components'] as List<dynamic>?;
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
                  if (componentTypes.contains('sublocality_level_1')) score += 15;
                  if (componentTypes.contains('sublocality_level_2')) score += 10;
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
            final addressComponents = bestResult['address_components'] as List<dynamic>?;
            
            print('🔍 LesgoLocation: Using best result with score $bestScore: $formattedAddress');
            print('🔍 LesgoLocation: Address components: ${json.encode(addressComponents)}');
            
            // Try to extract detailed address from components first
            if (addressComponents != null) {
              final detailedAddress = _extractDetailedAddressFromComponents(addressComponents);
              if (detailedAddress != null) {
                print('🔍 LesgoLocation: Using detailed address from components');
                return detailedAddress;
              }
            }
            
            // Fallback to formatted address parsing
            if (formattedAddress != null && formattedAddress.isNotEmpty) {
              // Use the most detailed part of the formatted address
              final addressParts = formattedAddress.split(',').map((e) => e.trim()).toList();
              
              // Remove "Philippines" if it's the last part
              if (addressParts.isNotEmpty && addressParts.last.toLowerCase().contains('philippines')) {
                addressParts.removeLast();
              }
              
              // Take the first 2-3 most specific parts
              String detailedAddress;
              if (addressParts.length >= 3) {
                detailedAddress = addressParts.take(3).join(', ');
              } else if (addressParts.length >= 2) {
                detailedAddress = addressParts.take(2).join(', ');
              } else {
                detailedAddress = addressParts.isNotEmpty ? addressParts[0] : formattedAddress;
              }
              
              print('🔍 LesgoLocation: Using detailed address from formatted: $detailedAddress');
              
              return LocationAddress(
                houseNumberStreet: null,
                subdivisionBarangay: null,
                cityProvince: detailedAddress,
                zipCode: null,
              );
            }
          }
        } else {
          print('🔴 LesgoLocation: Google API error: ${data['status']}');
        }
      } else {
        print('🔴 LesgoLocation: Google API HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('🔴 LesgoLocation: Google API exception: $e');
    }
    
    return null;
  }

  LocationAddress? _extractDetailedAddressFromComponents(List<dynamic> components) {
    try {
      String? streetNumber;
      String? route;
      String? subpremise; // For unit/lot numbers
      String? premise; // For building numbers
      String? locality;
      String? sublocality;
      String? sublocalityLevel1;
      String? sublocalityLevel2;
      String? sublocalityLevel3;
      String? administrativeAreaLevel1; // Province

      String? administrativeAreaLevel2; // City/Municipality
      String? administrativeAreaLevel3; // District
      String? postalCode;
      
      print('🔍 LesgoLocation: Processing ${components.length} address components...');
      
      for (var component in components) {
        final types = component['types'] as List<dynamic>?;
        final longName = component['long_name'] as String?;
        final shortName = component['short_name'] as String?;
        
        if (types != null && longName != null && longName.isNotEmpty) {
          print('🔍 LesgoLocation: Component - types: $types, longName: $longName, shortName: $shortName');
          
          if (types.contains('street_number')) {
            streetNumber = longName;
          } else if (types.contains('route')) {
            route = longName;
          } else if (types.contains('subpremise')) {
            subpremise = longName; // Unit, Lot, etc.
          } else if (types.contains('premise')) {
            premise = longName; // Building number
          } else if (types.contains('sublocality_level_1')) {
            sublocalityLevel1 = longName;
          } else if (types.contains('sublocality_level_2')) {
            sublocalityLevel2 = longName;
          } else if (types.contains('sublocality_level_3')) {
            sublocalityLevel3 = longName;
          } else if (types.contains('sublocality')) {
            sublocality = longName;
          } else if (types.contains('locality')) {
            locality = longName;
          } else if (types.contains('administrative_area_level_1')) {
            administrativeAreaLevel1 = longName; // Province
          } else if (types.contains('administrative_area_level_2')) {
            administrativeAreaLevel2 = longName; // City/Municipality
          } else if (types.contains('administrative_area_level_3')) {
            administrativeAreaLevel3 = longName; // District
          } else if (types.contains('postal_code')) {
            postalCode = longName;
          }
        }
      }
      
      // Build detailed address parts
      List<String> addressParts = [];
      
      // Add most specific location details first
      if (subpremise != null) {
        addressParts.add(subpremise); // "Lot 32" or "Unit 5A"
        print('🔍 LesgoLocation: Added subpremise: $subpremise');
      }
      
      if (premise != null) {
        addressParts.add(premise); // "Blk 10"
        print('🔍 LesgoLocation: Added premise: $premise');
      }
      
      // Add street information
      if (streetNumber != null && route != null) {
        addressParts.add('$streetNumber $route'); // "123 Main Street"
        print('🔍 LesgoLocation: Added street: $streetNumber $route');
      } else if (route != null) {
        addressParts.add(route); // "Main Street"
        print('🔍 LesgoLocation: Added route: $route');
      } else if (streetNumber != null) {
        addressParts.add(streetNumber);
        print('🔍 LesgoLocation: Added street number: $streetNumber');
      }
      
      // Add subdivision/barangay information (most specific first)
      if (sublocalityLevel3 != null) {
        addressParts.add(sublocalityLevel3); // Most specific subdivision
        print('🔍 LesgoLocation: Added sublocality level 3: $sublocalityLevel3');
      } else if (sublocalityLevel2 != null) {
        addressParts.add(sublocalityLevel2);
        print('🔍 LesgoLocation: Added sublocality level 2: $sublocalityLevel2');
      } else if (sublocalityLevel1 != null) {
        addressParts.add(sublocalityLevel1);
        print('🔍 LesgoLocation: Added sublocality level 1: $sublocalityLevel1');
      } else if (sublocality != null) {
        addressParts.add(sublocality);
        print('🔍 LesgoLocation: Added sublocality: $sublocality');
      }
      
      // Add city/municipality
      if (locality != null) {
        addressParts.add(locality);
        print('🔍 LesgoLocation: Added locality: $locality');
      } else if (administrativeAreaLevel2 != null) {
        addressParts.add(administrativeAreaLevel2);
        print('🔍 LesgoLocation: Added admin area level 2: $administrativeAreaLevel2');
      } else if (administrativeAreaLevel3 != null) {
        addressParts.add(administrativeAreaLevel3);
        print('🔍 LesgoLocation: Added admin area level 3: $administrativeAreaLevel3');
      }
      
      if (addressParts.isNotEmpty) {
        final detailedAddress = addressParts.join(', ');
        print('🔍 LesgoLocation: Final detailed address: $detailedAddress');
        
        return LocationAddress(
          houseNumberStreet: addressParts.isNotEmpty ? addressParts[0] : null,
          subdivisionBarangay: addressParts.length > 1 ? addressParts[1] : null,
          cityProvince: detailedAddress, // Store the full detailed address here
          zipCode: postalCode,
        );
      }
      
      print('🔍 LesgoLocation: No detailed address parts found');
      return null;
      
    } catch (e) {
      print('🔴 LesgoLocation: Error extracting detailed address: $e');
      return null;
    }
  }


}

final lesgoLocationProvider =
    StateNotifierProvider<LesgoLocationNotifier, LesgoLocationState>((ref) {
      return LesgoLocationNotifier();
    });
