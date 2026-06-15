import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Dev-only test widget — not used in production.
@Deprecated('Remove before production release')
class UltraSimpleMap extends StatelessWidget {
  const UltraSimpleMap({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ultra Simple Map'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: const GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(37.7749, -122.4194), // San Francisco
          zoom: 10,
        ),
      ),
    );
  }
}