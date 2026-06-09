import 'package:flutter/material.dart';

import '../di/injection.dart';
import '../services/connectivity_service.dart';

/// Blocks network-dependent actions when offline and offers retry.
class NetworkGuard {
  NetworkGuard._();

  static Future<bool> ensureOnline(BuildContext context) async {
    final service = getIt<ConnectivityService>();
    await service.checkConnection();
    if (service.isConnected) return true;
    if (!context.mounted) return false;

    final shouldRetry = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('No internet connection'),
        content: const Text(
          'Please check your Wi‑Fi or mobile data, then try again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF5F2D82),
            ),
            onPressed: () async {
              await service.checkConnection();
              if (!dialogContext.mounted) return;
              if (service.isConnected) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );

    if (shouldRetry == true) {
      await service.checkConnection();
      return service.isConnected;
    }
    return false;
  }
}
