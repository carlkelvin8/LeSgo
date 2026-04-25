import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'address_map_view.dart';
import 'current_location_button.dart';
import '../../../global/googlemaps/map_toggle_button.dart';
import '../../../../../core/utils/responsive_utils.dart';

class AddressMapContainer extends StatelessWidget {
  final bool isExpanded;
  final LatLng? selectedLocation;
  final Function(GoogleMapController) onMapCreated;
  final Function(LatLng) onMapTap;
  final VoidCallback onUseCurrentLocation;
  final VoidCallback onToggleExpand;

  const AddressMapContainer({
    super.key,
    required this.isExpanded,
    required this.selectedLocation,
    required this.onMapCreated,
    required this.onMapTap,
    required this.onUseCurrentLocation,
    required this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isExpanded ? ResponsiveUtils.imageHeight(context, 250) : 0,
      child: isExpanded
          ? Stack(
              children: [
                AddressMapView(
                  location: selectedLocation,
                  onMapCreated: onMapCreated,
                  onMapTap: onMapTap,
                ),

                Positioned(
                  bottom: ResponsiveUtils.spacing(context, 16),
                  right: ResponsiveUtils.spacing(context, 16),
                  child: CurrentLocationButton(onTap: onUseCurrentLocation),
                ),
                
                Positioned(
                  top: ResponsiveUtils.spacing(context, 8),
                  right: ResponsiveUtils.spacing(context, 8),
                  child: MapToggleButton(
                    isExpanded: isExpanded,
                    onTap: onToggleExpand,
                  ),
                ),
              ],
            )
          : null,
    );
  }
}
