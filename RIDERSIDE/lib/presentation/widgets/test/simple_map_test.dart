import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/config/secrets_config.dart';

class SimpleMapTest extends StatefulWidget {
  const SimpleMapTest({super.key});

  @override
  State<SimpleMapTest> createState() => _SimpleMapTestState();
}

class _SimpleMapTestState extends State<SimpleMapTest> {
  GoogleMapController? _controller;
  bool _mapReady = false;
  String _status = 'Initializing...';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Test'),
        backgroundColor: const Color(0xFF5F2D82),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Status Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _mapReady ? Colors.green : Colors.orange,
            child: Text(
              _status,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Map Area
          Expanded(
            child: Stack(
              children: [
                // Try the most basic GoogleMap possible
                GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(8.4542, 124.6319), // Cagayan de Oro
                    zoom: 14,
                  ),
                  onMapCreated: (GoogleMapController controller) {
                    print('🗺️ TEST MAP CREATED SUCCESSFULLY!');
                    _controller = controller;
                    setState(() {
                      _mapReady = true;
                      _status = 'MAP READY ✅';
                    });
                  },
                  onTap: (LatLng position) {
                    print('🗺️ TEST MAP TAPPED: ${position.latitude}, ${position.longitude}');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Map works! Tapped: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  // Minimal configuration
                  zoomGesturesEnabled: true,
                  scrollGesturesEnabled: true,
                  myLocationEnabled: false, // Disable to avoid permission issues
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: true, // Enable built-in controls for testing
                  mapToolbarEnabled: false,
                  compassEnabled: false,
                  tiltGesturesEnabled: false,
                  rotateGesturesEnabled: false,
                  trafficEnabled: false,
                  buildingsEnabled: false,
                  indoorViewEnabled: false,
                  liteModeEnabled: false, // Ensure full map mode
                  
                  // Add a simple marker
                  markers: {
                    const Marker(
                      markerId: MarkerId('test'),
                      position: LatLng(8.4542, 124.6319),
                      infoWindow: InfoWindow(title: 'Test Marker'),
                    ),
                  },
                ),
                
                // Loading overlay
                if (!_mapReady)
                  Container(
                    color: Colors.white.withOpacity(0.8),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading Test Map...'),
                          SizedBox(height: 8),
                          Text('If this stays loading, there\'s an API key issue'),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Debug Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Debug Info:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Map Ready: $_mapReady'),
                Text('Controller: ${_controller != null ? 'Available' : 'Null'}'),
                Text('Maps config: ${SecretsConfig.googleMapsConfigStatus}'),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _status = 'Refreshing...';
                      _mapReady = false;
                    });
                    // Force rebuild
                    Future.delayed(Duration(milliseconds: 100), () {
                      if (mounted) {
                        setState(() {});
                      }
                    });
                  },
                  child: Text('Refresh Map'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}