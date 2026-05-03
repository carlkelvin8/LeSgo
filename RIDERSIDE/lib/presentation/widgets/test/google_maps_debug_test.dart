import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapsDebugTest extends StatefulWidget {
  const GoogleMapsDebugTest({super.key});

  @override
  State<GoogleMapsDebugTest> createState() => _GoogleMapsDebugTestState();
}

class _GoogleMapsDebugTestState extends State<GoogleMapsDebugTest> {
  GoogleMapController? _controller;
  bool _mapCreated = false;
  String _status = 'Initializing...';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Maps Debug Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Status indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _mapCreated ? Colors.green.shade100 : Colors.orange.shade100,
            child: Text(
              'Status: $_status',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _mapCreated ? Colors.green.shade800 : Colors.orange.shade800,
              ),
            ),
          ),
          
          // Map
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red, width: 2),
              ),
              child: GoogleMap(
                mapType: MapType.normal,
                initialCameraPosition: const CameraPosition(
                  target: LatLng(37.7749, -122.4194), // San Francisco
                  zoom: 12,
                ),
                
                // Enable all gestures
                zoomGesturesEnabled: true,
                scrollGesturesEnabled: true,
                tiltGesturesEnabled: true,
                rotateGesturesEnabled: true,
                
                // Enable controls
                zoomControlsEnabled: true,
                myLocationButtonEnabled: true,
                mapToolbarEnabled: true,
                compassEnabled: true,
                
                // Enable location
                myLocationEnabled: false, // Disable to avoid permission issues
                
                onMapCreated: (GoogleMapController controller) {
                  _controller = controller;
                  setState(() {
                    _mapCreated = true;
                    _status = 'Map created successfully! ✅';
                  });
                  print('🗺️ DEBUG: Google Maps created successfully');
                  print('🔑 DEBUG: API Key should be: AIzaSyA0s1a7phLN0iaD6-MjnwqfpJFhYhmyNjU');
                },
                
                onTap: (LatLng position) {
                  setState(() {
                    _status = 'Tapped at: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
                  });
                  print('🗺️ DEBUG: Map tapped at ${position.latitude}, ${position.longitude}');
                },
                
                onCameraMove: (CameraPosition position) {
                  print('📷 DEBUG: Camera moved to ${position.target.latitude}, ${position.target.longitude} zoom: ${position.zoom}');
                },
              ),
            ),
          ),
          
          // Debug info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Debug Info:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Map Created: $_mapCreated'),
                Text('Controller: ${_controller != null ? "Available" : "Null"}'),
                Text('API Key: AIzaSyA0s1a7phLN0iaD6-MjnwqfpJFhYhmyNjU'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _mapCreated ? () {
                    _controller?.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        const LatLng(8.4542, 124.6319), // Cagayan de Oro
                        15,
                      ),
                    );
                    setState(() {
                      _status = 'Moved to Cagayan de Oro';
                    });
                  } : null,
                  child: const Text('Move to Cagayan de Oro'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}