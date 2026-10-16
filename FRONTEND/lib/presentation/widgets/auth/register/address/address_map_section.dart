import 'package:lesgo/core/theme/app_colors.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../provider/register/register_provider.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../widgets.dart';

class AddressMapSection extends ConsumerWidget {
  final GoogleMapController? mapController;
  final Function(GoogleMapController) onMapCreated;
  final VoidCallback onUseCurrentLocation;
  final VoidCallback onToggleFullscreen;
  final Function(LatLng) onMapTap;

  const AddressMapSection({
    super.key,
    required this.mapController,
    required this.onMapCreated,
    required this.onUseCurrentLocation,
    required this.onToggleFullscreen,
    required this.onMapTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registerState = ref.watch(registerProvider);
    final isLoading = registerState.isLoading;
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Container(
        height: ResponsiveUtils.imageHeight(context, 250),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              MapWidget(
                onMapCreated: onMapCreated,
                onUseCurrentLocation: onUseCurrentLocation,
                onToggleFullscreen: onToggleFullscreen,
                onMapTap: onMapTap,
                isFullscreen: false,
              ),
              if (isLoading)
                Positioned.fill(
                  child: IgnorePointer(
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
                ),
              Positioned(
                top: ResponsiveUtils.spacing(context, 16),
                right: ResponsiveUtils.spacing(context, 16),
                child: MapZoomControls(
                  onToggleFullscreen: onToggleFullscreen,
                  isFullscreen: false,
                ),
              ),
              Positioned(
                bottom: ResponsiveUtils.spacing(context, 16),
                right: ResponsiveUtils.spacing(context, 16),
                child: LocationButton(
                  onUseCurrentLocation: onUseCurrentLocation,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
