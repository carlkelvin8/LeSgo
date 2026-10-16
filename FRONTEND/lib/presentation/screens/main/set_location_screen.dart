import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../provider/main/location/location_provider.dart';
import '../../provider/main/location/controller/location_controller.notifier.dart';
import '../../provider/main/address/address_provider.dart';
import '../../provider/auth/auth_provider.dart';
import '../../provider/main/profile/profile_provider.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authState = ref.read(authProvider);
      final userId = int.tryParse(authState.user?.id ?? '0') ?? 0;
      ref.read(locationProvider.notifier).reset();
      if (userId > 0) {
        await ref.read(addressProvider.notifier).loadAddresses(userId);
        await ref.read(profileProvider.notifier).loadProfile();
      }
      await _controllers.initialize(ref);
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

      if (kDebugMode) {
        debugPrint('SetLocationScreen: Saving address...');
        debugPrint('SetLocationScreen: - userId: $userId');
        debugPrint('SetLocationScreen: - location: $location');
        debugPrint('SetLocationScreen: - address: $address');
      }

      // Build address lines
      final houseNumberStreet = address['houseNumberStreet']?.toString() ?? '';
      final subdivisionBarangay =
          address['subdivisionBarangay']?.toString() ?? '';
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

      if (kDebugMode) {
        debugPrint('SetLocationScreen: - addressLine1: $addressLine1');
        debugPrint('SetLocationScreen: - addressLine2: $addressLine2');
      }

      var city = '';
      var region = '';
      if (cityProvince.isNotEmpty) {
        final parts = cityProvince.split(',');
        if (parts.length > 1) {
          city = parts.first.trim();
          region = parts.sublist(1).join(',').trim();
        } else {
          city = cityProvince.trim();
        }
      }

      final profileState = ref.read(profileProvider);
      final contactPhone = profileState.phone.trim().isNotEmpty
          ? profileState.phone.trim()
          : (profileState.user?.phone ?? '').trim();

      final country = AddressNotifier.inferCountry(
        latitude: location.latitude,
        longitude: location.longitude,
        cityProvince: cityProvince,
      );

      // Update existing default location or create one if needed
      final success = await ref
          .read(addressProvider.notifier)
          .upsertDefaultLocation(
            userId: userId,
            label: address['landmark']?.toString().isNotEmpty == true
                ? address['landmark'].toString()
                : 'My Location',
            contactName: authState.user?.name ?? 'User',
            contactPhone: contactPhone,
            addressLine1: addressLine1.isNotEmpty
                ? addressLine1
                : 'Selected Location',
            addressLine2: addressLine2.isNotEmpty ? addressLine2 : null,
            city: city.isNotEmpty ? city : null,
            region: region.isNotEmpty ? region : null,
            postalCode: zipCode.isNotEmpty ? zipCode : null,
            country: country,
            latitude: location.latitude,
            longitude: location.longitude,
            context: context,
          );

      if (!mounted) return;

      if (success) {
        if (kDebugMode) {
          debugPrint('SetLocationScreen: Address saved successfully');
        }
        await ref.read(profileProvider.notifier).updateProfile(
              address1: addressLine1,
              address2: addressLine2.isNotEmpty ? addressLine2 : null,
            );
        SnackBarUtils.showSuccess(context, 'Address saved successfully');
        Navigator.of(context).pop(true);
      } else {
        final error = ref.read(addressProvider).error;
        if (kDebugMode) {
          debugPrint('SetLocationScreen: Failed to save address - $error');
        }
        SnackBarUtils.showError(
          context,
          error ?? 'Failed to save address',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SetLocationScreen: Error saving address - $e');
      }
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
      backgroundColor: AppColors.surface(context, Colors.white),
      resizeToAvoidBottomInset: true,
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

                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(
                      bottom: ResponsiveUtils.spacing(context, 110) + MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LocationMapSection(
                          key: ValueKey(_controllers.isFullscreen),
                          mapController: _controllers.mapController,
                          showPickupDestination: false,
                          onMapCreated: (controller) {
                            _controllers.onMapCreated(controller);
                            Future.delayed(
                              const Duration(milliseconds: 50),
                              () {
                                _controllers.moveSmallMapToMarker(ref);
                              },
                            );
                          },
                          onUseCurrentLocation: () => _controllers
                              .handleUseCurrentLocation(context, ref),
                          onToggleFullscreen: () {
                            _controllers.toggleFullscreen(ref);
                            setState(() {});
                          },
                          onMapTap: (location) =>
                              _controllers.handleMapTap(location, ref, context),
                        ),
                        SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                        LocationFormSection(
                          controllers: _controllers,
                          onDefaultChanged: () {
                            setState(() {
                              _controllers.setIsDefault(
                                !_controllers.isDefault,
                              );
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            LocationBottomButton(
              onPressed: (_isSaving || locationState.isLoading)
                  ? null
                  : _onContinue,
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
                onMarkerDragEnd: (location) => _controllers.handleMarkerDragEnd(
                  location,
                  ref,
                  context,
                ),
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
