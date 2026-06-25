import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../core/utils/responsive_utils.dart';

/// Map pin picker for merchant restaurant location during registration.
class MerchantLocationPinPicker extends StatefulWidget {
  const MerchantLocationPinPicker({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.onLocationChanged,
    this.hasError = false,
  });

  final double? latitude;
  final double? longitude;
  final void Function(double latitude, double longitude) onLocationChanged;
  final bool hasError;

  static const LatLng defaultCenter = LatLng(8.4542, 124.6319);

  @override
  State<MerchantLocationPinPicker> createState() =>
      _MerchantLocationPinPickerState();
}

class _MerchantLocationPinPickerState extends State<MerchantLocationPinPicker> {
  GoogleMapController? _mapController;
  late LatLng _pin;

  @override
  void initState() {
    super.initState();
    _pin = _initialPin();
  }

  LatLng _initialPin() {
    if (widget.latitude != null && widget.longitude != null) {
      return LatLng(widget.latitude!, widget.longitude!);
    }
    return MerchantLocationPinPicker.defaultCenter;
  }

  @override
  void didUpdateWidget(covariant MerchantLocationPinPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.latitude != null &&
        widget.longitude != null &&
        (widget.latitude != oldWidget.latitude ||
            widget.longitude != oldWidget.longitude)) {
      _pin = LatLng(widget.latitude!, widget.longitude!);
      _mapController?.animateCamera(CameraUpdate.newLatLng(_pin));
    }
  }

  Future<void> _useCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showMessage('Turn on location services to use your current position.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showMessage('Location permission is required to pin your restaurant.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final location = LatLng(position.latitude, position.longitude);
      setState(() => _pin = location);
      widget.onLocationChanged(location.latitude, location.longitude);
      await _mapController?.animateCamera(CameraUpdate.newLatLngZoom(location, 16));
    } catch (e) {
      _showMessage('Could not get current location. Drag the pin instead.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPin = widget.latitude != null && widget.longitude != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Pin restaurant location on map',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 14),
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _useCurrentLocation,
              icon: const Icon(Icons.my_location, size: 18),
              label: const Text('Use my location'),
            ),
          ],
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 220,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(target: _pin, zoom: 15),
                  onMapCreated: (controller) => _mapController = controller,
                  onTap: (latLng) {
                    setState(() => _pin = latLng);
                    widget.onLocationChanged(latLng.latitude, latLng.longitude);
                  },
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  markers: {
                    Marker(
                      markerId: const MarkerId('restaurant_pin'),
                      position: _pin,
                      draggable: true,
                      onDragEnd: (latLng) {
                        setState(() => _pin = latLng);
                        widget.onLocationChanged(
                          latLng.latitude,
                          latLng.longitude,
                        );
                      },
                    ),
                  },
                ),
                if (!hasPin)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.04),
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Tap map or drag pin to set location',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (widget.hasError) ...[
          SizedBox(height: ResponsiveUtils.spacing(context, 6)),
          Text(
            'Please pin your restaurant location on the map.',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 12),
              color: Colors.red.shade700,
            ),
          ),
        ] else if (hasPin) ...[
          SizedBox(height: ResponsiveUtils.spacing(context, 6)),
          Text(
            'Pinned: ${widget.latitude!.toStringAsFixed(5)}, ${widget.longitude!.toStringAsFixed(5)}',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 11),
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ],
    );
  }
}
