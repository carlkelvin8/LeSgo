import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lesgo/core/state/user_session_epoch.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import '../../../../domain/models/location/location_address.dart';
import '../../../../core/constants/api_constants.dart';

class LocationState {
  final LatLng? currentLocation;
  final LatLng? selectedLocation;
  final LatLng? pickupLocation;
  final LatLng? destinationLocation;
  final LocationAddress? address;
  final LocationAddress? pickupAddress;
  final LocationAddress? destinationAddress;
  final bool isLoading;
  final String? error;

  LocationState({
    this.currentLocation,
    this.selectedLocation,
    this.pickupLocation,
    this.destinationLocation,
    this.address,
    this.pickupAddress,
    this.destinationAddress,
    this.isLoading = false,
    this.error,
  });

  LocationState copyWith({
    LatLng? currentLocation,
    LatLng? selectedLocation,
    LatLng? pickupLocation,
    LatLng? destinationLocation,
    LocationAddress? address,
    LocationAddress? pickupAddress,
    LocationAddress? destinationAddress,
    bool? isLoading,
    String? error,
  }) {
    return LocationState(
      currentLocation: currentLocation ?? this.currentLocation,
      selectedLocation: selectedLocation ?? this.selectedLocation,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      destinationLocation: destinationLocation ?? this.destinationLocation,
      address: address ?? this.address,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class LocationNotifier extends StateNotifier<LocationState> {
  LocationNotifier() : super(LocationState());

  void reset() {
    state = LocationState();
  }

  Future<void> getCurrentLocation() async {
    print('🔵 LocationProvider: Getting current location...');
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

      print('🔵 LocationProvider: Getting position...');
      Position position =
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 15),
            ),
          ).timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception(
                'Location request timed out. Tap the button again or pick a spot on the map.',
              );
            },
          );

      final location = LatLng(position.latitude, position.longitude);
      print(
        '🔵 LocationProvider: Got position - ${location.latitude}, ${location.longitude}',
      );

      print('🔵 LocationProvider: Getting address from location...');
      final address = await _getAddressFromLocation(location);
      print('🔵 LocationProvider: Got address - $address');

      state = state.copyWith(
        currentLocation: location,
        selectedLocation: location,
        pickupLocation: location,
        pickupAddress: address,
        address: address,
        isLoading: false,
      );
      print('🔵 LocationProvider: State updated successfully');
    } catch (e) {
      print('🔴 LocationProvider: Error - $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateSelectedLocation(LatLng location) async {
    state = state.copyWith(selectedLocation: location, isLoading: true);

    final address = await _getAddressFromLocation(location);
    state = state.copyWith(address: address, isLoading: false);
  }

  Future<void> updateSelectedLocationWithAddress(
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

    state = state.copyWith(address: address, isLoading: false);
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

  Future<void> updatePickup(LatLng location) async {
    state = state.copyWith(selectedLocation: location, isLoading: true);
    final address = await _getAddressFromLocation(location);
    state = state.copyWith(
      pickupLocation: location,
      pickupAddress: address,
      address: address,
      isLoading: false,
    );
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
  }

  void setSelectedLocation(LatLng location) {
    state = state.copyWith(selectedLocation: location);
  }

  Future<LocationAddress?> _getAddressFromLocation(LatLng location) async {
    try {
      print('🔵 LocationProvider: Trying Google Geocoding API first...');

      // Try Google Geocoding API first for better results
      try {
        final googleAddress = await _getAddressFromGoogleAPI(location);
        if (googleAddress != null) {
          print('🔵 LocationProvider: Google API success');
          return googleAddress;
        }
      } catch (e) {
        print('🔴 LocationProvider: Google API failed - $e');
      }

      print('🔵 LocationProvider: Falling back to geocoding package...');

      // Fallback to geocoding package with better error handling
      try {
        List<Placemark> placemarks =
            await placemarkFromCoordinates(
              location.latitude,
              location.longitude,
            ).timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                print('🔴 LocationProvider: Geocoding timeout');
                return <Placemark>[];
              },
            );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          print('🔵 LocationProvider: Geocoding success');
          print('🔵 LocationProvider: - locality: ${place.locality}');
          print('🔵 LocationProvider: - subLocality: ${place.subLocality}');
          print(
            '🔵 LocationProvider: - administrativeArea: ${place.administrativeArea}',
          );
          print('🔵 LocationProvider: - thoroughfare: ${place.thoroughfare}');
          print(
            '🔵 LocationProvider: - subThoroughfare: ${place.subThoroughfare}',
          );

          final streetName = place.thoroughfare ?? place.street ?? '';
          final houseNumber = place.subThoroughfare ?? '';
          final houseNumberStreet =
              houseNumber.isNotEmpty && streetName.isNotEmpty
              ? '$houseNumber $streetName'
              : streetName.isNotEmpty
              ? streetName
              : null;

          final barangay = place.subLocality ?? place.locality ?? '';
          final city = place.locality ?? place.subAdministrativeArea ?? '';
          final province = place.administrativeArea ?? '';

          final cityProvince = city.isNotEmpty && province.isNotEmpty
              ? '$city, $province'
              : city.isNotEmpty
              ? city
              : province.isNotEmpty
              ? province
              : 'Philippines';

          final address = LocationAddress(
            houseNumberStreet: houseNumberStreet,
            subdivisionBarangay: barangay.isNotEmpty ? barangay : null,
            cityProvince: cityProvince,
            zipCode: place.postalCode,
          );

          print('🔵 LocationProvider: Created address - $cityProvince');
          return address;
        } else {
          print('🔴 LocationProvider: Geocoding returned empty results');
        }
      } catch (e) {
        print('🔴 LocationProvider: Geocoding package error - $e');
      }

      // Always return default address as fallback
      print('🔵 LocationProvider: Using default address');
      return _getDefaultAddress(location);
    } catch (e, stackTrace) {
      print('🔴 LocationProvider: Unexpected error - $e');
      print('🔴 LocationProvider: Stack trace - $stackTrace');
      return _getDefaultAddress(location);
    }
  }

  Future<LocationAddress?> _getAddressFromGoogleAPI(LatLng location) async {
    try {
      final url =
          'https://maps.googleapis.com/maps/api/geocode/json'
          '?latlng=${location.latitude},${location.longitude}'
          '&key=${ApiConstants.googleMapsApiKey}';

      print('🔵 LocationProvider: Calling Google Geocoding API...');

      final response = await http
          .get(Uri.parse(url))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('🔴 LocationProvider: Google API timeout');
              throw Exception('Timeout');
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' &&
            data['results'] != null &&
            data['results'].isNotEmpty) {
          final result = data['results'][0];
          final addressComponents =
              result['address_components'] as List<dynamic>?;

          if (addressComponents != null) {
            String? streetNumber;
            String? route;
            String? sublocality;
            String? locality;
            String? adminArea1; // Province
            String? adminArea2; // City
            String? postalCode;

            for (var component in addressComponents) {
              final types = component['types'] as List<dynamic>?;
              final longName = component['long_name'] as String?;

              if (types != null && longName != null) {
                if (types.contains('street_number')) {
                  streetNumber = longName;
                } else if (types.contains('route')) {
                  route = longName;
                } else if (types.contains('sublocality') ||
                    types.contains('sublocality_level_1')) {
                  sublocality = longName;
                } else if (types.contains('locality')) {
                  locality = longName;
                } else if (types.contains('administrative_area_level_1')) {
                  adminArea1 = longName;
                } else if (types.contains('administrative_area_level_2')) {
                  adminArea2 = longName;
                } else if (types.contains('postal_code')) {
                  postalCode = longName;
                }
              }
            }

            // Build street address
            String? houseNumberStreet;
            if (streetNumber != null && route != null) {
              houseNumberStreet = '$streetNumber $route';
            } else if (route != null) {
              houseNumberStreet = route;
            }

            // Build city/province
            String cityProvince = '';
            if (locality != null && adminArea1 != null) {
              cityProvince = '$locality, $adminArea1';
            } else if (adminArea2 != null && adminArea1 != null) {
              cityProvince = '$adminArea2, $adminArea1';
            } else if (locality != null) {
              cityProvince = locality;
            } else if (adminArea1 != null) {
              cityProvince = adminArea1;
            }

            final address = LocationAddress(
              houseNumberStreet: houseNumberStreet,
              subdivisionBarangay: sublocality,
              cityProvince: cityProvince.isNotEmpty
                  ? cityProvince
                  : 'Philippines',
              zipCode: postalCode,
            );

            print('🔵 LocationProvider: Google API address - $cityProvince');
            return address;
          }
        } else {
          print('🔴 LocationProvider: Google API error: ${data['status']}');
        }
      } else {
        print(
          '🔴 LocationProvider: Google API HTTP error: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('🔴 LocationProvider: Google API exception: $e');
    }

    return null;
  }

  LocationAddress _getDefaultAddress(LatLng location) {
    print(
      '🔵 LocationProvider: Using default address for ${location.latitude}, ${location.longitude}',
    );

    // Determine default city based on coordinates
    String defaultCity = 'Philippines';
    String defaultBarangay = 'Barangay';
    String defaultZip = '';

    // Metro Manila area (rough bounds)
    if (location.latitude >= 14.4 &&
        location.latitude <= 14.8 &&
        location.longitude >= 120.9 &&
        location.longitude <= 121.2) {
      defaultCity = 'Metro Manila, Philippines';
      defaultBarangay = 'Barangay';
      defaultZip = '1000';
    }
    // Cagayan de Oro area
    else if (location.latitude >= 8.3 &&
        location.latitude <= 8.6 &&
        location.longitude >= 124.5 &&
        location.longitude <= 124.8) {
      defaultCity = 'Cagayan de Oro, Misamis Oriental';
      defaultBarangay = 'Barangay';
      defaultZip = '9000';
    }

    return LocationAddress(
      houseNumberStreet: null,
      subdivisionBarangay: defaultBarangay,
      cityProvince: defaultCity,
      zipCode: defaultZip,
      landmark:
          'Coordinates: ${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
    );
  }
}

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>(
  (ref) {
    ref.watch(userSessionEpochProvider);
    return LocationNotifier();
  },
);
