import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../provider/main/location/location_provider.dart';
import '../../provider/main/location/controller/location_controller.notifier.dart';
import '../../provider/main/address/address_provider.dart';
import '../../provider/auth/auth_provider.dart';
import '../../widgets/widgets.dart';

class SetLocationScreen extends ConsumerStatefulWidget {
  const SetLocationScreen({super.key});

  @override
  ConsumerState<SetLocationScreen> createState() => _SetLocationScreenState();
}

class _SetLocationScreenState extends ConsumerState<SetLocationScreen> {
  late final LocationControllers _controllers;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controllers = LocationControllers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controllers.initialize(ref);
    });
  }

  @override
  void dispose() {
    _controllers.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    if (!_controllers.validateAndSave(ref)) {
      return;
    }

    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      // Get user ID
      final authState = ref.read(authProvider);
      final userId = int.tryParse(authState.user?.id ?? '0') ?? 0;

      if (userId == 0) {
        if (mounted) {
          SnackBarUtils.showError(context, 'Please login first');
        }
        return;
      }

      // Get location data
      final locationData = _controllers.getLocationData(ref);
      final location = locationData['location'];
      final address = locationData['address'];

      if (location == null) {
        if (mounted) {
          SnackBarUtils.showError(context, 'Please select a location');
        }
        return;
      }

      print('🔵 SetLocationScreen: Saving address...');
      print('🔵 SetLocationScreen: - userId: $userId');
      print('🔵 SetLocationScreen: - location: $location');
      print('🔵 SetLocationScreen: - address: $address');

      // Build address lines
      final houseNumberStreet = address['houseNumberStreet']?.toString() ?? '';
      final subdivisionBarangay = address['subdivisionBarangay']?.toString() ?? '';
      final cityProvince = address['cityProvince']?.toString() ?? '';
      final zipCode = address['zipCode']?.toString() ?? '';

      // Combine into address lines
      String addressLine1 = '';
      String addressLine2 = '';

      if (houseNumberStreet.isNotEmpty) {
        addressLine1 = houseNumberStreet;
      }

      if (subdivisionBarangay.isNotEmpty) {
        if (addressLine1.isNotEmpty) {
          addressLine1 += ', $subdivisionBarangay';
        } else {
          addressLine1 = subdivisionBarangay;
        }
      }

      if (cityProvince.isNotEmpty) {
        addressLine2 = cityProvince;
        if (zipCode.isNotEmpty) {
          addressLine2 += ' $zipCode';
        }
      }

      // If addressLine1 is empty, use cityProvince as fallback
      if (addressLine1.isEmpty && cityProvince.isNotEmpty) {
        addressLine1 = cityProvince;
        addressLine2 = '';
      }

      print('🔵 SetLocationScreen: - addressLine1: $addressLine1');
      print('🔵 SetLocationScreen: - addressLine2: $addressLine2');

      // Save address to backend
      final success = await ref.read(addressProvider.notifier).createAddress(
        userId: userId,
        label: address['landmark']?.toString().isNotEmpty == true
            ? address['landmark']
            : 'My Location',
        contactName: authState.user?.name ?? 'User',
        contactPhone: '', // Phone number not available in User entity
        addressLine1: addressLine1.isNotEmpty ? addressLine1 : 'Selected Location',
        addressLine2: addressLine2.isNotEmpty ? addressLine2 : null,
        latitude: location.latitude,
        longitude: location.longitude,
        isDefault: address['isDefault'] ?? false,
      );

      if (!mounted) return;

      if (success) {
        print('🔵 SetLocationScreen: Address saved successfully');
        SnackBarUtils.showSuccess(context, 'Address saved successfully');
        Navigator.of(context).pop(true);
      } else {
        print('🔴 SetLocationScreen: Failed to save address');
        SnackBarUtils.showError(context, 'Failed to save address');
      }
    } catch (e) {
      print('🔴 SetLocationScreen: Error saving address - $e');
      if (mounted) {
        SnackBarUtils.showError(context, 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Builder(
                  builder: (context) {
                    final horizontalPadding = ResponsiveUtils.horizontalPadding(
                      context,
                    );
                    return Padding(
                      padding: EdgeInsets.all(horizontalPadding),
                      child: Column(
                        children: [
                          const AuthHeader(title: 'Set Location'),
                          SizedBox(
                            height: ResponsiveUtils.spacing(context, 16),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                LocationMapSection(
                  key: ValueKey(_controllers.isFullscreen),
                  mapController: _controllers.mapController,
                  showPickupDestination: false,
                  onMapCreated: (controller) {
                    _controllers.onMapCreated(controller);
                    Future.delayed(const Duration(milliseconds: 50), () {
                      _controllers.moveSmallMapToMarker(ref);
                    });
                  },
                  onUseCurrentLocation: () =>
                      _controllers.handleUseCurrentLocation(context, ref),
                  onToggleFullscreen: () {
                    _controllers.toggleFullscreen(ref);
                    setState(() {});
                  },
                  onMapTap: (location) =>
                      _controllers.handleMapTap(location, ref, context),
                ),

                Builder(
                  builder: (context) {
                    return SizedBox(
                      height: ResponsiveUtils.spacing(context, 16),
                    );
                  },
                ),

                LocationFormSection(
                  controllers: _controllers,
                  onDefaultChanged: () {
                    setState(() {
                      _controllers.setIsDefault(!_controllers.isDefault);
                    });
                  },
                ),
              ],
            ),

            LocationBottomButton(
              onPressed: (_isSaving || locationState.isLoading) ? null : _onContinue,
              isLoading: _isSaving || locationState.isLoading,
            ),

            if (_controllers.isFullscreen &&
                locationState.selectedLocation != null)
              LocationFullscreenMapOverlay(
                onMapCreated: _controllers.onFullscreenMapCreated,
                onUseCurrentLocation: () =>
                    _controllers.handleUseCurrentLocation(context, ref),
                onToggleFullscreen: () async {
                  _controllers.toggleFullscreen(ref);
                  setState(() {});
                  // Fit current and selected when exiting fullscreen
                  await Future.delayed(const Duration(milliseconds: 50));
                  _controllers.moveSmallMapToMarker(ref);
                },
                onMapTap: (location) =>
                    _controllers.handleMapTap(location, ref, context),
                showPickupDestination: false,
                onAnimateToLocation: (location) =>
                    _controllers.animateOverlayToLocation(location),
                onPlaceSelected: () {
                  _controllers.updateFormFromProvider(ref);
                },
              ),
          ],
        ),
      ),
    );
  }
}
