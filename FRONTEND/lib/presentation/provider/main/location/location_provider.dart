import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lesgo/core/state/user_session_epoch.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../domain/models/location/location_address.dart';
import '../../../../core/services/address_geocoder.dart';
import '../../../../core/utils/ph_address.dart';

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

    state = state.copyWith(address: address, isLoading: false);
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

  final _geocoder = AddressGeocoder();

  Future<LocationAddress?> _getAddressFromLocation(LatLng location) async {
    final ph = await _geocoder.reverse(location);
    if (ph != null && !ph.isEmpty) return LocationAddress.fromPh(ph);
    // Nothing resolved: keep the pin, and let the customer type the address.
    return LocationAddress(
      cityProvince: 'Philippines',
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
