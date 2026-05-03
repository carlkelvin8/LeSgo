import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'lib/presentation/widgets/main/riderside/map/map_zoom_controls.dart';

class TestZoomControls extends StatefulWidget {
  @override
  _TestZoomControlsState createState() => _TestZoomControlsState();
}

class _TestZoomControlsState extends State<TestZoomControls> {
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Test Zoom Controls')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(8.4542, 124.6319),
              zoom: 14,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            zoomControlsEnabled: false,
            zoomGesturesEnabled: true,
          ),
          Positioned(
            right: 16,
            top: 100,
            child: MapZoomControls(
              mapController: _mapController,
              onCenterMap: () {
                print('Center map pressed');
              },
            ),
          ),
        ],
      ),
    );
  }
}