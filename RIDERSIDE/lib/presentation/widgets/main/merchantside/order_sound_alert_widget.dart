import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/order_sound_alert_service.dart';
import '../../provider/main/merchantside/merchant_sound_settings_provider.dart';
import '../../screens/main/merchantside/merchant_sound_alert_settings_screen.dart';

/// Widget to display order sound alert status and quick access to settings
class OrderSoundAlertWidget extends ConsumerWidget {
  const OrderSoundAlertWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final soundEnabled = ref.watch(soundEnabledProvider);
    final selectedSound = ref.watch(selectedSoundProvider);

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  soundEnabled ? Icons.volume_up : Icons.volume_off,
                  color: soundEnabled ? Colors.green : Colors.grey,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order Notifications',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        soundEnabled
                            ? 'Sound alerts enabled • ${_getSoundName(selectedSound)}'
                            : 'Sound alerts disabled',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Quick toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enable Sound Alerts'),
              value: soundEnabled,
              onChanged: (value) {
                ref.read(soundEnabledProvider.notifier).set(value);
              },
            ),
            const SizedBox(height: 12),

            // Settings button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          const MerchantSoundAlertSettingsScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Sound Settings'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSoundName(String soundKey) {
    const soundNames = {
      'bell': 'Bell',
      'chime': 'Chime',
      'ping': 'Ping',
      'notification': 'Notification',
    };
    return soundNames[soundKey] ?? soundKey;
  }
}
