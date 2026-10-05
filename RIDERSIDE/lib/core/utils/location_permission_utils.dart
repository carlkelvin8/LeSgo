import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> showLocationPermissionSnackBar(
  BuildContext context, {
  required bool openSettings,
  String? message,
}) async {
  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message ??
            (openSettings
                ? 'Location access is blocked. Open Settings to enable it for deliveries.'
                : 'Location permission is required for map and delivery tracking.'),
      ),
      action: openSettings
          ? SnackBarAction(
              label: 'Settings',
              onPressed: openAppSettings,
            )
          : null,
      duration: const Duration(seconds: 5),
    ),
  );
}

bool permissionNeedsSettings(PermissionStatus status) {
  return status.isPermanentlyDenied || status.isRestricted;
}
