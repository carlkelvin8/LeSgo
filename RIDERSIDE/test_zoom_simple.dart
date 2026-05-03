// Simple test to verify zoom controls work
// This demonstrates the zoom functionality

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SimpleMapWithZoom(),
    );
  }
}

class SimpleMapWithZoom extends StatefulWidget {
  @override
  _SimpleMapWithZoomState createState() => _SimpleMapWithZoomState();
}

class _SimpleMapWithZoomState extends State<SimpleMapWithZoom> {
  GoogleMapController? _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Zoom Test')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(8.4542, 124.6319),
              zoom: 14,
            ),
            onMapCreated: (controller) {
              _controller = controller;
              print('✅ Map controller ready');
            },
            zoomControlsEnabled: false,
            zoomGesturesEnabled: true,
          ),
          
          // Zoom Controls
          Positioned(
            right: 20,
            top: 100,
            child: Column(
              children: [
                // Zoom In
                FloatingActionButton(
                  heroTag: "zoom_in",
                  mini: true,
                  onPressed: () async {
                    print('🔍 ZOOM IN PRESSED');
                    if (_controller != null) {
                      await _controller!.animateCamera(CameraUpdate.zoomIn());
                      print('✅ ZOOMED IN SUCCESS');
                    } else {
                      print('❌ Controller null');
                    }
                  },
                  child: Icon(Icons.add),
                ),
                SizedBox(height: 10),
                
                // Zoom Out
                FloatingActionButton(
                  heroTag: "zoom_out",
                  mini: true,
                  onPressed: () async {
                    print('🔍 ZOOM OUT PRESSED');
                    if (_controller != null) {
                      await _controller!.animateCamera(CameraUpdate.zoomOut());
                      print('✅ ZOOMED OUT SUCCESS');
                    } else {
                      print('❌ Controller null');
                    }
                  },
                  child: Icon(Icons.remove),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}