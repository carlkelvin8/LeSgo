import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/services/order_sound_alert_service.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../provider/main/merchantside/merchant_sound_settings_provider.dart';

/// A settings card for choosing notification sound.
class MerchantSoundSettingsCard extends ConsumerWidget {
  const MerchantSoundSettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final soundEnabled = ref.watch(soundEnabledProvider);
    final selectedSound = ref.watch(selectedSoundProvider);
    final availableSounds = ref.watch(availableSoundsProvider);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.volume_up_outlined,
                color: const Color(0xFF5F2D82),
                size: ResponsiveUtils.fontSize(context, 20),
              ),
              SizedBox(width: ResponsiveUtils.spacing(context, 8)),
              Text(
                'Notification Sound',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 15),
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Switch(
                value: soundEnabled,
                activeThumbColor: const Color(0xFF5F2D82),
                onChanged: (value) {
                  ref.read(soundEnabledProvider.notifier).set(value);
                },
              ),
            ],
          ),
          if (soundEnabled) ...[
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
            Text(
              'Choose a sound:',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 12),
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 8)),
            Wrap(
              spacing: ResponsiveUtils.spacing(context, 8),
              runSpacing: ResponsiveUtils.spacing(context, 8),
              children: availableSounds.keys.map((soundKey) {
                final isSelected = soundKey == selectedSound;
                final label = _soundLabel(soundKey);
                return ChoiceChip(
                  label: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 12),
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: const Color(0xFF5F2D82),
                  backgroundColor: Colors.grey.shade100,
                  onSelected: (selected) {
                    if (selected) {
                      ref
                          .read(selectedSoundProvider.notifier)
                          .setSound(soundKey);
                      // Play preview
                      OrderSoundAlertService().testSound();
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _soundLabel(String key) {
    switch (key) {
      case 'bell':
        return '🔔 Bell';
      case 'chime':
        return '🎵 Chime';
      case 'ping':
        return '📢 Ping';
      case 'notification':
        return '🔊 Default';
      default:
        return key;
    }
  }
}
