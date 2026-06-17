import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/order_sound_alert_service.dart';
import '../../provider/main/merchantside/merchant_sound_settings_provider.dart';

class MerchantSoundAlertSettingsScreen extends ConsumerWidget {
  const MerchantSoundAlertSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final soundEnabled = ref.watch(soundEnabledProvider);
    final volume = ref.watch(soundVolumeProvider);
    final selectedSound = ref.watch(selectedSoundProvider);
    final vibrationEnabled = ref.watch(vibrationEnabledProvider);
    final availableSounds = ref.watch(availableSoundsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Notifications'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sound Alerts Section
            _buildSectionHeader('Sound Alerts'),
            _buildToggleTile(
              title: 'Enable Sound Alerts',
              subtitle: 'Play a sound when you receive new orders',
              value: soundEnabled,
              onChanged: (value) {
                ref.read(soundEnabledProvider.notifier).set(value);
              },
            ),
            const SizedBox(height: 24),

            // If sound enabled, show additional options
            if (soundEnabled) ...[
              // Sound Selection
              _buildSectionHeader('Select Sound'),
              _buildSoundSelector(
                availableSounds: availableSounds,
                selectedSound: selectedSound,
                onSelected: (sound) {
                  ref.read(selectedSoundProvider.notifier).setSound(sound);
                },
              ),
              const SizedBox(height: 24),

              // Volume Control
              _buildSectionHeader('Volume'),
              _buildVolumeControl(
                volume: volume,
                onChanged: (value) {
                  ref.read(soundVolumeProvider.notifier).setVolume(value);
                },
              ),
              const SizedBox(height: 24),

              // Test Sound Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.volume_up),
                  label: const Text('Test Sound'),
                  onPressed: () async {
                    await OrderSoundAlertService().testSound();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.blue,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Vibration Section
            _buildSectionHeader('Vibration'),
            _buildToggleTile(
              title: 'Enable Vibration',
              subtitle: 'Device will vibrate when you receive new orders',
              value: vibrationEnabled,
              onChanged: (value) {
                ref.read(vibrationEnabledProvider.notifier).set(value);
              },
            ),
            const SizedBox(height: 32),

            // Info Card
            _buildInfoCard(
              'Tip: Customize these settings to ensure you never miss an order!',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSoundSelector({
    required Map<String, String> availableSounds,
    required String selectedSound,
    required Function(String) onSelected,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: List.generate(
            availableSounds.length,
            (index) {
              final soundKey = availableSounds.keys.toList()[index];
              final isSelected = selectedSound == soundKey;

              return RadioListTile<String>(
                title: Text(
                  _getSoundDisplayName(soundKey),
                  style: const TextStyle(fontSize: 14),
                ),
                value: soundKey,
                groupValue: selectedSound,
                onChanged: (value) {
                  if (value != null) {
                    onSelected(value);
                  }
                },
                activeColor: Colors.blue,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildVolumeControl({
    required double volume,
    required ValueChanged<double> onChanged,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Slider(
              value: volume,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              label: '${(volume * 100).toInt()}%',
              onChanged: onChanged,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Volume: ${(volume * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String message) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.info, color: Colors.blue.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSoundDisplayName(String key) {
    const soundNames = {
      'bell': '🔔 Bell',
      'chime': '✨ Chime',
      'ping': '📳 Ping',
      'notification': '📢 Notification',
    };
    return soundNames[key] ?? key;
  }
}
