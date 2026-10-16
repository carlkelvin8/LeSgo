import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'register_state.dart';
import '../../../../domain/entities/auth/register/address_request.dart';

mixin AddressNotifier on StateNotifier<RegisterState> {
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

      await _getAddressFromLocation(location);

      state = state.copyWith(
        currentLocation: location,
        selectedLocation: location,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateSelectedLocation(LatLng location) async {
    state = state.copyWith(selectedLocation: location, isLoading: true);

    await _getAddressFromLocation(location);
  }

  Future<void> updateSelectedLocationWithAddress(
    LatLng location,
    String? formattedAddress,
    Map<String, String>? addressComponents,
  ) async {
    state = state.copyWith(selectedLocation: location, isLoading: true);

    if (addressComponents != null && addressComponents.isNotEmpty) {
      // Use structured address components from Google Places API
      await _updateAddressFromComponents(location, addressComponents);
    } else if (formattedAddress != null && formattedAddress.isNotEmpty) {
      // Parse formatted address and update state
      await _parseAndUpdateAddressFromFormatted(location, formattedAddress);
    } else {
      // Fallback to reverse geocoding
      await _getAddressFromLocation(location);
    }
  }

  Future<void> _updateAddressFromComponents(
    LatLng location,
    Map<String, String> components,
  ) async {
    try {
      final currentAddress = state.data.address ?? Address();

      final houseNumber = components['houseNumber'] ?? '';
      final streetName = components['streetName'] ?? '';
      final zipCode = components['zipCode'] ?? '';
      final barangay = components['barangay'] ?? '';
      final city = components['city'] ?? '';
      final province = components['province'] ?? '';

      state = state.copyWith(
        data: state.data.copyWith(
          address: currentAddress.copyWith(
            houseNumber: houseNumber,
            streetName: streetName,
            zipCode: zipCode,
            barangay: barangay,
            city: city,
            municipality: city,
            province: province,
            latitude: location.latitude,
            longitude: location.longitude,
          ),
        ),
        locationName: streetName.isNotEmpty
            ? streetName
            : (barangay.isNotEmpty ? barangay : 'Selected Location'),
        isLoading: false,
      );
    } catch (e) {
      // Fallback to reverse geocoding on error
      await _getAddressFromLocation(location);
    }
  }

  Future<void> _parseAndUpdateAddressFromFormatted(
    LatLng location,
    String formattedAddress,
  ) async {
    try {
      final parts = formattedAddress.split(',').map((e) => e.trim()).toList();
      final currentAddress = state.data.address ?? Address();

      String streetName = '';
      String city = '';
      String province = '';
      String barangay = '';

      if (parts.isNotEmpty) {
        streetName = parts[0];
      }
      if (parts.length >= 2) {
        city = parts[1];
      }
      if (parts.length >= 3) {
        province = parts[2];
      }
      if (parts.length >= 4) {
        barangay = parts[0]; // Use first part as barangay if available
      }

      state = state.copyWith(
        data: state.data.copyWith(
          address: currentAddress.copyWith(
            streetName: streetName,
            city: city,
            municipality: city,
            province: province,
            barangay: barangay,
            latitude: location.latitude,
            longitude: location.longitude,
          ),
        ),
        locationName: streetName.isNotEmpty
            ? streetName
            : (barangay.isNotEmpty ? barangay : 'Selected Location'),
        isLoading: false,
      );
    } catch (e) {
      // Fallback to reverse geocoding on error
      await _getAddressFromLocation(location);
    }
  }

  Future<void> _getAddressFromLocation(LatLng location) async {
    // Keep the chosen pin even when the geocoder has no address for it.
    state = state.copyWith(
      error: null,
      data: state.data.copyWith(
        address: (state.data.address ?? Address()).copyWith(
          latitude: location.latitude,
          longitude: location.longitude,
        ),
      ),
    );
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final currentAddress = state.data.address ?? Address();

        final streetName = place.thoroughfare ?? place.street ?? '';
        final houseNumber = place.subThoroughfare ?? '';

        final province =
            place.subAdministrativeArea ?? place.administrativeArea ?? '';
        final city = place.locality ?? '';
        final barangay = place.subLocality ?? '';

        state = state.copyWith(
          data: state.data.copyWith(
            address: currentAddress.copyWith(
              houseNumber: houseNumber,
              streetName: streetName,
              barangay: barangay,
              city: city,
              municipality: city,
              province: province,
              zipCode: place.postalCode ?? '',
              latitude: location.latitude,
              longitude: location.longitude,
            ),
          ),
          locationName: streetName.isNotEmpty
              ? streetName
              : (barangay.isNotEmpty ? barangay : 'Selected Location'),
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to get address: ${e.toString()}',
      );
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void updateAddress({
    String? houseNumber,
    String? streetName,
    String? subdivision,
    String? barangay,
    String? city,
    String? municipality,
    String? province,
    String? zipCode,
    String? landmark,
    bool? isDefault,
  }) {
    final currentAddress = state.data.address ?? Address();

    state = state.copyWith(
      data: state.data.copyWith(
        address: currentAddress.copyWith(
          houseNumber: houseNumber,
          streetName: streetName,
          subdivision: subdivision,
          barangay: barangay,
          city: city,
          municipality: municipality,
          province: province,
          zipCode: zipCode,
          landmark: landmark,
          isDefault: isDefault,
        ),
      ),
    );
  }

  void updateAddressFromForm({
    required String houseNumberStreet,
    required String subdivBarangay,
    required String cityProvince,
    required String zipCode,
    required String landmark,
  }) {
    print('🔍 DEBUG updateAddressFromForm INPUTS:');
    print('  - houseNumberStreet: "$houseNumberStreet"');
    print('  - subdivBarangay: "$subdivBarangay"');
    print('  - cityProvince: "$cityProvince"');
    print('  - zipCode: "$zipCode"');

    String houseNumber = '';
    String streetName = houseNumberStreet.trim();

    final houseStreetParts = houseNumberStreet.trim().split(' ');
    if (houseStreetParts.isNotEmpty) {
      final firstPart = houseStreetParts[0];
      if (RegExp(r'\d').hasMatch(firstPart)) {
        houseNumber = firstPart;
        streetName = houseStreetParts.skip(1).join(' ');
      }
    }

    String subdivision = '';
    String barangay = '';
    if (subdivBarangay.trim().isNotEmpty) {
      final subdivBarangayParts = subdivBarangay.split(',');
      if (subdivBarangayParts.length > 1) {
        subdivision = subdivBarangayParts[0].trim();
        barangay = subdivBarangayParts[1].trim();
      } else {
        barangay = subdivBarangayParts[0].trim();
      }
    }

    String city = '';
    String province = '';
    if (cityProvince.trim().isNotEmpty) {
      final cityProvinceParts = cityProvince.split(',');
      if (cityProvinceParts.length > 1) {
        city = cityProvinceParts[0].trim();
        province = cityProvinceParts[1].trim();
      } else {
        city = cityProvinceParts[0].trim();
      }
    }

    print('🔍 DEBUG updateAddressFromForm PARSED:');
    print('  - houseNumber: "$houseNumber"');
    print('  - streetName: "$streetName"');
    print('  - subdivision: "$subdivision"');
    print('  - barangay: "$barangay"');
    print('  - city: "$city"');
    print('  - province: "$province"');
    print('  - zipCode: "${zipCode.trim()}"');

    updateAddress(
      houseNumber: houseNumber,
      streetName: streetName,
      subdivision: subdivision,
      barangay: barangay,
      city: city,
      municipality: city,
      province: province,
      zipCode: zipCode.trim(),
      landmark: landmark.trim(),
    );
  }

  Map<String, String> getFormattedAddressFields() {
    final address = state.data.address;
    if (address == null) {
      return {
        'houseNumberStreet': '',
        'subdivBarangay': '',
        'cityProvince': '',
        'zipCode': '',
      };
    }

    String houseNumberStreet = '';
    if (address.houseNumber.isNotEmpty && address.streetName.isNotEmpty) {
      houseNumberStreet = '${address.houseNumber} ${address.streetName}';
    } else if (address.streetName.isNotEmpty) {
      houseNumberStreet = address.streetName;
    } else if (address.houseNumber.isNotEmpty) {
      houseNumberStreet = address.houseNumber;
    }

    List<String> subdivBarangayParts = [];
    if (address.subdivision.isNotEmpty) {
      subdivBarangayParts.add(address.subdivision);
    }
    if (address.barangay.isNotEmpty) {
      subdivBarangayParts.add(address.barangay);
    }
    String subdivBarangay = subdivBarangayParts.join(', ');

    List<String> cityProvinceParts = [];
    if (address.city.isNotEmpty) {
      cityProvinceParts.add(address.city);
    }
    if (address.province.isNotEmpty) {
      cityProvinceParts.add(address.province);
    }
    String cityProvince = cityProvinceParts.join(', ');

    return {
      'houseNumberStreet': houseNumberStreet,
      'subdivBarangay': subdivBarangay,
      'cityProvince': cityProvince,
      'zipCode': address.zipCode,
    };
  }

  Future<bool> saveAddress() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final address = state.data.address;

      // Debug logging
      print('🔍 DEBUG saveAddress - address: $address');
      print(
        '🔍 DEBUG saveAddress - address.isComplete: ${address?.isComplete}',
      );
      print('🔍 DEBUG saveAddress - houseNumber: ${address?.houseNumber}');
      print('🔍 DEBUG saveAddress - streetName: ${address?.streetName}');
      print('🔍 DEBUG saveAddress - barangay: ${address?.barangay}');
      print('🔍 DEBUG saveAddress - city: ${address?.city}');
      print('🔍 DEBUG saveAddress - zipCode: ${address?.zipCode}');

      if (address == null || !address.isComplete) {
        throw Exception('Please complete all required address fields');
      }

      if (address.latitude == null || address.longitude == null) {
        throw Exception('Please select your address on the map');
      }
      if (address.deliveryDetails.length > 255) {
        throw Exception(
          'Please shorten your subdivision, barangay, and landmark to 255 characters combined',
        );
      }

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      print('❌ ERROR saveAddress: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}
