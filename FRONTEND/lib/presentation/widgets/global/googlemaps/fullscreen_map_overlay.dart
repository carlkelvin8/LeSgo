import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../provider/register/register_provider.dart';
import 'map_zoom_controls.dart';
import 'map_widget.dart';
import 'map_search_bar.dart';

class FullscreenMapOverlay extends ConsumerWidget {
  final Function(GoogleMapController) onMapCreated;
  final VoidCallback onUseCurrentLocation;
  final VoidCallback onToggleFullscreen;
  final Function(LatLng) onMapTap;
  final Widget? mapWidget;
  final bool Function()? shouldShow;
  final bool showZoomControls;
  final bool showLocationButton;
  final Widget? customTopRightControls;
  final bool showSearchBar;
  final Future<void> Function(LatLng)? onAnimateToLocation;
  final Function(LatLng, String?, Map<String, String>)? onPlaceSelected;

  const FullscreenMapOverlay({
    super.key,
    required this.onMapCreated,
    required this.onUseCurrentLocation,
    required this.onToggleFullscreen,
    required this.onMapTap,
    this.mapWidget,
    this.shouldShow,
    this.showZoomControls = true,
    this.showLocationButton = true,
    this.customTopRightControls,
    this.showSearchBar = false,
    this.onAnimateToLocation,
    this.onPlaceSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use custom condition if provided, otherwise check registerProvider
    bool shouldDisplay = true;
    if (shouldShow != null) {
      shouldDisplay = shouldShow!();
    } else {
      final registerState = ref.watch(registerProvider);
      shouldDisplay = registerState.selectedLocation != null;
    }

    if (!shouldDisplay) {
      return const SizedBox.shrink();
    }

    // Use custom map widget if provided, otherwise use default MapWidget
    final widgetToUse =
        mapWidget ??
        MapWidget(
          onMapCreated: onMapCreated,
          onUseCurrentLocation: onUseCurrentLocation,
          onToggleFullscreen: onToggleFullscreen,
          onMapTap: onMapTap,
          isFullscreen: true,
        );

    return Positioned.fill(
      child: Container(
        color: AppColors.surface(context, Colors.white),
        child: Stack(
          children: [
            widgetToUse,
            if (showSearchBar && onPlaceSelected != null)
              Positioned(
                top: ResponsiveUtils.spacing(context, 16),
                left: 0,
                right: 0,
                child: MapSearchBar(
                  isSelectingDestination: false,
                  onPlaceSelected: onPlaceSelected!,
                  onAnimateToLocation: onAnimateToLocation,
                ),
              ),
            if (customTopRightControls != null)
              Positioned(
                top: ResponsiveUtils.spacing(context, 16),
                right: ResponsiveUtils.spacing(context, 16),
                child: customTopRightControls!,
              )
            else if (showZoomControls)
              Positioned(
                top: 16,
                right: 16,
                child: MapZoomControls(
                  onToggleFullscreen: onToggleFullscreen,
                  isFullscreen: true,
                ),
              ),
            if (showLocationButton && customTopRightControls == null)
              Positioned(
                bottom: 16,
                right: 16,
                child: LocationButton(
                  onUseCurrentLocation: onUseCurrentLocation,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
