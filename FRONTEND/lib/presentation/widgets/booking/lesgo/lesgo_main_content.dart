import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../provider/main/booking/lesgo_location_provider.dart';
import '../../../provider/main/booking/lesgo_provider.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../widgets.dart';

class LesgoMainContent extends ConsumerWidget {
  final DraggableScrollableController sheetController;
  final Function(GoogleMapController) onMainMapCreated;
  final Function(GoogleMapController) onOverlayMapCreated;
  final VoidCallback onCollapseSheet;
  final TextEditingController itemLocationController;
  final TextEditingController itemWeightController;
  final ValueChanged<String>? onItemLocationChanged;
  final ValueChanged<String>? onItemWeightChanged;

  const LesgoMainContent({
    super.key,
    required this.sheetController,
    required this.onMainMapCreated,
    required this.onOverlayMapCreated,
    required this.onCollapseSheet,
    required this.itemLocationController,
    required this.itemWeightController,
    this.onItemLocationChanged,
    this.onItemWeightChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFullscreen = ref.watch(
      lesgoProvider.select((s) => s.isFullscreen),
    );
    final shouldCollapse = ref.watch(
      lesgoProvider.select((s) => s.shouldCollapseAfterFullscreen),
    );
    final paymentMethod = ref.watch(
      lesgoProvider.select((s) => s.paymentMethod),
    );
    final selectingDestination = ref.watch(
      lesgoProvider.select((s) => s.selectingDestination),
    );
    final pickupAddress = ref.watch(
      lesgoLocationProvider.select((s) => s.pickupAddress),
    );
    final notifier = ref.read(lesgoProvider.notifier);

    // Handle post-frame callbacks
    if (shouldCollapse && !isFullscreen) {
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
        if (!isFullscreen)
          Positioned.fill(
            child: LesgoMapPanel(
              height: mapHeight,
              onMapCreated: onMainMapCreated,
              onUseCurrentLocation: () => notifier.useCurrentLocation(),
              onToggleFullscreen: () => notifier.toggleFullscreen(),
              onMapTap: (latLng) => notifier.onMapTap(latLng),
            ),
          ),
        if (!isFullscreen)
          DraggableScrollableSheet(
            controller: sheetController,
            initialChildSize: sheetDefault,
            minChildSize: sheetMin,
            maxChildSize: sheetMax,
            snap: true,
            snapAnimationDuration: const Duration(milliseconds: 200),
            builder: (context, scrollController) {
              return LesgoDetailsPanel(
                locationState: ref.read(lesgoLocationProvider),
                onChangeCurrent: () => notifier.openPickupSelection(),
                onChangeDestination: () => notifier.openDestinationSelection(),
                paymentMethod: paymentMethod,
                onPaymentChanged: (val) {
                  if (val != null) {
                    notifier.updatePaymentMethod(val);
                  }
                },
                onBook: () => notifier.handleBook(context),
                itemLocationController: itemLocationController,
                itemWeightController: itemWeightController,
                onItemLocationChanged: onItemLocationChanged,
                onItemWeightChanged: onItemWeightChanged,
                scrollController: scrollController,
              );
            },
          ),
        if (isFullscreen)
          Stack(
            children: [
              FullscreenMapOverlay(
                onMapCreated: onOverlayMapCreated,
                onUseCurrentLocation: () => notifier.useCurrentLocation(),
                onToggleFullscreen: () => notifier.toggleFullscreen(),
                onMapTap: (latLng) => notifier.onMapTap(latLng),
                mapWidget: LesgoMapWidget(
                  onMapCreated: onOverlayMapCreated,
                  onUseCurrentLocation: () => notifier.useCurrentLocation(),
                  onToggleFullscreen: () => notifier.toggleFullscreen(),
                  onMapTap: (latLng) => notifier.onMapTap(latLng),
                  onMarkerDragEnd: (latLng) => notifier.onMapTap(latLng),
                  isFullscreen: true,
                ),
                shouldShow: () => true,
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
              if (ref.watch(lesgoLocationProvider.select((s) => s.isLoading)) &&
                  pickupAddress == null)
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
        if (isFullscreen)
          Positioned(
            top: ResponsiveUtils.spacing(context, 16),
            left: 0,
            right: 0,
            child: MapSearchBar(
              requirePreviewConfirmation: true,
              isSelectingDestination: selectingDestination,
              onPlaceSelected:
                  (latLng, formattedAddress, addressComponents) async {
                    final locationNotifier = ref.read(
                      lesgoLocationProvider.notifier,
                    );
                    if (selectingDestination) {
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
        if (isFullscreen)
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
