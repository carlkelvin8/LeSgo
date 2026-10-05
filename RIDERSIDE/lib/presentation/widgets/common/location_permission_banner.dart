import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../provider/main/riderside/rider_location_provider.dart';

class LocationPermissionBanner extends ConsumerWidget {
  const LocationPermissionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(riderLocationProvider);
    final error = locationState.error;
    if (error == null) return const SizedBox.shrink();

    return Material(
      color: Colors.orange.shade800,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.location_off, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  error,
                  style: const TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (locationState.needsLocationSettings)
                TextButton(
                  onPressed: openAppSettings,
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  child: const Text('Settings'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
