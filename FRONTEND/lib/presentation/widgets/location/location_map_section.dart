import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lesgo/core/theme/app_colors.dart';

import '../../provider/main/location/location_provider.dart';
import '../widgets.dart';

class LocationMapSection extends ConsumerWidget {
  final GoogleMapController? mapController;
  final ValueChanged<GoogleMapController> onMapCreated;
  final VoidCallback onUseCurrentLocation;
  final VoidCallback onToggleFullscreen;
  final ValueChanged<LatLng> onMapTap;
  final bool showPickupDestination;

  const LocationMapSection({
    super.key,
    required this.mapController,
    required this.onMapCreated,
    required this.onUseCurrentLocation,
    required this.onToggleFullscreen,
    required this.onMapTap,
    this.showPickupDestination = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(locationProvider);
    final isLoading = state.isLoading && state.address == null;
    final accent = AppColors.buttonFill(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: BorderSide(
        color: AppColors.border(context, const Color(0xFFEAE2EF)),
      ),
    );

    return Material(
      shape: shape,
      clipBehavior: Clip.antiAlias,
      color: AppColors.surface(context, Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: (MediaQuery.sizeOf(context).height * .28).clamp(
              216.0,
              310.0,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                LocationMapWidget(
                  onMapCreated: onMapCreated,
                  onUseCurrentLocation: onUseCurrentLocation,
                  onToggleFullscreen: onToggleFullscreen,
                  onMapTap: onMapTap,
                  isFullscreen: false,
                  showPickupDestination: showPickupDestination,
                ),
                if (isLoading)
                  IgnorePointer(
                    child: ColoredBox(
                      color: AppColors.surface(
                        context,
                        Colors.white,
                      ).withValues(alpha: .82),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: accent),
                            const SizedBox(height: 12),
                            const Text('Finding your location…'),
                          ],
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(16),
                    color: AppColors.surface(context, Colors.white),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (mapController case final controller?) ...[
                          _MapControl(
                            icon: Icons.add_rounded,
                            label: 'Zoom in',
                            onPressed: () =>
                                controller.animateCamera(CameraUpdate.zoomIn()),
                          ),
                          _MapControl(
                            icon: Icons.remove_rounded,
                            label: 'Zoom out',
                            onPressed: () => controller.animateCamera(
                              CameraUpdate.zoomOut(),
                            ),
                          ),
                        ],
                        _MapControl(
                          icon: Icons.fullscreen_rounded,
                          label: 'Expand map',
                          onPressed: onToggleFullscreen,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton.icon(
              onPressed: onUseCurrentLocation,
              icon: const Icon(Icons.my_location_rounded, size: 20),
              label: const Text(
                'Use my current location',
                textAlign: TextAlign.center,
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 48),
                backgroundColor: accent.withValues(alpha: .10),
                foregroundColor: accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapControl extends StatelessWidget {
  const _MapControl({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: label,
      onPressed: onPressed,
      color: AppColors.buttonFill(context),
      constraints: const BoxConstraints.tightFor(width: 48, height: 48),
      icon: Icon(icon, size: 23),
    );
  }
}
