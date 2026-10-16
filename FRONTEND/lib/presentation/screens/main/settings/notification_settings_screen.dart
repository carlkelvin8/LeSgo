import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/services/app_preferences_service.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  late bool _promotions;
  late bool _orderUpdates;
  late bool _missionReminders;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final prefs = getIt<AppPreferencesService>();
    _promotions = prefs.pushPromotionsEnabled;
    _orderUpdates = prefs.pushOrderUpdatesEnabled;
    _missionReminders = prefs.pushMissionRemindersEnabled;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final prefs = getIt<AppPreferencesService>();
    await prefs.setPushPromotionsEnabled(_promotions);
    await prefs.setPushOrderUpdatesEnabled(_orderUpdates);
    await prefs.setPushMissionRemindersEnabled(_missionReminders);
    if (mounted) {
      setState(() => _saving = false);
      SnackBarUtils.showSuccess(context, 'Notification preferences saved.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: ListView(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
        children: [
          SwitchListTile(
            title: const Text('Promotions & offers'),
            subtitle: const Text('Daily promos and voucher alerts'),
            value: _promotions,
            activeThumbColor: Theme.of(context).colorScheme.primary,
            onChanged: (v) => setState(() => _promotions = v),
          ),
          SwitchListTile(
            title: const Text('Order updates'),
            subtitle: const Text('Driver assigned, picked up, delivered'),
            value: _orderUpdates,
            activeThumbColor: Theme.of(context).colorScheme.primary,
            onChanged: (v) => setState(() => _orderUpdates = v),
          ),
          SwitchListTile(
            title: const Text('Mission reminders'),
            subtitle: const Text('Referral and mission reward alerts'),
            value: _missionReminders,
            activeThumbColor: Theme.of(context).colorScheme.primary,
            onChanged: (v) => setState(() => _missionReminders = v),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 24)),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              minimumSize: const Size.fromHeight(48),
            ),
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save preferences'),
          ),
        ],
      ),
    );
  }
}
