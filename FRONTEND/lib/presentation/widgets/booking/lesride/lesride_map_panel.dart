import 'package:lesgo/core/theme/app_colors.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../provider/main/booking/lesride_location_provider.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../widgets.dart';

class LesrideMapPanel extends ConsumerWidget {
  const LesrideMapPanel({
    super.key,
    required this.onMapCreated,
    required this.onUseCurrentLocation,
    required this.onToggleFullscreen,
    required this.onMapTap,
    required this.height,
  });

  final Function(GoogleMapController) onMapCreated;
  final VoidCallback onUseCurrentLocation;
  final VoidCallback onToggleFullscreen;
  final Function(LatLng) onMapTap;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(lesrideLocationProvider);
    final isLoading =
        locationState.isLoading && locationState.pickupAddress == null;

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          LesrideMapWidget(
            onMapCreated: onMapCreated,
            onUseCurrentLocation: onUseCurrentLocation,
            onToggleFullscreen: onToggleFullscreen,
            onMapTap: onMapTap,
            isFullscreen: false,
          ),
          MapExpandHint(onTap: onToggleFullscreen),
          if (isLoading)
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
                            color: AppColors.surface(context, Colors.white),
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
                        SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                        const LoadingTextWithDots(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
