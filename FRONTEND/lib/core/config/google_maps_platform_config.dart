import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/services.dart';

import 'mobile_config_service.dart';

import 'web_maps_loader_stub.dart'
    if (dart.library.html) 'web_maps_loader_web.dart';

/// Loads the Google Maps JS SDK on web using the compile-time API key.
Future<void> configureGoogleMapsForPlatform() async {
  if (kIsWeb) {
    await loadGoogleMapsScript();
    return;
  }

  // The native Maps SDK needs its key before the first GoogleMap widget is
  // created. Local simulator builds may not have Secrets.xcconfig, so use the
  // same public mobile config that main() has already loaded from the API.
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    final apiKey = MobileConfigService.instance.googleMapsApiKey;
    final configured = await const MethodChannel('com.lesgo.app/google_maps')
        .invokeMethod<bool>('configure', {'apiKey': apiKey})
        .timeout(const Duration(seconds: 5));
    if (configured != true) {
      throw StateError('Google Maps configuration is unavailable');
    }
  }
}
