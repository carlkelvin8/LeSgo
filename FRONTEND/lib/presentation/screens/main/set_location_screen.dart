import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../provider/main/location/location_provider.dart';
import '../../provider/main/location/controller/location_controller.notifier.dart';
import '../../widgets/widgets.dart';

class SetLocationScreen extends ConsumerStatefulWidget {
  const SetLocationScreen({super.key});

  @override
  ConsumerState<SetLocationScreen> createState() => _SetLocationScreenState();
}

class _SetLocationScreenState extends ConsumerState<SetLocationScreen> {
  late final LocationControllers _controllers;

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

  void _onContinue() {
    if (_controllers.validateAndSave(ref)) {
      Navigator.of(context).pop(_controllers.getLocationData(ref));
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
              onPressed: locationState.isLoading ? null : _onContinue,
              isLoading: locationState.isLoading,
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
