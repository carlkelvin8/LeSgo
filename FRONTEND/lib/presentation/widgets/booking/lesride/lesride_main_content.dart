import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../provider/main/booking/lesride_location_provider.dart';
import '../../../provider/main/booking/lesride_provider.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../widgets.dart';

class LesrideMainContent extends ConsumerWidget {
  final DraggableScrollableController sheetController;
  final Function(GoogleMapController) onMainMapCreated;
  final Function(GoogleMapController) onOverlayMapCreated;
  final VoidCallback onCollapseSheet;

  const LesrideMainContent({
    super.key,
    required this.sheetController,
    required this.onMainMapCreated,
    required this.onOverlayMapCreated,
    required this.onCollapseSheet,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lesrideState = ref.watch(lesrideProvider);
    final locationState = ref.watch(lesrideLocationProvider);
    final notifier = ref.read(lesrideProvider.notifier);

    // Handle post-frame callbacks
    if (lesrideState.shouldCollapseAfterFullscreen &&
        !lesrideState.isFullscreen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.setShouldCollapseAfterFullscreen(false);
        onCollapseSheet();
      });
    }
    notifier.handlePostFrameCallbacks();

    final mapHeight = ResponsiveUtils.screenHeight(context) * 0.5;
    final sheetMax = notifier.sheetMax;
    final sheetMin = notifier.sheetMin;
    final sheetDefault = notifier.sheetDefault;

    return Stack(
      children: [
        if (!lesrideState.isFullscreen)
          Positioned.fill(
            child: LesrideMapPanel(
              height: mapHeight,
              onMapCreated: onMainMapCreated,
              onUseCurrentLocation: () => notifier.useCurrentLocation(),
              onToggleFullscreen: () => notifier.toggleFullscreen(),
              onMapTap: (latLng) => notifier.onMapTap(latLng),
            ),
          ),
        if (!lesrideState.isFullscreen)
          DraggableScrollableSheet(
            controller: sheetController,
            initialChildSize: sheetDefault,
            minChildSize: sheetMin,
            maxChildSize: sheetMax,
            snap: true,
            snapAnimationDuration: const Duration(milliseconds: 200),
            builder: (context, scrollController) {
              return LesrideDetailsPanel(
                locationState: locationState,
                onChangeCurrent: () => notifier.openPickupSelection(),
                onChangeDestination: () => notifier.openDestinationSelection(),
                selectedVehicle: lesrideState.selectedVehicle,
                onVehicleSelected: notifier.selectVehicle,
                paymentMethod: lesrideState.paymentMethod,
                onPaymentChanged: (val) {
                  if (val != null) {
                    notifier.updatePaymentMethod(val);
                  }
                },
                onBook:
                    locationState.distanceInKm != null &&
                        locationState.distanceInKm! > 0 &&
                        !lesrideState.isLoadingFare &&
                        !lesrideState.isBooking
                    ? () => notifier.handleBook(context)
                    : null,
                isBooking: lesrideState.isBooking,
                scrollController: scrollController,
              );
            },
          ),
        if (lesrideState.isFullscreen)
          Stack(
            children: [
              FullscreenMapOverlay(
                onMapCreated: onOverlayMapCreated,
                onUseCurrentLocation: () => notifier.useCurrentLocation(),
                onToggleFullscreen: () => notifier.toggleFullscreen(),
                onMapTap: (latLng) => notifier.onMapTap(latLng),
                mapWidget: LesrideMapWidget(
                  onMapCreated: onOverlayMapCreated,
                  onUseCurrentLocation: () => notifier.useCurrentLocation(),
                  onToggleFullscreen: () => notifier.toggleFullscreen(),
                  onMapTap: (latLng) => notifier.onMapTap(latLng),
                  onMarkerDragEnd: (latLng) => notifier.onMapTap(latLng),
                  isFullscreen: true,
                ),
                shouldShow: () => locationState.selectedLocation != null,
                showZoomControls: false,
                showLocationButton: false,
                customTopRightControls: Material(
                  color: Colors.white,
                  elevation: 4,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: () => notifier.toggleFullscreen(),
                    borderRadius: BorderRadius.circular(8),
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(Icons.close, color: Color(0xFF5F2D82)),
                    ),
                  ),
                ),
              ),
              if (locationState.isLoading &&
                  locationState.pickupAddress == null)
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                    child: Container(
                      color: Colors.white.withValues(alpha: 0.1),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: ResponsiveUtils.fontSize(context, 80),
                              height: ResponsiveUtils.fontSize(context, 80),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: MapLoadingIndicator(
                                  size: ResponsiveUtils.fontSize(context, 48),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: ResponsiveUtils.spacing(context, 16),
                            ),
                            const LoadingTextWithDots(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        if (lesrideState.isFullscreen)
          Positioned(
            top: ResponsiveUtils.spacing(context, 16),
            left: 0,
            right: 0,
            child: MapSearchBar(
              isSelectingDestination: lesrideState.selectingDestination,
              onPlaceSelected:
                  (latLng, formattedAddress, addressComponents) async {
                    final locationNotifier = ref.read(
                      lesrideLocationProvider.notifier,
                    );
                    if (lesrideState.selectingDestination) {
                      await locationNotifier.updateDestinationWithAddress(
                        latLng,
                        formattedAddress,
                        addressComponents,
                      );
                    } else {
                      await locationNotifier.updatePickupWithAddress(
                        latLng,
                        formattedAddress,
                        addressComponents,
                      );
                    }
                  },
              onAnimateToLocation: (latLng) =>
                  notifier.animateOverlayToLocation(latLng),
            ),
          ),
        if (lesrideState.isFullscreen)
          Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: PrimaryButton(
              text: 'Confirm location',
              onPressed: () => notifier.confirmSelection(),
            ),
          ),
      ],
    );
  }
}
