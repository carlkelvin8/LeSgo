import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../register_provider.dart';

class AddressControllers {
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

  AddressControllers()
      : formKey = GlobalKey<FormState>(),
        houseNumberController = TextEditingController(),
        subdivisionController = TextEditingController(),
        cityController = TextEditingController(),
        zipCodeController = TextEditingController(),
        landmarkController = TextEditingController();


  Future<void> initialize(WidgetRef ref) async {
    await ref.read(registerProvider.notifier).getCurrentLocation();
    updateFormFromProvider(ref);
  }


  void updateFormFromProvider(WidgetRef ref) {
    final fields = ref.read(registerProvider.notifier).getFormattedAddressFields();
    houseNumberController.text = fields['houseNumberStreet'] ?? '';
    subdivisionController.text = fields['subdivBarangay'] ?? '';
    cityController.text = fields['cityProvince'] ?? '';
    zipCodeController.text = fields['zipCode'] ?? '';
  }

  Future<void> handleUseCurrentLocation(BuildContext context, WidgetRef ref) async {
    await ref.read(registerProvider.notifier).getCurrentLocation();
    final registerState = ref.read(registerProvider);

    if (registerState.error != null) {
      if (context.mounted) {
        SnackBarUtils.showError(context, registerState.error!);
      }
    } else {
      updateFormFromProvider(ref);
      
      // Animate camera to current location
      if (registerState.selectedLocation != null) {
        final controller = isFullscreen ? fullscreenMapController : mapController;
        if (controller != null) {
          await controller.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: registerState.selectedLocation!,
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

  Future<void> handleMapTap(LatLng location, WidgetRef ref, BuildContext context) async {
    await ref.read(registerProvider.notifier).updateSelectedLocation(location);
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
      final registerState = ref.read(registerProvider);
      if (registerState.selectedLocation != null && mapController != null) {
        await Future.delayed(const Duration(milliseconds: 100));
        try {
          await mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: registerState.selectedLocation!,
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

  Future<bool> validateAndSaveAddress(BuildContext context, WidgetRef ref) async {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    ref.read(registerProvider.notifier).updateAddressFromForm(
      houseNumberStreet: houseNumberController.text,
      subdivBarangay: subdivisionController.text,
      cityProvince: cityController.text,
      zipCode: zipCodeController.text,
      landmark: landmarkController.text,
    );

    final success = await ref.read(registerProvider.notifier).saveAddress();

    if (!context.mounted) return false;

    if (success) {
      SnackBarUtils.showSuccess(context, 'Address confirmed');
    } else {
      final error = ref.read(registerProvider).error;
      if (error != null) {
        SnackBarUtils.showError(context, error);
      }
    }

    return success;
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
