// Alternative zoom controls implementation
// Replace the existing zoom controls with this simpler version

// Simple Zoom Controls using FloatingActionButtons
Positioned(
  right: 16,
  top: 120,
  child: Column(
    children: [
      // Zoom In
      FloatingActionButton(
        mini: true,
        heroTag: "zoom_in_btn",
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF5F2D82),
        onPressed: () async {
          print('🔍 ZOOM IN PRESSED - FloatingActionButton');
          if (_mapController != null) {
            try {
              await _mapController!.animateCamera(CameraUpdate.zoomIn());
              print('✅ ZOOM IN SUCCESS');
            } catch (e) {
              print('❌ ZOOM IN ERROR: $e');
            }
          } else {
            print('❌ Map controller is null');
          }
        },
        child: Icon(Icons.add),
      ),
      SizedBox(height: 10),
      
      // Zoom Out
      FloatingActionButton(
        mini: true,
        heroTag: "zoom_out_btn",
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF5F2D82),
        onPressed: () async {
          print('🔍 ZOOM OUT PRESSED - FloatingActionButton');
          if (_mapController != null) {
            try {
              await _mapController!.animateCamera(CameraUpdate.zoomOut());
              print('✅ ZOOM OUT SUCCESS');
            } catch (e) {
              print('❌ ZOOM OUT ERROR: $e');
            }
          } else {
            print('❌ Map controller is null');
          }
        },
        child: Icon(Icons.remove),
      ),
    ],
  ),
),