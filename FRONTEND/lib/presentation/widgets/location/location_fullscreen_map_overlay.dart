import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../provider/main/location/location_provider.dart';
import '../widgets.dart';

class LocationFullscreenMapOverlay extends ConsumerWidget {
  final Function(GoogleMapController) onMapCreated;
  final VoidCallback onUseCurrentLocation;
  final VoidCallback onToggleFullscreen;
  final Function(LatLng) onMapTap;
  final bool showPickupDestination;
  final Future<void> Function(LatLng)? onAnimateToLocation;
  final VoidCallback? onPlaceSelected;

  const LocationFullscreenMapOverlay({
    super.key,
    required this.onMapCreated,
    required this.onUseCurrentLocation,
    required this.onToggleFullscreen,
    required this.onMapTap,
    this.showPickupDestination = true,
    this.onAnimateToLocation,
    this.onPlaceSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(locationProvider);

    if (locationState.selectedLocation == null) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: Container(
        color: Colors.white,
        child: Stack(
          children: [
            LocationMapWidget(
              onMapCreated: onMapCreated,
              onUseCurrentLocation: onUseCurrentLocation,
              onToggleFullscreen: onToggleFullscreen,
              onMapTap: onMapTap,
              isFullscreen: true,
              showPickupDestination: showPickupDestination,
            ),
            Positioned(
              top: ResponsiveUtils.spacing(context, 16),
              left: 0,
              right: 0,
              child: MapSearchBar(
                isSelectingDestination: false,
                onPlaceSelected:
                    (latLng, formattedAddress, addressComponents) async {
                      await ref
                          .read(locationProvider.notifier)
                          .updateSelectedLocationWithAddress(
                            latLng,
                            formattedAddress,
                            addressComponents,
                          );
                      if (onPlaceSelected != null) {
                        onPlaceSelected!();
                      }
                    },
                onAnimateToLocation: onAnimateToLocation,
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: MapZoomControls(
                onToggleFullscreen: onToggleFullscreen,
                isFullscreen: true,
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: LocationButton(onUseCurrentLocation: onUseCurrentLocation),
            ),
          ],
        ),
      ),
    );
  }
}
