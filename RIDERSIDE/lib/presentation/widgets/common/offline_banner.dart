import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/offline_request_queue.dart';
import '../../../core/services/connectivity_service.dart';

final connectivityProvider = StreamProvider<bool>((ref) {
  return connectivityService.connectivityStream;
});

final offlinePendingCountProvider = StreamProvider<int>((ref) {
  return offlineRequestQueue.pendingCountStream;
});

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectivityProvider);
    final pendingAsync = ref.watch(offlinePendingCountProvider);

    return connectivityAsync.when(
      data: (isConnected) {
        final pending =
            pendingAsync.valueOrNull ?? offlineRequestQueue.pendingCount;
        if (isConnected && pending == 0) return const SizedBox.shrink();

        final message = isConnected
            ? '$pending action${pending == 1 ? '' : 's'} queued — retrying now'
            : pending > 0
                ? 'No internet — $pending action${pending == 1 ? '' : 's'} will retry when back online'
                : 'No internet connection';

        return Material(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: isConnected ? Colors.orange.shade800 : Colors.red.shade700,
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  Icon(
                    isConnected ? Icons.sync : Icons.wifi_off,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (!isConnected)
                    TextButton(
                      onPressed: () => connectivityService.checkConnection(),
                      style: TextButton.styleFrom(foregroundColor: Colors.white),
                      child: const Text('Retry'),
                    ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
