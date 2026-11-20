import 'package:lesgo/core/theme/app_colors.dart';
import 'package:lesgo/core/theme/app_tokens.dart';
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

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
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
      appBar: AppBar(title: const Text('Notification Settings')),
      body: ListView(
        padding: EdgeInsets.all(ResponsiveUtils.screenPadding(context)),
        children: [
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Promotions & offers'),
                  subtitle: const Text('Daily promos and voucher alerts'),
                  value: _promotions,
                  onChanged: (v) => setState(() => _promotions = v),
                ),
                const Divider(height: 1, indent: AppSpace.lg),
                SwitchListTile(
                  title: const Text('Order updates'),
                  subtitle: const Text('Driver assigned, picked up, delivered'),
                  value: _orderUpdates,
                  onChanged: (v) => setState(() => _orderUpdates = v),
                ),
                const Divider(height: 1, indent: AppSpace.lg),
                SwitchListTile(
                  title: const Text('Mission reminders'),
                  subtitle: const Text('Referral and mission reward alerts'),
                  value: _missionReminders,
                  onChanged: (v) => setState(() => _missionReminders = v),
                ),
              ],
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 24)),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.buttonFill(context),
              foregroundColor: AppColors.onButton(context),
              minimumSize: const Size.fromHeight(52),
            ),
            child: _saving
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.onButton(context),
                    ),
                  )
                : const Text('Save preferences'),
          ),
        ],
      ),
    );
  }
}
