import 'dart:html' as html;

import 'secrets_config.dart';

Future<void> loadGoogleMapsScript() async {
  if (!SecretsConfig.isGoogleMapsConfigured) return;
  if (html.document.getElementById('google-maps-js') != null) return;

  final script = html.ScriptElement()
    ..id = 'google-maps-js'
    ..async = true
    ..defer = true
    ..src =
        'https://maps.googleapis.com/maps/api/js'
        '?key=${SecretsConfig.googleMapsApiKey}'
        '&loading=async&libraries=marker,geometry,places&v=weekly';

  html.document.head?.append(script);
}
