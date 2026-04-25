import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../location_provider.dart';

class LocationControllers {
  final GlobalKey<FormState> formKey;
  final TextEditingController houseNumberController;
  final TextEditingController subdivisionController;
  final TextEditingController cityController;
  final TextEditingController zipCodeController;
  final TextEditingController landmarkController;

  GoogleMapController? mapController;
  GoogleMapController? fullscreenMapController;
  bool isFullscreen = false;
  bool _shouldMoveCameraOnExit = false;
  bool isDefault = false;

  LocationControllers()
    : formKey = GlobalKey<FormState>(),
      houseNumberController = TextEditingController(),
      subdivisionController = TextEditingController(),
      cityController = TextEditingController(),
      zipCodeController = TextEditingController(),
      landmarkController = TextEditingController();

  void setIsDefault(bool value) {
    isDefault = value;
  }

  bool validateAndSave(WidgetRef ref) {
    if (!formKey.currentState!.validate()) {
      return false;
    }
    return true;
  }

  Map<String, dynamic> getLocationData(WidgetRef ref) {
    final locationState = ref.read(locationProvider);
    return {
      'location': locationState.selectedLocation,
      'address': {
        'houseNumberStreet': houseNumberController.text,
        'subdivisionBarangay': subdivisionController.text,
        'cityProvince': cityController.text,
        'zipCode': zipCodeController.text,
        'landmark': landmarkController.text,
        'isDefault': isDefault,
      },
    };
  }

  Future<void> initialize(WidgetRef ref) async {
    print('🔵 LocationController: Initializing...');
    
    // Set default values immediately for better UX
    _setDefaultFormValues();
    
    // Then try to get actual location
    await ref.read(locationProvider.notifier).getCurrentLocation();
    print('🔵 LocationController: Got current location');
    updateFormFromProvider(ref);
    print('🔵 LocationController: Updated form from provider');
  }

  void _setDefaultFormValues() {
    print('🔵 LocationController: Setting default form values');
    houseNumberController.text = '';
    subdivisionController.text = 'Barangay';
    cityController.text = 'Cagayan de Oro, Misamis Oriental';
    zipCodeController.text = '9000';
    landmarkController.text = '';
  }

  void updateFormFromProvider(WidgetRef ref) {
    final locationState = ref.read(locationProvider);
    print('🔵 LocationController: Updating form - address: ${locationState.address}');
    if (locationState.address != null) {
      houseNumberController.text =
          locationState.address!.houseNumberStreet ?? '';
      subdivisionController.text =
          locationState.address!.subdivisionBarangay ?? '';
      cityController.text = locationState.address!.cityProvince ?? '';
      zipCodeController.text = locationState.address!.zipCode ?? '';
      landmarkController.text = locationState.address!.landmark ?? '';
      print('🔵 LocationController: Form updated - city: ${cityController.text}');
    } else {
      print('🔴 LocationController: No address available');
    }
  }

  Future<void> handleUseCurrentLocation(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await ref.read(locationProvider.notifier).getCurrentLocation();
    final locationState = ref.read(locationProvider);

    if (locationState.error != null) {
      if (context.mounted) {
        SnackBarUtils.showError(context, locationState.error!);
      }
    } else {
      updateFormFromProvider(ref);

      // Animate camera to current location
      if (locationState.selectedLocation != null) {
        final controller = isFullscreen
            ? fullscreenMapController
            : mapController;
        if (controller != null) {
          await controller.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: locationState.selectedLocation!,
                zoom: 17.0,
              ),
            ),
          );
        }
      }

      if (context.mounted) {
        SnackBarUtils.showSuccess(context, 'Location updated');
      }
    }
  }

  Future<void> handleMapTap(
    LatLng location,
    WidgetRef ref,
    BuildContext context,
  ) async {
    await ref.read(locationProvider.notifier).updateSelectedLocation(location);
    updateFormFromProvider(ref);

    if (context.mounted) {
      SnackBarUtils.showSuccess(context, 'Location updated');
    }
  }

  void toggleFullscreen(WidgetRef ref) {
    final wasFullscreen = isFullscreen;
    isFullscreen = !isFullscreen;

    if (wasFullscreen && !isFullscreen) {
      _shouldMoveCameraOnExit = true;
    }
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<void> moveSmallMapToMarker(WidgetRef ref) async {
    if (_shouldMoveCameraOnExit) {
      _shouldMoveCameraOnExit = false;
      final locationState = ref.read(locationProvider);
      if (locationState.selectedLocation != null && mapController != null) {
        await Future.delayed(const Duration(milliseconds: 100));
        try {
          await mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: locationState.selectedLocation!,
                zoom: 17.0,
              ),
            ),
          );
        } catch (e) {
          // Handle potential errors, e.g., controller not ready
        }
      }
    }
  }

  void onFullscreenMapCreated(GoogleMapController controller) {
    fullscreenMapController = controller;
  }

  Future<void> animateOverlayToLocation(LatLng location) async {
    if (fullscreenMapController != null) {
      try {
        await fullscreenMapController!.animateCamera(
          CameraUpdate.newLatLngZoom(location, 17.0),
        );
      } catch (_) {
        // Handle potential errors
      }
    }
  }

  void dispose() {
    houseNumberController.dispose();
    subdivisionController.dispose();
    cityController.dispose();
    zipCodeController.dispose();
    landmarkController.dispose();
    mapController?.dispose();
    fullscreenMapController?.dispose();
  }
}
