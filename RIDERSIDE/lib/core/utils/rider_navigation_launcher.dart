import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'rider_route_utils.dart';

enum RiderMapApp { google, waze, appleMaps }

class RiderNavigationLauncher {
  RiderNavigationLauncher._();

  static Future<void> showChooser({
    required BuildContext context,
    required double destLat,
    required double destLng,
    required String destinationLabel,
    double? originLat,
    double? originLng,
  }) async {
    // Missing coordinates arrive as 0,0; navigating there sends the rider to
    // the Gulf of Guinea. Tell them instead of opening a useless chooser.
    if (!RiderRouteUtils.hasValidCoordinates(destLat, destLng)) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text('No map location for $destinationLabel on this order.'),
        ),
      );
      return;
    }

    final apps = <RiderMapApp>[RiderMapApp.google];
    if (!Platform.isIOS) {
      apps.add(RiderMapApp.waze);
    } else {
      apps.add(RiderMapApp.appleMaps);
    }
    if (!Platform.isIOS) {
      apps.add(RiderMapApp.appleMaps);
    }

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Navigate to $destinationLabel',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                for (final app in apps)
                  ListTile(
                    leading: Icon(_iconFor(app), color: const Color(0xFF5F2D82)),
                    title: Text(
                      _labelFor(app),
                      style: const TextStyle(fontFamily: 'TT Fors'),
                    ),
                    onTap: () async {
                      final messenger = ScaffoldMessenger.maybeOf(context);
                      Navigator.pop(ctx);
                      final opened = await launch(
                        app: app,
                        destLat: destLat,
                        destLng: destLng,
                        originLat: originLat,
                        originLng: originLng,
                      );
                      if (!opened) {
                        messenger?.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Could not open ${_labelFor(app)}. Is it installed?',
                            ),
                          ),
                        );
                      }
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<bool> launch({
    required RiderMapApp app,
    required double destLat,
    required double destLng,
    double? originLat,
    double? originLng,
  }) async {
    final Uri uri;
    switch (app) {
      case RiderMapApp.google:
        uri = Uri.parse(
          RiderRouteUtils.buildGoogleMapsNavigationUrl(
            destLat: destLat,
            destLng: destLng,
            originLat: originLat,
            originLng: originLng,
          ),
        );
        break;
      case RiderMapApp.waze:
        uri = Uri.parse(
          'https://waze.com/ul?ll=$destLat,$destLng&navigate=yes',
        );
        break;
      case RiderMapApp.appleMaps:
        final daddr = '$destLat,$destLng';
        if (originLat != null &&
            originLng != null &&
            RiderRouteUtils.hasValidCoordinates(originLat, originLng)) {
          uri = Uri.parse(
            'http://maps.apple.com/?saddr=$originLat,$originLng&daddr=$daddr&dirflg=d',
          );
        } else {
          uri = Uri.parse('http://maps.apple.com/?daddr=$daddr&dirflg=d');
        }
        break;
    }

    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
    return false;
  }

  static IconData _iconFor(RiderMapApp app) {
    switch (app) {
      case RiderMapApp.google:
        return Icons.map_outlined;
      case RiderMapApp.waze:
        return Icons.navigation_outlined;
      case RiderMapApp.appleMaps:
        return Icons.apple;
    }
  }

  static String _labelFor(RiderMapApp app) {
    switch (app) {
      case RiderMapApp.google:
        return 'Google Maps';
      case RiderMapApp.waze:
        return 'Waze';
      case RiderMapApp.appleMaps:
        return 'Apple Maps';
    }
  }
}
