import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/utils/responsive_utils.dart';
import '../../../../../core/utils/rider_route_utils.dart';
import '../../../../../domain/entities/rider_booking.dart';
import '../../../../provider/main/riderside/rider_location_provider.dart';
import '../../../../screens/main/riderside/map/rider_map_screen.dart';

class RiderBookingDetailMapSection extends ConsumerStatefulWidget {
  const RiderBookingDetailMapSection({
    super.key,
    required this.booking,
    required this.locationState,
    required this.currentApiStatus,
    required this.onMapCreated,
    required this.onFitBounds,
  });

  final RiderBooking booking;
  final RiderLocationState locationState;
  final String? currentApiStatus;
  final ValueChanged<GoogleMapController> onMapCreated;
  final VoidCallback onFitBounds;

  @override
  ConsumerState<RiderBookingDetailMapSection> createState() =>
      _RiderBookingDetailMapSectionState();

  static void fitBounds({
    required GoogleMapController? controller,
    required RiderBooking booking,
    RiderLocationState? locationState,
  }) {
    if (controller == null) return;

    final points = <LatLng>[];
    if (booking.pickupLat != null && booking.pickupLng != null) {
      points.add(LatLng(booking.pickupLat!, booking.pickupLng!));
    }
    if (booking.dropoffLat != null && booking.dropoffLng != null) {
      points.add(LatLng(booking.dropoffLat!, booking.dropoffLng!));
    }
    if (locationState?.hasLocation == true) {
      points.add(LatLng(locationState!.latitude!, locationState.longitude!));
    }
    if (points.isEmpty) return;

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;
    for (final point in points) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        80,
      ),
    );
  }
}

class _RiderBookingDetailMapSectionState
    extends ConsumerState<RiderBookingDetailMapSection> {
  Set<Polyline> _polylines = {};
  bool _loadingRoute = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshRoute());
  }

  @override
  void didUpdateWidget(covariant RiderBookingDetailMapSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locationState.latitude != widget.locationState.latitude ||
        oldWidget.locationState.longitude != widget.locationState.longitude ||
        oldWidget.currentApiStatus != widget.currentApiStatus) {
      _refreshRoute();
    }
  }

  Future<void> _refreshRoute() async {
    final booking = widget.booking;
    final location = widget.locationState;
    if (!location.hasLocation ||
        booking.pickupLat == null ||
        booking.pickupLng == null ||
        booking.dropoffLat == null ||
        booking.dropoffLng == null) {
      return;
    }

    setState(() => _loadingRoute = true);
    final polylines = await RiderRouteUtils.buildNavigationPolylinesForBooking(
      status: widget.currentApiStatus,
      pickupLat: booking.pickupLat!,
      pickupLng: booking.pickupLng!,
      dropoffLat: booking.dropoffLat!,
      dropoffLng: booking.dropoffLng!,
      riderLat: location.latitude!,
      riderLng: location.longitude!,
    );
    if (mounted) {
      setState(() {
        _polylines = polylines;
        _loadingRoute = false;
      });
    }
  }

  Future<void> _openNavigation() async {
    final booking = widget.booking;
    if (booking.pickupLat == null ||
        booking.pickupLng == null ||
        booking.dropoffLat == null ||
        booking.dropoffLng == null) {
      return;
    }

    final target = RiderRouteUtils.navigationTargetForStatus(
      status: widget.currentApiStatus,
      pickupLat: booking.pickupLat!,
      pickupLng: booking.pickupLng!,
      dropoffLat: booking.dropoffLat!,
      dropoffLng: booking.dropoffLng!,
    );

    final url = RiderRouteUtils.buildGoogleMapsNavigationUrl(
      destLat: target.destination.latitude,
      destLng: target.destination.longitude,
      originLat: widget.locationState.latitude,
      originLng: widget.locationState.longitude,
    );

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Set<Marker> _buildMarkers() {
    final booking = widget.booking;
    final locationState = widget.locationState;
    final markers = <Marker>{};

    if (locationState.hasLocation) {
      markers.add(Marker(
        markerId: const MarkerId('driver_location'),
        position: LatLng(locationState.latitude!, locationState.longitude!),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Your Location'),
        zIndex: 2,
      ));
    }

    if (booking.pickupLat != null && booking.pickupLng != null) {
      markers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(booking.pickupLat!, booking.pickupLng!),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Pickup Location'),
      ));
    }

    if (booking.dropoffLat != null && booking.dropoffLng != null) {
      markers.add(Marker(
        markerId: const MarkerId('dropoff'),
        position: LatLng(booking.dropoffLat!, booking.dropoffLng!),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Dropoff Location'),
      ));
    }

    return markers;
  }

  String get _navButtonLabel {
    final target = RiderRouteUtils.navigationTargetForStatus(
      status: widget.currentApiStatus,
      pickupLat: widget.booking.pickupLat ?? 0,
      pickupLng: widget.booking.pickupLng ?? 0,
      dropoffLat: widget.booking.dropoffLat ?? 0,
      dropoffLng: widget.booking.dropoffLng ?? 0,
    );
    return 'Navigate to ${target.navLabel}';
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final mapHeight = ResponsiveUtils.adaptiveMapSectionHeight(context, 300);
    final narrow = MediaQuery.sizeOf(context).width < 360;

    Widget buildNavButton() {
      return GestureDetector(
        onTap: _openNavigation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF5F2D82),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.navigation, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _navButtonLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget buildFullMapButton() {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RiderMapScreen(
                orderId: int.parse(booking.id),
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.fullscreen, color: Colors.white, size: 16),
              SizedBox(width: 4),
              Text(
                'View Full Map',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 11,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: mapHeight,
      margin: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: booking.pickupLat != null && booking.pickupLng != null
                    ? LatLng(booking.pickupLat!, booking.pickupLng!)
                    : const LatLng(8.4542, 124.6319),
                zoom: 13,
              ),
              zoomGesturesEnabled: true,
              scrollGesturesEnabled: true,
              tiltGesturesEnabled: true,
              rotateGesturesEnabled: true,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: true,
              myLocationEnabled: true,
              markers: _buildMarkers(),
              polylines: _polylines,
              onMapCreated: (controller) {
                widget.onMapCreated(controller);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Future.delayed(
                    const Duration(milliseconds: 500),
                    widget.onFitBounds,
                  );
                });
              },
            ),
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 8,
                      height: 8,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'LIVE TRACKING',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_loadingRoute)
              const Positioned(
                top: 8,
                right: 8,
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            if (narrow)
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    buildNavButton(),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: buildFullMapButton(),
                    ),
                  ],
                ),
              )
            else ...[
              Positioned(
                bottom: 8,
                left: 8,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * 0.55,
                  ),
                  child: buildNavButton(),
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: buildFullMapButton(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
