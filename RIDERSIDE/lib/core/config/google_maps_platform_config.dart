import 'package:flutter/foundation.dart' show kIsWeb;

import 'web_maps_loader_stub.dart'
    if (dart.library.html) 'web_maps_loader_web.dart';

/// Loads the Google Maps JS SDK on web using the compile-time API key.
Future<void> configureGoogleMapsForPlatform() async {
  if (kIsWeb) {
    await loadGoogleMapsScript();
  }
}
